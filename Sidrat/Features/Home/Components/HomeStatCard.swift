//
//  HomeStatCard.swift
//  Sidrat
//
//  Statistics card components for home screen
//  Extracted from HomeView.swift for maintainability
//

import SwiftUI

// MARK: - Stat Card

/// Compact statistics card showing a single metric
/// Used in home screen stats section
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .cardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Streak Badge (Legacy)

/// Legacy streak badge component
/// Note: EnhancedStreakBadge in Components.swift is preferred for new implementations
struct StreakBadge: View {
    let streak: Int
    
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.brandAccent)
            
            Text("\(streak)")
                .font(.labelLarge)
                .foregroundStyle(.textPrimary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.brandAccent.opacity(0.1))
        .clipShape(Capsule())
        .accessibilityLabel("Streak: \(streak) days")
    }
}

// MARK: - Preview

#Preview("Stat Cards") {
    HStack(spacing: Spacing.md) {
        StatCard(
            title: "Total XP",
            value: "250",
            icon: "star.fill",
            color: .brandAccent
        )
        
        StatCard(
            title: "Lessons",
            value: "12",
            icon: "book.fill",
            color: .brandSecondary
        )
        
        StatCard(
            title: "Streak",
            value: "5",
            icon: "flame.fill",
            color: .brandPrimary
        )
    }
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Streak Badge") {
    VStack(spacing: Spacing.md) {
        StreakBadge(streak: 1)
        StreakBadge(streak: 7)
        StreakBadge(streak: 30)
        StreakBadge(streak: 100)
    }
    .padding()
}
