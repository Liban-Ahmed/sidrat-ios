//
//  Achievement.swift
//  Sidrat
//
//  Achievement/badge data model
//

import Foundation
import SwiftData

@Model
final class Achievement {
    var id: UUID = UUID()
    
    /// Raw string value for achievement type (stored in database)
    var achievementTypeRaw: String = AchievementType.firstLesson.rawValue
    
    var unlockedAt: Date = Date()
    var isNew: Bool = true
    
    @Relationship
    var child: Child?
    
    /// Computed property to get/set the achievement type enum
    @Transient
    var achievementType: AchievementType {
        get { AchievementType(rawValue: achievementTypeRaw) ?? .firstLesson }
        set { achievementTypeRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        achievementType: AchievementType,
        unlockedAt: Date = Date(),
        isNew: Bool = true
    ) {
        self.id = id
        self.achievementTypeRaw = achievementType.rawValue
        self.unlockedAt = unlockedAt
        self.isNew = isNew
    }
}

// MARK: - Achievement Category

enum AchievementCategory: String, Codable, CaseIterable {
    case progress = "progress"     // Streaks, XP milestones, consistency
    case mastery = "mastery"       // Category completion, perfect scores
    case special = "special"       // Ramadan, Eid, seasonal events
    case social = "social"         // Family activities, sharing
    
    var title: String {
        switch self {
        case .progress: return "Progress"
        case .mastery: return "Mastery"
        case .special: return "Special Events"
        case .social: return "Family & Friends"
        }
    }
    
    var icon: String {
        switch self {
        case .progress: return "chart.line.uptrend.xyaxis"
        case .mastery: return "star.circle.fill"
        case .special: return "sparkles"
        case .social: return "heart.circle.fill"
        }
    }
}

// MARK: - Achievement Rarity

enum AchievementRarity: String, Codable, CaseIterable {
    case bronze = "bronze"     // Common - First steps
    case silver = "silver"     // Uncommon - Week streaks
    case gold = "gold"         // Rare - Month streaks, mastery
    case platinum = "platinum" // Ultra rare - Perfect achievements
    
    var title: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .platinum: return "Platinum"
        }
    }
    
    var color: String {
        switch self {
        case .bronze: return "#CD7F32"
        case .silver: return "#C0C0C0"
        case .gold: return "#DAA520"
        case .platinum: return "#E5E4E2"
        }
    }
}

// MARK: - Achievement Type

enum AchievementType: String, Codable, CaseIterable {
    // Progress Achievements
    case firstLesson = "first_lesson"
    case streak3 = "streak_3"
    case streak7 = "streak_7"
    case streak30 = "streak_30"
    case streak100 = "streak_100"
    case perfectWeek = "perfect_week"
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case streakSaver = "streak_saver"
    case superLearner = "super_learner"
    case xpMilestone1000 = "xp_milestone_1000"
    case xpMilestone2500 = "xp_milestone_2500"
    
    // Mastery Achievements
    case perfectScore = "perfect_score"
    case wuduMaster = "wudu_master"
    case salahMaster = "salah_master"
    case quranMaster = "quran_master"
    case duaMaster = "dua_master"
    case prophetStoriesMaster = "prophet_stories_master"
    case categoryExplorer = "category_explorer"
    case allCategoriesMaster = "all_categories_master"
    
    // Special Event Achievements
    case ramadanReady = "ramadan_ready"
    case eidCelebration = "eid_celebration"
    case islamicNewYear = "islamic_new_year"
    case laylatAlQadr = "laylat_al_qadr"
    
    // Social Achievements
    case firstFamilyActivity = "first_family_activity"
    case familyTime = "family_time"
    case familyChampion = "family_champion"
    case weeklyChampion = "weekly_champion"
    
    var title: String {
        switch self {
        // Progress
        case .firstLesson: return "First Steps"
        case .streak3: return "3 Day Streak"
        case .streak7: return "Week Warrior"
        case .streak30: return "Monthly Master"
        case .streak100: return "Dedication Master"
        case .perfectWeek: return "Perfect Week"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .streakSaver: return "Streak Saver"
        case .superLearner: return "Super Learner"
        case .xpMilestone1000: return "Rising Star"
        case .xpMilestone2500: return "Shining Star"
            
        // Mastery
        case .perfectScore: return "Perfect Score"
        case .wuduMaster: return "Wudu Master"
        case .salahMaster: return "Salah Master"
        case .quranMaster: return "Quran Master"
        case .duaMaster: return "Du'a Master"
        case .prophetStoriesMaster: return "Story Master"
        case .categoryExplorer: return "Explorer"
        case .allCategoriesMaster: return "Ultimate Master"
            
        // Special Events
        case .ramadanReady: return "Ramadan Ready"
        case .eidCelebration: return "Eid Joy"
        case .islamicNewYear: return "New Year Blessing"
        case .laylatAlQadr: return "Night of Power"
            
        // Social
        case .firstFamilyActivity: return "Family First"
        case .familyTime: return "Family Time"
        case .familyChampion: return "Family Champion"
        case .weeklyChampion: return "Weekly Champion"
        }
    }
    
    var description: String {
        switch self {
        // Progress
        case .firstLesson: return "Completed your first lesson!"
        case .streak3: return "Learned for 3 days in a row"
        case .streak7: return "Learned for 7 days in a row"
        case .streak30: return "Learned for 30 days in a row"
        case .streak100: return "Learned for 100 days in a row!"
        case .perfectWeek: return "Completed lessons all 7 days this week"
        case .earlyBird: return "Completed a lesson before 9 AM"
        case .nightOwl: return "Completed a lesson after 7 PM"
        case .streakSaver: return "Used a streak freeze to protect your streak"
        case .superLearner: return "Earned 500 XP"
        case .xpMilestone1000: return "Earned 1,000 total XP"
        case .xpMilestone2500: return "Earned 2,500 total XP"
            
        // Mastery
        case .perfectScore: return "Got 100% on a lesson!"
        case .wuduMaster: return "Completed all Wudu lessons"
        case .salahMaster: return "Completed all Salah lessons"
        case .quranMaster: return "Completed all Quran lessons"
        case .duaMaster: return "Completed all Du'a lessons"
        case .prophetStoriesMaster: return "Completed all Prophet Stories"
        case .categoryExplorer: return "Tried lessons from all categories"
        case .allCategoriesMaster: return "Mastered every category!"
            
        // Special Events
        case .ramadanReady: return "Completed Ramadan preparation lessons"
        case .eidCelebration: return "Learned about Eid celebration"
        case .islamicNewYear: return "Celebrated Islamic New Year"
        case .laylatAlQadr: return "Learned about Laylat al-Qadr"
            
        // Social
        case .firstFamilyActivity: return "Completed your first family activity"
        case .familyTime: return "Completed a family activity"
        case .familyChampion: return "Completed 10 family activities"
        case .weeklyChampion: return "Completed all lessons this week"
        }
    }
    
    var icon: String {
        switch self {
        // Progress
        case .firstLesson: return "star.fill"
        case .streak3: return "flame.fill"
        case .streak7: return "flame.fill"
        case .streak30: return "flame.fill"
        case .streak100: return "flame.fill"
        case .perfectWeek: return "calendar.badge.checkmark"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .streakSaver: return "shield.lefthalf.filled"
        case .superLearner: return "sparkles"
        case .xpMilestone1000: return "star.circle.fill"
        case .xpMilestone2500: return "star.leadinghalf.filled"
            
        // Mastery
        case .perfectScore: return "checkmark.seal.fill"
        case .wuduMaster: return "drop.fill"
        case .salahMaster: return "figure.stand"
        case .quranMaster: return "book.closed.fill"
        case .duaMaster: return "hands.sparkles.fill"
        case .prophetStoriesMaster: return "book.pages.fill"
        case .categoryExplorer: return "map.fill"
        case .allCategoriesMaster: return "crown.fill"
            
        // Special Events
        case .ramadanReady: return "moon.fill"
        case .eidCelebration: return "party.popper.fill"
        case .islamicNewYear: return "calendar.badge.plus"
        case .laylatAlQadr: return "sparkle"
            
        // Social
        case .firstFamilyActivity: return "heart.fill"
        case .familyTime: return "figure.2.and.child.holdinghands"
        case .familyChampion: return "heart.circle.fill"
        case .weeklyChampion: return "trophy.fill"
        }
    }
    
    var category: AchievementCategory {
        switch self {
        // Progress
        case .firstLesson, .streak3, .streak7, .streak30, .streak100, .perfectWeek,
             .earlyBird, .nightOwl, .streakSaver, .superLearner,
             .xpMilestone1000, .xpMilestone2500:
            return .progress
            
        // Mastery
        case .perfectScore, .wuduMaster, .salahMaster, .quranMaster,
             .duaMaster, .prophetStoriesMaster, .categoryExplorer,
             .allCategoriesMaster:
            return .mastery
            
        // Special Events
        case .ramadanReady, .eidCelebration, .islamicNewYear, .laylatAlQadr:
            return .special
            
        // Social
        case .firstFamilyActivity, .familyTime, .familyChampion, .weeklyChampion:
            return .social
        }
    }
    
    var rarity: AchievementRarity {
        switch self {
        // Bronze (Common)
        case .firstLesson, .streak3, .perfectScore, .earlyBird, .nightOwl,
             .firstFamilyActivity:
            return .bronze
            
        // Silver (Uncommon)
        case .streak7, .perfectWeek, .wuduMaster, .salahMaster, .quranMaster,
             .duaMaster, .prophetStoriesMaster, .familyTime, .weeklyChampion,
             .superLearner, .categoryExplorer:
            return .silver
            
        // Gold (Rare)
        case .streak30, .xpMilestone1000, .familyChampion, .ramadanReady,
             .eidCelebration, .islamicNewYear, .laylatAlQadr:
            return .gold
            
        // Platinum (Ultra Rare)
        case .streak100, .streakSaver, .xpMilestone2500, .allCategoriesMaster:
            return .platinum
        }
    }
    
    var isHidden: Bool {
        // Secret achievements that don't show until unlocked
        switch self {
        case .streakSaver, .nightOwl, .laylatAlQadr:
            return true
        default:
            return false
        }
    }
    
    /// Unlock requirements for progress tracking
    var unlockRequirement: UnlockRequirement {
        switch self {
        // Streak achievements
        case .streak3: return .streak(days: 3)
        case .streak7: return .streak(days: 7)
        case .streak30: return .streak(days: 30)
        case .streak100: return .streak(days: 100)
        case .perfectWeek: return .perfectWeek
            
        // XP milestones
        case .superLearner: return .xp(amount: 500)
        case .xpMilestone1000: return .xp(amount: 1000)
        case .xpMilestone2500: return .xp(amount: 2500)
            
        // Lesson count
        case .firstLesson: return .lessonCount(count: 1)
            
        // Category completion
        case .wuduMaster: return .categoryCompletion(category: LessonCategory.wudu.rawValue)
        case .salahMaster: return .categoryCompletion(category: LessonCategory.salah.rawValue)
        case .quranMaster: return .categoryCompletion(category: LessonCategory.quran.rawValue)
        case .duaMaster: return .categoryCompletion(category: LessonCategory.duaa.rawValue)
        case .prophetStoriesMaster: return .categoryCompletion(category: LessonCategory.stories.rawValue)
        case .categoryExplorer: return .allCategoriesTried
        case .allCategoriesMaster: return .allCategoriesCompleted
            
        // Family activities
        case .firstFamilyActivity: return .familyActivityCount(count: 1)
        case .familyTime: return .familyActivityCount(count: 1)
        case .familyChampion: return .familyActivityCount(count: 10)
            
        // Special conditions
        case .perfectScore: return .perfectScoreCount(count: 1)
        case .earlyBird: return .timeOfDay(before: 9)
        case .nightOwl: return .timeOfDay(after: 19)
        case .streakSaver: return .streakFreezeUsed
        case .weeklyChampion: return .weeklyCompletion
            
        // Special events (date-based)
        case .ramadanReady: return .specialEvent(name: "Ramadan")
        case .eidCelebration: return .specialEvent(name: "Eid")
        case .islamicNewYear: return .specialEvent(name: "Islamic New Year")
        case .laylatAlQadr: return .specialEvent(name: "Laylat al-Qadr")
        }
    }
    
    var xpReward: Int {
        switch self {
        // Bronze rewards
        case .firstLesson: return 20
        case .streak3: return 30
        case .perfectScore: return 50
        case .earlyBird: return 25
        case .nightOwl: return 25
        case .firstFamilyActivity: return 25
            
        // Silver rewards
        case .streak7: return 100
        case .perfectWeek: return 150
        case .wuduMaster: return 200
        case .salahMaster: return 200
        case .quranMaster: return 200
        case .duaMaster: return 200
        case .prophetStoriesMaster: return 200
        case .familyTime: return 25
        case .weeklyChampion: return 100
        case .superLearner: return 150
        case .categoryExplorer: return 100
            
        // Gold rewards
        case .streak30: return 500
        case .xpMilestone1000: return 250
        case .familyChampion: return 300
        case .ramadanReady: return 300
        case .eidCelebration: return 200
        case .islamicNewYear: return 200
        case .laylatAlQadr: return 400
            
        // Platinum rewards
        case .streak100: return 2000
        case .streakSaver: return 100
        case .xpMilestone2500: return 500
        case .allCategoriesMaster: return 1000
        }
    }
}

// MARK: - Unlock Requirement

enum UnlockRequirement {
    case streak(days: Int)
    case xp(amount: Int)
    case lessonCount(count: Int)
    case categoryCompletion(category: String)
    case allCategoriesTried
    case allCategoriesCompleted
    case familyActivityCount(count: Int)
    case perfectScoreCount(count: Int)
    case timeOfDay(before: Int? = nil, after: Int? = nil)
    case streakFreezeUsed
    case weeklyCompletion
    case perfectWeek
    case specialEvent(name: String)
    
    /// Human-readable description for progress display
    var description: String {
        switch self {
        case .streak(let days):
            return "Learn for \(days) days in a row"
        case .xp(let amount):
            return "Earn \(amount) XP"
        case .lessonCount(let count):
            return count == 1 ? "Complete your first lesson" : "Complete \(count) lessons"
        case .categoryCompletion(let category):
            return "Complete all \(category) lessons"
        case .allCategoriesTried:
            return "Try lessons from all categories"
        case .allCategoriesCompleted:
            return "Master all categories"
        case .familyActivityCount(let count):
            return count == 1 ? "Complete your first family activity" : "Complete \(count) family activities"
        case .perfectScoreCount(let count):
            return count == 1 ? "Get a perfect score on a lesson" : "Get perfect scores on \(count) lessons"
        case .timeOfDay(let before, let after):
            if let before = before {
                return "Complete a lesson before \(formattedHour(before))"
            } else if let after = after {
                return "Complete a lesson after \(formattedHour(after))"
            }
            return "Complete a lesson at a special time"
        case .streakFreezeUsed:
            return "Use a streak freeze"
        case .weeklyCompletion:
            return "Complete all lessons this week"
        case .perfectWeek:
            return "Learn every day this week"
        case .specialEvent(let name):
            return "Complete \(name) special lesson"
        }
    }

    private func formattedHour(_ hour24: Int) -> String {
        // Clamp to a sensible range to avoid confusing output
        let hour = max(0, min(23, hour24))
        let isPM = hour >= 12
        let hour12 = (hour % 12 == 0) ? 12 : (hour % 12)
        return "\(hour12):00 \(isPM ? "PM" : "AM")"
    }
}

// MARK: - Achievement Progress

struct AchievementProgress {
    let type: AchievementType
    let current: Int
    let required: Int
    
    var percentage: Double {
        guard required > 0 else { return 0 }
        return min(Double(current) / Double(required), 1.0)
    }
    
    var isComplete: Bool {
        current >= required
    }
    
    var progressText: String {
        "\(current)/\(required)"
    }
}
