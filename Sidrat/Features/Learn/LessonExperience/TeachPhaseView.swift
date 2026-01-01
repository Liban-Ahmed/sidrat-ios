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
    var audioPlayer: AudioPlayerService? = nil  // Optional bundled audio player
    let onComplete: () -> Void
    
    @Environment(\.isReduceMotionEnabled) private var reduceMotion
    @State private var currentStepIndex: Int = 0
    @State private var showContent = false
    @State private var canContinue = false
    @State private var hasStartedNarration = false
    @State private var showEnhancedControls = true
    
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
            // Enhanced audio controls with visual indicator
            if showEnhancedControls {
                enhancedAudioControls
                    .padding(.horizontal, Spacing.lg)
            } else {
                // Fallback to legacy controls
                legacyAudioControls
            }
        }
    }
    
    // MARK: - Enhanced Audio Controls (New)
    
    private var enhancedAudioControls: some View {
        VStack(spacing: Spacing.md) {
            // Audio status with animated indicator
            HStack(spacing: Spacing.sm) {
                if audioService.playbackState == .playing {
                    AudioPlayingIndicator(
                        color: category.color,
                        barWidth: 4,
                        barHeight: 20,
                        minBarHeight: 10
                    )
                    .frame(width: 24, height: 24)
                    
                    Text("Playing...")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(category.color)
                } else if audioService.playbackState == .paused {
                    Image(systemName: "pause.circle.fill")
                        .font(.title3)
                        .foregroundStyle(category.color)
                    
                    Text("Paused")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.textSecondary)
                }
                
                Spacer()
                
                // Time display
                if audioService.duration > 0 {
                    Text(formatTime(audioService.currentTime))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.textTertiary)
                    Text("/")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                    Text(formatTime(audioService.duration))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.textTertiary)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .opacity(audioService.playbackState == .playing || audioService.playbackState == .paused ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: audioService.playbackState)
            
            // Progress bar with scrubbing
            if audioService.duration > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        Capsule()
                            .fill(Color.surfaceTertiary)
                            .frame(height: 6)
                        
                        // Progress fill
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [category.color, category.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * audioService.progress, height: 6)
                            .animation(.linear(duration: 0.1), value: audioService.progress)
                        
                        // Scrubber handle
                        Circle()
                            .fill(.white)
                            .frame(width: 16, height: 16)
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                            .offset(x: (geometry.size.width * audioService.progress) - 8)
                            .animation(.linear(duration: 0.1), value: audioService.progress)
                    }
                }
                .frame(height: 16)
            }
            
            // Control buttons
            HStack(spacing: Spacing.lg) {
                // Replay button (44pt)
                Button {
                    replayCurrentStep()
                    triggerHaptic(.light)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.surfaceSecondary)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Replay from beginning")
                
                // Main Play/Pause button (60pt)
                Button {
                    if audioService.playbackState == .finished {
                        replayCurrentStep()
                    } else {
                        audioService.togglePlayPause()
                    }
                    triggerHaptic(.medium)
                } label: {
                    ZStack {
                        Circle()
                            .fill(category.color)
                            .frame(width: 60, height: 60)
                            .shadow(color: category.color.opacity(0.3), radius: 8, y: 4)
                        
                        if audioService.playbackState == .loading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: audioService.playbackState.icon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(audioService.playbackState == .loading)
                .accessibilityLabel(audioService.playbackState.accessibilityLabel)
                
                // Visual indicator space (44pt) for balance
                Group {
                    if audioService.playbackState == .playing {
                        CircularAudioIndicator(
                            color: category.color,
                            size: 32
                        )
                        .frame(width: 44, height: 44)
                    } else {
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color.surfacePrimary)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }
    
    // MARK: - Legacy Audio Controls
    
    private var legacyAudioControls: some View {
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
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
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
