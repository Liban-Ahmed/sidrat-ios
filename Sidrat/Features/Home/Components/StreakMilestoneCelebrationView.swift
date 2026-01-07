//
//  StreakMilestoneCelebrationView.swift
//  Sidrat
//
//  Full-screen celebration overlay for streak milestones
//  US-303 Phase 5
//

import SwiftUI

/// Celebration view shown when a streak milestone is achieved
/// Shows confetti, milestone-specific message, badge, and XP earned
struct StreakMilestoneCelebrationView: View {
    // MARK: - Properties
    
    let milestone: StreakMilestone
    let onDismiss: () -> Void
    
    // MARK: - State
    
    @State private var showConfetti = false
    @State private var animateFlame = false
    @State private var showContent = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.brandAccent.opacity(0.15),
                    Color.brandPrimary.opacity(0.1),
                    Color.brandSecondary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Confetti particles
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Animated flame icon
                ZStack {
                    // Glow circles
                    ForEach(0..<6) { index in
                        Circle()
                            .fill(Color.brandAccent.opacity(0.2))
                            .frame(width: 30, height: 30)
                            .offset(y: animateFlame ? -100 : 0)
                            .rotationEffect(.degrees(Double(index) * 60 + (animateFlame ? 360 : 0)))
                            .animation(
                                .easeInOut(duration: 1.8)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                                value: animateFlame
                            )
                    }
                    
                    // Main flame
                    Image(systemName: "flame.fill")
                        .font(.system(size: 120))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.brandAccent, Color.orange, Color.red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.brandAccent.opacity(0.6), radius: 30, y: 15)
                        .scaleEffect(animateFlame ? 1.15 : 0.95)
                        .animation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                            value: animateFlame
                        )
                }
                .scaleEffect(showContent ? 1 : 0.3)
                .opacity(showContent ? 1 : 0)
                
                // Milestone message
                VStack(spacing: Spacing.sm) {
                    Text(milestoneTitle)
                        .font(.displayMedium)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("You've learned for \(milestone.days) days in a row!")
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Spacing.xl)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                // Achievement badge reveal
                VStack(spacing: Spacing.md) {
                    // Badge icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.brandAccent.opacity(0.2), Color.brandPrimary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: milestone.achievementType.icon)
                            .font(.system(size: 48))
                            .foregroundStyle(Color.brandAccent)
                    }
                    .scaleEffect(showContent ? 1 : 0.5)
                    .rotationEffect(.degrees(showContent ? 0 : -180))
                    
                    // Badge title
                    Text(milestone.achievementType.title)
                        .font(.labelLarge)
                        .foregroundStyle(Color.textPrimary)
                    
                    // XP earned
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text("+\(milestone.xpReward) XP")
                            .font(.labelMedium)
                    }
                    .foregroundStyle(Color.brandAccent)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(Color.brandAccent.opacity(0.15))
                    )
                }
                .padding(.vertical, Spacing.lg)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                
                Spacer()
                
                // Continue button
                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Text("Keep Going!")
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .font(.labelLarge)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md + 2)
                    .background(
                        LinearGradient(
                            colors: [Color.brandAccent, Color.brandPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    .shadow(color: Color.brandAccent.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 40)
            }
        }
        .onAppear {
            // Staggered animations for smooth entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
                animateFlame = true
            }
            
            // Delayed confetti for impact
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Streak milestone achieved! \(milestone.days) days. \(milestone.achievementType.title). Plus \(milestone.xpReward) XP earned.")
    }
    
    // MARK: - Helper Properties
    
    /// Returns the milestone-specific celebratory title
    private var milestoneTitle: String {
        switch milestone.days {
        case 3:
            return "Amazing!"
        case 7:
            return "Incredible!"
        case 30:
            return "Outstanding!"
        case 100:
            return "Legendary!"
        default:
            return "Great Job!"
        }
    }
}

// MARK: - Preview

#Preview("3 Days") {
    StreakMilestoneCelebrationView(
        milestone: StreakMilestone(
            days: 3,
            achievementType: .streak3,
            xpReward: 30
        ),
        onDismiss: {
            print("Dismissed")
        }
    )
}

#Preview("7 Days") {
    StreakMilestoneCelebrationView(
        milestone: StreakMilestone(
            days: 7,
            achievementType: .streak7,
            xpReward: 100
        ),
        onDismiss: {
            print("Dismissed")
        }
    )
}

#Preview("30 Days") {
    StreakMilestoneCelebrationView(
        milestone: StreakMilestone(
            days: 30,
            achievementType: .streak30,
            xpReward: 500
        ),
        onDismiss: {
            print("Dismissed")
        }
    )
}

#Preview("100 Days") {
    StreakMilestoneCelebrationView(
        milestone: StreakMilestone(
            days: 100,
            achievementType: .streak100,
            xpReward: 2000
        ),
        onDismiss: {
            print("Dismissed")
        }
    )
}
