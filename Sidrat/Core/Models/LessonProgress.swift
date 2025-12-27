//
//  LessonProgress.swift
//  Sidrat
//
//  Tracks lesson completion progress
//

import Foundation
import SwiftData

@Model
final class LessonProgress {
    var id: UUID = UUID()
    var lessonId: UUID = UUID()
    var isCompleted: Bool = false
    var completedAt: Date?
    var score: Int = 0
    var xpEarned: Int = 0
    var attempts: Int = 0
    
    @Relationship
    var child: Child?
    
    init(
        id: UUID = UUID(),
        lessonId: UUID,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        score: Int = 0,
        xpEarned: Int = 0,
        attempts: Int = 0
    ) {
        self.id = id
        self.lessonId = lessonId
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.score = score
        self.xpEarned = xpEarned
        self.attempts = attempts
    }
}
