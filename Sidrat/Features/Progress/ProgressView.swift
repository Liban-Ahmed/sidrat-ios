//
//  ProgressView.swift
//  Sidrat
//
//  Progress tracking and achievements
//

import SwiftUI
import SwiftData

struct ProgressView: View {
    @Environment(AppState.self) private var appState
    @Query private var children: [Child]
    @Query(sort: \Lesson.order) private var lessons: [Lesson]
    @State private var selectedTab = 0
    
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
                        achievementsSection
                    } else {
                        learningHistorySection
                    }
                }
                .padding()
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Progress")
        }
    }
    
    // MARK: - Stats Overview
    
    private var statsOverview: some View {
        VStack(spacing: Spacing.md) {
            // Main stats row
            HStack(spacing: Spacing.md) {
                StatBox(
                    value: "\(currentChild?.totalXP ?? 0)",
                    label: "Total XP",
                    icon: "star.fill",
                    color: .brandAccent
                )
                
                StatBox(
                    value: "\(currentChild?.currentStreak ?? 0)",
                    label: "Day Streak",
                    icon: "flame.fill",
                    color: .error
                )
                
                StatBox(
                    value: "\(currentChild?.totalLessonsCompleted ?? 0)",
                    label: "Lessons",
                    icon: "book.fill",
                    color: .brandSecondary
                )
            }
            
            // Weekly progress bar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Weekly Goal")
                        .font(.labelMedium)
                        .foregroundStyle(.textPrimary)
                    
                    Spacer()
                    
                    Text("\(weeklyLessonsCompleted)/5 lessons")
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.backgroundTertiary)
                            .frame(height: 8)
                        
                        let progress = min(1.0, Double(weeklyLessonsCompleted) / 5.0)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient.primaryGradient)
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.spring(response: 0.4), value: weeklyLessonsCompleted)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "Achievements", isSelected: selectedTab == 0) {
                withAnimation { selectedTab = 0 }
            }
            
            TabButton(title: "History", isSelected: selectedTab == 1) {
                withAnimation { selectedTab = 1 }
            }
        }
        .padding(4)
        .background(Color.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    // MARK: - Achievements Section
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your Badges")
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                ForEach(AchievementType.allCases, id: \.self) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        isUnlocked: unlockedAchievements.contains(achievement)
                    )
                }
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Learning History Section
    
    private var learningHistorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recent Activity")
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            if completedLessonsInfo.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(.textTertiary)
                    
                    Text("No lessons completed yet")
                        .font(.bodyMedium)
                        .foregroundStyle(.textSecondary)
                    
                    Text("Complete your first lesson to see it here!")
                        .font(.bodySmall)
                        .foregroundStyle(.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(Array(completedLessonsInfo.prefix(5).enumerated()), id: \.offset) { index, info in
                        HistoryItem(
                            title: info.lesson.title,
                            category: info.lesson.category.rawValue,
                            xp: info.xp,
                            date: formatRelativeDate(info.completedAt)
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfDate = calendar.startOfDay(for: date)
        
        let days = calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day ?? 0
        
        switch days {
        case 0: return "Today"
        case 1: return "Yesterday"
        case 2...6: return "\(days) days ago"
        default:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .foregroundStyle(.textPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
    }
}

struct TabButton: View {
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

struct AchievementCard: View {
    let achievement: AchievementType
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.brandAccent.opacity(0.15) : Color.backgroundTertiary)
                    .frame(width: 56, height: 56)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundStyle(isUnlocked ? .brandAccent : .textTertiary)
            }
            
            Text(achievement.title)
                .font(.caption)
                .foregroundStyle(isUnlocked ? .textPrimary : .textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .opacity(isUnlocked ? 1 : 0.5)
    }
}

struct HistoryItem: View {
    let title: String
    let category: String
    let xp: Int
    let date: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.brandSecondary)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.labelMedium)
                    .foregroundStyle(.textPrimary)
                
                Text(category)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("+\(xp) XP")
                    .font(.labelSmall)
                    .foregroundStyle(.brandAccent)
                
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

#Preview {
    ProgressView()
        .environment(AppState())
}
