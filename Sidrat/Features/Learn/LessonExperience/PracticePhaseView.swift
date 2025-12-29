//
//  PracticePhaseView.swift
//  Sidrat
//
//  The Practice phase view - Interactive quiz/matching/sequencing
//  Features max 3 attempts per question, immediate feedback
//

import SwiftUI

// MARK: - Practice Phase View

/// Interactive practice phase with quiz, matching, and sequencing exercises
struct PracticePhaseView: View {
    let practices: [PracticeContent]
    let category: LessonCategory
    let audioService: AudioNarrationService
    let onComplete: (Int, Int) -> Void // (correctCount, totalCount)
    
    @Environment(\.isReduceMotionEnabled) private var reduceMotion
    @State private var currentPracticeIndex: Int = 0
    @State private var correctCount: Int = 0
    @State private var currentAttempts: Int = 0
    @State private var showFeedback: Bool = false
    @State private var isCorrect: Bool = false
    @State private var showExplanation: Bool = false
    @State private var selectedAnswer: Int? = nil
    @State private var hasAnswered: Bool = false
    
    private var currentPractice: PracticeContent {
        practices[safe: currentPracticeIndex] ?? practices[0]
    }
    
    private var isLastPractice: Bool {
        currentPracticeIndex >= practices.count - 1
    }
    
    private var practiceProgress: Double {
        guard practices.count > 0 else { return 0 }
        return Double(currentPracticeIndex + 1) / Double(practices.count)
    }
    
    private var maxAttempts: Int {
        currentPractice.maxAttempts
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Progress header
                progressHeader
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.md)
                
                // Scrollable content area
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Practice content
                        practiceContentView
                            .padding(.horizontal, Spacing.lg)
                        
                        // Spacer to push content up when feedback is not showing
                        if !showFeedback {
                            Spacer(minLength: 100)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                
                // Feedback section - always pinned at bottom when visible
                if showFeedback {
                    feedbackSection
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.lg)
                        .background(
                            Color.surfacePrimary
                                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.surfacePrimary)
        }
        .onAppear {
            startCurrentPractice()
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                // Question counter
                Text("Question \(currentPracticeIndex + 1) of \(practices.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.textSecondary)
                
                Spacer()
                
                // Attempts indicator
                HStack(spacing: 4) {
                    ForEach(0..<maxAttempts, id: \.self) { index in
                        Circle()
                            .fill(attemptColor(for: index))
                            .frame(width: 8, height: 8)
                    }
                }
                .accessibilityLabel("Attempts remaining: \(maxAttempts - currentAttempts)")
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.surfaceTertiary)
                    
                    Capsule()
                        .fill(category.color)
                        .frame(width: geometry.size.width * practiceProgress)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: practiceProgress)
                }
            }
            .frame(height: 6)
            
            // Score display
            HStack {
                Spacer()
                
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.brandAccent)
                    
                    Text("\(correctCount) correct")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.textSecondary)
                }
            }
        }
    }
    
    private func attemptColor(for index: Int) -> Color {
        if index < currentAttempts {
            return isCorrect ? .green : .red.opacity(0.5)
        } else {
            return .surfaceTertiary
        }
    }
    
    // MARK: - Practice Content
    
    @ViewBuilder
    private var practiceContentView: some View {
        switch currentPractice {
        case .quiz(let quiz):
            quizView(quiz)
        case .matching(let matching):
            matchingView(matching)
        case .sequencing(let sequencing):
            sequencingView(sequencing)
        }
    }
    
    // MARK: - Question Header
    
    private func questionHeader(icon: String, text: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(category.color)
            
            HStack(alignment: .center, spacing: Spacing.sm) {
                Text(text)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Button {
                    if audioService.playbackState == .playing {
                        audioService.pause()
                    } else if audioService.playbackState == .paused {
                        audioService.resume()
                    } else {
                        audioService.speak(text)
                    }
                } label: {
                    if audioService.playbackState == .loading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: audioService.playbackState == .playing ? "pause.circle.fill" : "speaker.wave.2.circle.fill")
                            .font(.title2)
                            .foregroundStyle(category.color)
                    }
                }
                .buttonStyle(.plain)
                .disabled(audioService.playbackState == .loading)
                .accessibilityLabel("Play question audio")
            }
        }
    }
    
    // MARK: - Quiz View
    
    private func quizView(_ quiz: QuizPractice) -> some View {
        VStack(spacing: Spacing.xl) {
            // Question
            questionHeader(icon: "questionmark.circle.fill", text: quiz.question)
            
            // Options
            VStack(spacing: Spacing.md) {
                ForEach(Array(quiz.options.enumerated()), id: \.offset) { index, option in
                    SimplifiedQuizOptionButton(
                        text: option,
                        isSelected: selectedAnswer == index,
                        isCorrect: hasAnswered ? index == quiz.correctIndex : nil,
                        isDisabled: hasAnswered,
                        action: {
                            selectAnswer(index, correctIndex: quiz.correctIndex)
                        }
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quiz question: \(quiz.question)")
    }
    
    // MARK: - Matching View
    
    private func matchingView(_ matching: MatchingPractice) -> some View {
        VStack(spacing: Spacing.xl) {
            // Instruction
            questionHeader(icon: "arrow.left.arrow.right", text: matching.instruction)
            
            // Matching pairs display (simplified for now - can be expanded)
            VStack(spacing: Spacing.md) {
                ForEach(Array(matching.pairs.enumerated()), id: \.offset) { index, pair in
                    HStack {
                        Text(pair.left)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    .fill(Color.surfaceSecondary)
                            )
                        
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.textTertiary)
                        
                        Text(pair.right)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    .fill(category.color.opacity(0.15))
                            )
                    }
                }
            }
            
            // Auto-complete matching (simplified)
            if !hasAnswered {
                Button("Check Matches") {
                    selectAnswer(0, correctIndex: 0) // Simplified matching validation
                }
                .buttonStyle(PracticeButtonStyle(color: category.color))
            }
        }
    }
    
    // MARK: - Sequencing View
    
    private func sequencingView(_ sequencing: SequencingPractice) -> some View {
        VStack(spacing: Spacing.xl) {
            // Instruction
            questionHeader(icon: "list.number", text: sequencing.instruction)
            
            // Sequence items (displayed in correct order for now - can add drag reordering)
            VStack(spacing: Spacing.sm) {
                ForEach(Array(sequencing.items.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: Spacing.md) {
                        Text("\(index + 1)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(category.color)
                            )
                        
                        Text(item)
                            .font(.body)
                            .foregroundStyle(.textPrimary)
                        
                        Spacer()
                    }
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(Color.surfaceSecondary)
                    )
                }
            }
            
            // Auto-complete sequencing (simplified)
            if !hasAnswered {
                Button("Check Order") {
                    selectAnswer(0, correctIndex: 0) // Simplified sequencing validation
                }
                .buttonStyle(PracticeButtonStyle(color: category.color))
            }
        }
    }
    
    // MARK: - Feedback Section
    
    private var feedbackSection: some View {
        VStack(spacing: Spacing.lg) {
            // Feedback card
            VStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isCorrect ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(isCorrect ? .green : .red)
                }
                
                // Message
                Text(feedbackMessage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.textPrimary)
                
                // Explanation (for quizzes)
                if showExplanation, case .quiz(let quiz) = currentPractice {
                    Text(quiz.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .fill(Color.surfaceTertiary)
                        )
                }
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(Color.surfaceSecondary)
            )
            
            // Continue button
            Button(action: goToNextPractice) {
                HStack(spacing: Spacing.sm) {
                    Text(isLastPractice ? "See Results" : "Next Question")
                        .font(.headline.weight(.bold))
                    
                    Image(systemName: isLastPractice ? "trophy.fill" : "arrow.right")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [category.color, category.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: category.color.opacity(0.3), radius: 10, y: 5)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var feedbackMessage: String {
        if isCorrect {
            return ["Amazing! 🌟", "Great job! ⭐", "Excellent! 🎉", "Perfect! 💫"].randomElement() ?? "Correct!"
        } else if currentAttempts >= maxAttempts {
            return "That's okay! Here's the answer 📚"
        } else {
            return ["Try again! 💪", "Almost! 🤔", "Not quite... 🔄"].randomElement() ?? "Try again!"
        }
    }
    
    // MARK: - Actions
    
    private func startCurrentPractice() {
        currentAttempts = 0
        selectedAnswer = nil
        hasAnswered = false
        showFeedback = false
        showExplanation = false
        isCorrect = false
        
        // Narrate the question
        switch currentPractice {
        case .quiz(let quiz):
            audioService.speak(quiz.question)
        case .matching(let matching):
            audioService.speak(matching.instruction)
        case .sequencing(let sequencing):
            audioService.speak(sequencing.instruction)
        }
    }
    
    private func selectAnswer(_ index: Int, correctIndex: Int) {
        guard !hasAnswered || currentAttempts < maxAttempts else { return }
        
        currentAttempts += 1
        selectedAnswer = index
        isCorrect = index == correctIndex
        
        // Provide audio feedback
        if isCorrect {
            audioService.speak("Correct! Great job!", rate: 0.5)
            correctCount += 1
            hasAnswered = true
            showExplanation = true
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showFeedback = true
            }
            
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            // Haptic feedback for wrong answer
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            
            if currentAttempts >= maxAttempts {
                // Show correct answer after max attempts
                hasAnswered = true
                showExplanation = true
                audioService.speak("Let's see the correct answer")
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showFeedback = true
                }
            } else {
                // Allow retry
                audioService.speak("Try again!", rate: 0.5)
                
                // Brief feedback then reset
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showFeedback = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showFeedback = false
                        selectedAnswer = nil
                    }
                }
            }
        }
    }
    
    private func goToNextPractice() {
        audioService.stop()
        
        if isLastPractice {
            onComplete(correctCount, practices.count)
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPracticeIndex += 1
            }
            startCurrentPractice()
        }
    }
}

// MARK: - Simple Quiz Option Button (Simplified version for Practice Phase)

private struct SimplifiedQuizOptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool?
    let isDisabled: Bool
    let action: () -> Void
    
    @Environment(\.isReduceMotionEnabled) private var reduceMotion
    @State private var isPressed = false
    
    private var backgroundColor: Color {
        if let isCorrect {
            if isCorrect {
                return .green.opacity(0.15)
            } else if isSelected {
                return .red.opacity(0.15)
            }
        }
        return isSelected ? Color.brandPrimary.opacity(0.15) : Color.surfaceSecondary
    }
    
    private var borderColor: Color {
        if let isCorrect {
            if isCorrect {
                return .green
            } else if isSelected {
                return .red
            }
        }
        return isSelected ? .brandPrimary : .clear
    }
    
    private var iconName: String? {
        guard let isCorrect else { return nil }
        if isCorrect {
            return "checkmark.circle.fill"
        } else if isSelected {
            return "xmark.circle.fill"
        }
        return nil
    }
    
    private var iconColor: Color {
        if let isCorrect, isCorrect {
            return .green
        }
        return .red
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Text(text)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if let iconName {
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .strokeBorder(borderColor, lineWidth: isSelected ? 2 : 0)
            )
            .scaleEffect(isPressed && !reduceMotion ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled && !isSelected && isCorrect != true ? 0.6 : 1.0)
        .accessibilityLabel(text)
        .accessibilityHint(isDisabled ? "" : "Double tap to select this answer")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isDisabled && !reduceMotion {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    if !reduceMotion {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = false
                        }
                    }
                }
        )
    }
}

// MARK: - Practice Button Style

struct PracticeButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Preview

#Preview("Practice Phase") {
    PracticePhaseView(
        practices: LessonContentGenerator.generateContent(
            for: Lesson(
                id: "test",
                title: "Test Lesson",
                description: "Test",
                category: .wudu,
                difficulty: .beginner,
                durationMinutes: 5,
                xpReward: 50,
                order: 1,
                weekNumber: 1
            )
        ).practice,
        category: .wudu,
        audioService: AudioNarrationService(),
        onComplete: { correct, total in
            print("Score: \(correct)/\(total)")
        }
    )
}
