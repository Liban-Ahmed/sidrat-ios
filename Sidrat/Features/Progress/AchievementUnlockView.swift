//
//  AchievementUnlockView.swift
//  Sidrat
//
//  Full-screen celebration view for unlocking achievements
//

import SwiftUI

struct AchievementUnlockView: View {
    // MARK: - Properties
    
    let achievement: AchievementType
    let onDismiss: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showBadge = false
    @State private var showConfetti = false
    @State private var showText = false
    @State private var badgeScale: CGFloat = 0.1
    @State private var textOpacity: Double = 0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .blur(radius: 20)
            
            // Confetti layer
            if showConfetti && !reduceMotion {
                ConfettiView(particleCount: 35, colors: confettiColors)
                    .ignoresSafeArea()
            }
            
            // Main content
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Congratulations text
                if showText {
                    Text("Congratulations!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                        .opacity(textOpacity)
                }
                
                // Badge with rarity glow
                ZStack {
                    // Rarity glow effect
                    if !reduceMotion {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        rarityColor.opacity(0.6),
                                        rarityColor.opacity(0.2),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 40,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 240, height: 240)
                            .blur(radius: 20)
                    }
                    
                    // Badge container
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(Color.surfaceSecondary)
                            .shadow(color: rarityColor.opacity(0.3), radius: 20, x: 0, y: 10)
                        
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
                    }
                    .frame(width: 160, height: 160)
                    .scaleEffect(badgeScale)
                    .rotation3DEffect(
                        .degrees(showBadge && !reduceMotion ? 360 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                }
                
                // Achievement details
                if showText {
                    VStack(spacing: Spacing.sm) {
                        // Title
                        Text(achievement.title)
                            .font(.title2.bold())
                            .foregroundStyle(Color.textPrimary)
                        
                        // Description
                        Text(achievement.description)
                            .font(.body)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        // Rarity badge
                        HStack(spacing: Spacing.xs) {
                            Circle()
                                .fill(rarityColor)
                                .frame(width: 8, height: 8)
                            
                            Text(achievement.rarity.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(rarityColor)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            Capsule()
                                .fill(rarityColor.opacity(0.15))
                        )
                        .padding(.top, Spacing.sm)
                        
                        // XP reward
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text("+\(achievement.xpReward) XP")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Color.brandAccent)
                        .padding(.top, Spacing.xs)
                    }
                    .opacity(textOpacity)
                    .padding(.horizontal, Spacing.xl)
                }
                
                Spacer()
                
                // Dismiss button
                if showText {
                    Button(action: {
                        dismissWithAnimation()
                    }) {
                        Text("Continue")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .opacity(textOpacity)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xl)
                }
            }
        }
        .onAppear {
            startCelebration()
            
            // Auto-dismiss after 4 seconds if user doesn't interact
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
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
        .accessibilityLabel("Achievement Unlocked: \(achievement.title)")
        .accessibilityHint("Double tap to continue")
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
        // Play achievement sound effect
        SoundEffectsService.shared.play(.achievementUnlocked, haptic: .heavy)
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        if reduceMotion {
            // Simplified animation for reduce motion
            showBadge = true
            showText = true
            badgeScale = 1.0
            textOpacity = 1.0
            showConfetti = false
        } else {
            // Full animation sequence
            // 1. Show badge with spring animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)) {
                showBadge = true
                badgeScale = 1.2
            }
            
            // 2. Settle badge to final size
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.3)) {
                badgeScale = 1.0
            }
            
            // 3. Show confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showConfetti = true
            }
            
            // 4. Show text
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showText = true
                    textOpacity = 1.0
                }
            }
        }
    }
    
    private func dismissWithAnimation() {
        if reduceMotion {
            onDismiss()
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                textOpacity = 0
                badgeScale = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
            achievement: .streak7,
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
