//
//  StatsOverviewCard.swift
//  Sidrat
//
//  Stats overview card showing XP, streak, and lessons completed
//

import SwiftUI

struct StatsOverviewCard: View {
    let totalXP: Int
    let currentStreak: Int
    let totalLessons: Int
    let weeklyCompleted: Int
    let weeklyGoal: Int
    
    @State private var streakPulse = false
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Main stats row
            HStack(spacing: Spacing.md) {
                StatBox(
                    value: "\(totalXP)",
                    label: "Total XP",
                    icon: "star.fill",
                    color: .brandAccent
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total experience points: \(totalXP)")
                
                StatBox(
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    icon: "flame.fill",
                    color: .error
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current streak: \(currentStreak) days")
                .modifier(PulseModifier(isActive: currentStreak > 3, pulse: streakPulse))
                
                StatBox(
                    value: "\(totalLessons)",
                    label: "Lessons",
                    icon: "book.fill",
                    color: .brandSecondary
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total lessons completed: \(totalLessons)")
            }
            
            // Weekly progress bar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Weekly Goal")
                        .font(.labelMedium)
                        .foregroundStyle(.textPrimary)
                    
                    Spacer()
                    
                    Text("\(weeklyCompleted)/\(weeklyGoal) lessons")
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.backgroundTertiary)
                            .frame(height: 8)
                        
                        let progress = min(1.0, Double(weeklyCompleted) / Double(weeklyGoal))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient.primaryGradient)
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.spring(response: 0.4), value: weeklyCompleted)
                    }
                }
                .frame(height: 8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Weekly progress")
                .accessibilityValue("\(weeklyCompleted) of \(weeklyGoal) lessons completed")
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
        .onAppear {
            if currentStreak > 3 {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    streakPulse = true
                }
            }
        }
    }
}

// MARK: - Supporting View

private struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .foregroundStyle(.textPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Pulse Modifier

private struct PulseModifier: ViewModifier {
    let isActive: Bool
    let pulse: Bool
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        if isActive && !reduceMotion {
            content
                .scaleEffect(pulse ? 1.05 : 1.0)
                .shadow(
                    color: .error.opacity(pulse ? 0.4 : 0.2),
                    radius: pulse ? 12 : 8,
                    x: 0,
                    y: 0
                )
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        StatsOverviewCard(
            totalXP: 1250,
            currentStreak: 7,
            totalLessons: 12,
            weeklyCompleted: 3,
            weeklyGoal: 5
        )
        
        StatsOverviewCard(
            totalXP: 450,
            currentStreak: 2,
            totalLessons: 5,
            weeklyCompleted: 5,
            weeklyGoal: 5
        )
    }
    .padding()
    .background(Color.backgroundSecondary)
}
