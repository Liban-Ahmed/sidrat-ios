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
    var id: UUID
    var achievementType: AchievementType
    var unlockedAt: Date
    var isNew: Bool
    
    @Relationship
    var child: Child?
    
    init(
        id: UUID = UUID(),
        achievementType: AchievementType,
        unlockedAt: Date = Date(),
        isNew: Bool = true
    ) {
        self.id = id
        self.achievementType = achievementType
        self.unlockedAt = unlockedAt
        self.isNew = isNew
    }
}

// MARK: - Achievement Type

enum AchievementType: String, Codable, CaseIterable {
    case firstLesson = "first_lesson"
    case streak3 = "streak_3"
    case streak7 = "streak_7"
    case streak30 = "streak_30"
    case wuduMaster = "wudu_master"
    case salahStarter = "salah_starter"
    case quranExplorer = "quran_explorer"
    case familyTime = "family_time"
    case superLearner = "super_learner"
    case weeklyChampion = "weekly_champion"
    
    var title: String {
        switch self {
        case .firstLesson: return "First Steps"
        case .streak3: return "3 Day Streak"
        case .streak7: return "Week Warrior"
        case .streak30: return "Monthly Master"
        case .wuduMaster: return "Wudu Master"
        case .salahStarter: return "Salah Starter"
        case .quranExplorer: return "Quran Explorer"
        case .familyTime: return "Family Time"
        case .superLearner: return "Super Learner"
        case .weeklyChampion: return "Weekly Champion"
        }
    }
    
    var description: String {
        switch self {
        case .firstLesson: return "Completed your first lesson!"
        case .streak3: return "Learned for 3 days in a row"
        case .streak7: return "Learned for 7 days in a row"
        case .streak30: return "Learned for 30 days in a row"
        case .wuduMaster: return "Completed all Wudu lessons"
        case .salahStarter: return "Started learning about Salah"
        case .quranExplorer: return "Explored Quran stories"
        case .familyTime: return "Completed a family activity"
        case .superLearner: return "Earned 500 XP"
        case .weeklyChampion: return "Completed all lessons this week"
        }
    }
    
    var icon: String {
        switch self {
        case .firstLesson: return "star.fill"
        case .streak3: return "flame.fill"
        case .streak7: return "flame.fill"
        case .streak30: return "flame.fill"
        case .wuduMaster: return "drop.fill"
        case .salahStarter: return "person.fill"
        case .quranExplorer: return "book.fill"
        case .familyTime: return "heart.fill"
        case .superLearner: return "sparkles"
        case .weeklyChampion: return "trophy.fill"
        }
    }
    
    var xpRequired: Int? {
        switch self {
        case .superLearner: return 500
        default: return nil
        }
    }
}
