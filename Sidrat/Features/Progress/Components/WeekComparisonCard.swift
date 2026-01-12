//
//  WeekComparisonCard.swift
//  Sidrat
//
//  Week-over-week comparison card for Parent Progress Dashboard (US-304)
//  Shows side-by-side bar comparison with trend indicator
//

import SwiftUI

struct WeekComparisonCard: View {
    let comparison: WeekComparison
    
    @State private var animateThisWeek = false
    @State private var animateLastWeek = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            headerSection
            
            // Bar comparison
            barComparisonSection
            
            // Motivational message
            messageSection
        }
        .padding(Spacing.md)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateLastWeek = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                animateThisWeek = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Text("Weekly Progress")
                .font(.labelLarge)
                .foregroundStyle(.textPrimary)
            
            Spacer()
            
            trendBadge
        }
    }
    
    // MARK: - Trend Badge
    
    private var trendBadge: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: comparison.trend.iconName)
                .font(.caption)
            
            Text(comparison.shortDescription)
                .font(.caption)
        }
        .foregroundStyle(trendColor)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(trendColor.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Trend: \(comparison.trend.rawValue), \(comparison.shortDescription)")
    }
    
    // MARK: - Bar Comparison Section
    
    private var barComparisonSection: some View {
        HStack(alignment: .bottom, spacing: Spacing.lg) {
            // Last week bar
            weekBar(
                label: "Last Week",
                count: comparison.lastWeekCount,
                xp: comparison.lastWeekXP,
                isAnimated: animateLastWeek,
                color: .textTertiary,
                maxCount: maxBarValue
            )
            
            // This week bar
            weekBar(
                label: "This Week",
                count: comparison.thisWeekCount,
                xp: comparison.thisWeekXP,
                isAnimated: animateThisWeek,
                color: .brandPrimary,
                maxCount: maxBarValue
            )
        }
        .frame(height: 140)
        .padding(.horizontal, Spacing.sm)
    }
    
    // MARK: - Week Bar
    
    private func weekBar(
        label: String,
        count: Int,
        xp: Int,
        isAnimated: Bool,
        color: Color,
        maxCount: Int
    ) -> some View {
        VStack(spacing: Spacing.xs) {
            // Count label above bar
            VStack(spacing: 2) {
                Text("\(count)")
                    .font(.title2)
                    .foregroundStyle(.textPrimary)
                
                Text("lessons")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
            
            // Bar
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    
                    let barHeight = maxCount > 0 ? 
                        (CGFloat(count) / CGFloat(maxCount)) * geometry.size.height :
                        (count > 0 ? geometry.size.height * 0.2 : 0)
                    
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(color.opacity(0.2))
                        .overlay(
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: CornerRadius.small)
                                    .fill(barGradient(for: color))
                                    .frame(height: isAnimated ? max(barHeight, count > 0 ? 12 : 0) : 0)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                }
            }
            .frame(height: 80)
            
            // XP earned
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.brandAccent)
                Text("\(xp)")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
            
            // Label
            Text(label)
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(count) lessons, \(xp) XP earned")
    }
    
    // MARK: - Bar Gradient
    
    private func barGradient(for color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Message Section
    
    private var messageSection: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: messageIcon)
                .font(.title3)
                .foregroundStyle(trendColor)
            
            Text(comparison.message)
                .font(.bodySmall)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(trendColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
    
    // MARK: - Computed Properties
    
    private var maxBarValue: Int {
        max(comparison.thisWeekCount, comparison.lastWeekCount, 1)
    }
    
    private var trendColor: Color {
        switch comparison.trend {
        case .improving: return .success
        case .declining: return .warning
        case .stable: return .brandPrimary
        }
    }
    
    private var messageIcon: String {
        switch comparison.trend {
        case .improving: return "sparkles"
        case .declining: return "hand.wave"
        case .stable: return "checkmark.seal"
        }
    }
}

// MARK: - Preview

#Preview("Improving") {
    WeekComparisonCard(
        comparison: WeekComparison(
            thisWeekCount: 5,
            lastWeekCount: 3,
            thisWeekXP: 250,
            lastWeekXP: 150
        )
    )
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Declining") {
    WeekComparisonCard(
        comparison: WeekComparison(
            thisWeekCount: 2,
            lastWeekCount: 5,
            thisWeekXP: 100,
            lastWeekXP: 250
        )
    )
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Stable") {
    WeekComparisonCard(
        comparison: WeekComparison(
            thisWeekCount: 4,
            lastWeekCount: 4,
            thisWeekXP: 200,
            lastWeekXP: 200
        )
    )
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("First Week") {
    WeekComparisonCard(
        comparison: WeekComparison(
            thisWeekCount: 3,
            lastWeekCount: 0,
            thisWeekXP: 150,
            lastWeekXP: 0
        )
    )
    .padding()
    .background(Color.backgroundSecondary)
}
