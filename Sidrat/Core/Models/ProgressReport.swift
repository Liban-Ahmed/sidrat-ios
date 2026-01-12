//
//  ProgressReport.swift
//  Sidrat
//
//  Models for Parent Progress Dashboard (US-304)
//  Aggregated progress data for parent reporting
//

import Foundation

// MARK: - Report Period

/// Time period for filtering progress reports
enum ReportPeriod: String, CaseIterable, Identifiable {
    case thisWeek = "This Week"
    case lastWeek = "Last Week"
    case thisMonth = "This Month"
    case allTime = "All Time"
    
    var id: String { rawValue }
    
    /// Get date range for this period
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .thisWeek:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            return (startOfWeek, now)
            
        case .lastWeek:
            let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek) ?? now
            return (startOfLastWeek, startOfThisWeek)
            
        case .thisMonth:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            return (startOfMonth, now)
            
        case .allTime:
            // Use a very early date for "all time"
            let distantPast = calendar.date(byAdding: .year, value: -10, to: now) ?? now
            return (distantPast, now)
        }
    }
}

// MARK: - Trend

/// Week-over-week trend direction
enum Trend: String {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
    
    /// Icon for the trend
    var iconName: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    /// Color name for the trend (use with Color extension)
    var colorName: String {
        switch self {
        case .improving: return "success"
        case .declining: return "warning"
        case .stable: return "brandPrimary"
        }
    }
}

// MARK: - Week Comparison

/// Comparison between this week and last week's progress
struct WeekComparison {
    let thisWeekCount: Int
    let lastWeekCount: Int
    let thisWeekXP: Int
    let lastWeekXP: Int
    
    /// Determine the trend direction
    var trend: Trend {
        if thisWeekCount > lastWeekCount { return .improving }
        if thisWeekCount < lastWeekCount { return .declining }
        return .stable
    }
    
    /// Calculate percentage change in lessons completed
    var percentageChange: Double {
        guard lastWeekCount > 0 else {
            return thisWeekCount > 0 ? 100.0 : 0.0
        }
        return Double(thisWeekCount - lastWeekCount) / Double(lastWeekCount) * 100
    }
    
    /// User-friendly message based on the trend
    var message: String {
        switch trend {
        case .improving:
            if lastWeekCount == 0 {
                return "🌟 Great start! \(thisWeekCount) lesson\(thisWeekCount == 1 ? "" : "s") completed this week!"
            }
            return "📈 Amazing progress! \(thisWeekCount) lessons this week vs \(lastWeekCount) last week"
            
        case .declining:
            if thisWeekCount == 0 {
                return "Let's get back on track! Try completing a lesson today."
            }
            return "Keep going! You've completed \(thisWeekCount) lesson\(thisWeekCount == 1 ? "" : "s") so far this week."
            
        case .stable:
            if thisWeekCount == 0 {
                return "Ready to start learning? Let's begin today!"
            }
            return "Consistent learning! Keeping up the steady pace with \(thisWeekCount) lessons."
        }
    }
    
    /// Short description of the change
    var shortDescription: String {
        let diff = thisWeekCount - lastWeekCount
        if diff > 0 {
            return "+\(diff) from last week"
        } else if diff < 0 {
            return "\(diff) from last week"
        } else {
            return "Same as last week"
        }
    }
}

// MARK: - Category Stats

/// Progress statistics for a single lesson category
struct CategoryStats: Identifiable {
    let category: LessonCategory
    let completedCount: Int
    let totalCount: Int
    let recentLessons: [RecentLesson]
    
    var id: String { category.rawValue }
    
    /// Completion percentage (0.0 to 1.0)
    var completionPercentage: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    /// Formatted percentage string (e.g., "75%")
    var formattedPercentage: String {
        let percent = Int(completionPercentage * 100)
        return "\(percent)%"
    }
    
    /// Whether this category has any completed lessons
    var hasProgress: Bool {
        completedCount > 0
    }
    
    /// Whether this category is fully completed
    var isComplete: Bool {
        completedCount >= totalCount && totalCount > 0
    }
    
    /// Remaining lessons count
    var remainingCount: Int {
        max(0, totalCount - completedCount)
    }
}

/// Simplified lesson info for recent lessons display
struct RecentLesson: Identifiable {
    let id: UUID
    let title: String
    let completedAt: Date
    let xpEarned: Int
    let score: Int
    
    /// Formatted completion date
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: completedAt, relativeTo: Date())
    }
}

// MARK: - Activity Recommendation

/// A recommended family activity with relevance context
struct ActivityRecommendation: Identifiable {
    let activity: FamilyActivity
    let relevanceScore: Double
    let relevanceReason: String
    
    var id: UUID { activity.id }
}

// MARK: - Progress Report

/// Comprehensive progress report for a child
/// Used by Parent Progress Dashboard (US-304)
struct ProgressReport {
    // MARK: - Core Properties
    
    let childId: UUID
    let childName: String
    let childAvatarId: String
    let reportDate: Date
    let reportPeriod: ReportPeriod
    
    // MARK: - Overall Stats
    
    /// Total lessons completed (all time)
    let totalLessonsCompleted: Int
    
    /// Total XP earned (all time)
    let totalXP: Int
    
    /// Current streak in days
    let currentStreak: Int
    
    /// Longest streak achieved
    let longestStreak: Int
    
    /// Lessons completed in the selected period
    let periodLessonsCompleted: Int
    
    /// XP earned in the selected period
    let periodXPEarned: Int
    
    /// Estimated learning time in minutes for the period
    let estimatedLearningTimeMinutes: Int
    
    // MARK: - Comparisons
    
    /// Week-over-week comparison data
    let weekComparison: WeekComparison
    
    // MARK: - Category Breakdown
    
    /// Progress stats for each lesson category
    let categoryProgress: [CategoryStats]
    
    // MARK: - Recent Activity
    
    /// Recently unlocked achievements (last 30 days)
    let recentAchievements: [AchievementType]
    
    /// Lessons completed in the selected period
    let recentLessons: [RecentLesson]
    
    // MARK: - Recommendations
    
    /// Suggested family activities based on recent progress
    let suggestedActivities: [ActivityRecommendation]
    
    // MARK: - Computed Properties
    
    /// Average score across completed lessons in period
    var averageScore: Int {
        guard !recentLessons.isEmpty else { return 0 }
        let totalScore = recentLessons.reduce(0) { $0 + $1.score }
        return totalScore / recentLessons.count
    }
    
    /// Formatted learning time (e.g., "1h 25m")
    var formattedLearningTime: String {
        let hours = estimatedLearningTimeMinutes / 60
        let minutes = estimatedLearningTimeMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Overall progress percentage across all categories
    var overallProgress: Double {
        guard !categoryProgress.isEmpty else { return 0.0 }
        
        let totalCompleted = categoryProgress.reduce(0) { $0 + $1.completedCount }
        let totalLessons = categoryProgress.reduce(0) { $0 + $1.totalCount }
        
        guard totalLessons > 0 else { return 0.0 }
        return Double(totalCompleted) / Double(totalLessons)
    }
    
    /// Categories sorted by completion percentage (highest first)
    var sortedCategoryProgress: [CategoryStats] {
        categoryProgress.sorted { $0.completionPercentage > $1.completionPercentage }
    }
    
    /// Categories with no progress yet
    var categoriesNotStarted: [CategoryStats] {
        categoryProgress.filter { !$0.hasProgress }
    }
    
    /// Categories that are fully completed
    var completedCategories: [CategoryStats] {
        categoryProgress.filter { $0.isComplete }
    }
    
    /// Whether there is enough data for a meaningful report
    var hasEnoughData: Bool {
        totalLessonsCompleted > 0 || currentStreak > 0 || totalXP > 0
    }
}

// MARK: - Empty Report Factory

extension ProgressReport {
    /// Create an empty report for a child with no data
    static func empty(
        childId: UUID,
        childName: String,
        childAvatarId: String,
        period: ReportPeriod
    ) -> ProgressReport {
        ProgressReport(
            childId: childId,
            childName: childName,
            childAvatarId: childAvatarId,
            reportDate: Date(),
            reportPeriod: period,
            totalLessonsCompleted: 0,
            totalXP: 0,
            currentStreak: 0,
            longestStreak: 0,
            periodLessonsCompleted: 0,
            periodXPEarned: 0,
            estimatedLearningTimeMinutes: 0,
            weekComparison: WeekComparison(
                thisWeekCount: 0,
                lastWeekCount: 0,
                thisWeekXP: 0,
                lastWeekXP: 0
            ),
            categoryProgress: [],
            recentAchievements: [],
            recentLessons: [],
            suggestedActivities: []
        )
    }
}
