//
//  CelebrationOverlay.swift
//  Sidrat
//
//  Full-screen celebration when new achievement unlocked
//

import SwiftUI

struct CelebrationOverlay: View {
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var pulseAnimation = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissOverlay()
                }
            
            // Content card
            VStack(spacing: Spacing.lg) {
                // Achievement icon
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color.brandAccent.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.8)
                    
                    // Main icon
                    Image(systemName: "star.circle.fill")
                        .font(.celebrationIcon)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.brandAccent, .brandAccentLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showContent ? 1.0 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)
                }
                
                // Text
                VStack(spacing: Spacing.xs) {
                    Text("New Achievement!")
                        .font(.title2)
                        .foregroundStyle(.textPrimary)
                    
                    Text("Your tree is growing! 🌳")
                        .font(.bodyMedium)
                        .foregroundStyle(.textSecondary)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                // Continue button
                PrimaryButton("Continue", icon: "arrow.right") {
                    dismissOverlay()
                }
                .opacity(showContent ? 1 : 0)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: 320)
            .background(Color.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .cardShadow()
            .padding(Spacing.xl)
            
            // Confetti overlay (doesn't block touches)
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        if reduceMotion {
            // Skip animations for reduced motion
            showContent = true
            showConfetti = true
            return
        }
        
        // Stagger animations
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showContent = true
        }
        
        // Start pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseAnimation = true
        }
        
        // Show confetti after slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showConfetti = true
            }
        }
    }
    
    private func dismissOverlay() {
        withAnimation(.easeOut(duration: 0.25)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.backgroundSecondary.ignoresSafeArea()
        
        CelebrationOverlay { }
    }
}
