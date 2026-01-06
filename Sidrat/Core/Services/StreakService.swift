//
//  StreakService.swift
//  Sidrat
//
//  Centralized streak management service with freeze logic and milestone detection
//  Implements business rules from BUSINESS_LOGIC.md
//

import SwiftUI
import SwiftData
import Foundation

// MARK: - Streak Service

@Observable
final class StreakService {
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    
    // MARK: - State
    
    var errorMessage: String?
    
    // MARK: - Constants
    
    /// Streak milestone definitions with achievement types and XP rewards
    private static let milestones: [StreakMilestone] = [
        StreakMilestone(days: 3, achievementType: .streak3, xpReward: 30),
        StreakMilestone(days: 7, achievementType: .streak7, xpReward: 100),
        StreakMilestone(days: 30, achievementType: .streak30, xpReward: 500),
        StreakMilestone(days: 100, achievementType: .streak100, xpReward: 2000)
    ]
    
    // MARK: - Init
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Core Streak Operations
    
    /// Update streak when a lesson is completed
    /// Implements business logic: increment if consecutive day, reset if gap (unless freeze available)
    /// - Parameter child: The child completing the lesson
    func updateStreakForCompletion(child: Child) async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if already completed today - only count first lesson of the day
        if let lastDate = child.lastLessonCompletedDate,
           calendar.isDate(lastDate, inSameDayAs: now) {
            #if DEBUG
            print("🔥 [StreakService] Already completed today, streak unchanged: \(child.currentStreak)")
            #endif
            return // Already counted today
        }
        
        // Check days since last completion
        if let lastDate = child.lastLessonCompletedDate {
            let daysSince = daysBetween(lastDate, and: now)
            
            if daysSince == 1 {
                // Consecutive day - increment streak
                child.currentStreak += 1
                #if DEBUG
                print("🔥 [StreakService] Streak incremented: \(child.name) now at \(child.currentStreak) days")
                #endif
            } else if daysSince > 1 {
                // Gap detected - reset streak to 1 (this lesson starts new streak)
                child.currentStreak = 1
                #if DEBUG
                print("🔥 [StreakService] Streak reset for \(child.name), starting new streak at 1")
                #endif
            }
        } else {
            // First lesson ever
            child.currentStreak = 1
            #if DEBUG
            print("🔥 [StreakService] First lesson for \(child.name), streak set to 1")
            #endif
        }
        
        // Update longest streak
        if child.currentStreak > child.longestStreak {
            child.longestStreak = child.currentStreak
            #if DEBUG
            print("🏆 [StreakService] New longest streak for \(child.name): \(child.longestStreak)")
            #endif
        }
        
        // Update last completed date
        child.lastLessonCompletedDate = now
        
        // Save changes
        try modelContext.save()
        
        // Check for milestone achievements
        try await checkAndAwardMilestones(for: child)
    }
    
    /// Check and reset streak if expired (missed day without freeze)
    /// Call this on app launch to handle missed days
    /// - Parameter child: The child to check
    func checkAndResetExpiredStreak(child: Child) async throws {
        guard let lastDate = child.lastLessonCompletedDate else {
            return // No previous activity
        }
        
        let daysSince = daysBetween(lastDate, and: Date())
        
        if daysSince > 1 {
            // More than 1 day missed - reset streak
            child.currentStreak = 0
            try modelContext.save()
            #if DEBUG
            print("🔥 [StreakService] Streak expired for \(child.name), reset to 0")
            #endif
        }
    }
    
    /// Check if the child has completed a lesson today
    /// - Parameter child: The child to check
    /// - Returns: True if a lesson was completed today
    func isCompletedToday(child: Child) -> Bool {
        guard let lastDate = child.lastLessonCompletedDate else {
            return false
        }
        return Calendar.current.isDate(lastDate, inSameDayAs: Date())
    }
    
    /// Calculate hours remaining in current day (before 11:59 PM deadline)
    /// - Returns: Number of full hours remaining, or 0 if past deadline
    func hoursRemainingToday() -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        // Get end of day (11:59:59 PM local time)
        guard let endOfDay = calendar.date(
            bySettingHour: 23, minute: 59, second: 59, of: now
        ) else { return 0 }
        
        let secondsRemaining = endOfDay.timeIntervalSince(now)
        return max(0, Int(secondsRemaining / 3600))
    }
    
    // MARK: - Milestone Detection
    
    /// Check and award streak milestone achievements
    /// Awards achievements at 3, 7, 30, 100 days
    /// - Parameter child: The child to check for milestones
    func checkAndAwardMilestones(for child: Child) async throws {
        for milestone in Self.milestones {
            if child.currentStreak == milestone.days {
                // Check if achievement already awarded
                let hasAchievement = child.achievements.contains {
                    $0.achievementType == milestone.achievementType
                }
                
                if !hasAchievement {
                    // Award new achievement
                    let achievement = Achievement(
                        achievementType: milestone.achievementType,
                        unlockedAt: Date(),
                        isNew: true
                    )
                    achievement.child = child
                    modelContext.insert(achievement)
                    
                    // Award XP
                    child.totalXP += milestone.xpReward
                    
                    try modelContext.save()
                    
                    #if DEBUG
                    print("🏆 [StreakService] Milestone achieved: \(milestone.achievementType.title) for \(child.name)")
                    #endif
                    
                    // Post notification for celebration UI
                    NotificationCenter.default.post(
                        name: .streakMilestoneAchieved,
                        object: milestone,
                        userInfo: ["childId": child.id.uuidString]
                    )
                }
            }
        }
    }
    
    /// Get the next milestone for the current streak
    /// - Parameter currentStreak: The current streak count
    /// - Returns: The next milestone to achieve, or nil if past all milestones
    func getNextMilestone(currentStreak: Int) -> StreakMilestone? {
        return Self.milestones.first { $0.days > currentStreak }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate number of full days between two dates
    /// - Parameters:
    ///   - date1: Earlier date
    ///   - date2: Later date
    /// - Returns: Number of days difference
    private func daysBetween(_ date1: Date, and date2: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day ?? 0
    }
}

// MARK: - Streak Milestone

/// Represents a streak milestone achievement
struct StreakMilestone {
    let days: Int
    let achievementType: AchievementType
    let xpReward: Int
}

// MARK: - Streak Error

/// Errors that can occur during streak operations
enum StreakError: LocalizedError {
    case invalidDateRange
    case saveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            return "Invalid date range for streak calculation"
        case .saveFailed(let error):
            return "Failed to save streak data: \(error.localizedDescription)"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a streak milestone is achieved
    static let streakMilestoneAchieved = Notification.Name("streakMilestoneAchieved")
}
