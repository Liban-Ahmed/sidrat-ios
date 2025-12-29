//
//  TeachPhaseView.swift
//  Sidrat
//
//  The Teach phase view - 2-2.5 minutes of learning content
//  Features audio narration, pause/replay controls, tap-to-continue
//

import SwiftUI

// MARK: - Teach Phase View

/// The main teaching phase with audio narration and interactive content
struct TeachPhaseView: View {
    let contents: [TeachContent]
    let category: LessonCategory
    let audioService: AudioNarrationService
    let onComplete: () -> Void
    
    @Environment(\.isReduceMotionEnabled) private var reduceMotion
    @State private var currentStepIndex: Int = 0
    @State private var showContent = false
    @State private var canContinue = false
    @State private var hasStartedNarration = false
    
    private var currentContent: TeachContent {
        contents[safe: currentStepIndex] ?? contents[0]
    }
    
    private var isLastStep: Bool {
        currentStepIndex >= contents.count - 1
    }
    
    private var stepProgress: Double {
        guard contents.count > 0 else { return 0 }
        return Double(currentStepIndex + 1) / Double(contents.count)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Step progress indicator
                stepProgressView
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.md)
                
                // Scrollable content area
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Main content card
                        contentCard
                            .padding(.horizontal, Spacing.lg)
                        
                        // Audio controls
                        audioControlsSection
                            .padding(.top, Spacing.md)
                    }
                    .padding(.bottom, Spacing.lg)
                }
                .scrollIndicators(.hidden)
                
                // Continue button - pinned at bottom
                if canContinue || !currentContent.requiresTapToContinue {
                    continueSection
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
            startCurrentStep()
        }
        .onChange(of: currentStepIndex) { _, _ in
            startCurrentStep()
        }
    }
    
    // MARK: - Step Progress View
    
    private var stepProgressView: some View {
        VStack(spacing: Spacing.xs) {
            // Step counter
            HStack {
                Text("Step \(currentStepIndex + 1) of \(contents.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.textSecondary)
                
                Spacer()
                
                // Time estimate
                Text(estimatedTimeRemaining)
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.surfaceTertiary)
                    
                    // Progress
                    Capsule()
                        .fill(category.color)
                        .frame(width: geometry.size.width * stepProgress)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: stepProgress)
                }
            }
            .frame(height: 6)
        }
    }
    
    private var estimatedTimeRemaining: String {
        let remainingSteps = contents.count - currentStepIndex
        let estimatedSeconds = remainingSteps * 45 // ~45 seconds per step
        let minutes = estimatedSeconds / 60
        let seconds = estimatedSeconds % 60
        return "~\(minutes):\(String(format: "%02d", seconds)) remaining"
    }
    
    // MARK: - Content Card
    
    private var contentCard: some View {
        VStack(spacing: Spacing.lg) {
            // Icon header
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: currentContent.icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(category.color)
            }
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1.0 : 0.0)
            
            // Title
            Text(currentContent.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 10)
            
            // Main text
            Text(currentContent.text)
                .font(.body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 10)
            
            // Fun fact (if available)
            if let funFact = currentContent.funFact {
                funFactBubble(funFact)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 10)
            }
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.extraLarge)
                .fill(Color.surfaceSecondary)
                .shadow(color: .black.opacity(0.05), radius: 15, y: 5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentContent.title). \(currentContent.text)")
    }
    
    private func funFactBubble(_ fact: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(.body)
                .foregroundStyle(.brandAccent)
            
            Text(fact)
                .font(.footnote)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.brandAccent.opacity(0.1))
        )
    }
    
    // MARK: - Audio Controls
    
    private var audioControlsSection: some View {
        VStack(spacing: Spacing.md) {
            // Audio progress bar
            if audioService.playbackState == .playing || audioService.playbackState == .paused {
                audioProgressBar
                    .padding(.horizontal, Spacing.xl)
            }
            
            // Audio control buttons
            AudioControlButton(
                playbackState: audioService.playbackState,
                action: {
                    audioService.togglePlayPause()
                },
                replayAction: {
                    replayCurrentStep()
                }
            )
        }
    }
    
    private var audioProgressBar: some View {
        VStack(spacing: Spacing.xxs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.surfaceTertiary)
                    
                    // Progress
                    Capsule()
                        .fill(Color.brandPrimary)
                        .frame(width: geometry.size.width * audioService.progress)
                }
            }
            .frame(height: 4)
            
            // Time labels
            HStack {
                Text(formatTime(audioService.currentTime))
                    .font(.caption2)
                    .foregroundStyle(.textTertiary)
                
                Spacer()
                
                Text(formatTime(audioService.duration))
                    .font(.caption2)
                    .foregroundStyle(.textTertiary)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Continue Section
    
    private var continueSection: some View {
        VStack(spacing: Spacing.sm) {
            // Tap to continue hint
            if currentContent.requiresTapToContinue && canContinue {
                Text("Tap to continue")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
            
            // Continue button
            Button {
                goToNextStep()
            } label: {
                HStack(spacing: Spacing.sm) {
                    Text(isLastStep ? "Start Practice" : "Next")
                        .font(.headline.weight(.bold))
                    
                    Image(systemName: isLastStep ? "pencil.and.list.clipboard" : "arrow.right")
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
            .accessibilityHint(isLastStep ? "Double tap to start practice questions" : "Double tap to continue to next step")
        }
    }
    
    // MARK: - Actions
    
    private func startCurrentStep() {
        showContent = false
        canContinue = false
        
        // Animate content appearance
        if reduceMotion {
            showContent = true
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        
        // Start narration
        let textToSpeak = "\(currentContent.title). \(currentContent.text)"
        if let funFact = currentContent.funFact {
            audioService.speak("\(textToSpeak) Did you know? \(funFact)") { [self] in
                enableContinue()
            }
        } else {
            audioService.speak(textToSpeak) { [self] in
                enableContinue()
            }
        }
        
        // Auto-enable continue if no tap required
        if !currentContent.requiresTapToContinue {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                if !canContinue {
                    enableContinue()
                }
            }
        }
    }
    
    private func enableContinue() {
        if reduceMotion {
            canContinue = true
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                canContinue = true
            }
        }
    }
    
    private func goToNextStep() {
        audioService.stop()
        
        if isLastStep {
            onComplete()
        } else {
            if reduceMotion {
                currentStepIndex += 1
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStepIndex += 1
                }
            }
        }
    }
    
    private func replayCurrentStep() {
        canContinue = false
        audioService.replay()
        
        // Re-enable continue when narration completes
        DispatchQueue.main.asyncAfter(deadline: .now() + currentContent.estimatedDuration) { [self] in
            enableContinue()
        }
    }
}

// MARK: - Preview

#Preview("Teach Phase") {
    TeachPhaseView(
        contents: LessonContentGenerator.generateContent(
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
        ).teach,
        category: .wudu,
        audioService: AudioNarrationService(),
        onComplete: {}
    )
}
