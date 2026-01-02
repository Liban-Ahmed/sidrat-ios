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
    
    // Phase-level progress tracking (US-204)
    var lastCompletedPhase: String? = nil  // Stores phase enum rawValue ("hook", "teach", "practice")
    var phaseProgress: [String: Date] = [:]  // Dictionary of phase -> completion timestamp
    var lastAccessedAt: Date? = nil  // For resume logic and spaced repetition
    
    @Relationship
    var child: Child?
    
    // Computed property for partial progress state
    @Transient
    var isPartialProgress: Bool {
        return !isCompleted && lastCompletedPhase != nil
    }
    
    init(
        id: UUID = UUID(),
        lessonId: UUID,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        score: Int = 0,
        xpEarned: Int = 0,
        attempts: Int = 0,
        lastCompletedPhase: String? = nil,
        phaseProgress: [String: Date] = [:],
        lastAccessedAt: Date? = nil
    ) {
        self.id = id
        self.lessonId = lessonId
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.score = score
        self.xpEarned = xpEarned
        self.attempts = attempts
        self.lastCompletedPhase = lastCompletedPhase
        self.phaseProgress = phaseProgress
        self.lastAccessedAt = lastAccessedAt
    }
    
    // MARK: - Phase Progress Helpers
    
    /// Mark a phase as complete with timestamp
    func markPhaseComplete(_ phase: String, at date: Date = Date()) {
        lastCompletedPhase = phase
        phaseProgress[phase] = date
        lastAccessedAt = date
    }
    
    /// Clear all partial progress (used for restart)
    func clearPartialProgress() {
        lastCompletedPhase = nil
        phaseProgress = [:]
    }
}
