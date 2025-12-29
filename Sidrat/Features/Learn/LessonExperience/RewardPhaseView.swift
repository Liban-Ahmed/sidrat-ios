//
//  RewardPhaseView.swift
//  Sidrat
//
//  The Reward phase view - Celebration with XP, stars, and share prompt
//  Features achievement animation, XP/stars display, "Share with family"
//

import SwiftUI

// MARK: - Reward Phase View

/// Celebration phase showing achievements, XP earned, and share prompt
struct RewardPhaseView: View {
    let lesson: Lesson
    let score: Int
    let correctCount: Int
    let totalCount: Int
    let xpEarned: Int
    let onShare: () -> Void
    let onContinue: () -> Void
    
    @Environment(\.isReduceMotionEnabled) private var reduceMotion
    @State private var showContent = false
    @State private var showStars = false
    @State private var showXP = false
    @State private var showShareButton = false
    @State private var currentXPDisplay: Int = 0
    @State private var starScale: [CGFloat] = [0, 0, 0]
    @State private var confettiCounter: Int = 0
    
    private var starsEarned: Int {
        if score >= 80 { return 3 }
        if score >= 60 { return 2 }
        return 1
    }
    
    private var celebrationMessage: String {
        if score >= 80 {
            return "Amazing Job! 🌟"
        } else if score >= 60 {
            return "Great Work! 💪"
        } else {
            return "Good Effort! 📚"
        }
    }
    
    private var encouragementMessage: String {
        if score >= 80 {
            return "You're a star learner! MashaAllah!"
        } else if score >= 60 {
            return "Keep it up! You're doing great!"
        } else {
            return "Practice makes perfect! Keep learning!"
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            // Confetti (only when not reduce motion and high score)
            if !reduceMotion && score >= 60 {
                RewardConfettiView(counter: confettiCounter)
            }
            
            // Main content
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    Spacer(minLength: Spacing.xxl)
                    
                    // Celebration header
                    celebrationHeader
                    
                    // Stars display
                    starsDisplay
                    
                    // Score card
                    scoreCard
                    
                    // XP earned animation
                    xpDisplay
                    
                    Spacer(minLength: Spacing.lg)
                    
                    // Action buttons
                    actionButtons
                    
                    Spacer(minLength: Spacing.xl)
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                lesson.category.color.opacity(0.2),
                Color.surfacePrimary,
                Color.brandAccent.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Celebration Header
    
    private var celebrationHeader: some View {
        VStack(spacing: Spacing.md) {
            // Trophy icon
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.brandAccent)
                    .symbolEffect(.bounce, options: .speed(0.5))
            }
            .scaleEffect(showContent ? 1.0 : 0.5)
            .opacity(showContent ? 1.0 : 0)
            
            // Celebration text
            VStack(spacing: Spacing.xs) {
                Text(celebrationMessage)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(encouragementMessage)
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1.0 : 0)
            .offset(y: showContent ? 0 : 20)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(celebrationMessage). \(encouragementMessage)")
    }
    
    // MARK: - Stars Display
    
    private var starsDisplay: some View {
        HStack(spacing: Spacing.md) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < starsEarned ? "star.fill" : "star")
                    .font(.system(size: 44))
                    .foregroundStyle(index < starsEarned ? Color.brandAccent : Color.surfaceTertiary)
                    .scaleEffect(starScale[index])
                    .rotationEffect(.degrees(starScale[index] > 0 ? 0 : -30))
            }
        }
        .accessibilityLabel("\(starsEarned) out of 3 stars earned")
    }
    
    // MARK: - Score Card
    
    private var scoreCard: some View {
        VStack(spacing: Spacing.md) {
            // Lesson title
            HStack(spacing: Spacing.sm) {
                Image(systemName: lesson.category.iconName)
                    .font(.headline)
                    .foregroundStyle(lesson.category.color)
                
                Text(lesson.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.textPrimary)
            }
            
            Divider()
            
            // Score details
            HStack(spacing: Spacing.xl) {
                // Correct answers
                VStack(spacing: Spacing.xxs) {
                    Text("\(correctCount)/\(totalCount)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.textPrimary)
                    
                    Text("Correct")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
                
                // Score percentage
                VStack(spacing: Spacing.xxs) {
                    Text("\(score)%")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(scoreColor)
                    
                    Text("Score")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
                
                // Time taken (placeholder)
                VStack(spacing: Spacing.xxs) {
                    Text("~5min")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.textPrimary)
                    
                    Text("Time")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.extraLarge)
                .fill(Color.surfaceSecondary)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
        .opacity(showContent ? 1.0 : 0)
        .offset(y: showContent ? 0 : 20)
    }
    
    private var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 60 { return .brandAccent }
        return .orange
    }
    
    // MARK: - XP Display
    
    private var xpDisplay: some View {
        HStack(spacing: Spacing.md) {
            // XP icon
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.brandPrimary)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("XP Earned")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                
                Text("+\(currentXPDisplay)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.brandPrimary)
                    .contentTransition(.numericText())
            }
            
            Spacer()
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color.brandPrimary.opacity(0.1))
        )
        .opacity(showXP ? 1.0 : 0)
        .scaleEffect(showXP ? 1.0 : 0.9)
        .accessibilityLabel("\(xpEarned) XP earned")
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: Spacing.md) {
            // Share with family button
            Button(action: onShare) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "person.2.fill")
                        .font(.headline)
                    
                    Text("Share with Family")
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(lesson.category.color)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(lesson.category.color.opacity(0.15))
                )
            }
            .buttonStyle(.plain)
            .opacity(showShareButton ? 1.0 : 0)
            .offset(y: showShareButton ? 0 : 10)
            .accessibilityHint("Double tap to share your achievement with family members")
            
            // Continue button
            Button(action: onContinue) {
                HStack(spacing: Spacing.sm) {
                    Text("Continue Learning")
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
                                colors: [lesson.category.color, lesson.category.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: lesson.category.color.opacity(0.3), radius: 10, y: 5)
                )
            }
            .buttonStyle(.plain)
            .opacity(showShareButton ? 1.0 : 0)
            .offset(y: showShareButton ? 0 : 10)
            .accessibilityHint("Double tap to return to your lessons")
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        if reduceMotion {
            // Instant display for reduced motion
            showContent = true
            showStars = true
            showXP = true
            showShareButton = true
            currentXPDisplay = xpEarned
            starScale = [1, 1, 1]
            return
        }
        
        // Trigger confetti
        confettiCounter += 1
        
        // Content appears
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showContent = true
        }
        
        // Stars appear one by one
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 + Double(i) * 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    if i < starsEarned {
                        starScale[i] = 1.2
                        
                        // Bounce back
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                starScale[i] = 1.0
                            }
                        }
                        
                        // Haptic for each star
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } else {
                        starScale[i] = 1.0
                    }
                }
            }
        }
        
        // XP counter animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showXP = true
            }
            
            // Animate XP counting
            animateXPCounter()
        }
        
        // Share button appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showShareButton = true
            }
        }
    }
    
    private func animateXPCounter() {
        let duration: Double = 1.0
        let steps = 20
        let stepDuration = duration / Double(steps)
        let xpPerStep = xpEarned / steps
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.linear(duration: stepDuration)) {
                    currentXPDisplay = min(xpPerStep * i, xpEarned)
                }
            }
        }
    }
}

// MARK: - Reward Confetti View

struct RewardConfettiView: View {
    let counter: Int
    
    @State private var particles: [RewardConfettiParticle] = []
    @State private var isAnimating = false
    
    private let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink,
        .brandPrimary, .brandSecondary, .brandAccent
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    RewardConfettiPiece(
                        particle: particle,
                        color: colors[particle.colorIndex % colors.count]
                    )
                    .position(
                        x: isAnimating ? particle.endX * geometry.size.width : particle.startX * geometry.size.width,
                        y: isAnimating ? particle.endY * geometry.size.height : -20
                    )
                    .opacity(isAnimating ? 0 : 1)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: counter) { _, _ in
            spawnConfetti()
        }
    }
    
    private func spawnConfetti() {
        particles = (0..<50).map { _ in
            RewardConfettiParticle(
                startX: CGFloat.random(in: 0.2...0.8),
                endX: CGFloat.random(in: -0.2...1.2),
                endY: CGFloat.random(in: 1.0...1.3),
                colorIndex: Int.random(in: 0..<colors.count),
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.5)
            )
        }
        
        isAnimating = false
        
        withAnimation(.easeIn(duration: 3.0)) {
            isAnimating = true
        }
    }
}

private struct RewardConfettiParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let colorIndex: Int
    let rotation: Double
    let scale: CGFloat
}

private struct RewardConfettiPiece: View {
    let particle: RewardConfettiParticle
    let color: Color
    
    @State private var rotation: Double = 0
    
    var body: some View {
        Group {
            if Int.random(in: 0...2) == 0 {
                Circle()
                    .fill(color)
                    .frame(width: 8 * particle.scale, height: 8 * particle.scale)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 10 * particle.scale, height: 6 * particle.scale)
            }
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                rotation = particle.rotation + 360
            }
        }
    }
}

// MARK: - Preview

#Preview("Reward Phase - High Score") {
    RewardPhaseView(
        lesson: Lesson(
            id: "test",
            title: "Introduction to Wudu",
            description: "Learn about wudu",
            category: .wudu,
            difficulty: .beginner,
            durationMinutes: 5,
            xpReward: 50,
            order: 1,
            weekNumber: 1
        ),
        score: 100,
        correctCount: 3,
        totalCount: 3,
        xpEarned: 50,
        onShare: {},
        onContinue: {}
    )
}

#Preview("Reward Phase - Medium Score") {
    RewardPhaseView(
        lesson: Lesson(
            id: "test",
            title: "Introduction to Salah",
            description: "Learn about prayer",
            category: .salah,
            difficulty: .beginner,
            durationMinutes: 5,
            xpReward: 50,
            order: 1,
            weekNumber: 1
        ),
        score: 66,
        correctCount: 2,
        totalCount: 3,
        xpEarned: 35,
        onShare: {},
        onContinue: {}
    )
}
