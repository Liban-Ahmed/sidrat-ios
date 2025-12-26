//
//  Child.swift
//  Sidrat
//
//  Child data model
//

import Foundation
import SwiftData

@Model
final class Child {
    var id: UUID
    var name: String
    var age: Int
    var avatarName: String
    var createdAt: Date
    
    // Progress tracking
    var currentStreak: Int
    var longestStreak: Int
    var totalLessonsCompleted: Int
    var totalXP: Int
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var lessonProgress: [LessonProgress]
    
    @Relationship(deleteRule: .cascade)
    var achievements: [Achievement]
    
    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        avatarName: String = "avatar_default",
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalLessonsCompleted: Int = 0,
        totalXP: Int = 0
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.avatarName = avatarName
        self.createdAt = Date()
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalLessonsCompleted = totalLessonsCompleted
        self.totalXP = totalXP
        self.lessonProgress = []
        self.achievements = []
    }
}

// MARK: - Sample Data

extension Child {
    static let sample = Child(
        name: "Yusuf",
        age: 6,
        avatarName: "avatar_boy_1",
        currentStreak: 5,
        longestStreak: 12,
        totalLessonsCompleted: 24,
        totalXP: 480
    )
}
