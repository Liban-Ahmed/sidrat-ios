//
//  LessonCompletionView.swift
//  Sidrat
//
//  Celebratory view shown after completing a lesson
//

import SwiftUI

struct LessonCompletionView: View {
    let lesson: Lesson
    let score: Int
    let totalQuestions: Int
    let onDismiss: () -> Void
    
    @State private var showConfetti = false
    @State private var animateStars = false
    @State private var showContent = false
    @State private var showShareSheet = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.brandPrimary.opacity(0.1), Color.brandSecondary.opacity(0.05)],
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
                
                // Star animation
                ZStack {
                    // Outer glow
                    ForEach(0..<8) { index in
                        Circle()
                            .fill(Color.brandAccent.opacity(0.3))
                            .frame(width: 20, height: 20)
                            .offset(y: animateStars ? -80 : 0)
                            .rotationEffect(.degrees(Double(index) * 45 + (animateStars ? 360 : 0)))
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                                value: animateStars
                            )
                    }
                    
                    // Main star
                    Image(systemName: "star.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.brandAccent, Color.brandAccentLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.brandAccent.opacity(0.5), radius: 20, y: 10)
                        .scaleEffect(animateStars ? 1.1 : 0.9)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                            value: animateStars
                        )
                }
                .scaleEffect(showContent ? 1 : 0.3)
                .opacity(showContent ? 1 : 0)
                
                // Congratulations text
                VStack(spacing: Spacing.sm) {
                    Text("Amazing Job!")
                        .font(.displayMedium)
                        .foregroundStyle(.textPrimary)
                    
                    Text("You completed \(lesson.title)!")
                        .font(.bodyLarge)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                // Rewards
                HStack(spacing: Spacing.xl) {
                    RewardItem(
                        icon: "star.fill",
                        value: "+\(lesson.xpReward)",
                        label: "XP Earned",
                        color: .brandAccent
                    )
                    
                    RewardItem(
                        icon: "checkmark.circle.fill",
                        value: "\(score)/\(totalQuestions * 10)",
                        label: "Quiz Score",
                        color: .brandSecondary
                    )
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                
                Spacer()
                
                // Share with family button
                Button {
                    showShareSheet = true
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "person.2.fill")
                        Text("Share with Family")
                    }
                    .font(.labelMedium)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.brandPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                .padding(.horizontal, Spacing.lg)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 35)
                
                // Continue button
                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Text("Continue Learning")
                        Image(systemName: "arrow.right")
                    }
                    .font(.labelLarge)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md + 2)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal, Spacing.lg)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 40)
            }
            .padding()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(items: ["I just learned about \(lesson.title) on Sidrat! 🌟🎉"])
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
                animateStars = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Share Sheet View

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Reward Item

struct RewardItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)
            }
            
            Text(value)
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.textTertiary)
        }
    }
}



#Preview {
    LessonCompletionView(
        lesson: .sampleWuduLesson,
        score: 20,
        totalQuestions: 2,
        onDismiss: {}
    )
}
