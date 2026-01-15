//
//  ScannableSummaryCard.swift
//  Sidrat
//
//  Quick glance summary for parents - 10-second overview
//  Shows: weekly progress, streak status, alerts, and next action
//

import SwiftUI

struct ScannableSummaryCard: View {
    let report: ProgressReport
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Always visible: Collapsed header
            headerSection
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }
            
            // Expandable: Detailed view
            if isExpanded {
                detailSection
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Header Section (Always Visible)
    
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                // Status icon
                statusIcon
                
                // Main summary text
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("This Week")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                    
                    HStack(spacing: Spacing.xs) {
                        Text(summaryText)
                            .font(.labelLarge)
                            .foregroundStyle(.textPrimary)
                        
                        statusBadge
                    }
                    
                    // Secondary info
                    Text(secondaryInfo)
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Expand/collapse indicator
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.brandPrimary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            
            // Alert banner (if applicable)
            if let alert = urgentAlert {
                alertBanner(alert)
            }
        }
        .padding(Spacing.md)
    }
    
    // MARK: - Detail Section (Expandable)
    
    private var detailSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Divider()
                .padding(.horizontal, Spacing.md)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Detailed metrics
                detailRow(
                    icon: "book.fill",
                    label: "Lessons completed",
                    value: "\(report.weekComparison.thisWeekCount)",
                    trend: report.weekComparison.trend
                )
                
                detailRow(
                    icon: "flame.fill",
                    label: "Current streak",
                    value: "\(report.currentStreak) days",
                    trend: nil
                )
                
                detailRow(
                    icon: "star.fill",
                    label: "XP earned this week",
                    value: "\(report.weekComparison.thisWeekXP)",
                    trend: nil
                )
                
                // Next action
                if let nextAction = suggestedNextAction {
                    Divider()
                        .padding(.vertical, Spacing.xxs)
                    
                    nextActionRow(nextAction)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.md)
        }
    }
    
    // MARK: - Status Icon
    
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.1))
                .frame(width: 40, height: 40)
            
            Image(systemName: statusIconName)
                .font(.system(size: 20))
                .foregroundStyle(statusColor)
        }
    }
    
    // MARK: - Detail Row
    
    private func detailRow(icon: String, label: String, value: String, trend: Trend?) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.textTertiary)
                .frame(width: 24)
            
            Text(label)
                .font(.bodySmall)
                .foregroundStyle(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: Spacing.xxs) {
                Text(value)
                    .font(.labelMedium)
                    .foregroundStyle(.textPrimary)
                
                if let trend = trend {
                    Image(systemName: trend.iconName)
                        .font(.caption2)
                        .foregroundStyle(trendColor(trend))
                }
            }
        }
    }
    
    // MARK: - Next Action Row
    
    private func nextActionRow(_ action: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "target")
                .font(.body)
                .foregroundStyle(.brandPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Next step")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                
                Text(action)
                    .font(.bodySmall)
                    .foregroundStyle(.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.sm)
        .background(Color.brandPrimary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
    
    // MARK: - Alert Banner
    
    private func alertBanner(_ alert: DashboardAlert) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: alert.icon)
                .font(.body)
                .foregroundStyle(alert.color)
            
            Text(alert.message)
                .font(.bodySmall)
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(alert.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
    
    // MARK: - Computed Properties
    
    private var summaryText: String {
        let weeklyGoal = 7 // TODO: Get from child settings
        let completed = report.weekComparison.thisWeekCount
        
        if completed >= weeklyGoal {
            return "\(completed) lessons (Goal met!)"
        } else if completed == 0 {
            return "No lessons yet"
        } else {
            return "\(completed)/\(weeklyGoal) lessons"
        }
    }
    
    private var secondaryInfo: String {
        "\(report.currentStreak)-day streak | \(report.weekComparison.thisWeekXP) XP"
    }
    
    private var statusBadge: some View {
        let weeklyGoal = 7
        let completed = report.weekComparison.thisWeekCount
        let percentage = Double(completed) / Double(weeklyGoal)
        
        let (icon, color): (String, Color) = {
            if percentage >= 1.0 {
                return ("star.fill", .brandAccent)
            } else if percentage >= 0.7 {
                return ("arrow.up.circle.fill", .success)
            } else if percentage >= 0.4 {
                return ("book.circle.fill", .brandPrimary)
            } else if completed > 0 {
                return ("leaf.fill", .success)
            } else {
                return ("pause.circle.fill", .textTertiary)
            }
        }()
        
        return Image(systemName: icon)
            .font(.body)
            .foregroundStyle(color)
    }
    
    private var statusColor: Color {
        let weeklyGoal = 7
        let completed = report.weekComparison.thisWeekCount
        
        if completed >= weeklyGoal {
            return .success
        } else if completed >= weeklyGoal / 2 {
            return .brandPrimary
        } else if completed > 0 {
            return .warning
        } else {
            return .textTertiary
        }
    }
    
    private var statusIconName: String {
        let weeklyGoal = 7
        let completed = report.weekComparison.thisWeekCount
        
        if completed >= weeklyGoal {
            return "checkmark.circle.fill"
        } else if completed >= weeklyGoal / 2 {
            return "circle.lefthalf.filled"
        } else if completed > 0 {
            return "circle.dashed"
        } else {
            return "circle"
        }
    }
    
    private var urgentAlert: DashboardAlert? {
        // Check for alerts in priority order
        
        // 1. Streak at risk (expires today)
        if report.currentStreak > 0 && report.weekComparison.thisWeekCount == 0 {
            let calendar = Calendar.current
            if let lastCompleted = report.recentLessons.first?.completedAt,
               !calendar.isDateInToday(lastCompleted) {
                return DashboardAlert(
                    type: .streakAtRisk,
                    message: "Streak expires today! Complete a lesson to keep it going.",
                    icon: "flame.fill",
                    color: .error
                )
            }
        }
        
        // 2. No progress this week
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: Date())
        if dayOfWeek >= 4 && report.weekComparison.thisWeekCount == 0 {
            return DashboardAlert(
                type: .noProgressThisWeek,
                message: "No lessons completed this week. Let's start today!",
                icon: "exclamationmark.triangle.fill",
                color: .warning
            )
        }
        
        // 3. Category stagnation (TODO: needs more data)
        
        return nil
    }
    
    private var suggestedNextAction: String? {
        // Prioritize next action based on current state
        
        // If no lessons this week, encourage starting
        if report.weekComparison.thisWeekCount == 0 {
            return "Complete today's lesson to start the week strong"
        }
        
        // If behind on goal
        let weeklyGoal = 7
        if report.weekComparison.thisWeekCount < weeklyGoal {
            let remaining = weeklyGoal - report.weekComparison.thisWeekCount
            return "Complete \(remaining) more lesson\(remaining == 1 ? "" : "s") to reach weekly goal"
        }
        
        // If goal met
        if report.weekComparison.thisWeekCount >= weeklyGoal {
            return "Goal met! Keep the momentum going"
        }
        
        // Default
        return "Continue learning journey"
    }
    
    private func trendColor(_ trend: Trend) -> Color {
        switch trend {
        case .improving: return .success
        case .declining: return .warning
        case .stable: return .textTertiary
        }
    }
}

// MARK: - Dashboard Alert

struct DashboardAlert {
    enum AlertType {
        case streakAtRisk
        case noProgressThisWeek
        case strugglingTopic
        case milestone
    }
    
    let type: AlertType
    let message: String
    let icon: String
    let color: Color
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.lg) {
        // Active progress
        ScannableSummaryCard(
            report: ProgressReport(
                childId: UUID(),
                childName: "Zainab",
                childAvatarId: "cat",
                reportDate: Date(),
                reportPeriod: .thisWeek,
                totalLessonsCompleted: 15,
                totalXP: 1200,
                currentStreak: 5,
                longestStreak: 7,
                periodLessonsCompleted: 4,
                periodXPEarned: 320,
                estimatedLearningTimeMinutes: 20,
                weekComparison: WeekComparison(
                    thisWeekCount: 4,
                    lastWeekCount: 3,
                    thisWeekXP: 320,
                    lastWeekXP: 240
                ),
                dailyActivity: [],
                categoryProgress: [],
                recentAchievements: [],
                recentLessons: [
                    RecentLesson(
                        id: UUID(),
                        title: "Who is Allah?",
                        completedAt: Date().addingTimeInterval(-3600),
                        xpEarned: 80,
                        score: 95
                    )
                ],
                suggestedActivities: [],
                suggestedActions: [],
                engagementScore: 85,
                engagementInsights: EngagementInsights(
                    consistencyScore: 90,
                    frequencyScore: 80,
                    completionScore: 85
                ),
                weeklyLessonCounts: [7, 6, 7, 7, 6, 7, 7, 7],
                velocityTrend: .stable
            )
        )
        
        // No progress this week
        ScannableSummaryCard(
            report: ProgressReport(
                childId: UUID(),
                childName: "Omar",
                childAvatarId: "lion",
                reportDate: Date(),
                reportPeriod: .thisWeek,
                totalLessonsCompleted: 8,
                totalXP: 640,
                currentStreak: 0,
                longestStreak: 5,
                periodLessonsCompleted: 0,
                periodXPEarned: 0,
                estimatedLearningTimeMinutes: 0,
                weekComparison: WeekComparison(
                    thisWeekCount: 0,
                    lastWeekCount: 3,
                    thisWeekXP: 0,
                    lastWeekXP: 240
                ),
                dailyActivity: [],
                categoryProgress: [],
                recentAchievements: [],
                recentLessons: [],
                suggestedActivities: [],
                suggestedActions: [],
                engagementScore: 25,
                engagementInsights: EngagementInsights(
                    consistencyScore: 20,
                    frequencyScore: 30,
                    completionScore: 25
                ),
                weeklyLessonCounts: [5, 4, 3, 2, 2, 1, 1, 0],
                velocityTrend: .declining
            )
        )
        
        Spacer()
    }
    .padding(Spacing.md)
    .background(Color.backgroundSecondary)
}
