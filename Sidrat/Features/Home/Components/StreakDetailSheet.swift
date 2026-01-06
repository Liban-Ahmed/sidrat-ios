//
//  StreakDetailSheet.swift
//  Sidrat
//
//  Detailed streak information sheet with history and milestones
//  US-303 Phase 3
//

import SwiftUI
import SwiftData

struct StreakDetailSheet: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    // MARK: - Properties
    
    let child: Child
    
    // MARK: - State
    
    // MARK: - Computed Properties
    
    private var streakService: StreakService {
        StreakService(modelContext: modelContext)
    }
    
    private var hoursRemaining: Int {
        streakService.hoursRemainingToday()
    }
    
    private var nextMilestone: StreakMilestone? {
        streakService.getNextMilestone(currentStreak: child.currentStreak)
    }
    
    private var completedMilestones: [AchievementType] {
        child.achievements
            .map { $0.achievementType }
            .filter { [.streak3, .streak7, .streak30, .streak100].contains($0) }
    }
    
    private var allMilestones: [(type: AchievementType, days: Int, unlocked: Bool)] {
        let milestoneTypes: [(AchievementType, Int)] = [
            (.streak3, 3),
            (.streak7, 7),
            (.streak30, 30),
            (.streak100, 100)
        ]
        
        return milestoneTypes.map { type, days in
            (type: type, days: days, unlocked: completedMilestones.contains(type))
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Current streak display
                    currentStreakSection
                    
                    // Milestone progress
                    if nextMilestone != nil {
                        milestoneProgressSection
                    }
                    
                    // All milestones
                    allMilestonesSection
                    
                    // Stats
                    statsSection
                }
                .padding(Spacing.lg)
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Streak Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Current Streak Section
    
    private var currentStreakSection: some View {
        VStack(spacing: Spacing.md) {
            // Large flame icon with animation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.brandAccent.opacity(0.3), .brandAccent.opacity(0.1)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.brandAccent, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            Text("\(child.currentStreak)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.textPrimary)
            
            Text(child.currentStreak == 1 ? "Day Streak" : "Days Streak")
                .font(.title3)
                .foregroundStyle(.textSecondary)
            
            if hoursRemaining > 0 && hoursRemaining <= 12 {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    Text("\(hoursRemaining) hours left today")
                        .font(.bodySmall)
                }
                .foregroundStyle(.textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Color.backgroundSecondary)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current streak: \(child.currentStreak) days")
    }
    
    // MARK: - Milestone Progress Section
    
    private var milestoneProgressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Next Milestone")
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            StreakMilestoneProgress(
                currentStreak: child.currentStreak,
                nextMilestone: nextMilestone
            )
        }
    }
    
    // MARK: - All Milestones Section
    
    private var allMilestonesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Milestones")
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            VStack(spacing: Spacing.sm) {
                ForEach(allMilestones, id: \.type) { milestone in
                    milestoneBadge(milestone)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func milestoneBadge(_ milestone: (type: AchievementType, days: Int, unlocked: Bool)) -> some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(milestone.unlocked ? Color.success.opacity(0.1) : Color.backgroundSecondary)
                    .frame(width: 48, height: 48)
                
                Image(systemName: milestone.unlocked ? "checkmark.circle.fill" : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(milestone.unlocked ? .success : .textSecondary.opacity(0.5))
            }
            
            // Text
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(milestone.type.title)
                    .font(.labelLarge)
                    .foregroundStyle(milestone.unlocked ? .textPrimary : .textSecondary)
                
                Text("\(milestone.days) days")
                    .font(.bodySmall)
                    .foregroundStyle(.textSecondary)
            }
            
            Spacer()
            
            // XP reward
            if milestone.unlocked {
                Image(systemName: "star.fill")
                    .foregroundStyle(.brandAccent)
            } else {
                Text("+\(milestone.type.xpReward) XP")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .opacity(milestone.unlocked ? 1.0 : 0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(milestone.type.title), \(milestone.days) days, \(milestone.unlocked ? "unlocked" : "locked")")
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Statistics")
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            HStack(spacing: Spacing.md) {
                statCard(
                    title: "Longest",
                    value: "\(child.longestStreak)",
                    icon: "trophy.fill",
                    color: .brandAccent
                )
                
                statCard(
                    title: "Lessons",
                    value: "\(child.totalLessonsCompleted)",
                    icon: "book.fill",
                    color: .brandPrimary
                )
            }
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .cardShadow()
    }
}

// MARK: - Preview

#Preview("Streak Detail - Active Streak") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Child.self, configurations: config)
    
    let child = Child(
        name: "Test Child",
        birthYear: 2018,
        avatarId: "cat"
    )
    child.currentStreak = 12
    child.longestStreak = 15
    child.totalLessonsCompleted = 25
    
    container.mainContext.insert(child)
    
    return StreakDetailSheet(child: child)
    .modelContainer(container)
    .environment(AppState())
}

#Preview("Streak Detail - No Freeze") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Child.self, configurations: config)
    
    let child = Child(
        name: "Test Child",
        birthYear: 2018,
        avatarId: "cat"
    )
    child.currentStreak = 45
    child.longestStreak = 45
    child.totalLessonsCompleted = 50
    
    container.mainContext.insert(child)
    
    return StreakDetailSheet(child: child)
    .modelContainer(container)
    .environment(AppState())
}
