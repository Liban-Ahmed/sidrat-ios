//
//  StatsOverviewCard.swift
//  Sidrat
//
//  Progress Garden - Stats displayed as organic, living elements
//  Design: Soft & Organic with Garden of Growth metaphor
//

import SwiftUI

struct StatsOverviewCard: View {
    let totalXP: Int
    let currentStreak: Int
    let totalLessons: Int
    let weeklyCompleted: Int
    let weeklyGoal: Int
    
    @State private var streakAnimation = false
    @State private var xpSparkle = false
    @State private var lessonBloom = false
    @State private var floatOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Atmospheric background - subtle gradient garden
            atmosphericBackground
            
            // Organic flowing layout with aligned elements
            VStack(spacing: Spacing.lg) {
                // Top row: XP Stars (dominant) + Streak Flame (accent)
                HStack(alignment: .center, spacing: Spacing.lg) {
                    // XP - Primary focus, larger and more prominent
                    xpStarElement
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Streak - Compact but eye-catching
                    streakFlameElement
                }
                
                // Bottom row: Balanced layout
                HStack(alignment: .center, spacing: Spacing.lg) {
                    // Lessons - Medium size, blooming flower
                    lessonsBloomElement
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Weekly Goal - Flowing progress path
                    weeklyGoalElement
                }
            }
            .padding(Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color.backgroundPrimary)
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
        )
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Atmospheric Background
    
    private var atmosphericBackground: some View {
        RoundedRectangle(cornerRadius: CornerRadius.large)
            .fill(
                LinearGradient(
                    colors: [
                        Color.brandPrimary.opacity(0.03),
                        Color.brandSecondary.opacity(0.05),
                        Color.brandAccent.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Subtle Islamic geometric pattern hint
                Circle()
                    .fill(Color.brandAccent.opacity(0.02))
                    .blur(radius: 40)
                    .offset(x: 100, y: -50)
            )
    }
    
    // MARK: - XP Star Element (Primary Focus)
    
    private var xpStarElement: some View {
        HStack(alignment: .center, spacing: 0) {
            // Fixed icon column
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.brandAccent.opacity(0.2),
                                Color.brandAccent.opacity(0)
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .blur(radius: 8)
                    .opacity(xpSparkle ? 1 : 0.5)
                
                // Star icon with sparkle
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.brandAccent, Color.brandAccent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(xpSparkle ? 1.1 : 1.0)
                    .rotationEffect(.degrees(xpSparkle ? 5 : -5))
            }
            .frame(width: 60, height: 60)
            .offset(y: floatOffset)
            
            Spacer()
                .frame(width: Spacing.md)
            
            // Value and Label
            VStack(alignment: .leading, spacing: 2) {
                // Value - Extra large for emphasis
                Text("\(totalXP)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.textPrimary, Color.textPrimary.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Label with decorative element
                HStack(spacing: 4) {
                    Text("Experience")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.textSecondary)
                        .lineLimit(1)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.brandAccent.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total experience points: \(totalXP)")
    }
    
    // MARK: - Streak Flame Element (Accent)
    
    private var streakFlameElement: some View {
        HStack(alignment: .center, spacing: 0) {
            // Fixed icon column
            ZStack {
                // Flame glow
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.error.opacity(0.3),
                                Color.orange.opacity(0.2)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 50, height: 70)
                    .blur(radius: 12)
                    .offset(y: streakAnimation ? -2 : 2)
                
                // Flame icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.error],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(x: streakAnimation ? 0.95 : 1.05, y: streakAnimation ? 1.1 : 0.9)
            }
            .frame(width: 60, height: 60)
            .offset(y: floatOffset * 0.7)
            
            Spacer()
                .frame(width: Spacing.md)
            
            // Value and Label
            VStack(alignment: .leading, spacing: 2) {
                // Value
                Text("\(currentStreak)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Label
                Text("Day Streak")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current streak: \(currentStreak) days")
    }
    
    // MARK: - Lessons Bloom Element
    
    private var lessonsBloomElement: some View {
        HStack(alignment: .center, spacing: 0) {
            // Fixed icon column
            ZStack {
                // Petals glow
                ForEach(0..<6) { index in
                    Circle()
                        .fill(Color.brandSecondary.opacity(0.15))
                        .frame(width: 12, height: 12)
                        .offset(
                            x: cos(Double(index) * .pi / 3) * 20,
                            y: sin(Double(index) * .pi / 3) * 20
                        )
                        .scaleEffect(lessonBloom ? 1.0 : 0.5)
                        .opacity(lessonBloom ? 1 : 0.3)
                }
                
                // Center
                Image(systemName: "book.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.brandSecondary, Color.brandSecondary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(lessonBloom ? 0 : -10))
            }
            .frame(width: 60, height: 60)
            .offset(y: floatOffset * 0.5)
            
            Spacer()
                .frame(width: Spacing.md)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(totalLessons)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Lessons Complete")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total lessons completed: \(totalLessons)")
    }
    
    // MARK: - Weekly Goal Element (Flowing Path)
    
    private var weeklyGoalElement: some View {
        HStack(alignment: .center, spacing: 0) {
            // Fixed icon column
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.brandPrimary.opacity(0.15), lineWidth: 4)
                    .frame(width: 52, height: 52)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: min(1.0, Double(weeklyCompleted) / Double(max(weeklyGoal, 1))))
                    .stroke(
                        LinearGradient(
                            colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                
                // Icon
                Image(systemName: "target")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
            }
            .frame(width: 60, height: 60)
            .offset(y: floatOffset * 0.3)
            
            Spacer()
                .frame(width: Spacing.md)
            
            // Value and Label
            VStack(alignment: .leading, spacing: 2) {
                // Progress text
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(weeklyCompleted)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Text("/\(weeklyGoal)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Label
                Text("This Week")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly goal: \(weeklyCompleted) of \(weeklyGoal) lessons")
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // Gentle floating animation
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            floatOffset = -4
        }
        
        // XP sparkle
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.2)) {
            xpSparkle = true
        }
        
        // Streak flame dance
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
            streakAnimation = true
        }
        
        // Lesson bloom pulse
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).repeatForever(autoreverses: true).delay(0.8)) {
            lessonBloom = true
        }
    }
}



// MARK: - Preview

#Preview("Progress Garden") {
    VStack(spacing: Spacing.lg) {
        // Default state
        StatsOverviewCard(
            totalXP: 125,
            currentStreak: 7,
            totalLessons: 12,
            weeklyCompleted: 3,
            weeklyGoal: 5
        )
        
        // High achiever state
        StatsOverviewCard(
            totalXP: 5840,
            currentStreak: 45,
            totalLessons: 58,
            weeklyCompleted: 5,
            weeklyGoal: 5
        )
        
        // Beginner state
        StatsOverviewCard(
            totalXP: 1500,
            currentStreak: 1,
            totalLessons: 1,
            weeklyCompleted: 1,
            weeklyGoal: 5
        )
    }
    .padding()
    .background(Color.backgroundSecondary)
}

