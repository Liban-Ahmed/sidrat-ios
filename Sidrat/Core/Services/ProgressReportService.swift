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
        let suggestedActions = generatePersonalizedActions(
            for: child,
            weekComparison: weekComparison,
            categoryProgress: categoryProgress,
            recentAchievements: recentAchievements,
            allActivities: allActivities
        )
        let (engagementScore, engagementInsights) = calculateEngagementScore(
            for: child,
            weekComparison: weekComparison,
            periodLessons: periodLessons
        )
        let completedLessons = child.lessonProgress.filter { $0.isCompleted }
        let (weeklyLessonCounts, velocityTrend) = calculateLearningVelocity(
            for: child,
            completedLessons: completedLessons
        )
        
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
            suggestedActivities: recommendations,
            suggestedActions: suggestedActions,
            engagementScore: engagementScore,
            engagementInsights: engagementInsights,
            weeklyLessonCounts: weeklyLessonCounts,
            velocityTrend: velocityTrend
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
    
    // MARK: - Personalized Action Generation (Quick Win #2)
    
    /// Generate 1-3 prioritized action items for parents
    /// Based on: weekly goals, struggling topics, streak status, achievements
    func generatePersonalizedActions(
        for child: Child,
        weekComparison: WeekComparison,
        categoryProgress: [CategoryStats],
        recentAchievements: [AchievementType],
        allActivities: [FamilyActivity]
    ) -> [PersonalizedAction] {
        var actions: [PersonalizedAction] = []
        
        // Priority 1: Streak at risk (most urgent)
        if child.currentStreak > 0 {
            let calendar = Calendar.current
            if let lastCompleted = child.lastLessonCompletedDate,
               !calendar.isDateInToday(lastCompleted) {
                actions.append(PersonalizedAction(
                    priority: .high,
                    title: "Complete today's lesson to maintain streak",
                    description: "\(child.name) has a \(child.currentStreak)-day streak at risk",
                    estimatedMinutes: 5,
                    impact: "Keep \(child.currentStreak)-day streak alive",
                    actionType: .streakMaintenance
                ))
            }
        }
        
        // Priority 2: Behind on weekly goal
        let weeklyGoal = child.weeklyLearningGoal
        let completed = weekComparison.thisWeekCount
        if completed < weeklyGoal {
            let remaining = weeklyGoal - completed
            let calendar = Calendar.current
            let dayOfWeek = calendar.component(.weekday, from: Date())
            
            // Only suggest if we're past Wednesday (day 4)
            if dayOfWeek >= 4 && remaining > 0 {
                let urgency: ActionPriority = remaining >= 4 ? .high : .medium
                actions.append(PersonalizedAction(
                    priority: urgency,
                    title: "Complete \(remaining) more lesson\(remaining == 1 ? "" : "s") this week",
                    description: "\(completed)/\(weeklyGoal) lessons completed. Let's reach the weekly goal!",
                    estimatedMinutes: remaining * 5,
                    impact: "Reach weekly goal",
                    actionType: .completeLesson
                ))
            }
        }
        
        // Priority 3: Struggling topics (based on low scores in recent lessons)
        // TODO: Implement once we track per-lesson scores
        // For now, we'll check if any category has very low progress
        if let strugglingCategory = categoryProgress.first(where: { 
            $0.completedCount > 0 && $0.completionPercentage < 0.3 
        }) {
            actions.append(PersonalizedAction(
                priority: .medium,
                title: "Review \(strugglingCategory.category.rawValue) concepts",
                description: "\(child.name) may benefit from revisiting this topic",
                estimatedMinutes: 10,
                impact: "Strengthen understanding",
                actionType: .reviewCategory
            ))
        }
        
        // Priority 4: Family activity reminder
        let incompleteFamilyActivities = allActivities.filter { !$0.isCompleted }
        if let nextActivity = incompleteFamilyActivities.first,
           weekComparison.thisWeekCount > 0 { // Only if child has done some lessons
            actions.append(PersonalizedAction(
                priority: .medium,
                title: "Complete this week's family activity",
                description: nextActivity.title,
                estimatedMinutes: 15,
                impact: "Strengthen family bond",
                actionType: .familyActivity
            ))
        }
        
        // Priority 5: Celebrate recent achievements
        if let recentAchievement = recentAchievements.first {
            actions.append(PersonalizedAction(
                priority: .low,
                title: "Celebrate \(child.name)'s achievement",
                description: "Earned the '\(recentAchievement.title)' badge!",
                estimatedMinutes: 5,
                impact: "Boost motivation",
                actionType: .celebrateMilestone
            ))
        }
        
        // Priority 6: Get started (if no progress this week)
        if weekComparison.thisWeekCount == 0 && actions.isEmpty {
            actions.append(PersonalizedAction(
                priority: .high,
                title: "Start this week's learning",
                description: "Complete today's lesson to begin the week",
                estimatedMinutes: 5,
                impact: "Build momentum",
                actionType: .completeLesson
            ))
        }
        
        // Return top 3 actions, prioritized
        return Array(actions
            .sorted { action1, action2 in
                // Sort by priority (high > medium > low)
                let priorityOrder: [ActionPriority: Int] = [.high: 3, .medium: 2, .low: 1]
                return (priorityOrder[action1.priority] ?? 0) > (priorityOrder[action2.priority] ?? 0)
            }
            .prefix(3))
    }
    
    // MARK: - Engagement Score Calculation (Quick Win #3)
    
    /// Calculate engagement quality score (0-100) based on multiple factors
    /// Returns: (score, insights breakdown)
    func calculateEngagementScore(
        for child: Child,
        weekComparison: WeekComparison,
        periodLessons: Int
    ) -> (score: Int, insights: EngagementInsights) {
        
        // Factor 1: Consistency (40 points) - Streak maintenance
        let consistencyScore = calculateConsistencyScore(for: child)
        
        // Factor 2: Frequency (30 points) - Lessons per week
        let frequencyScore = calculateFrequencyScore(weeklyLessons: weekComparison.thisWeekCount, goal: child.weeklyLearningGoal)
        
        // Factor 3: Completion Rate (30 points) - Finishing started lessons
        let completionScore = calculateCompletionScore(for: child)
        
        // Calculate weighted total (0-100)
        let totalScore = Int(
            (Double(consistencyScore) * 0.4) +
            (Double(frequencyScore) * 0.3) +
            (Double(completionScore) * 0.3)
        )
        
        // Generate recommendation
        let recommendation = generateEngagementRecommendation(
            score: totalScore,
            consistency: consistencyScore,
            frequency: frequencyScore,
            completion: completionScore
        )
        
        let insights = EngagementInsights(
            consistencyScore: consistencyScore,
            frequencyScore: frequencyScore,
            completionScore: completionScore,
            recommendation: recommendation
        )
        
        return (totalScore, insights)
    }
    
    /// Calculate consistency score based on streak maintenance
    private func calculateConsistencyScore(for child: Child) -> Int {
        let currentStreak = child.currentStreak
        let longestStreak = child.longestStreak
        
        // Score based on current streak
        var score: Int
        if currentStreak >= 30 {
            score = 100
        } else if currentStreak >= 14 {
            score = 90
        } else if currentStreak >= 7 {
            score = 75
        } else if currentStreak >= 3 {
            score = 60
        } else if currentStreak >= 1 {
            score = 40
        } else {
            score = 20
        }
        
        // Bonus: If close to longest streak (shows sustained effort)
        if longestStreak > 0 {
            let streakRatio = Double(currentStreak) / Double(longestStreak)
            if streakRatio >= 0.8 {
                score = min(100, score + 10) // Bonus for maintaining near-peak
            }
        }
        
        return score
    }
    
    /// Calculate frequency score based on lessons per week vs goal
    private func calculateFrequencyScore(weeklyLessons: Int, goal: Int) -> Int {
        guard goal > 0 else { return weeklyLessons > 0 ? 50 : 0 }
        
        let percentage = Double(weeklyLessons) / Double(goal)
        
        if percentage >= 1.0 {
            return 100 // Met or exceeded goal
        } else if percentage >= 0.8 {
            return 85 // Very close
        } else if percentage >= 0.6 {
            return 70 // On track
        } else if percentage >= 0.4 {
            return 50 // Some progress
        } else if percentage >= 0.2 {
            return 30 // Minimal progress
        } else if weeklyLessons > 0 {
            return 15 // At least started
        } else {
            return 0 // No lessons
        }
    }
    
    /// Calculate completion score based on finished vs started lessons
    private func calculateCompletionScore(for child: Child) -> Int {
        let allProgress = child.lessonProgress
        
        guard !allProgress.isEmpty else { return 0 }
        
        let completedCount = allProgress.filter { $0.isCompleted }.count
        let totalStarted = allProgress.count
        
        guard totalStarted > 0 else { return 0 }
        
        let completionRate = Double(completedCount) / Double(totalStarted)
        
        // Convert to 0-100 score
        let score = Int(completionRate * 100)
        
        // Bonus for high total completions (shows sustained engagement)
        if child.totalLessonsCompleted >= 30 {
            return min(100, score + 10)
        } else if child.totalLessonsCompleted >= 15 {
            return min(100, score + 5)
        }
        
        return score
    }
    
    /// Generate personalized recommendation based on scores
    private func generateEngagementRecommendation(
        score: Int,
        consistency: Int,
        frequency: Int,
        completion: Int
    ) -> String {
        // Identify weakest area
        let scores = [
            ("consistency", consistency),
            ("frequency", frequency),
            ("completion", completion)
        ].sorted { $0.1 < $1.1 }
        
        guard let weakest = scores.first else {
            return "Keep up the great work!"
        }
        
        // High engagement - just encourage
        if score >= 80 {
            return "Excellent engagement! Consistent daily practice is building strong habits."
        }
        
        // Medium-high engagement - gentle nudge
        if score >= 60 {
            switch weakest.0 {
            case "consistency":
                return "Try completing lessons at the same time each day to build consistency."
            case "frequency":
                return "Aim for one more lesson per week to reach your learning goal."
            case "completion":
                return "Great start! Focus on finishing each lesson for maximum benefit."
            default:
                return "You're doing well! Keep up the steady pace."
            }
        }
        
        // Medium engagement - specific guidance
        if score >= 40 {
            switch weakest.0 {
            case "consistency":
                return "Set a daily reminder to help maintain a learning routine."
            case "frequency":
                return "Try shorter, more frequent sessions (5 min daily vs 30 min once)."
            case "completion":
                return "Focus on one lesson at a time until complete before starting another."
            default:
                return "Consider shorter sessions and more variety to boost interest."
            }
        }
        
        // Low engagement - supportive intervention
        return "Consider more parental involvement and shorter sessions to rebuild engagement."
    }
    
    // MARK: - Learning Velocity Calculation
    
    /// Calculate weekly lesson counts and velocity trend over the past 8 weeks
    private func calculateLearningVelocity(
        for child: Child,
        completedLessons: [LessonProgress]
    ) -> (weeklyLessonCounts: [Int], trend: VelocityTrend) {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate weekly counts for past 8 weeks
        var weeklyLessonCounts: [Int] = []
        
        for weekOffset in (0..<8).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                weeklyLessonCounts.append(0)
                continue
            }
            
            let lessonsThisWeek = completedLessons.filter { progress in
                guard let completedAt = progress.completedAt else { return false }
                return completedAt >= weekStart && completedAt < weekEnd
            }.count
            
            weeklyLessonCounts.append(lessonsThisWeek)
        }
        
        // Calculate trend based on recent weeks vs earlier weeks
        let trend = determineTrend(from: weeklyLessonCounts)
        
        return (weeklyLessonCounts: weeklyLessonCounts, trend: trend)
    }
    
    /// Determine velocity trend by comparing recent 4 weeks to previous 4 weeks
    private func determineTrend(from weeklyLessonCounts: [Int]) -> VelocityTrend {
        guard weeklyLessonCounts.count == 8 else { return .stable }
        
        let earlierWeeks = weeklyLessonCounts[0..<4]
        let recentWeeks = weeklyLessonCounts[4..<8]
        
        let earlierAverage = Double(earlierWeeks.reduce(0, +)) / 4.0
        let recentAverage = Double(recentWeeks.reduce(0, +)) / 4.0
        
        let percentageChange = earlierAverage > 0 ? ((recentAverage - earlierAverage) / earlierAverage) : 0
        
        // Thresholds for trend determination
        if percentageChange > 0.15 {  // 15% increase
            return .increasing
        } else if percentageChange < -0.15 {  // 15% decrease
            return .declining
        } else {
            return .stable
        }
    }
}
