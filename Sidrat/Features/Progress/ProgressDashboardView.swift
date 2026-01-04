//
//  ProgressView.swift
//  Sidrat
//
//  Progress tracking and achievements
//

import SwiftUI
import SwiftData

struct ProgressDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.modelContext) private var modelContext
    @Query private var children: [Child]
    @Query(sort: \Lesson.order) private var lessons: [Lesson]
    @State private var selectedTab = 0
    @State private var achievementService: AchievementService?
    @State private var showingAchievementUnlock = false
    @State private var pendingAchievements: [AchievementType] = []
    
    private var currentChild: Child? {
        guard let childId = appState.currentChildId,
              let uuid = UUID(uuidString: childId) else { return nil }
        return children.first { $0.id == uuid }
    }
    
    // Get unlocked achievement types
    private var unlockedAchievements: [AchievementType] {
        currentChild?.achievements.map { $0.achievementType } ?? []
    }
    
    // Get completed lessons with their info
    private var completedLessonsInfo: [(lesson: Lesson, completedAt: Date, xp: Int)] {
        guard let child = currentChild else { return [] }
        
        var result: [(lesson: Lesson, completedAt: Date, xp: Int)] = []
        
        for progress in child.lessonProgress.filter({ $0.isCompleted }) {
            if let lesson = lessons.first(where: { $0.id == progress.lessonId }),
               let completedAt = progress.completedAt {
                result.append((lesson: lesson, completedAt: completedAt, xp: progress.xpEarned))
            }
        }
        
        return result.sorted { $0.completedAt > $1.completedAt }
    }
    
    // Count completed lessons this week
    private var weeklyLessonsCompleted: Int {
        guard let child = currentChild else { return 0 }
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        
        return child.lessonProgress.filter { progress in
            guard let completedAt = progress.completedAt else { return false }
            return completedAt >= startOfWeek
        }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Stats overview
                    statsOverview
                    
                    // Tab selector
                    tabSelector
                    
                    // Content based on tab
                    if selectedTab == 0 {
                        treeViewSection
                    } else if selectedTab == 1 {
                        achievementsSection
                    } else {
                        learningHistorySection
                    }
                }
                .padding()
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Progress")
            .onAppear {
                if achievementService == nil {
                    achievementService = AchievementService(modelContext: modelContext)
                }
                
                // Check for new achievements when view appears
                if let child = currentChild, let service = achievementService {
                    let newAchievements = service.checkAndUnlockAchievements(for: child)
                    if !newAchievements.isEmpty {
                        pendingAchievements = newAchievements
                        showingAchievementUnlock = true
                    }
                }
            }
        }
        .overlay {
            // Achievement unlock celebration overlay
            if showingAchievementUnlock, let achievement = pendingAchievements.first {
                AchievementUnlockView(achievement: achievement) {
                    // Remove the shown achievement from pending
                    pendingAchievements.removeFirst()
                    
                    // If more achievements pending, keep showing
                    if pendingAchievements.isEmpty {
                        showingAchievementUnlock = false
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .zIndex(999)
            }
        }
    }
    
    // MARK: - Stats Overview
    
    private var statsOverview: some View {
        StatsOverviewCard(
            totalXP: currentChild?.totalXP ?? 0,
            currentStreak: currentChild?.currentStreak ?? 0,
            totalLessons: currentChild?.totalLessonsCompleted ?? 0,
            weeklyCompleted: weeklyLessonsCompleted,
            weeklyGoal: 5
        )
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "Tree", isSelected: selectedTab == 0) {
                withAnimation { selectedTab = 0 }
            }
            
            TabButton(title: "Badges", isSelected: selectedTab == 1) {
                withAnimation { selectedTab = 1 }
            }
            
            TabButton(title: "History", isSelected: selectedTab == 2) {
                withAnimation { selectedTab = 2 }
            }
        }
        .padding(4)
        .background(Color.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    // MARK: - Tree View Section
    
    private var treeViewSection: some View {
        VStack(spacing: Spacing.md) {
            if let child = currentChild {
                // Legend showing tree growth state
                TreeLegendView(growthState: calculateGrowthState())
                
                // Main tree visualization
                // NOTE: Tree is now part of the outer ScrollView - no inner scroll
                LearningTreeView(child: child, lessons: lessons, modelContext: modelContext)
                    .id(child.id) // Stabilize identity to prevent unnecessary recreations
            } else {
                // Empty state when no child selected
                EmptyState(
                    icon: "person.crop.circle.badge.questionmark",
                    title: "No Profile Selected",
                    message: "Select a child profile to view their learning tree"
                )
            }
        }
    }
    
    /// Calculate tree growth state based on completion percentage
    private func calculateGrowthState() -> TreeGrowthState {
        guard let child = currentChild else { return .skeleton }
        
        let completedCount = child.lessonProgress.filter { $0.isCompleted }.count
        let totalLessons = lessons.count
        
        guard totalLessons > 0 else { return .skeleton }
        
        let percentage = Double(completedCount) / Double(totalLessons)
        
        switch percentage {
        case 0..<0.25:
            return .skeleton
        case 0.25..<0.50:
            return .sprouting
        case 0.50..<0.75:
            return .growing
        default:
            return .flourishing
        }
    }
    
    // MARK: - Achievements Section
    
    private var achievementsSection: some View {
        AchievementsBadgeGrid(unlockedAchievements: unlockedAchievements)
    }
    
    // MARK: - Learning History Section
    
    private var learningHistorySection: some View {
        LearningHistoryList(completedLessonsInfo: completedLessonsInfo)
    }
}

// MARK: - Supporting Views

private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.labelMedium)
                .foregroundStyle(isSelected ? .textPrimary : .textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.backgroundPrimary : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        }
    }
}

#Preview {
    ProgressDashboardView()
        .environment(AppState())
}
