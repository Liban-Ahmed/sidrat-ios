//
//  AchievementService.swift
//  Sidrat
//
//  Service for checking and unlocking achievements
//

import Foundation
import SwiftData
import SwiftUI
import os

@Observable
final class AchievementService {
    // MARK: - Dependencies
    
    private let modelContext: ModelContext

    private let logger = Logger(subsystem: "Sidrat", category: "AchievementService")
    
    // MARK: - State
    
    var pendingUnlocks: [AchievementType] = []
    var showingCelebration = false
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private func saveContext(_ reason: String) {
        do {
            try modelContext.save()
        } catch {
            logger.error("ModelContext save failed (\(reason, privacy: .public)): \(error.localizedDescription, privacy: .public)")
        }
    }
    
    // MARK: - Main Achievement Checking
    
    /// Check all possible achievements for a child and unlock any that meet criteria
    /// Returns newly unlocked achievements for celebration
    @discardableResult
    func checkAndUnlockAchievements(for child: Child) -> [AchievementType] {
        var newlyUnlocked: [AchievementType] = []
        
        // Get already unlocked achievement types
        let unlockedTypes = Set(child.achievements.map { $0.achievementType })
        
        // Check each category
        let progressAchievements = checkProgressAchievements(child, unlockedTypes: unlockedTypes)
        let masteryAchievements = checkMasteryAchievements(child, unlockedTypes: unlockedTypes)
        let specialAchievements = checkSpecialAchievements(child, unlockedTypes: unlockedTypes)
        let socialAchievements = checkSocialAchievements(child, unlockedTypes: unlockedTypes)
        
        newlyUnlocked.append(contentsOf: progressAchievements)
        newlyUnlocked.append(contentsOf: masteryAchievements)
        newlyUnlocked.append(contentsOf: specialAchievements)
        newlyUnlocked.append(contentsOf: socialAchievements)
        
        // Unlock each achievement
        for type in newlyUnlocked {
            unlockAchievement(type, for: child)
        }
        
        return newlyUnlocked
    }
    
    // MARK: - Progress Achievements
    
    private func checkProgressAchievements(_ child: Child, unlockedTypes: Set<AchievementType>) -> [AchievementType] {
        var unlocked: [AchievementType] = []
        
        // First lesson
        if !unlockedTypes.contains(.firstLesson) && child.totalLessonsCompleted >= 1 {
            unlocked.append(.firstLesson)
        }
        
        // Streak achievements
        if !unlockedTypes.contains(.streak3) && child.currentStreak >= 3 {
            unlocked.append(.streak3)
        }
        if !unlockedTypes.contains(.streak7) && child.currentStreak >= 7 {
            unlocked.append(.streak7)
        }
        if !unlockedTypes.contains(.streak30) && child.currentStreak >= 30 {
            unlocked.append(.streak30)
        }
        
        // Perfect week - 7 days with lessons
        if !unlockedTypes.contains(.perfectWeek) && checkPerfectWeek(child) {
            unlocked.append(.perfectWeek)
        }
        
        // XP milestones
        if !unlockedTypes.contains(.superLearner) && child.totalXP >= 500 {
            unlocked.append(.superLearner)
        }
        if !unlockedTypes.contains(.xpMilestone1000) && child.totalXP >= 1000 {
            unlocked.append(.xpMilestone1000)
        }
        if !unlockedTypes.contains(.xpMilestone2500) && child.totalXP >= 2500 {
            unlocked.append(.xpMilestone2500)
        }
        
        // Time-based achievements (checked separately via lesson completion)
        // earlyBird and nightOwl are checked in checkTimeBasedAchievements
        
        return unlocked
    }
    
    // MARK: - Mastery Achievements
    
    private func checkMasteryAchievements(_ child: Child, unlockedTypes: Set<AchievementType>) -> [AchievementType] {
        var unlocked: [AchievementType] = []
        
        // Fetch all lessons to check category completion
        let descriptor = FetchDescriptor<Lesson>(sortBy: [SortDescriptor(\.order)])
        guard let allLessons = try? modelContext.fetch(descriptor) else { return unlocked }
        
        // Get completed lesson IDs
        let completedLessonIds = Set(child.lessonProgress.filter { $0.isCompleted }.map { $0.lessonId })
        
        // Perfect score achievement
        // Assuming score is stored as percentage (0-100)
        let perfectScoreCount = child.lessonProgress.filter { $0.score == 100 }.count
        if !unlockedTypes.contains(.perfectScore) && perfectScoreCount >= 1 {
            unlocked.append(.perfectScore)
        }
        
        // Category completion achievements
        let categories: [(type: AchievementType, category: LessonCategory)] = [
            (.wuduMaster, .wudu),
            (.salahMaster, .salah),
            (.quranMaster, .quran),
            (.duaMaster, .duaa),
            (.prophetStoriesMaster, .stories)
        ]
        
        for (achievementType, category) in categories {
            if !unlockedTypes.contains(achievementType) {
                let categoryLessons = allLessons.filter { $0.category == category }
                let categoryLessonIds = Set(categoryLessons.map { $0.id })
                let completed = categoryLessonIds.isSubset(of: completedLessonIds)
                
                if completed && !categoryLessons.isEmpty {
                    unlocked.append(achievementType)
                }
            }
        }
        
        // Category explorer - tried all categories
        if !unlockedTypes.contains(.categoryExplorer) {
            let triedCategories = Set(allLessons.filter { completedLessonIds.contains($0.id) }.map { $0.category })
            if triedCategories.count == LessonCategory.allCases.count {
                unlocked.append(.categoryExplorer)
            }
        }
        
        // All categories master - completed everything
        if !unlockedTypes.contains(.allCategoriesMaster) {
            let allCategoryTypes: [LessonCategory] = [.wudu, .salah, .quran, .duaa, .stories, .aqeedah, .seerah, .adab]
            var allCompleted = true
            
            for category in allCategoryTypes {
                let categoryLessons = allLessons.filter { $0.category == category }
                let categoryLessonIds = Set(categoryLessons.map { $0.id })
                
                if !categoryLessons.isEmpty && !categoryLessonIds.isSubset(of: completedLessonIds) {
                    allCompleted = false
                    break
                }
            }
            
            if allCompleted && !allLessons.isEmpty {
                unlocked.append(.allCategoriesMaster)
            }
        }
        
        return unlocked
    }
    
    // MARK: - Special Event Achievements
    
    private func checkSpecialAchievements(_ child: Child, unlockedTypes: Set<AchievementType>) -> [AchievementType] {
        var unlocked: [AchievementType] = []
        
        // Special event achievements are checked based on completing specific lessons
        // tagged with special events or during specific Islamic calendar dates
        
        let descriptor = FetchDescriptor<Lesson>(sortBy: [SortDescriptor(\.order)])
        guard let allLessons = try? modelContext.fetch(descriptor) else { return unlocked }
        
        let completedLessonIds = Set(child.lessonProgress.filter { $0.isCompleted }.map { $0.lessonId })
        
        // Ramadan achievements - check if completed lessons with "Ramadan" in title
        if !unlockedTypes.contains(.ramadanReady) {
            let ramadanLessons = allLessons.filter { $0.title.contains("Ramadan") || $0.title.contains("Fasting") }
            if !ramadanLessons.isEmpty && ramadanLessons.allSatisfy({ completedLessonIds.contains($0.id) }) {
                unlocked.append(.ramadanReady)
            }
        }
        
        // Eid achievements
        if !unlockedTypes.contains(.eidCelebration) {
            let eidLessons = allLessons.filter { $0.title.contains("Eid") }
            if !eidLessons.isEmpty && eidLessons.allSatisfy({ completedLessonIds.contains($0.id) }) {
                unlocked.append(.eidCelebration)
            }
        }
        
        // Islamic New Year
        if !unlockedTypes.contains(.islamicNewYear) {
            let newYearLessons = allLessons.filter { $0.title.contains("Hijri") || $0.title.contains("Islamic New Year") }
            if !newYearLessons.isEmpty && newYearLessons.allSatisfy({ completedLessonIds.contains($0.id) }) {
                unlocked.append(.islamicNewYear)
            }
        }
        
        // Laylat al-Qadr
        if !unlockedTypes.contains(.laylatAlQadr) {
            let laylahLessons = allLessons.filter { $0.title.contains("Laylat") || $0.title.contains("Night of Power") }
            if !laylahLessons.isEmpty && laylahLessons.allSatisfy({ completedLessonIds.contains($0.id) }) {
                unlocked.append(.laylatAlQadr)
            }
        }
        
        return unlocked
    }
    
    // MARK: - Social Achievements
    
    private func checkSocialAchievements(_ child: Child, unlockedTypes: Set<AchievementType>) -> [AchievementType] {
        var unlocked: [AchievementType] = []
        
        // Fetch family activities
        let descriptor = FetchDescriptor<FamilyActivity>()
        guard let allActivities = try? modelContext.fetch(descriptor) else { return unlocked }
        
        // Count completed family activities
        // Note: FamilyActivity currently uses a simple isCompleted flag
        let completedActivities = allActivities.filter { $0.isCompleted }
        
        let activityCount = completedActivities.count
        
        // First family activity
        if !unlockedTypes.contains(.firstFamilyActivity) && activityCount >= 1 {
            unlocked.append(.firstFamilyActivity)
        }
        
        // Family time (same as first, but keeping both for flexibility)
        if !unlockedTypes.contains(.familyTime) && activityCount >= 1 {
            unlocked.append(.familyTime)
        }
        
        // Family champion
        if !unlockedTypes.contains(.familyChampion) && activityCount >= 10 {
            unlocked.append(.familyChampion)
        }
        
        // Weekly champion - completed all lessons this week
        if !unlockedTypes.contains(.weeklyChampion) && checkWeeklyCompletion(child) {
            unlocked.append(.weeklyChampion)
        }
        
        return unlocked
    }
    
    // MARK: - Time-Based Achievement Checking
    
    /// Check time-based achievements when a lesson is completed
    func checkTimeBasedAchievements(for child: Child, completionDate: Date = Date()) -> [AchievementType] {
        var unlocked: [AchievementType] = []
        let unlockedTypes = Set(child.achievements.map { $0.achievementType })
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: completionDate)
        
        // Early bird - before 9 AM
        if !unlockedTypes.contains(.earlyBird) && hour < 9 {
            unlocked.append(.earlyBird)
            unlockAchievement(.earlyBird, for: child)
        }
        
        // Night owl - after 7 PM (19:00)
        if !unlockedTypes.contains(.nightOwl) && hour >= 19 {
            unlocked.append(.nightOwl)
            unlockAchievement(.nightOwl, for: child)
        }
        
        return unlocked
    }
    
    // MARK: - Helper Methods
    
    private func checkPerfectWeek(_ child: Child) -> Bool {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return false
        }
        
        // Check if there's a completed lesson for each day of the week
        var daysWithLessons = Set<Date>()
        
        for progress in child.lessonProgress.filter({ $0.isCompleted }) {
            guard let completedAt = progress.completedAt,
                  completedAt >= startOfWeek else { continue }
            
            let day = calendar.startOfDay(for: completedAt)
            daysWithLessons.insert(day)
        }
        
        return daysWithLessons.count >= 7
    }
    
    private func checkWeeklyCompletion(_ child: Child) -> Bool {
        // Get current week's lessons
        let currentWeek = child.currentWeekNumber
        let descriptor = FetchDescriptor<Lesson>(
            predicate: #Predicate<Lesson> { lesson in
                lesson.weekNumber == currentWeek
            }
        )
        
        guard let weekLessons = try? modelContext.fetch(descriptor) else { return false }
        
        let completedLessonIds = Set(child.lessonProgress.filter { $0.isCompleted }.map { $0.lessonId })
        let weekLessonIds = Set(weekLessons.map { $0.id })
        
        return !weekLessons.isEmpty && weekLessonIds.isSubset(of: completedLessonIds)
    }
    
    // MARK: - Achievement Progress
    
    /// Get progress toward a specific achievement
    func getProgress(for achievementType: AchievementType, child: Child) -> AchievementProgress? {
        // If already unlocked, return completed progress
        if child.achievements.contains(where: { $0.achievementType == achievementType }) {
            return nil // Already unlocked, no progress to show
        }
        
        let requirement = achievementType.unlockRequirement
        
        switch requirement {
        case .streak(let days):
            return AchievementProgress(
                type: achievementType,
                current: child.currentStreak,
                required: days
            )
            
        case .xp(let amount):
            return AchievementProgress(
                type: achievementType,
                current: child.totalXP,
                required: amount
            )
            
        case .lessonCount(let count):
            return AchievementProgress(
                type: achievementType,
                current: child.totalLessonsCompleted,
                required: count
            )
            
        case .categoryCompletion(let categoryName):
            guard let category = LessonCategory.allCases.first(where: { $0.rawValue == categoryName }) else {
                return nil
            }
            
            let categoryRaw = category.rawValue
            let descriptor = FetchDescriptor<Lesson>(
                predicate: #Predicate<Lesson> { lesson in
                    lesson.categoryRaw == categoryRaw
                }
            )
            
            guard let categoryLessons = try? modelContext.fetch(descriptor) else { return nil }
            
            let completedCount = categoryLessons.filter { lesson in
                child.lessonProgress.contains { $0.lessonId == lesson.id && $0.isCompleted }
            }.count
            
            return AchievementProgress(
                type: achievementType,
                current: completedCount,
                required: categoryLessons.count
            )
            
        case .familyActivityCount(let count):
            let descriptor = FetchDescriptor<FamilyActivity>()
            guard let allActivities = try? modelContext.fetch(descriptor) else { return nil }
            
            let completedCount = allActivities.filter { $0.isCompleted }.count
            
            return AchievementProgress(
                type: achievementType,
                current: completedCount,
                required: count
            )
            
        case .perfectScoreCount(let count):
            let perfectScoreCount = child.lessonProgress.filter { $0.score == 100 }.count
            return AchievementProgress(
                type: achievementType,
                current: perfectScoreCount,
                required: count
            )
            
        case .allCategoriesTried:
            let descriptor = FetchDescriptor<Lesson>()
            guard let allLessons = try? modelContext.fetch(descriptor) else { return nil }
            
            let completedLessonIds = Set(child.lessonProgress.filter { $0.isCompleted }.map { $0.lessonId })
            let triedCategories = Set(allLessons.filter { completedLessonIds.contains($0.id) }.map { $0.category })
            
            return AchievementProgress(
                type: achievementType,
                current: triedCategories.count,
                required: LessonCategory.allCases.count
            )
            
        case .allCategoriesCompleted:
            // Complex calculation - return nil for now (shown as locked)
            return nil
            
        case .perfectWeek, .weeklyCompletion:
            // Binary achievements - either done or not
            return nil
            
        case .timeOfDay, .streakFreezeUsed, .specialEvent:
            // These are opportunistic achievements
            return nil
        }
    }
    
    // MARK: - Unlock Achievement
    
    private func unlockAchievement(_ type: AchievementType, for child: Child) {
        // Create new achievement
        let achievement = Achievement(achievementType: type, unlockedAt: Date(), isNew: true)
        achievement.child = child
        
        // Add to child's achievements
        child.achievements.append(achievement)
        
        // Award XP
        child.totalXP += type.xpReward
        
        // Save context
        saveContext("unlockAchievement \(type.rawValue)")
    }
    
    // MARK: - Mark Achievement as Seen
    
    func markAchievementAsSeen(_ achievement: Achievement) {
        achievement.isNew = false
        saveContext("markAchievementAsSeen")
    }
    
    // MARK: - Get All Progress
    
    /// Get progress for all locked achievements
    func getAllProgress(for child: Child) -> [AchievementType: AchievementProgress] {
        var progressDict: [AchievementType: AchievementProgress] = [:]
        
        let unlockedTypes = Set(child.achievements.map { $0.achievementType })
        
        for type in AchievementType.allCases {
            // Skip if already unlocked or hidden
            if unlockedTypes.contains(type) || type.isHidden {
                continue
            }
            
            if let progress = getProgress(for: type, child: child) {
                progressDict[type] = progress
            }
        }
        
        return progressDict
    }
}
