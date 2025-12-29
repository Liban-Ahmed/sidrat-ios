//
//  LessonPlayerViewModel.swift
//  Sidrat
//
//  ViewModel for the lesson player with Hook-Teach-Practice-Reward structure
//  Manages state, phase transitions, scoring, and completion logic
//

import SwiftUI
import SwiftData

// MARK: - Lesson Player ViewModel

@Observable
final class LessonPlayerViewModel {
    
    // MARK: - Phase Enum
    
    enum Phase: Int, CaseIterable, Identifiable {
        case hook = 0
        case teach = 1
        case practice = 2
        case reward = 3
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .hook: return "Get Ready"
            case .teach: return "Learn"
            case .practice: return "Practice"
            case .reward: return "Complete"
            }
        }
        
        var icon: String {
            switch self {
            case .hook: return "sparkles"
            case .teach: return "book.fill"
            case .practice: return "pencil.and.list.clipboard"
            case .reward: return "star.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .hook: return .brandAccent
            case .teach: return .brandPrimary
            case .practice: return .brandSecondary
            case .reward: return .brandAccent
            }
        }
        
        /// Target duration for each phase (in seconds)
        var targetDuration: TimeInterval {
            switch self {
            case .hook: return 37.5      // 30-45 seconds average
            case .teach: return 135       // 2-2.5 minutes average
            case .practice: return 90     // ~1.5 minutes
            case .reward: return 30       // 30 seconds celebration
            }
        }
        
        var next: Phase? {
            switch self {
            case .hook: return .teach
            case .teach: return .practice
            case .practice: return .reward
            case .reward: return nil
            }
        }
        
        var previous: Phase? {
            switch self {
            case .hook: return nil
            case .teach: return .hook
            case .practice: return .teach
            case .reward: return .practice
            }
        }
    }
    
    // MARK: - State Properties
    
    /// Current phase of the lesson
    var currentPhase: Phase = .hook
    
    /// Current step within the current phase
    var currentStepIndex: Int = 0
    
    /// Score earned in practice phase (0-100)
    var score: Int = 0
    
    /// Number of attempts on current practice question
    var attempts: Int = 0
    
    /// Maximum attempts allowed per question
    let maxAttempts: Int = 3
    
    /// Whether user can proceed to next step/phase
    var canProceed: Bool = false
    
    /// Whether lesson is currently paused
    var isPaused: Bool = false
    
    /// Set of completed phases
    var completedPhases: Set<Phase> = []
    
    /// Whether this is the first time viewing this lesson
    var isFirstViewing: Bool = true
    
    /// Total XP earned from this lesson attempt
    var xpEarned: Int = 0
    
    /// Number of correct answers in practice phase
    var correctAnswers: Int = 0
    
    /// Total number of practice questions
    var totalQuestions: Int = 0
    
    /// Whether audio narration is enabled
    var isAudioEnabled: Bool = true
    
    /// Whether to show exit confirmation
    var showExitConfirmation: Bool = false
    
    /// Whether to show share sheet
    var showShareSheet: Bool = false
    
    /// Whether lesson is complete
    var isLessonComplete: Bool = false
    
    /// Current teach step content
    var teachStepsTotal: Int = 0
    
    /// Error message if any
    var errorMessage: String?
    
    // MARK: - Hook Phase State
    
    var hookAnimationProgress: Double = 0
    var hookAutoPlayComplete: Bool = false
    
    // MARK: - Teach Phase State
    
    var teachCurrentStepComplete: Bool = false
    var canSkipTeachStep: Bool = false
    
    // MARK: - Practice Phase State
    
    var selectedAnswer: Int? = nil
    var isAnswerRevealed: Bool = false
    var showExplanation: Bool = false
    var lastAnswerCorrect: Bool = false
    var shouldShowAnswer: Bool { attempts >= maxAttempts }
    
    // MARK: - Reward Phase State
    
    var starsEarned: Int {
        if score >= 80 { return 3 }
        if score >= 60 { return 2 }
        return 1
    }
    
    var celebrationMessage: String {
        if score >= 80 { return "Amazing Job! 🌟" }
        if score >= 60 { return "Great Work! 💪" }
        return "Good Effort! 📚"
    }
    
    // MARK: - Dependencies
    
    private let lesson: Lesson
    private let child: Child
    private let modelContext: ModelContext
    private var lessonStartTime: Date = Date()
    
    // MARK: - Generated Content
    
    private(set) var hookContent: HookContent?
    private(set) var teachContent: [TeachContent] = []
    private(set) var practiceContent: [PracticeContent] = []
    private(set) var rewardContent: RewardContent?
    
    // MARK: - Computed Properties
    
    /// Overall progress through the lesson (0.0 - 1.0)
    var overallProgress: Double {
        let phaseWeight = 1.0 / Double(Phase.allCases.count)
        var progress = Double(currentPhase.rawValue) * phaseWeight
        
        switch currentPhase {
        case .hook:
            progress += hookAutoPlayComplete ? phaseWeight : (hookAnimationProgress * phaseWeight)
        case .teach:
            if teachStepsTotal > 0 {
                progress += (Double(currentStepIndex + 1) / Double(teachStepsTotal)) * phaseWeight
            }
        case .practice:
            if totalQuestions > 0 {
                progress += (Double(currentStepIndex + 1) / Double(totalQuestions)) * phaseWeight
            }
        case .reward:
            progress = 1.0
        }
        
        return min(progress, 1.0)
    }
    
    /// Whether user can skip the current phase
    var canSkipPhase: Bool {
        !isFirstViewing
    }
    
    /// Current practice question (if in practice phase)
    var currentPracticeQuestion: PracticeContent? {
        guard currentPhase == .practice,
              currentStepIndex < practiceContent.count else { return nil }
        return practiceContent[currentStepIndex]
    }
    
    /// Current teach content (if in teach phase)
    var currentTeachContent: TeachContent? {
        guard currentPhase == .teach,
              currentStepIndex < teachContent.count else { return nil }
        return teachContent[currentStepIndex]
    }
    
    /// Share message for social sharing
    var shareMessage: String {
        "I just learned about \(lesson.title) on Sidrat and scored \(score)%! 🌟🎉"
    }
    
    // MARK: - Initialization
    
    init(lesson: Lesson, child: Child, modelContext: ModelContext) {
        self.lesson = lesson
        self.child = child
        self.modelContext = modelContext
        
        setupLesson()
    }
    
    // MARK: - Setup
    
    private func setupLesson() {
        lessonStartTime = Date()
        
        // Check if user has completed this lesson before
        isFirstViewing = !child.lessonProgress.contains { 
            $0.lessonId == lesson.id && $0.isCompleted 
        }
        
        // Generate content for the lesson
        let content = LessonContentGenerator.generateContent(for: lesson)
        
        hookContent = content.hook
        teachContent = content.teach
        practiceContent = content.practice
        rewardContent = content.reward
        
        teachStepsTotal = teachContent.count
        totalQuestions = practiceContent.count
    }
    
    // MARK: - Phase Navigation
    
    /// Move to the next step within the current phase or transition to next phase
    func nextStep() {
        switch currentPhase {
        case .hook:
            transitionToPhase(.teach)
            
        case .teach:
            if currentStepIndex < teachContent.count - 1 {
                currentStepIndex += 1
                teachCurrentStepComplete = false
                canSkipTeachStep = false
            } else {
                transitionToPhase(.practice)
            }
            
        case .practice:
            // Reset state for next question
            selectedAnswer = nil
            isAnswerRevealed = false
            showExplanation = false
            attempts = 0
            
            if currentStepIndex < practiceContent.count - 1 {
                currentStepIndex += 1
            } else {
                calculateScore()
                transitionToPhase(.reward)
            }
            
        case .reward:
            completeLesson()
        }
    }
    
    /// Move to the previous step (if allowed)
    func previousStep() {
        guard !isFirstViewing || currentPhase != .hook else { return }
        
        switch currentPhase {
        case .hook:
            break // Can't go back from hook
            
        case .teach:
            if currentStepIndex > 0 {
                currentStepIndex -= 1
            } else if canSkipPhase {
                transitionToPhase(.hook)
            }
            
        case .practice:
            if currentStepIndex > 0 {
                currentStepIndex -= 1
                selectedAnswer = nil
                isAnswerRevealed = false
                showExplanation = false
                attempts = 0
            }
            
        case .reward:
            break // Can't go back from reward
        }
    }
    
    /// Transition to a specific phase
    func transitionToPhase(_ newPhase: Phase) {
        guard canSkipPhase || newPhase.rawValue == currentPhase.rawValue + 1 else {
            return
        }
        
        // Mark current phase as complete
        completedPhases.insert(currentPhase)
        
        // Reset step index for new phase
        currentStepIndex = 0
        
        // Reset phase-specific state
        switch newPhase {
        case .hook:
            hookAnimationProgress = 0
            hookAutoPlayComplete = false
            
        case .teach:
            teachCurrentStepComplete = false
            canSkipTeachStep = false
            
        case .practice:
            selectedAnswer = nil
            isAnswerRevealed = false
            showExplanation = false
            attempts = 0
            
        case .reward:
            calculateScore()
            calculateXP()
        }
        
        currentPhase = newPhase
        canProceed = false
    }
    
    // MARK: - Hook Phase Actions
    
    func updateHookProgress(_ progress: Double) {
        hookAnimationProgress = progress
        if progress >= 1.0 {
            hookAutoPlayComplete = true
            canProceed = true
        }
    }
    
    func completeHookPhase() {
        hookAutoPlayComplete = true
        canProceed = true
    }
    
    // MARK: - Teach Phase Actions
    
    func markTeachStepComplete() {
        teachCurrentStepComplete = true
        canProceed = true
    }
    
    func enableTeachSkip() {
        canSkipTeachStep = true
    }
    
    // MARK: - Practice Phase Actions
    
    /// Submit an answer for the current practice question
    func submitAnswer(_ answerIndex: Int) {
        guard currentPhase == .practice,
              !isAnswerRevealed else { return }
        
        selectedAnswer = answerIndex
        attempts += 1
        
        // Check if answer is correct
        guard let practice = currentPracticeQuestion else { return }
        
        let isCorrect: Bool
        switch practice {
        case .quiz(let quiz):
            isCorrect = answerIndex == quiz.correctIndex
        case .matching, .sequencing:
            // For matching/sequencing, this would be handled differently
            isCorrect = false
        }
        
        lastAnswerCorrect = isCorrect
        
        if isCorrect {
            correctAnswers += 1
            isAnswerRevealed = true
            showExplanation = true
            canProceed = true
            
            // Haptic feedback for correct answer
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            // Haptic feedback for wrong answer
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            if attempts >= maxAttempts {
                // Show the correct answer after max attempts
                isAnswerRevealed = true
                showExplanation = true
                canProceed = true
            }
        }
    }
    
    /// Force show the correct answer (after max attempts)
    func showCorrectAnswer() {
        isAnswerRevealed = true
        showExplanation = true
        canProceed = true
    }
    
    /// Reset current practice question for retry
    func retryQuestion() {
        selectedAnswer = nil
        isAnswerRevealed = false
        showExplanation = false
        // Note: attempts count is preserved
    }
    
    // MARK: - Scoring
    
    private func calculateScore() {
        guard totalQuestions > 0 else {
            score = 100
            return
        }
        score = Int((Double(correctAnswers) / Double(totalQuestions)) * 100)
    }
    
    private func calculateXP() {
        let baseXP = lesson.xpReward
        let scoreMultiplier = Double(score) / 100.0
        xpEarned = Int(Double(baseXP) * max(0.5, scoreMultiplier))
    }
    
    // MARK: - Reward Phase Actions
    
    func shareLesson() {
        showShareSheet = true
    }
    
    // MARK: - Completion
    
    func completeLesson() {
        // Calculate final values
        calculateScore()
        calculateXP()
        
        // Create or update lesson progress
        if let existingProgress = child.lessonProgress.first(where: { $0.lessonId == lesson.id }) {
            // Update existing progress if this attempt is better
            if score > existingProgress.score || !existingProgress.isCompleted {
                existingProgress.isCompleted = true
                existingProgress.completedAt = Date()
                existingProgress.score = max(existingProgress.score, score)
                existingProgress.xpEarned = max(existingProgress.xpEarned, xpEarned)
                existingProgress.attempts += 1
            } else {
                existingProgress.attempts += 1
            }
        } else {
            // Create new progress record
            let newProgress = LessonProgress(
                lessonId: lesson.id,
                isCompleted: true,
                score: score,
                xpEarned: xpEarned,
                attempts: 1
            )
            newProgress.child = child
            modelContext.insert(newProgress)
        }
        
        // Update child's total XP (only if first completion)
        if isFirstViewing {
            child.totalXP += xpEarned
            child.totalLessonsCompleted += 1
        }
        
        // Update streak
        updateStreak()
        
        // Check for achievements
        checkAchievements()
        
        // Save changes
        do {
            try modelContext.save()
            isLessonComplete = true
        } catch {
            errorMessage = "Error saving progress: \(error.localizedDescription)"
        }
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastActivity = child.lastLessonCompletedDate {
            let lastActivityDay = calendar.startOfDay(for: lastActivity)
            let daysDifference = calendar.dateComponents([.day], from: lastActivityDay, to: today).day ?? 0
            
            if daysDifference == 1 {
                // Consecutive day - increase streak
                child.currentStreak += 1
                if child.currentStreak > child.longestStreak {
                    child.longestStreak = child.currentStreak
                }
            } else if daysDifference > 1 {
                // Streak broken - reset
                child.currentStreak = 1
            }
            // If daysDifference == 0, same day - don't change streak
        } else {
            // First activity
            child.currentStreak = 1
            child.longestStreak = max(child.longestStreak, 1)
        }
        
        child.lastLessonCompletedDate = Date()
    }
    
    private func checkAchievements() {
        var newAchievements: [Achievement] = []
        
        func hasAchievement(_ type: AchievementType) -> Bool {
            child.achievements.contains { $0.achievementType == type }
        }
        
        // First Lesson achievement
        let completedLessons = child.lessonProgress.filter { $0.isCompleted }.count
        if completedLessons == 1 && !hasAchievement(.firstLesson) {
            let achievement = Achievement(achievementType: .firstLesson)
            achievement.child = child
            newAchievements.append(achievement)
        }
        
        // Streak achievements
        if child.currentStreak >= 3 && !hasAchievement(.streak3) {
            let achievement = Achievement(achievementType: .streak3)
            achievement.child = child
            newAchievements.append(achievement)
        }
        
        if child.currentStreak >= 7 && !hasAchievement(.streak7) {
            let achievement = Achievement(achievementType: .streak7)
            achievement.child = child
            newAchievements.append(achievement)
        }
        
        if child.currentStreak >= 30 && !hasAchievement(.streak30) {
            let achievement = Achievement(achievementType: .streak30)
            achievement.child = child
            newAchievements.append(achievement)
        }
        
        // Super Learner - XP based
        if child.totalXP >= 500 && !hasAchievement(.superLearner) {
            let achievement = Achievement(achievementType: .superLearner)
            achievement.child = child
            newAchievements.append(achievement)
        }
        
        // Perfect score achievements
        if score == 100 && !hasAchievement(.perfectScore) {
            let achievement = Achievement(achievementType: .perfectScore)
            achievement.child = child
            newAchievements.append(achievement)
        }
        
        // Insert all new achievements and award XP
        for achievement in newAchievements {
            modelContext.insert(achievement)
            child.totalXP += achievement.achievementType.xpReward
        }
    }
    
    // MARK: - Pause/Resume
    
    func togglePause() {
        isPaused.toggle()
    }
    
    func pause() {
        isPaused = true
    }
    
    func resume() {
        isPaused = false
    }
    
    // MARK: - Exit
    
    func requestExit() {
        showExitConfirmation = true
    }
    
    func confirmExit() {
        // Don't save progress - just exit
        showExitConfirmation = false
    }
    
    func cancelExit() {
        showExitConfirmation = false
    }
}

// MARK: - Safe Array Access Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
