//
//  LessonProgressService.swift
//  Sidrat
//
//  Centralized lesson progress management service
//  Handles phase-level progress saving, loading, and completion tracking
//

import SwiftUI
import SwiftData

// MARK: - Lesson Progress Service

@Observable
final class LessonProgressService {
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    
    // MARK: - Published State
    
    var errorMessage: String?
    
    // MARK: - Init
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Phase Progress Management
    
    /// Save progress after completing a phase
    /// - Parameters:
    ///   - lessonId: The lesson's unique identifier
    ///   - childId: The child's unique identifier
    ///   - phase: The phase that was just completed
    func savePhaseProgress(lessonId: UUID, childId: UUID, phase: String) async throws {
        print("[LessonProgressService] Saving phase: \(phase) for lesson \(lessonId)")
        
        // Find or create progress record
        let descriptor = FetchDescriptor<LessonProgress>(
            predicate: #Predicate<LessonProgress> { progress in
                progress.lessonId == lessonId && progress.child?.id == childId
            }
        )
        
        let existingProgress = try? modelContext.fetch(descriptor).first
        
        if let progress = existingProgress {
            // Update existing progress
            progress.markPhaseComplete(phase)
        } else {
            // Create new partial progress record
            let newProgress = LessonProgress(
                lessonId: lessonId,
                lastCompletedPhase: phase,
                phaseProgress: [phase: Date()],
                lastAccessedAt: Date()
            )
            
            // Link to child
            let childDescriptor = FetchDescriptor<Child>(
                predicate: #Predicate<Child> { child in
                    child.id == childId
                }
            )
            if let child = try? modelContext.fetch(childDescriptor).first {
                newProgress.child = child
            }
            
            modelContext.insert(newProgress)
        }
        
        // Save to disk
        do {
            try modelContext.save()
            print("[LessonProgressService] ✅ Phase progress saved successfully")
        } catch {
            print("[LessonProgressService] ⚠️ Save failed: \(error)")
            throw LessonProgressError.saveFailed(underlying: error)
        }
    }
    
    /// Load partial progress for a lesson to enable resume functionality
    /// - Parameters:
    ///   - lessonId: The lesson's unique identifier
    ///   - childId: The child's unique identifier
    /// - Returns: The last completed phase, or nil if no partial progress exists. The ViewModel is responsible for determining the next phase to resume.
    func loadPartialProgress(lessonId: UUID, childId: UUID) -> String? {
        print("[LessonProgressService] Loading partial progress for lesson \(lessonId)")
        
        let descriptor = FetchDescriptor<LessonProgress>(
            predicate: #Predicate<LessonProgress> { progress in
                progress.lessonId == lessonId && progress.child?.id == childId
            }
        )
        
        guard let progress = try? modelContext.fetch(descriptor).first else {
            print("[LessonProgressService] No progress record found")
            return nil
        }
        
        // Don't resume if lesson is already completed
        if progress.isCompleted {
            print("[LessonProgressService] Lesson already completed, no resume needed")
            return nil
        }
        
        // Don't resume if no partial progress exists
        guard progress.isPartialProgress, let lastPhase = progress.lastCompletedPhase else {
            print("[LessonProgressService] No partial progress found")
            return nil
        }
        
        print("[LessonProgressService] Found partial progress, last completed phase: \(lastPhase)")
        
        // Return the NEXT phase after the last completed one
        // The ViewModel will handle phase transition logic
        return lastPhase
    }
    
    /// Mark a lesson as fully complete
    /// - Parameters:
    ///   - lessonId: The lesson's unique identifier
    ///   - childId: The child's unique identifier
    ///   - score: Final score (0-100)
    ///   - xpEarned: XP earned from this completion
    func markLessonComplete(
        lessonId: UUID,
        childId: UUID,
        score: Int,
        xpEarned: Int
    ) async throws {
        print("[LessonProgressService] Marking lesson \(lessonId) as complete")
        
        let descriptor = FetchDescriptor<LessonProgress>(
            predicate: #Predicate<LessonProgress> { progress in
                progress.lessonId == lessonId && progress.child?.id == childId
            }
        )
        
        guard let progress = try? modelContext.fetch(descriptor).first else {
            print("[LessonProgressService] ⚠️ Progress record not found")
            throw LessonProgressError.lessonNotFound
        }
        
        // Update completion status
        progress.isCompleted = true
        progress.completedAt = Date()
        progress.score = max(progress.score, score)  // Keep best score
        progress.xpEarned = max(progress.xpEarned, xpEarned)  // Keep best XP
        progress.attempts += 1
        progress.lastAccessedAt = Date()
        
        // Clear resume indicator (lastCompletedPhase) since lesson is complete
        // Keep phaseProgress for historical data
        progress.lastCompletedPhase = nil
        
        // Save
        do {
            try modelContext.save()
            print("[LessonProgressService] ✅ Lesson marked complete successfully")
        } catch {
            print("[LessonProgressService] ⚠️ Complete failed: \(error)")
            throw LessonProgressError.saveFailed(underlying: error)
        }
    }
    
    /// Clear partial progress for a lesson (used for restart)
    /// - Parameters:
    ///   - lessonId: The lesson's unique identifier
    ///   - childId: The child's unique identifier
    func clearPartialProgress(lessonId: UUID, childId: UUID) async throws {
        print("[LessonProgressService] Clearing partial progress for lesson \(lessonId)")
        
        let descriptor = FetchDescriptor<LessonProgress>(
            predicate: #Predicate<LessonProgress> { progress in
                progress.lessonId == lessonId && progress.child?.id == childId
            }
        )
        
        guard let progress = try? modelContext.fetch(descriptor).first else {
            print("[LessonProgressService] No progress record found to clear")
            return
        }
        
        progress.clearPartialProgress()
        
        do {
            try modelContext.save()
            print("[LessonProgressService] ✅ Partial progress cleared")
        } catch {
            print("[LessonProgressService] ⚠️ Clear failed: \(error)")
            throw LessonProgressError.saveFailed(underlying: error)
        }
    }
    
    /// Get existing progress record (useful for checking completion status)
    /// - Parameters:
    ///   - lessonId: The lesson's unique identifier
    ///   - childId: The child's unique identifier
    /// - Returns: Existing progress record or nil
    func getProgress(lessonId: UUID, childId: UUID) -> LessonProgress? {
        let descriptor = FetchDescriptor<LessonProgress>(
            predicate: #Predicate<LessonProgress> { progress in
                progress.lessonId == lessonId && progress.child?.id == childId
            }
        )
        
        return try? modelContext.fetch(descriptor).first
    }
}

// MARK: - Error Types

enum LessonProgressError: LocalizedError {
    case saveFailed(underlying: Error)
    case loadFailed(underlying: Error)
    case invalidPhase(String)
    case childNotFound
    case lessonNotFound
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save progress: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load progress: \(error.localizedDescription)"
        case .invalidPhase(let phase):
            return "Invalid phase identifier: \(phase)"
        case .childNotFound:
            return "Child profile not found"
        case .lessonNotFound:
            return "Lesson not found"
        }
    }
}
