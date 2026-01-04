//
//  AchievementsBadgeGrid.swift
//  Sidrat
//
//  Grid display of achievement badges
//

import SwiftUI

struct AchievementsBadgeGrid: View {
    let unlockedAchievements: [AchievementType]
    
    var body: some View {
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
}

// MARK: - Supporting View

private struct AchievementCard: View {
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.title) achievement")
        .accessibilityValue(isUnlocked ? "Unlocked" : "Locked")
        .accessibilityHint(isUnlocked ? "" : "Complete requirements to unlock")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        AchievementsBadgeGrid(
            unlockedAchievements: [.firstLesson, .streak7]
        )
        
        AchievementsBadgeGrid(
            unlockedAchievements: []
        )
    }
    .padding()
    .background(Color.backgroundSecondary)
}
