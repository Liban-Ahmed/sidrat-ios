//
//  ProgressReportService.swift
//  Sidrat
//
//  Service for generating progress reports for Parent Dashboard (US-304)
//  Aggregates child progress data, calculates statistics, and recommends activities
//

import SwiftUI
import SwiftData

@Observable
final class ProgressReportService {
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    
    // MARK: - Cache
    
    /// Cached reports with expiration (5 minutes)
    private var reportCache: [String: (report: ProgressReport, timestamp: Date)] = [:]
    private let cacheExpirationSeconds: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// Generate a comprehensive progress report for a child
    /// - Parameters:
    ///   - child: The child to generate the report for
    ///   - period: The time period to focus on
    /// - Returns: A complete ProgressReport
    func generateReport(for child: Child, period: ReportPeriod) -> ProgressReport {
        let cacheKey = "\(child.id.uuidString)-\(period.rawValue)"
        
        // Check cache
        if let cached = reportCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheExpirationSeconds {
            #if DEBUG
            print("[ProgressReportService] Returning cached report for \(child.name)")
            #endif
            return cached.report
        }
        
        #if DEBUG
        print("[ProgressReportService] Generating new report for \(child.name), period: \(period.rawValue)")
        #endif
        
        // Fetch all lessons
        let allLessons = fetchAllLessons()
        let allActivities = fetchAllActivities()
        
        // Calculate all the components
        let categoryProgress = calculateCategoryProgress(for: child, lessons: allLessons)
        let weekComparison = compareWeekProgress(for: child)
        let (periodLessons, periodXP) = calculatePeriodProgress(for: child, period: period)
        let learningTime = calculateLearningTime(for: child, period: period, lessons: allLessons)
        let recentLessons = getRecentLessons(for: child, period: period, lessons: allLessons)
        let recentAchievements = getRecentAchievements(for: child)
        let recommendations = recommendActivities(for: child, activities: allActivities)
        let dailyActivity = calculateDailyActivity(for: child)
        
        let report = ProgressReport(
            childId: child.id,
            childName: child.name,
            childAvatarId: child.avatarId,
            reportDate: Date(),
            reportPeriod: period,
            totalLessonsCompleted: child.totalLessonsCompleted,
            totalXP: child.totalXP,
            currentStreak: child.currentStreak,
            longestStreak: child.longestStreak,
            periodLessonsCompleted: periodLessons,
            periodXPEarned: periodXP,
            estimatedLearningTimeMinutes: learningTime,
            weekComparison: weekComparison,
            dailyActivity: dailyActivity,
            categoryProgress: categoryProgress,
            recentAchievements: recentAchievements,
            recentLessons: recentLessons,
            suggestedActivities: recommendations
        )
        
        // Cache the report
        reportCache[cacheKey] = (report, Date())
        
        return report
    }
    
    /// Invalidate cached reports (call after lesson completion)
    func invalidateCache() {
        reportCache.removeAll()
        #if DEBUG
        print("[ProgressReportService] Cache invalidated")
        #endif
    }
    
    /// Invalidate cache for a specific child
    func invalidateCache(for childId: UUID) {
        reportCache = reportCache.filter { !$0.key.hasPrefix(childId.uuidString) }
        #if DEBUG
        print("[ProgressReportService] Cache invalidated for child: \(childId)")
        #endif
    }
    
    // MARK: - Category Progress Calculation
    
    /// Calculate progress statistics for each lesson category
    /// - Parameters:
    ///   - child: The child to calculate progress for
    ///   - lessons: All available lessons
    /// - Returns: Array of CategoryStats for each category
    func calculateCategoryProgress(for child: Child, lessons: [Lesson]? = nil) -> [CategoryStats] {
        let allLessons = lessons ?? fetchAllLessons()
        let completedLessonIds = Set(child.lessonProgress.filter { $0.isCompleted }.map { $0.lessonId })
        
        var result: [CategoryStats] = []
        
        for category in LessonCategory.allCases {
            let categoryLessons = allLessons.filter { $0.category == category }
            let completedInCategory = categoryLessons.filter { completedLessonIds.contains($0.id) }
            
            // Get recent lessons for this category (last 5)
            let recentLessonsForCategory: [RecentLesson] = completedInCategory
                .compactMap { lesson -> RecentLesson? in
                    guard let progress = child.lessonProgress.first(where: {
                        $0.lessonId == lesson.id && $0.isCompleted
                    }),
                    let completedAt = progress.completedAt else {
                        return nil
                    }
                    
                    return RecentLesson(
                        id: lesson.id,
                        title: lesson.title,
                        completedAt: completedAt,
                        xpEarned: progress.xpEarned,
                        score: progress.score
                    )
                }
                .sorted { $0.completedAt > $1.completedAt }
                .prefix(5)
                .map { $0 }
            
            let stats = CategoryStats(
                category: category,
                completedCount: completedInCategory.count,
                totalCount: categoryLessons.count,
                recentLessons: recentLessonsForCategory
            )
            
            result.append(stats)
        }
        
        return result
    }
    
    // MARK: - Week Comparison
    
    /// Compare this week's progress to last week's
    /// - Parameter child: The child to compare progress for
    /// - Returns: WeekComparison with counts and trend
    func compareWeekProgress(for child: Child) -> WeekComparison {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate start of this week and last week
        let startOfThisWeek = calendar.date(from: calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear],
            from: now
        )) ?? now
        
        let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek) ?? now
        
        // Filter completed lessons by week
        let thisWeekProgress = child.lessonProgress.filter { progress in
            guard progress.isCompleted, let completedAt = progress.completedAt else { return false }
            return completedAt >= startOfThisWeek && completedAt <= now
        }
        
        let lastWeekProgress = child.lessonProgress.filter { progress in
            guard progress.isCompleted, let completedAt = progress.completedAt else { return false }
            return completedAt >= startOfLastWeek && completedAt < startOfThisWeek
        }
        
        return WeekComparison(
            thisWeekCount: thisWeekProgress.count,
            lastWeekCount: lastWeekProgress.count,
            thisWeekXP: thisWeekProgress.reduce(0) { $0 + $1.xpEarned },
            lastWeekXP: lastWeekProgress.reduce(0) { $0 + $1.xpEarned }
        )
    }
    
    // MARK: - Learning Time Calculation
    
    /// Calculate estimated learning time based on completed lessons
    /// Note: This is an estimate based on lesson durations, not actual tracked time (privacy-friendly)
    /// - Parameters:
    ///   - child: The child to calculate time for
    ///   - period: The time period to consider
    ///   - lessons: All available lessons (optional, will fetch if nil)
    /// - Returns: Estimated learning time in minutes
    func calculateLearningTime(for child: Child, period: ReportPeriod, lessons: [Lesson]? = nil) -> Int {
        let allLessons = lessons ?? fetchAllLessons()
        let dateRange = period.dateRange
        
        // Get completed lessons in the period
        let completedInPeriod = child.lessonProgress.filter { progress in
            guard progress.isCompleted, let completedAt = progress.completedAt else { return false }
            return completedAt >= dateRange.start && completedAt <= dateRange.end
        }
        
        // Sum up lesson durations
        var totalMinutes = 0
        for progress in completedInPeriod {
            if let lesson = allLessons.first(where: { $0.id == progress.lessonId }) {
                totalMinutes += lesson.durationMinutes
            }
        }
        
        return totalMinutes
    }
    
    // MARK: - Activity Recommendations
    
    /// Recommend family activities based on the child's recent learning
    /// - Parameters:
    ///   - child: The child to recommend activities for
    ///   - activities: All available family activities (optional, will fetch if nil)
    /// - Returns: Array of ActivityRecommendation sorted by relevance
    func recommendActivities(for child: Child, activities: [FamilyActivity]? = nil) -> [ActivityRecommendation] {
        let allActivities = activities ?? fetchAllActivities()
        
        // Get categories with recent progress (last 2 weeks)
        let recentCategories = identifyRecentCategories(for: child)
        
        // Filter and score activities
        var recommendations: [ActivityRecommendation] = []
        
        for activity in allActivities {
            // Skip already completed activities
            if activity.isCompleted { continue }
            
            let (score, reason) = calculateActivityRelevance(
                activity,
                for: child,
                recentCategories: recentCategories
            )
            
            // Only include activities with some relevance
            if score > 0 {
                recommendations.append(ActivityRecommendation(
                    activity: activity,
                    relevanceScore: score,
                    relevanceReason: reason
                ))
            }
        }
        
        // Sort by relevance and take top 3
        return recommendations
            .sorted { $0.relevanceScore > $1.relevanceScore }
            .prefix(3)
            .map { $0 }
    }
    
    // MARK: - Daily Activity Calculation
    
    /// Calculate daily activity for the last 7 days
    /// - Parameter child: The child to calculate activity for
    /// - Returns: Array of DailyActivity
    func calculateDailyActivity(for child: Child) -> [DailyActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var activities: [DailyActivity] = []
        
        // Loop through last 7 days (including today)
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -6 + i, to: today) else { continue }
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date)!
            
            // Filter lessons completed on this day
            let completedOnDay = child.lessonProgress.filter { progress in
                guard progress.isCompleted, let completedAt = progress.completedAt else { return false }
                return completedAt >= date && completedAt < nextDate
            }
            
            let count = completedOnDay.count
            let xp = completedOnDay.reduce(0) { $0 + $1.xpEarned }
            
            activities.append(DailyActivity(date: date, lessonsCompleted: count, xpEarned: xp))
        }
        
        return activities
    }
    
    // MARK: - Private Helpers
    
    /// Fetch all lessons from the database
    private func fetchAllLessons() -> [Lesson] {
        var descriptor = FetchDescriptor<Lesson>()
        descriptor.sortBy = [SortDescriptor(\Lesson.order)]
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Fetch all family activities from the database
    private func fetchAllActivities() -> [FamilyActivity] {
        var descriptor = FetchDescriptor<FamilyActivity>()
        descriptor.sortBy = [SortDescriptor(\FamilyActivity.weekNumber)]
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Calculate progress for a specific period
    private func calculatePeriodProgress(for child: Child, period: ReportPeriod) -> (lessons: Int, xp: Int) {
        let dateRange = period.dateRange
        
        let periodProgress = child.lessonProgress.filter { progress in
            guard progress.isCompleted, let completedAt = progress.completedAt else { return false }
            return completedAt >= dateRange.start && completedAt <= dateRange.end
        }
        
        let lessonCount = periodProgress.count
        let xpEarned = periodProgress.reduce(0) { $0 + $1.xpEarned }
        
        return (lessonCount, xpEarned)
    }
    
    /// Get recent lessons completed in a period
    private func getRecentLessons(for child: Child, period: ReportPeriod, lessons: [Lesson]) -> [RecentLesson] {
        let dateRange = period.dateRange
        
        return child.lessonProgress
            .filter { progress in
                guard progress.isCompleted, let completedAt = progress.completedAt else { return false }
                return completedAt >= dateRange.start && completedAt <= dateRange.end
            }
            .compactMap { progress -> RecentLesson? in
                guard let lesson = lessons.first(where: { $0.id == progress.lessonId }),
                      let completedAt = progress.completedAt else {
                    return nil
                }
                
                return RecentLesson(
                    id: lesson.id,
                    title: lesson.title,
                    completedAt: completedAt,
                    xpEarned: progress.xpEarned,
                    score: progress.score
                )
            }
            .sorted { $0.completedAt > $1.completedAt }
    }
    
    /// Get achievements unlocked in the last 30 days
    private func getRecentAchievements(for child: Child) -> [AchievementType] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        return child.achievements
            .filter { $0.unlockedAt >= thirtyDaysAgo }
            .sorted { $0.unlockedAt > $1.unlockedAt }
            .map { $0.achievementType }
    }
    
    /// Identify categories with recent progress (last 2 weeks)
    private func identifyRecentCategories(for child: Child) -> Set<LessonCategory> {
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let allLessons = fetchAllLessons()
        
        // Get lesson IDs completed in the last 2 weeks
        let recentLessonIds = Set(child.lessonProgress
            .filter { progress in
                guard progress.isCompleted, let completedAt = progress.completedAt else { return false }
                return completedAt >= twoWeeksAgo
            }
            .map { $0.lessonId })
        
        // Map to categories
        let recentCategories = allLessons
            .filter { recentLessonIds.contains($0.id) }
            .map { $0.category }
        
        return Set(recentCategories)
    }
    
    /// Calculate relevance score for an activity
    private func calculateActivityRelevance(
        _ activity: FamilyActivity,
        for child: Child,
        recentCategories: Set<LessonCategory>
    ) -> (score: Double, reason: String) {
        var score = 0.0
        var reasons: [String] = []
        
        // Recent category match: +20 points
        if recentCategories.contains(activity.relatedCategory) {
            score += 20.0
            reasons.append("Matches recent learning in \(activity.relatedCategory.rawValue)")
        }
        
        // Week alignment: +10 points if activity week matches child's current week
        if activity.weekNumber == child.currentWeekNumber {
            score += 10.0
            reasons.append("Matches current week")
        }
        
        // Not yet completed: +15 points (already filtered, but reinforcing)
        if !activity.isCompleted {
            score += 15.0
        }
        
        // Lower week number for newer learners: +5 points if it's an early activity
        if activity.weekNumber <= 2 && child.totalLessonsCompleted < 10 {
            score += 5.0
            reasons.append("Great for getting started")
        }
        
        // Category progress: Prefer activities for categories with some progress
        let categoryProgress = child.lessonProgress.filter { progress in
            guard progress.isCompleted else { return false }
            // We'd need to look up lesson category here, using a simplified approach
            return true
        }
        
        if categoryProgress.count > 0 {
            score += 5.0
        }
        
        // Build reason string
        let reason = reasons.isEmpty ? "Recommended activity" : reasons.first ?? "Recommended"
        
        return (score, reason)
    }
}
