//
//  TodayLessonCard.swift
//  Sidrat
//
//  Today's lesson card component with completion states
//  Extracted from HomeView.swift for maintainability
//

import SwiftUI
import SwiftData

// MARK: - Today's Lesson Card

/// Premium lesson card component that shows today's lesson
/// Features: Thumbnail, title, category icon, duration, animated bounce, completion state
struct TodayLessonCard: View {
    let lesson: Lesson?
    let isCompleted: Bool
    let onStartLesson: (Lesson) -> Void
    
    // Animation state for attention-grabbing bounce
    @State private var isAnimating = false
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Text("Today's Lesson")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
                
                Spacer()
                
                if let lesson = lesson {
                    Text("Week \(lesson.weekNumber)")
                        .font(.labelSmall)
                        .foregroundStyle(.brandPrimary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.brandPrimary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            if let lesson = lesson {
                if isCompleted {
                    // Completed state - "Great job!"
                    CompletedLessonContent(lesson: lesson)
                } else {
                    // Active lesson card with animation
                    ActiveLessonContent(
                        lesson: lesson,
                        isAnimating: isAnimating,
                        onStartLesson: onStartLesson
                    )
                }
            } else {
                // No lessons available - all completed
                AllLessonsCompletedContent()
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
        .onAppear {
            // Start bounce animation after a short delay
            guard !hasAppeared, !isCompleted else { return }
            hasAppeared = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    isAnimating = true
                }
                
                // Reset after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isAnimating = false
                    }
                }
            }
        }
    }
}

// MARK: - Active Lesson Content

/// Content shown when today's lesson is not yet completed
private struct ActiveLessonContent: View {
    let lesson: Lesson
    let isAnimating: Bool
    let onStartLesson: (Lesson) -> Void
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Lesson preview with thumbnail
            HStack(spacing: Spacing.md) {
                // Category icon / thumbnail placeholder
                LessonThumbnail(lesson: lesson)
                
                // Lesson info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(lesson.title)
                        .font(.labelLarge)
                        .foregroundStyle(.textPrimary)
                        .lineLimit(2)
                    
                    Text(lesson.lessonDescription)
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                        .lineLimit(2)
                    
                    // Meta info: category icon + duration
                    HStack(spacing: Spacing.md) {
                        // Category with icon
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: lesson.category.icon)
                                .font(.caption)
                            Text(lesson.category.rawValue)
                                .font(.caption)
                        }
                        .foregroundStyle(.textTertiary)
                        
                        // Duration - always "5 min" as per requirements
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("5 min")
                                .font(.caption)
                        }
                        .foregroundStyle(.textTertiary)
                    }
                }
                
                Spacer(minLength: 0)
            }
            
            // Start Lesson button - large touch target (min 60pt height)
            Button {
                onStartLesson(lesson)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Start Lesson")
                        .font(.labelLarge)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60) // Minimum 60pt touch target
                .background(LinearGradient.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(BounceButtonStyle())
            .accessibilityLabel("Start lesson: \(lesson.title)")
            .accessibilityHint("Opens the lesson to begin learning")
        }
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isAnimating)
    }
}

// MARK: - Completed Lesson Content

/// Content shown when today's lesson has been completed - "Great job!" state
private struct CompletedLessonContent: View {
    let lesson: Lesson
    
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Success icon with celebration animation
            ZStack {
                // Outer glow rings
                Circle()
                    .fill(Color.brandSecondary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(Color.brandSecondary.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                // Success circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandSecondary, Color.brandSecondaryLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.brandSecondary.opacity(0.4), radius: 12, y: 6)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(showConfetti ? 1.0 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)
            
            VStack(spacing: Spacing.xs) {
                Text("Great job! 🎉")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.textPrimary)
                
                Text("You completed today's lesson")
                    .font(.bodyMedium)
                    .foregroundStyle(.textSecondary)
                
                // Lesson completed info
                HStack(spacing: Spacing.sm) {
                    Image(systemName: lesson.category.icon)
                        .foregroundStyle(.brandSecondary)
                    
                    Text(lesson.title)
                        .font(.labelSmall)
                        .foregroundStyle(.textSecondary)
                }
                .padding(.top, Spacing.xs)
            }
            
            // Encouragement message
            Text("Come back tomorrow for your next lesson!")
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showConfetti = true
            }
        }
    }
}

// MARK: - All Lessons Completed Content

/// Content shown when all available lessons have been completed
private struct AllLessonsCompletedContent: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.brandSecondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.brandSecondary)
            }
            
            Text("All caught up!")
                .font(.labelLarge)
                .foregroundStyle(.textPrimary)
            
            Text("You've completed all available lessons. Check back soon for new content!")
                .font(.bodySmall)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
    }
}

// MARK: - Bounce Button Style

/// Custom button style with satisfying bounce feedback
private struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Today's Lesson Card - Active") {
    let lesson = Lesson(
        title: "Who is Allah?",
        lessonDescription: "Learn about Allah's beautiful names and attributes",
        category: .aqeedah,
        durationMinutes: 5,
        xpReward: 20,
        order: 1,
        weekNumber: 1
    )
    
    return TodayLessonCard(
        lesson: lesson,
        isCompleted: false,
        onStartLesson: { _ in }
    )
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Today's Lesson Card - Completed") {
    let lesson = Lesson(
        title: "Who is Allah?",
        lessonDescription: "Learn about Allah's beautiful names and attributes",
        category: .aqeedah,
        durationMinutes: 5,
        xpReward: 20,
        order: 1,
        weekNumber: 1
    )
    
    return TodayLessonCard(
        lesson: lesson,
        isCompleted: true,
        onStartLesson: { _ in }
    )
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Today's Lesson Card - No Lessons") {
    TodayLessonCard(
        lesson: nil,
        isCompleted: false,
        onStartLesson: { _ in }
    )
    .padding()
    .background(Color.backgroundSecondary)
}
