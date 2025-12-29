//
//  EnhancedLessonPlayerView.swift
//  Sidrat
//
//  Main lesson player orchestrating the 4-phase learning experience
//  Hook → Teach → Practice → Reward
//
//  Features:
//  - Visual phase progress indicator
//  - Audio narration with pause/replay
//  - Tap-to-continue interactions
//  - Max 3 attempts per practice question
//  - Immediate feedback
//  - Achievement animation and share prompt
//  - Cannot skip phases on first viewing
//  - Reduced motion support
//

import SwiftUI
import SwiftData

// MARK: - Enhanced Lesson Player View

/// The main lesson player view orchestrating the 4-phase learning experience
struct EnhancedLessonPlayerView: View {
    let lesson: Lesson
    let child: Child
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    /// Whether reduced motion is enabled system-wide
    private var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    // MARK: - State
    
    @State private var currentPhase: LessonPhase = .hook
    @State private var progress: LessonPhaseProgress = LessonPhaseProgress()
    @State private var content: LessonPhaseContent?
    @State private var audioService = AudioNarrationService()
    @State private var showExitConfirmation = false
    @State private var lessonStartTime: Date = Date()
    @State private var correctCount: Int = 0
    @State private var totalCount: Int = 0
    @State private var showShareSheet = false
    
    // Animation states
    @State private var phaseTransitionOpacity: Double = 1.0
    @State private var headerVisible = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.surfacePrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with phase indicator and close button
                    if headerVisible {
                        headerView
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Phase content
                    phaseContent
                        .opacity(phaseTransitionOpacity)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupLesson()
        }
        .onDisappear {
            audioService.stop()
        }
        .confirmationDialog(
            "Exit Lesson?",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Exit", role: .destructive) {
                dismiss()
            }
            Button("Continue Learning", role: .cancel) {}
        } message: {
            Text("Your progress won't be saved if you exit now.")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareMessage])
        }
        .environment(\.isReduceMotionEnabled, isReduceMotionEnabled)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: Spacing.md) {
            // Top bar with close button
            HStack {
                // Close button
                Button {
                    showExitConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.surfaceSecondary)
                        )
                }
                .accessibilityLabel("Exit lesson")
                .accessibilityHint("Double tap to exit this lesson")
                
                Spacer()
                
                // Audio toggle
                Button {
                    audioService.isAudioEnabled.toggle()
                } label: {
                    Image(systemName: audioService.isAudioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(audioService.isAudioEnabled ? .brandPrimary : .textTertiary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.surfaceSecondary)
                        )
                }
                .accessibilityLabel(audioService.isAudioEnabled ? "Mute audio" : "Enable audio")
            }
            .padding(.horizontal, Spacing.md)
            
            // Phase indicator
            LessonPhaseIndicator(currentPhase: currentPhase, progress: progress)
                .padding(.horizontal, Spacing.md)
            
            // Lesson title
            HStack(spacing: Spacing.xs) {
                Image(systemName: lesson.category.iconName)
                    .font(.caption)
                    .foregroundStyle(lesson.category.color)
                
                Text(lesson.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
        .background(
            Color.surfacePrimary
                .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
        )
    }
    
    // MARK: - Phase Content
    
    @ViewBuilder
    private var phaseContent: some View {
        if let content {
            switch currentPhase {
            case .hook:
                HookPhaseView(
                    content: content.hook,
                    category: lesson.category,
                    audioService: audioService,
                    onComplete: {
                        transitionToPhase(.teach)
                    }
                )
                
            case .teach:
                TeachPhaseView(
                    contents: content.teach,
                    category: lesson.category,
                    audioService: audioService,
                    onComplete: {
                        transitionToPhase(.practice)
                    }
                )
                
            case .practice:
                PracticePhaseView(
                    practices: content.practice,
                    category: lesson.category,
                    audioService: audioService,
                    onComplete: { correct, total in
                        correctCount = correct
                        totalCount = total
                        transitionToPhase(.reward)
                    }
                )
                
            case .reward:
                RewardPhaseView(
                    lesson: lesson,
                    score: calculateScore(),
                    correctCount: correctCount,
                    totalCount: totalCount,
                    xpEarned: calculateXPEarned(),
                    audioService: audioService,
                    onShare: {
                        showShareSheet = true
                    },
                    onContinue: {
                        completeLesson()
                    }
                )
            }
        } else {
            // Loading state
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
        }
    }
    
    // MARK: - Setup
    
    private func setupLesson() {
        lessonStartTime = Date()
        
        // Generate content for the lesson
        content = LessonContentGenerator.generateContent(for: lesson)
        totalCount = content?.practice.count ?? 0
        
        // Initialize progress
        progress = LessonPhaseProgress(
            currentPhase: .hook,
            isFirstViewing: !hasCompletedLessonBefore()
        )
        
        // Update teach steps total
        if let teachContent = content?.teach {
            progress.teachTotalSteps = teachContent.count
        }
    }
    
    private func hasCompletedLessonBefore() -> Bool {
        return child.lessonProgress.contains { $0.lessonId == lesson.id && $0.isCompleted }
    }
    
    // MARK: - Phase Transitions
    
    private func transitionToPhase(_ newPhase: LessonPhase) {
        // Check if skipping is allowed
        guard progress.canSkipPhase || newPhase.rawValue == currentPhase.rawValue + 1 else {
            return
        }
        
        // Stop current audio
        audioService.stop()
        
        // Update progress for completed phase
        switch currentPhase {
        case .hook:
            progress.hookCompleted = true
        case .teach:
            progress.teachStepsCompleted = progress.teachTotalSteps
        case .practice:
            progress.practiceCorrect = correctCount
            progress.practiceTotal = totalCount
        case .reward:
            break
        }
        
        // Hide header during reward phase
        if newPhase == .reward {
            withAnimation(.easeInOut(duration: 0.3)) {
                headerVisible = false
            }
        }
        
        // Transition animation
        if isReduceMotionEnabled {
            currentPhase = newPhase
            progress.currentPhase = newPhase
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                phaseTransitionOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                currentPhase = newPhase
                progress.currentPhase = newPhase
                
                withAnimation(.easeIn(duration: 0.3)) {
                    phaseTransitionOpacity = 1
                }
            }
        }
    }
    
    // MARK: - Scoring
    
    private func calculateScore() -> Int {
        guard totalCount > 0 else { return 100 }
        return Int((Double(correctCount) / Double(totalCount)) * 100)
    }
    
    private func calculateXPEarned() -> Int {
        let baseXP = lesson.xpReward
        let scoreMultiplier = Double(calculateScore()) / 100.0
        return Int(Double(baseXP) * max(0.5, scoreMultiplier))
    }
    
    private var shareMessage: String {
        "I just learned about \(lesson.title) on Sidrat and scored \(calculateScore())%! 🌟🎉"
    }
    
    // MARK: - Completion
    
    private func completeLesson() {
        // Calculate final values
        let finalScore = calculateScore()
        let xpEarned = calculateXPEarned()
        
        // Create or update lesson progress
        if let existingProgress = child.lessonProgress.first(where: { $0.lessonId == lesson.id }) {
            // Update existing progress if this attempt is better
            if finalScore > existingProgress.score || !existingProgress.isCompleted {
                existingProgress.isCompleted = true
                existingProgress.completedAt = Date()
                existingProgress.score = max(existingProgress.score, finalScore)
                existingProgress.xpEarned = max(existingProgress.xpEarned, xpEarned)
                existingProgress.attempts += 1
            }
        } else {
            // Create new progress record
            let newProgress = LessonProgress(
                lessonId: lesson.id,
                isCompleted: true,
                score: finalScore,
                xpEarned: xpEarned,
                attempts: 1
            )
            newProgress.child = child
            modelContext.insert(newProgress)
        }
        
        // Update child's total XP (only if this is first completion)
        if !hasCompletedLessonBefore() {
            child.totalXP += xpEarned
        }
        
        // Update streak
        updateStreak()
        
        // Check for achievements
        checkAchievements()
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Error saving lesson completion: \(error)")
        }
        
        // Dismiss
        dismiss()
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
            child.longestStreak = 1
        }
        
        child.lastLessonCompletedDate = Date()
    }
    
    private func checkAchievements() {
        var newAchievements: [Achievement] = []
        
        // Helper to check if achievement already exists
        func hasAchievement(_ type: AchievementType) -> Bool {
            child.achievements.contains { $0.achievementType == type }
        }
        
        // First Lesson achievement
        if child.lessonProgress.filter({ $0.isCompleted }).count == 1 && !hasAchievement(.firstLesson) {
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
        
        // Insert all new achievements and award XP
        for achievement in newAchievements {
            modelContext.insert(achievement)
            child.totalXP += achievement.achievementType.xpReward
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

