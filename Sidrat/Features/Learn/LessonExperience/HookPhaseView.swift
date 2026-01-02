//
//  HookPhaseView.swift
//  Sidrat
//
//  The Hook phase view - 30-45 second attention-grabbing intro
//  Auto-plays engaging animation with a thought-provoking question
//

import SwiftUI

// MARK: - Hook Phase View

/// The opening hook phase of a lesson - designed to capture attention
struct HookPhaseView: View {
    let content: HookContent
    let category: LessonCategory
    let audioService: AudioNarrationService?
    let onComplete: () -> Void
    
    @Environment(\.isReduceMotionEnabled) private var reduceMotion
    @State private var animationPhase: AnimationPhase = .idle
    @State private var showQuestion = false
    @State private var questionScale: CGFloat = 0.8
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = 0
    @State private var sparkleOpacity: Double = 0
    @State private var backgroundPulse: Bool = false
    @State private var autoPlayProgress: Double = 0
    @State private var autoPlayTimer: Timer?
    @State private var hasStartedAudio: Bool = false
    
    private enum AnimationPhase: Int, Comparable {
        case idle = 0
        case iconAppear = 1
        case iconAnimate = 2
        case questionReveal = 3
        case complete = 4
        
        static func < (lhs: AnimationPhase, rhs: AnimationPhase) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Main content area
                VStack(spacing: Spacing.xl) {
                    // Animated icon
                    iconView
                        .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)
                    
                    // Question text
                    questionView
                        .padding(.horizontal, Spacing.lg)
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Auto-play progress indicator
                progressView
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.lg)
                
                // Continue button (appears when auto-play completes)
                if animationPhase >= .complete {
                    continueButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, Spacing.xl)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundGradient)
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            autoPlayTimer?.invalidate()
        }
    }
    
    // MARK: - Icon View
    
    private var iconView: some View {
        ZStack {
            // Glow effect
            if !reduceMotion && backgroundPulse {
                Circle()
                    .fill(category.color.opacity(0.3))
                    .scaleEffect(backgroundPulse ? 1.5 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: backgroundPulse
                    )
            }
            
            // Sparkle particles (only when not reduce motion)
            if !reduceMotion && sparkleOpacity > 0 {
                SparkleParticles(color: category.color)
                    .opacity(sparkleOpacity)
            }
            
            // Main icon container
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [category.color, category.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: category.color.opacity(0.4), radius: 20, y: 10)
                
                // Icon
                Image(systemName: content.animation.rawValue)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(reduceMotion ? 0 : iconRotation))
            }
            .scaleEffect(iconScale)
        }
    }
    
    // MARK: - Question View
    
    private var questionView: some View {
        VStack(spacing: Spacing.sm) {
            Text(content.question)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(showQuestion ? 1 : 0)
                .scaleEffect(questionScale)
                .accessibilityLabel("Hook question: \(content.question)")
        }
    }
    
    // MARK: - Progress View
    
    private var progressView: some View {
        VStack(spacing: Spacing.sm) {
            // Audio playing indicator when narration is active
            if audioService?.playbackState == .playing {
                HStack(spacing: Spacing.sm) {
                    WaveformIndicator(
                        color: category.color,
                        barCount: 5,
                        barWidth: 3,
                        maxBarHeight: 16,
                        spacing: 2
                    )
                    
                    Text("Listening...")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(category.color)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.surfaceTertiary)
                    
                    // Progress
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [category.color, category.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * autoPlayProgress)
                }
            }
            .frame(height: 8)
            
            // Time remaining
            Text(timeRemainingText)
                .font(.caption)
                .foregroundStyle(.textTertiary)
        }
        .animation(.easeInOut(duration: 0.3), value: audioService?.playbackState)
    }
    
    private var timeRemainingText: String {
        let remaining = content.duration * (1 - autoPlayProgress)
        let seconds = Int(remaining)
        return seconds > 0 ? "Continuing in \(seconds)s..." : "Ready!"
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button(action: onComplete) {
            HStack(spacing: Spacing.sm) {
                Text("Let's Learn!")
                    .font(.headline.weight(.bold))
                
                Image(systemName: "arrow.right")
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
        .accessibilityHint("Double tap to start learning")
        .padding(.horizontal, Spacing.xl)
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                category.color.opacity(0.1),
                Color.surfacePrimary,
                category.color.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Animation
    
    private func startAnimation() {
        // Prevent re-triggering if animation already started
        guard animationPhase == .idle else { return }
        
        if reduceMotion {
            // Skip animations for reduced motion
            iconScale = 1.0
            questionScale = 1.0
            showQuestion = true
            animationPhase = .complete
            autoPlayProgress = 1.0
            return
        }
        
        // Phase 1: Icon appears (0.5s)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            animationPhase = .iconAppear
            iconScale = 1.0
        }
        
        // Phase 2: Icon animates (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.5)) {
                animationPhase = .iconAnimate
                backgroundPulse = true
                sparkleOpacity = 1.0
            }
            
            // Icon rotation
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                iconRotation = 360
            }
        }
        
        // Phase 3: Question reveals (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animationPhase = .questionReveal
                showQuestion = true
                questionScale = 1.0
            }
            
            // Play audio narration (only once)
            guard !hasStartedAudio else { return }
            hasStartedAudio = true
            audioService?.speak(content.question)
        }
        
        // Start auto-play progress
        startAutoPlayTimer()
    }
    
    private func startAutoPlayTimer() {
        let updateInterval: TimeInterval = 0.05 // 50ms updates for smooth animation
        let progressIncrement = updateInterval / content.duration
        
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            withAnimation(.linear(duration: updateInterval)) {
                autoPlayProgress += progressIncrement
            }
            
            if autoPlayProgress >= 1.0 {
                timer.invalidate()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animationPhase = .complete
                }
            }
        }
    }
}

// MARK: - Sparkle Particles

/// Floating sparkle particles for visual interest
private struct SparkleParticles: View {
    let color: Color
    
    @State private var particles: [Particle] = []
    
    private struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var rotation: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundStyle(color.opacity(particle.opacity))
                        .scaleEffect(particle.scale)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(
                            x: geometry.size.width * particle.x,
                            y: geometry.size.height * particle.y
                        )
                }
            }
            .onAppear {
                generateParticles()
            }
        }
    }
    
    private func generateParticles() {
        particles = (0..<8).map { _ in
            Particle(
                x: CGFloat.random(in: 0.1...0.9),
                y: CGFloat.random(in: 0.1...0.9),
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: Double.random(in: 0.3...0.8),
                rotation: Double.random(in: 0...360)
            )
        }
        
        // Animate particles
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            particles = particles.map { particle in
                var p = particle
                p.y = CGFloat.random(in: 0.1...0.9)
                p.scale = CGFloat.random(in: 0.5...1.5)
                p.opacity = Double.random(in: 0.3...0.8)
                p.rotation = Double.random(in: 0...360)
                return p
            }
        }
    }
}

// MARK: - Preview

#Preview("Hook Phase - Wudu") {
    HookPhaseView(
        content: HookContent.forCategory(.wudu),
        category: .wudu,
        audioService: nil,
        onComplete: {}
    )
}

#Preview("Hook Phase - Salah") {
    HookPhaseView(
        content: HookContent.forCategory(.salah),
        category: .salah,
        audioService: nil,
        onComplete: {}
    )
}
