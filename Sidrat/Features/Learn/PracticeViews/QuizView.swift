//
//  QuizView.swift
//  Sidrat
//
//  Multiple choice quiz component for practice phase
//  Features: 60pt min height options, visual/haptic feedback,
//  3 max attempts, shake animation for wrong answers
//

import SwiftUI

// MARK: - Quiz View

/// Multiple choice quiz component with immediate feedback
struct QuizView: View {
    let quiz: QuizPractice
    let category: LessonCategory
    let attemptCount: Int
    let maxAttempts: Int
    let selectedAnswer: Int?
    let isAnswerRevealed: Bool
    let onSelectAnswer: (Int) -> Void
    let onContinue: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shakeWrongAnswer = false
    @State private var showCorrectFlash = false
    @State private var wrongAnswerIndex: Int? = nil
    
    private var isCorrect: Bool {
        selectedAnswer == quiz.correctIndex
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Question header
            questionHeader
            
            // Options
            optionsSection
            
            // Feedback section
            if isAnswerRevealed {
                feedbackSection
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Continue button (after answering)
            if isAnswerRevealed {
                continueButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAnswerRevealed)
    }
    
    // MARK: - Question Header
    
    private var questionHeader: some View {
        VStack(spacing: Spacing.md) {
            // Question icon
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "questionmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(category.color)
            }
            
            // Question text
            Text(quiz.question)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            // Attempts indicator
            attemptsIndicator
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Question: \(quiz.question). Attempts: \(attemptCount) of \(maxAttempts)")
    }
    
    private var attemptsIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxAttempts, id: \.self) { index in
                Circle()
                    .fill(attemptColor(for: index))
                    .frame(width: 8, height: 8)
            }
            
            Text("\(maxAttempts - attemptCount) tries left")
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .padding(.leading, Spacing.xs)
        }
    }
    
    private func attemptColor(for index: Int) -> Color {
        if index < attemptCount {
            if isAnswerRevealed && isCorrect {
                return .success
            } else {
                return .error.opacity(0.6)
            }
        }
        return .surfaceTertiary
    }
    
    // MARK: - Options Section
    
    private var optionsSection: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(Array(quiz.options.enumerated()), id: \.offset) { index, option in
                QuizOptionButton(
                    text: option,
                    index: index,
                    isSelected: selectedAnswer == index,
                    isCorrect: index == quiz.correctIndex,
                    isRevealed: isAnswerRevealed,
                    isDisabled: isAnswerRevealed,
                    categoryColor: category.color,
                    shake: wrongAnswerIndex == index && shakeWrongAnswer,
                    showCorrectFlash: index == quiz.correctIndex && showCorrectFlash,
                    reduceMotion: reduceMotion,
                    onTap: {
                        selectAnswer(index)
                    }
                )
            }
        }
    }
    
    private func selectAnswer(_ index: Int) {
        guard !isAnswerRevealed else { return }
        
        onSelectAnswer(index)
        
        // Visual feedback
        if index != quiz.correctIndex {
            wrongAnswerIndex = index
            if !reduceMotion {
                withAnimation(.default) {
                    shakeWrongAnswer = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shakeWrongAnswer = false
                    wrongAnswerIndex = nil
                }
            }
        } else {
            if !reduceMotion {
                showCorrectFlash = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCorrectFlash = false
                }
            }
        }
    }
    
    // MARK: - Feedback Section
    
    private var feedbackSection: some View {
        VStack(spacing: Spacing.sm) {
            // Result indicator
            HStack(spacing: Spacing.sm) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "info.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isCorrect ? .success : .brandPrimary)
                
                Text(isCorrect ? "Correct! 🎉" : "Let's learn!")
                    .font(.headline)
                    .foregroundStyle(isCorrect ? .success : .textPrimary)
            }
            
            // Explanation
            Text(quiz.explanation)
                .font(.body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Spacing.md)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(isCorrect ? Color.success.opacity(0.1) : Color.brandPrimary.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isCorrect ? "Correct answer! \(quiz.explanation)" : "Explanation: \(quiz.explanation)")
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button(action: onContinue) {
            HStack(spacing: Spacing.sm) {
                Text("Continue")
                    .font(.headline)
                
                Image(systemName: "arrow.right")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(LinearGradient.primaryGradient)
            )
            .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, y: 4)
        }
        .accessibilityLabel("Continue to next question")
    }
}

// MARK: - Quiz Option Button

struct QuizOptionButton: View {
    let text: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool
    let isRevealed: Bool
    let isDisabled: Bool
    let categoryColor: Color
    let shake: Bool
    let showCorrectFlash: Bool
    let reduceMotion: Bool
    let onTap: () -> Void
    
    // Design specification: 60pt minimum height
    private let minHeight: CGFloat = 60
    
    private var backgroundColor: Color {
        if isRevealed {
            if isCorrect {
                return Color.brandSecondary.opacity(0.2)
            } else if isSelected && !isCorrect {
                return Color.error.opacity(0.15)
            }
        }
        return isSelected ? categoryColor.opacity(0.1) : Color.surfaceSecondary
    }
    
    private var borderColor: Color {
        if isRevealed {
            if isCorrect {
                return .brandSecondary
            } else if isSelected && !isCorrect {
                return .error
            }
        }
        return isSelected ? categoryColor : .clear
    }
    
    private var textColor: Color {
        if isRevealed && isCorrect {
            return .brandSecondary
        } else if isRevealed && isSelected && !isCorrect {
            return .error
        }
        return .textPrimary
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Option letter
                optionLetter
                
                // Option text
                Text(text)
                    .font(.body.weight(.medium))
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                Spacer()
                
                // Result indicator
                if isRevealed {
                    resultIndicator
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .frame(minHeight: minHeight)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .strokeBorder(borderColor, lineWidth: isSelected || (isRevealed && isCorrect) ? 2 : 0)
                    )
                    .overlay(
                        // Correct answer flash
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(Color.brandSecondary)
                            .opacity(showCorrectFlash ? 0.3 : 0)
                    )
            )
            .modifier(ShakeModifier(shake: shake, reduceMotion: reduceMotion))
        }
        .disabled(isDisabled)
        .accessibilityLabel("\(optionLetterText): \(text)")
        .accessibilityHint(isRevealed ? (isCorrect ? "Correct answer" : "Incorrect answer") : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var optionLetterText: String {
        String(UnicodeScalar(65 + index)!) // A, B, C, D...
    }
    
    private var optionLetter: some View {
        ZStack {
            Circle()
                .fill(isSelected ? categoryColor : Color.surfaceTertiary)
                .frame(width: 32, height: 32)
            
            Text(optionLetterText)
                .font(.labelMedium)
                .foregroundStyle(isSelected ? .white : .textSecondary)
        }
    }
    
    @ViewBuilder
    private var resultIndicator: some View {
        if isCorrect {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.brandSecondary)
        } else if isSelected && !isCorrect {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.error)
        }
    }
}

// MARK: - Shake Modifier

struct ShakeModifier: ViewModifier {
    let shake: Bool
    let reduceMotion: Bool
    
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .offset(x: shake ? -10 : 0)
                .animation(
                    shake ? Animation.default.repeatCount(3, autoreverses: true).speed(6) : .default,
                    value: shake
                )
        }
    }
}

// MARK: - Quiz Practice Model Extension

extension QuizPractice {
    /// Creates a sample quiz for previews
    static var sample: QuizPractice {
        QuizPractice(
            question: "What do we say before starting wudu?",
            options: ["Alhamdulillah", "Bismillah", "SubhanAllah", "Allahu Akbar"],
            correctIndex: 1,
            explanation: "'Bismillah' means 'In the name of Allah' - we say it to start wudu!"
        )
    }
}

// MARK: - Preview

#Preview("Quiz - Unanswered") {
    QuizView(
        quiz: QuizPractice.sample,
        category: .wudu,
        attemptCount: 0,
        maxAttempts: 3,
        selectedAnswer: nil,
        isAnswerRevealed: false,
        onSelectAnswer: { _ in },
        onContinue: {}
    )
    .padding()
    .background(Color.surfacePrimary)
}

#Preview("Quiz - Correct Answer") {
    QuizView(
        quiz: QuizPractice.sample,
        category: .wudu,
        attemptCount: 1,
        maxAttempts: 3,
        selectedAnswer: 1,
        isAnswerRevealed: true,
        onSelectAnswer: { _ in },
        onContinue: {}
    )
    .padding()
    .background(Color.surfacePrimary)
}

#Preview("Quiz - Wrong Answer") {
    QuizView(
        quiz: QuizPractice.sample,
        category: .wudu,
        attemptCount: 2,
        maxAttempts: 3,
        selectedAnswer: 0,
        isAnswerRevealed: true,
        onSelectAnswer: { _ in },
        onContinue: {}
    )
    .padding()
    .background(Color.surfacePrimary)
}
