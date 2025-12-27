//
//  FamilyActivity.swift
//  Sidrat
//
//  Weekly family activity model
//

import Foundation
import SwiftData

@Model
final class FamilyActivity: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var activityDescription: String = ""
    var instructions: [String] = []
    var durationMinutes: Int = 15
    var weekNumber: Int = 1
    
    /// Raw string value for related category (stored in database)
    var relatedCategoryRaw: String = LessonCategory.aqeedah.rawValue
    
    var isCompleted: Bool = false
    var completedAt: Date?
    
    // Tips for parents
    var parentTips: [String] = []
    var conversationPrompts: [String] = []
    
    /// Computed property to get/set the related category enum
    @Transient
    var relatedCategory: LessonCategory {
        get { LessonCategory(rawValue: relatedCategoryRaw) ?? .aqeedah }
        set { relatedCategoryRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        activityDescription: String,
        instructions: [String],
        durationMinutes: Int = 15,
        weekNumber: Int,
        relatedCategory: LessonCategory,
        parentTips: [String] = [],
        conversationPrompts: [String] = [],
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.activityDescription = activityDescription
        self.instructions = instructions
        self.durationMinutes = durationMinutes
        self.weekNumber = weekNumber
        self.relatedCategoryRaw = relatedCategory.rawValue
        self.parentTips = parentTips
        self.conversationPrompts = conversationPrompts
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

// MARK: - Sample Data

extension FamilyActivity {
    static let sampleWuduActivity = FamilyActivity(
        title: "Practice Wudu Together",
        activityDescription: "This week, practice making Wudu together with your child. Go through each step slowly and make it fun!",
        instructions: [
            "Go to the bathroom sink together",
            "Show your child how to make intention (niyyah)",
            "Wash hands 3 times together",
            "Rinse mouth 3 times",
            "Clean nose 3 times",
            "Wash face 3 times",
            "Wash arms up to elbows 3 times",
            "Wipe head once",
            "Wipe ears once",
            "Wash feet 3 times",
            "Say the du'a after Wudu together"
        ],
        durationMinutes: 15,
        weekNumber: 1,
        relatedCategory: .wudu,
        parentTips: [
            "Make it playful - use a fun timer or sing a simple nasheed",
            "Let them splash a little - it's about learning, not perfection",
            "Praise effort, not just getting it right"
        ],
        conversationPrompts: [
            "Why do you think we clean ourselves before talking to Allah?",
            "What's your favorite part of making Wudu?",
            "How do you feel after making Wudu?"
        ]
    )
}
