//
//  MatchingView.swift
//  Sidrat
//
//  Drag-and-drop matching exercise for practice phase
//  Features: Visual/haptic feedback, 3 max attempts, accessibility support
//

import SwiftUI

// MARK: - Matching View

/// Drag-and-drop matching exercise component
struct MatchingView: View {
    let matching: MatchingPractice
    let category: LessonCategory
    let attemptCount: Int
    let maxAttempts: Int
    let onComplete: (Bool) -> Void
    let onContinue: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var matches: [Int: Int] = [:] // leftIndex: rightIndex
    @State private var selectedLeftIndex: Int? = nil
    @State private var isComplete = false
    @State private var isAllCorrect = false
    @State private var incorrectPairs: Set<Int> = []
    @State private var showFeedback = false
    
    // Shuffled right items for the exercise
    @State private var shuffledRightIndices: [Int] = []
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            headerSection
            
            // Instruction
            instructionSection
            
            // Matching area
            matchingSection
            
            // Check/Continue button
            actionButton
            
            // Feedback
            if showFeedback {
                feedbackSection
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showFeedback)
        .onAppear {
            setupExercise()
        }
    }
    
    // MARK: - Setup
    
    private func setupExercise() {
        // Shuffle right side items
        shuffledRightIndices = Array(0..<matching.pairs.count).shuffled()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(category.color)
            }
            
            // Title
            Text("Match the pairs!")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.textPrimary)
            
            // Attempts indicator
            attemptsIndicator
        }
    }
    
    private var attemptsIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxAttempts, id: \.self) { index in
                Circle()
                    .fill(index < attemptCount ? (isAllCorrect ? Color.success : Color.error.opacity(0.6)) : Color.surfaceTertiary)
                    .frame(width: 8, height: 8)
            }
            
            Text("\(maxAttempts - attemptCount) tries left")
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .padding(.leading, Spacing.xs)
        }
    }
    
    // MARK: - Instruction Section
    
    private var instructionSection: some View {
        Text(matching.instruction)
            .font(.body)
            .foregroundStyle(.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
    
    // MARK: - Matching Section
    
    private var matchingSection: some View {
        HStack(spacing: Spacing.xl) {
            // Left column
            VStack(spacing: Spacing.sm) {
                ForEach(Array(matching.pairs.enumerated()), id: \.offset) { index, pair in
                    MatchingItemButton(
                        text: pair.left,
                        isSelected: selectedLeftIndex == index,
                        isMatched: matches[index] != nil,
                        isCorrect: isComplete && !incorrectPairs.contains(index),
                        isIncorrect: isComplete && incorrectPairs.contains(index),
                        color: category.color,
                        reduceMotion: reduceMotion
                    ) {
                        selectLeftItem(index)
                    }
                    .disabled(isComplete)
                }
            }
            
            // Connection indicators
            VStack(spacing: Spacing.sm) {
                ForEach(0..<matching.pairs.count, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill(matches[index] != nil ? category.color : Color.surfaceTertiary)
                            .frame(width: 12, height: 12)
                        
                        if matches[index] != nil {
                            Image(systemName: "link")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(height: 52)
                }
            }
            
            // Right column (shuffled)
            VStack(spacing: Spacing.sm) {
                ForEach(shuffledRightIndices, id: \.self) { originalIndex in
                    let pair = matching.pairs[originalIndex]
                    let isMatchedToSomething = matches.values.contains(originalIndex)
                    let matchedFromIndex = matches.first(where: { $0.value == originalIndex })?.key
                    
                    MatchingItemButton(
                        text: pair.right,
                        isSelected: false,
                        isMatched: isMatchedToSomething,
                        isCorrect: isComplete && matchedFromIndex == originalIndex,
                        isIncorrect: isComplete && matchedFromIndex != nil && matchedFromIndex != originalIndex,
                        color: category.color,
                        reduceMotion: reduceMotion
                    ) {
                        selectRightItem(originalIndex)
                    }
                    .disabled(isComplete || isMatchedToSomething)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color.surfaceSecondary)
        )
    }
    
    private func selectLeftItem(_ index: Int) {
        if selectedLeftIndex == index {
            selectedLeftIndex = nil
        } else if matches[index] != nil {
            // Remove existing match
            matches[index] = nil
            selectedLeftIndex = index
        } else {
            selectedLeftIndex = index
        }
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    private func selectRightItem(_ rightIndex: Int) {
        guard let leftIndex = selectedLeftIndex else { return }
        
        // Create match
        matches[leftIndex] = rightIndex
        selectedLeftIndex = nil
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Group {
            if isComplete {
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
            } else {
                Button(action: checkMatches) {
                    Text("Check Answers")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .fill(matches.count == matching.pairs.count ? LinearGradient.primaryGradient : LinearGradient(colors: [Color.surfaceTertiary], startPoint: .leading, endPoint: .trailing))
                        )
                }
                .disabled(matches.count < matching.pairs.count)
            }
        }
    }
    
    private func checkMatches() {
        // Check each match
        incorrectPairs.removeAll()
        
        for (leftIndex, rightIndex) in matches {
            if leftIndex != rightIndex {
                incorrectPairs.insert(leftIndex)
            }
        }
        
        isAllCorrect = incorrectPairs.isEmpty
        isComplete = true
        showFeedback = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(isAllCorrect ? .success : .error)
        
        // Notify parent
        onComplete(isAllCorrect)
    }
    
    // MARK: - Feedback Section
    
    private var feedbackSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isAllCorrect ? "checkmark.circle.fill" : "info.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isAllCorrect ? .success : .brandPrimary)
                
                Text(isAllCorrect ? "Perfect! All matched correctly! 🎉" : "Some matches need another look!")
                    .font(.headline)
                    .foregroundStyle(isAllCorrect ? .success : .textPrimary)
            }
            
            if !isAllCorrect {
                Text("The correct matches are now highlighted in green.")
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(isAllCorrect ? Color.success.opacity(0.1) : Color.brandPrimary.opacity(0.1))
        )
    }
}

// MARK: - Matching Item Button

struct MatchingItemButton: View {
    let text: String
    let isSelected: Bool
    let isMatched: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    let color: Color
    let reduceMotion: Bool
    let onTap: () -> Void
    
    private var backgroundColor: Color {
        if isCorrect {
            return Color.brandSecondary.opacity(0.2)
        } else if isIncorrect {
            return Color.error.opacity(0.15)
        } else if isSelected {
            return color.opacity(0.15)
        } else if isMatched {
            return color.opacity(0.08)
        }
        return Color.surfacePrimary
    }
    
    private var borderColor: Color {
        if isCorrect {
            return .brandSecondary
        } else if isIncorrect {
            return .error
        } else if isSelected {
            return color
        } else if isMatched {
            return color.opacity(0.5)
        }
        return Color.surfaceTertiary
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.body.weight(.medium))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(width: 120, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .strokeBorder(borderColor, lineWidth: isSelected || isCorrect || isIncorrect ? 2 : 1)
                        )
                )
                .scaleEffect(isSelected && !reduceMotion ? 1.05 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)
        }
        .accessibilityLabel(text)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Sequencing View

/// Order items in correct sequence exercise
struct SequencingView: View {
    let sequencing: SequencingPractice
    let category: LessonCategory
    let attemptCount: Int
    let maxAttempts: Int
    let onComplete: (Bool) -> Void
    let onContinue: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var orderedItems: [String] = []
    @State private var isComplete = false
    @State private var isAllCorrect = false
    @State private var showFeedback = false
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            headerSection
            
            // Instruction
            Text(sequencing.instruction)
                .font(.body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Sequencing area
            sequencingSection
            
            // Action button
            actionButton
            
            // Feedback
            if showFeedback {
                feedbackSection
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showFeedback)
        .onAppear {
            setupExercise()
        }
    }
    
    private func setupExercise() {
        // Shuffle items for the user to order
        orderedItems = sequencing.items.shuffled()
    }
    
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "list.number")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(category.color)
            }
            
            Text("Put in the right order!")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.textPrimary)
            
            // Attempts indicator
            HStack(spacing: 4) {
                ForEach(0..<maxAttempts, id: \.self) { index in
                    Circle()
                        .fill(index < attemptCount ? (isAllCorrect ? Color.success : Color.error.opacity(0.6)) : Color.surfaceTertiary)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
    
    private var sequencingSection: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(Array(orderedItems.enumerated()), id: \.element) { index, item in
                SequencingItemRow(
                    text: item,
                    position: index + 1,
                    isCorrectPosition: isComplete && isItemInCorrectPosition(item, at: index),
                    isIncorrectPosition: isComplete && !isItemInCorrectPosition(item, at: index),
                    color: category.color,
                    onMoveUp: index > 0 ? { moveItem(from: index, to: index - 1) } : nil,
                    onMoveDown: index < orderedItems.count - 1 ? { moveItem(from: index, to: index + 1) } : nil
                )
                .disabled(isComplete)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color.surfaceSecondary)
        )
    }
    
    private func isItemInCorrectPosition(_ item: String, at index: Int) -> Bool {
        guard index < sequencing.correctOrder.count else { return false }
        let correctItemIndex = sequencing.correctOrder[index]
        return sequencing.items[correctItemIndex] == item
    }
    
    private func moveItem(from source: Int, to destination: Int) {
        withAnimation(.spring(response: 0.3)) {
            orderedItems.swapAt(source, destination)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private var actionButton: some View {
        Group {
            if isComplete {
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
                }
            } else {
                Button(action: checkOrder) {
                    Text("Check Order")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .fill(LinearGradient.primaryGradient)
                        )
                }
            }
        }
    }
    
    private func checkOrder() {
        // Check if order is correct
        isAllCorrect = orderedItems.enumerated().allSatisfy { index, item in
            isItemInCorrectPosition(item, at: index)
        }
        
        isComplete = true
        showFeedback = true
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(isAllCorrect ? .success : .error)
        
        onComplete(isAllCorrect)
    }
    
    private var feedbackSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isAllCorrect ? "checkmark.circle.fill" : "info.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isAllCorrect ? .success : .brandPrimary)
                
                Text(isAllCorrect ? "Perfect order! 🎉" : "Not quite right, check the highlights!")
                    .font(.headline)
                    .foregroundStyle(isAllCorrect ? .success : .textPrimary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(isAllCorrect ? Color.success.opacity(0.1) : Color.brandPrimary.opacity(0.1))
        )
    }
}

// MARK: - Sequencing Item Row

struct SequencingItemRow: View {
    let text: String
    let position: Int
    let isCorrectPosition: Bool
    let isIncorrectPosition: Bool
    let color: Color
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    
    private var backgroundColor: Color {
        if isCorrectPosition {
            return Color.brandSecondary.opacity(0.2)
        } else if isIncorrectPosition {
            return Color.error.opacity(0.15)
        }
        return Color.surfacePrimary
    }
    
    private var borderColor: Color {
        if isCorrectPosition {
            return .brandSecondary
        } else if isIncorrectPosition {
            return .error
        }
        return Color.surfaceTertiary
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Position number
            ZStack {
                Circle()
                    .fill(isCorrectPosition ? Color.brandSecondary : (isIncorrectPosition ? Color.error : color))
                    .frame(width: 32, height: 32)
                
                Text("\(position)")
                    .font(.labelMedium)
                    .foregroundStyle(.white)
            }
            
            // Item text
            Text(text)
                .font(.body.weight(.medium))
                .foregroundStyle(.textPrimary)
                .lineLimit(2)
            
            Spacer()
            
            // Move buttons
            if !isCorrectPosition && !isIncorrectPosition {
                HStack(spacing: Spacing.xs) {
                    if let onMoveUp {
                        Button(action: onMoveUp) {
                            Image(systemName: "chevron.up")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(Color.surfaceTertiary)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Move up")
                    }
                    
                    if let onMoveDown {
                        Button(action: onMoveDown) {
                            Image(systemName: "chevron.down")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(Color.surfaceTertiary)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Move down")
                    }
                }
            }
            
            // Result indicator
            if isCorrectPosition || isIncorrectPosition {
                Image(systemName: isCorrectPosition ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isCorrectPosition ? .brandSecondary : .error)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .strokeBorder(borderColor, lineWidth: isCorrectPosition || isIncorrectPosition ? 2 : 1)
                )
        )
    }
}

// MARK: - Sample Data

extension MatchingPractice {
    static var sample: MatchingPractice {
        MatchingPractice(
            pairs: [
                (left: "Bismillah", right: "Before eating"),
                (left: "Alhamdulillah", right: "After eating"),
                (left: "SubhanAllah", right: "When amazed")
            ],
            instruction: "Match each phrase with when we say it"
        )
    }
}

extension SequencingPractice {
    static var sample: SequencingPractice {
        SequencingPractice(
            items: ["Wash hands", "Rinse mouth", "Rinse nose", "Wash face"],
            correctOrder: [0, 1, 2, 3],
            instruction: "Put the wudu steps in the correct order"
        )
    }
}

// MARK: - Preview

#Preview("Matching View") {
    MatchingView(
        matching: MatchingPractice.sample,
        category: .adab,
        attemptCount: 0,
        maxAttempts: 3,
        onComplete: { _ in },
        onContinue: {}
    )
    .padding()
    .background(Color.surfacePrimary)
}

#Preview("Sequencing View") {
    SequencingView(
        sequencing: SequencingPractice.sample,
        category: .wudu,
        attemptCount: 0,
        maxAttempts: 3,
        onComplete: { _ in },
        onContinue: {}
    )
    .padding()
    .background(Color.surfacePrimary)
}
