//
//  AchievementUnlockView.swift
//  Sidrat
//
//  Full-screen celebration view for unlocking achievements
//

import SwiftUI

struct AchievementUnlockView: View {
    private enum Constants {
        static let autoDismissDelay: TimeInterval = 3.5

        static let badgePopResponse: Double = 0.6
        static let badgePopDamping: Double = 0.6
        static let badgePopScale: CGFloat = 1.2

        static let badgeSettleResponse: Double = 0.3
        static let badgeSettleDamping: Double = 0.8
        static let badgeSettleDelay: TimeInterval = 0.3

        static let confettiDelay: TimeInterval = 0.2

        static let textAppearDelay: TimeInterval = 0.4
        static let textFadeDuration: TimeInterval = 0.35

        static let dismissFadeDuration: TimeInterval = 0.3
        static let dismissDelay: TimeInterval = 0.3
    }

    // MARK: - Properties
    
    let achievement: AchievementType
    let onDismiss: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var showBadge = false
    @State private var showConfetti = false
    @State private var showText = false
    @State private var badgeScale: CGFloat = 0.1
    @State private var glowScale: CGFloat = 0.1
    @State private var glowPulse: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var textOpacity: Double = 0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(colorScheme == .dark ? 0.7 : 0.6)
                .ignoresSafeArea()
                .blur(radius: 10)
            
            // Confetti layer
            if showConfetti && !reduceMotion {
                ConfettiView(particleCount: 35, colors: confettiColors)
                    .ignoresSafeArea()
            }
            
            // Main content
            VStack(spacing: Spacing.lg) {
                Spacer()
                
                // "Achievement Unlocked" header with animated appearance
                if showText {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.brandAccent)
                            .shadow(color: Color.brandAccent.opacity(0.5), radius: 8, x: 0, y: 0)
                        
                        Text("ACHIEVEMENT UNLOCKED")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(colorScheme == .dark ? 0.9 : 0.8))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .opacity(textOpacity)
                }
                
                // Badge with rarity glow
                ZStack {
                    // Outer pulsing glow
                    if !reduceMotion {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        rarityColor.opacity(colorScheme == .dark ? 0.7 : 0.7),
                                        rarityColor.opacity(colorScheme == .dark ? 0.3 : 0.2),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 50,
                                    endRadius: 140
                                )
                            )
                            .frame(width: 280, height: 280)
                            .blur(radius: 25)
                            .scaleEffect(glowScale * glowPulse)
                    }
                    
                    // Inner glow ring for definition
                    Circle()
                        .stroke(
                            RadialGradient(
                                colors: [
                                    rarityColor.opacity(0.8),
                                    rarityColor.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 70,
                                endRadius: 100
                            ),
                            lineWidth: 8
                        )
                        .frame(width: 180, height: 180)
                        .blur(radius: 8)
                        .scaleEffect(glowScale)
                    
                    // Badge container
                    ZStack {
                        // Background circle with better light mode contrast
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: colorScheme == .dark 
                                        ? [Color.surfaceSecondary, Color.surfaceTertiary]
                                        : [.white, Color(hex: "F8F8F8")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.25), radius: 20, x: 0, y: 10)
                            .shadow(color: rarityColor.opacity(0.4), radius: 15, x: 0, y: 5)
                        
                        // Border ring - more visible in dark mode
                        Circle()
                            .stroke(rarityColor.opacity(colorScheme == .dark ? 0.6 : 0.2), lineWidth: 2)
                        
                        // Icon
                        Image(systemName: achievement.icon)
                            .font(.system(size: 60, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [rarityColor, rarityColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: rarityColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .frame(width: 160, height: 160)
                    .scaleEffect(badgeScale)
                    .rotation3DEffect(
                        .degrees(rotationAngle),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.3
                    )
                }
                .frame(width: 280, height: 280) // Fixed frame to prevent layout shift
                
                // Achievement details
                if showText {
                    VStack(spacing: Spacing.md) {
                        // Title - larger and more prominent
                        Text(achievement.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                            .multilineTextAlignment(.center)
                        
                        // Description
                        Text(achievement.description)
                            .font(.body)
                            .foregroundStyle(.white.opacity(colorScheme == .dark ? 0.85 : 0.85))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.md)
                        
                        // Rarity and XP in a single row
                        HStack(spacing: Spacing.md) {
                            // Rarity badge
                            HStack(spacing: Spacing.xs) {
                                Circle()
                                    .fill(rarityColor)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: rarityColor.opacity(0.5), radius: 4, x: 0, y: 0)
                                
                                Text(achievement.rarity.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(colorScheme == .dark ? rarityColor : .white)
                            }
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(colorScheme == .dark ? rarityColor.opacity(0.25) : .white.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(rarityColor.opacity(colorScheme == .dark ? 0.4 : 0), lineWidth: 1)
                                    )
                            )
                            
                            // XP reward
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                Text("+\(achievement.xpReward) XP")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(Color.brandAccent)
                            .shadow(color: Color.brandAccent.opacity(0.3), radius: 4, x: 0, y: 0)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(Color.brandAccent.opacity(colorScheme == .dark ? 0.25 : 0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.brandAccent.opacity(colorScheme == .dark ? 0.4 : 0), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.top, Spacing.xs)
                    }
                    .opacity(textOpacity)
                    .padding(.horizontal, Spacing.xl)
                }
                
                Spacer()
                
                // Tap to dismiss hint
                if showText {
                    Text("Tap anywhere to continue")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .opacity(textOpacity * 0.8)
                        .padding(.bottom, Spacing.xl)
                }
            }
        }
        .onAppear {
            startCelebration()
            
            // Auto-dismiss after 4 seconds if user doesn't interact
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.autoDismissDelay) {
                if showText {
                    dismissWithAnimation()
                }
            }
        }
        .onTapGesture {
            // Allow tap anywhere to dismiss after animation completes
            if showText {
                dismissWithAnimation()
            }
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Achievement Unlocked: \(achievement.title). \(achievement.description). \(achievement.rarity.title) rarity, plus \(achievement.xpReward) XP")
        .accessibilityHint("Tap anywhere to dismiss")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Computed Properties
    
    private var rarityColor: Color {
        Color(hex: achievement.rarity.color)
    }
    
    private var confettiColors: [Color] {
        [.brandPrimary, .brandAccent, .brandSecondary, rarityColor]
    }
    
    // MARK: - Animations
    
    private func startCelebration() {
        // Prepare haptic generators
        let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
        let impactMedium = UIImpactFeedbackGenerator(style: .medium)
        let notificationGenerator = UINotificationFeedbackGenerator()
        impactHeavy.prepare()
        impactMedium.prepare()
        notificationGenerator.prepare()
        
        // Play achievement sound effect with haptic
        SoundEffectsService.shared.play(.achievementUnlocked, haptic: .heavy)
        
        // Initial heavy haptic for badge appearance
        impactHeavy.impactOccurred()
        
        if reduceMotion {
            // Simplified animation for reduce motion
            showBadge = true
            showText = true
            badgeScale = 1.0
            glowScale = 1.0
            glowPulse = 1.0
            rotationAngle = 0
            textOpacity = 1.0
            showConfetti = false
            notificationGenerator.notificationOccurred(.success)
        } else {
            // Full animation sequence
            // 1. Show badge with spring animation (pop in)
            withAnimation(.spring(response: Constants.badgePopResponse, dampingFraction: Constants.badgePopDamping, blendDuration: 0)) {
                showBadge = true
                badgeScale = Constants.badgePopScale
                glowScale = Constants.badgePopScale * 0.9
            }
            
            // 2. Start rotation animation (separate for smoother motion)
            withAnimation(.easeInOut(duration: 0.8)) {
                rotationAngle = 360
            }
            
            // 3. Settle badge to final size with medium haptic
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.badgeSettleDelay) {
                impactMedium.impactOccurred()
            }
            withAnimation(.spring(response: Constants.badgeSettleResponse, dampingFraction: Constants.badgeSettleDamping).delay(Constants.badgeSettleDelay)) {
                badgeScale = 1.0
                glowScale = 1.0
            }
            
            // 4. Show confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.confettiDelay) {
                showConfetti = true
            }
            
            // 5. Show text with success haptic
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.textAppearDelay) {
                notificationGenerator.notificationOccurred(.success)
                withAnimation(.easeOut(duration: Constants.textFadeDuration)) {
                    showText = true
                    textOpacity = 1.0
                }
            }
            
            // 6. Start subtle glow pulsing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                startGlowPulse()
            }
        }
    }
    
    private func startGlowPulse() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPulse = 1.1
        }
    }
    
    private func dismissWithAnimation() {
        // Light haptic on dismiss
        let impactLight = UIImpactFeedbackGenerator(style: .light)
        impactLight.impactOccurred()
        
        if reduceMotion {
            onDismiss()
        } else {
            withAnimation(.easeOut(duration: Constants.dismissFadeDuration)) {
                textOpacity = 0
                badgeScale = 0.8
                glowScale = 0.6
                glowPulse = 1.0 // Stop pulsing
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.dismissDelay) {
                onDismiss()
            }
        }
    }
}



// MARK: - Preview

#Preview("Achievement Unlock") {
    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()
        
        AchievementUnlockView(
            achievement: .firstLesson,
            onDismiss: {
                print("Dismissed")
            }
        )
    }
}

#Preview("Platinum Achievement") {
    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()
        
        AchievementUnlockView(
            achievement: .allCategoriesMaster,
            onDismiss: {
                print("Dismissed")
            }
        )
    }
}
