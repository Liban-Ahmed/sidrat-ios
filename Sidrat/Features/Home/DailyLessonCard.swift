//
//  DailyLessonCard.swift
//  Sidrat
//
//  Premium daily lesson card component for HomeView
//  Implements US-201: Daily Lesson Display
//

import SwiftUI

// MARK: - Daily Lesson Card

/// A premium card component that displays today's lesson with engaging animations.
///
/// Features:
/// - Category icon with gradient background (80pt circle)
/// - Title, description, duration, and XP badges
/// - "Start Lesson" button with 60pt minimum height
/// - Subtle pulse animation to draw attention
/// - "Great job!" overlay when completed
/// - Replay option for completed lessons
/// - Works offline with cached lesson content
///
/// Usage:
/// ```swift
/// DailyLessonCard(
///     lesson: todaysLesson,
///     isCompleted: isTodaysLessonCompleted,
///     onStart: { startLesson(lesson) },
///     onReplay: { replayLesson(lesson) }
/// )
/// ```
struct DailyLessonCard: View {
    // MARK: - Properties
    
    /// The lesson to display (nil if no lessons available)
    let lesson: Lesson?
    
    /// Whether the lesson has been completed today
    let isCompleted: Bool
    
    /// Whether the lesson has partial progress (US-204)
    var hasPartialProgress: Bool = false
    
    /// Callback when the Start Lesson button is tapped
    let onStart: () -> Void
    
    /// Optional callback when Review Lesson is tapped
    var onReplay: (() -> Void)?
    
    // MARK: - Animation State
    
    /// Controls the continuous pulse animation on the button
    @State private var isPulsing = false
    
    /// Controls the entrance animation
    @State private var hasAppeared = false
    
    /// Controls the card's attention-grabbing bounce
    @State private var isAnimating = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with "Today's Lesson" label
            cardHeader
            
            // Main content based on state
            if let lesson = lesson {
                if isCompleted {
                    CompletedLessonOverlay(
                        lesson: lesson,
                        onReplay: onReplay
                    )
                } else {
                    activeLessonContent(lesson: lesson)
                }
            } else {
                AllLessonsCompletedView()
            }
        }
        .padding(Spacing.lg)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
        // Subtle bounce animation to draw attention
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .animation(
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            // Start attention animation if lesson is active (not completed)
            if !isCompleted && lesson != nil {
                isAnimating = true
            }
            
            // Start button pulse animation
            isPulsing = true
            
            // Entrance animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                hasAppeared = true
            }
        }
        .onChange(of: isCompleted) { _, newValue in
            // Stop bounce when completed
            if newValue {
                withAnimation {
                    isAnimating = false
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0.8)
        .offset(y: hasAppeared ? 0 : 10)
    }
    
    // MARK: - Card Header
    
    private var cardHeader: some View {
        HStack {
            Text("Today's Lesson")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.textPrimary)
            
            Spacer()
            
            if let lesson = lesson {
                weekBadge(weekNumber: lesson.weekNumber)
            }
        }
    }
    
    // MARK: - Week Badge
    
    private func weekBadge(weekNumber: Int) -> some View {
        Text("Week \(weekNumber)")
            .font(.labelSmall)
            .fontWeight(.medium)
            .foregroundStyle(.brandPrimary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(Color.brandPrimary.opacity(0.1))
            .clipShape(Capsule())
    }
    
    // MARK: - Active Lesson Content
    
    private func activeLessonContent(lesson: Lesson) -> some View {
        VStack(spacing: Spacing.lg) {
            // Lesson preview row
            HStack(spacing: Spacing.md) {
                // Category icon with gradient background (80pt)
                CategoryIconView(category: lesson.category, size: 80)
                
                // Lesson info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(lesson.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(lesson.lessonDescription)
                        .font(.bodyMedium)
                        .foregroundStyle(.textSecondary)
                        .lineLimit(2)
                    
                    // Meta badges row
                    metaBadgesRow(lesson: lesson)
                }
                
                Spacer(minLength: 0)
            }
            
            // Start Lesson button with pulse animation
            startLessonButton(lesson: lesson)
        }
    }
    
    // MARK: - Meta Badges Row
    
    private func metaBadgesRow(lesson: Lesson) -> some View {
        HStack(spacing: Spacing.md) {
            // Category badge
            HStack(spacing: Spacing.xxs) {
                Image(systemName: lesson.category.icon)
                    .font(.caption)
                Text(lesson.category.rawValue)
                    .font(.caption)
            }
            .foregroundStyle(.textTertiary)
            
            // Duration badge - always "5 min"
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                Text("5 min")
                    .font(.caption)
            }
            .foregroundStyle(.textTertiary)
            
            // XP badge
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "star.fill")
                    .font(.caption)
                Text("+\(lesson.xpReward) XP")
                    .font(.caption)
            }
            .foregroundStyle(.brandAccent)
        }
        .padding(.top, Spacing.xxs)
    }
    
    // MARK: - Start Lesson Button
    
    private func startLessonButton(lesson: Lesson) -> some View {
        Button(action: onStart) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: hasPartialProgress ? "arrow.clockwise.circle.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text(hasPartialProgress ? "Resume Lesson" : "Start Lesson")
                    .font(.labelLarge)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60) // Minimum 60pt touch target per requirements
            .background(
                LinearGradient.primaryGradient
                    .overlay {
                        // Subtle pulse glow effect
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(Color.white.opacity(isPulsing ? 0.15 : 0))
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                                value: isPulsing
                            )
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .shadow(color: Color.brandPrimary.opacity(0.4), radius: 12, y: 6)
        }
        .buttonStyle(SpringButtonStyle())
        .accessibilityLabel(hasPartialProgress ? "Resume lesson: \(lesson.title)" : "Start lesson: \(lesson.title)")
        .accessibilityHint(hasPartialProgress ? "Opens the lesson to continue from where you left off" : "Opens the lesson to begin learning")
        .accessibilityAddTraits(.startsMediaSession)
    }
}

// MARK: - Category Icon View

/// Displays a lesson category icon with gradient background
struct CategoryIconView: View {
    let category: LessonCategory
    var size: CGFloat = 80
    
    /// Category-based gradient colors
    private var gradient: LinearGradient {
        switch category {
        case .aqeedah:
            return LinearGradient(
                colors: [.brandPrimary, .brandPrimaryLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .salah:
            return LinearGradient(
                colors: [.brandAccent, .brandAccentLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .wudu:
            return LinearGradient(
                colors: [.brandPrimary, .brandSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .quran:
            return LinearGradient(
                colors: [.brandSecondary, .brandSecondaryLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .seerah:
            return LinearGradient(
                colors: [.brandAccent, .brandPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .adab:
            return LinearGradient(
                colors: [.error, .brandAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .duaa:
            return LinearGradient(
                colors: [.brandPrimary, .brandAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .stories:
            return LinearGradient(
                colors: [.brandSecondary, .brandPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Background circle with gradient
            Circle()
                .fill(gradient)
                .frame(width: size, height: size)
                .shadow(color: category.color.opacity(0.3), radius: 8, y: 4)
            
            // Category icon
            Image(systemName: category.icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("\(category.rawValue) lesson")
    }
}

// MARK: - Completed Lesson Overlay

/// Overlay shown when today's lesson has been completed
struct CompletedLessonOverlay: View {
    let lesson: Lesson
    var onReplay: (() -> Void)?
    
    @State private var showCheckmark = false
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Success animation
            successIcon
            
            // Congratulations text
            VStack(spacing: Spacing.xs) {
                Text("Great job! 🎉")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.textPrimary)
                
                Text("You completed today's lesson")
                    .font(.bodyMedium)
                    .foregroundStyle(.textSecondary)
                
                // Lesson info
                HStack(spacing: Spacing.sm) {
                    Image(systemName: lesson.category.icon)
                        .foregroundStyle(.brandSecondary)
                    
                    Text(lesson.title)
                        .font(.labelSmall)
                        .foregroundStyle(.textSecondary)
                }
                .padding(.top, Spacing.xs)
                
                // XP earned badge
                xpEarnedBadge
            }
            
            // Review button (optional)
            if let onReplay = onReplay {
                reviewButton(action: onReplay)
            }
            
            // Encouragement message
            Text("Come back tomorrow for your next lesson!")
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                showCheckmark = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) {
                showConfetti = true
            }
        }
    }
    
    // MARK: - Success Icon
    
    private var successIcon: some View {
        ZStack {
            // Outer glow rings
            Circle()
                .fill(Color.brandSecondary.opacity(0.1))
                .frame(width: 120, height: 120)
                .scaleEffect(showConfetti ? 1.0 : 0.8)
            
            Circle()
                .fill(Color.brandSecondary.opacity(0.15))
                .frame(width: 100, height: 100)
                .scaleEffect(showConfetti ? 1.0 : 0.9)
            
            // Main success circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.brandSecondary, .brandSecondaryLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .shadow(color: Color.brandSecondary.opacity(0.4), radius: 12, y: 6)
            
            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(showCheckmark ? 1.0 : 0.5)
                .opacity(showCheckmark ? 1 : 0)
        }
        .accessibilityLabel("Lesson completed successfully")
    }
    
    // MARK: - XP Earned Badge
    
    private var xpEarnedBadge: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "star.fill")
                .foregroundStyle(.brandAccent)
            
            Text("+\(lesson.xpReward) XP earned!")
                .font(.labelSmall)
                .fontWeight(.medium)
                .foregroundStyle(.brandAccent)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.brandAccent.opacity(0.1))
        .clipShape(Capsule())
        .padding(.top, Spacing.sm)
    }
    
    // MARK: - Review Button
    
    private func reviewButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .medium))
                
                Text("Review Lesson")
                    .font(.labelMedium)
            }
            .foregroundStyle(.brandPrimary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(Color.brandPrimary.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(SpringButtonStyle())
        .accessibilityLabel("Review lesson: \(lesson.title)")
        .accessibilityHint("Replays the completed lesson")
    }
}

// MARK: - All Lessons Completed View

/// View shown when all available lessons have been completed
struct AllLessonsCompletedView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Star icon with glow
            ZStack {
                Circle()
                    .fill(Color.brandSecondary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Circle()
                    .fill(Color.brandSecondary.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.brandSecondary)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
            }
            .animation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
            
            Text("All caught up!")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.textPrimary)
            
            Text("You've completed all available lessons.\nCheck back soon for new content!")
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Spring Button Style

/// Custom button style with satisfying spring bounce feedback
struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Daily Lesson Card - Active") {
    let lesson = Lesson(
        title: "Who is Allah?",
        lessonDescription: "Learn about Allah's beautiful names and attributes in this engaging lesson.",
        category: .aqeedah,
        durationMinutes: 5,
        xpReward: 20,
        order: 1,
        weekNumber: 1
    )
    
    return DailyLessonCard(
        lesson: lesson,
        isCompleted: false,
        onStart: { print("Start tapped") },
        onReplay: { print("Replay tapped") }
    )
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Daily Lesson Card - Completed") {
    let lesson = Lesson(
        title: "Who is Allah?",
        lessonDescription: "Learn about Allah's beautiful names and attributes",
        category: .aqeedah,
        durationMinutes: 5,
        xpReward: 20,
        order: 1,
        weekNumber: 1
    )
    
    return DailyLessonCard(
        lesson: lesson,
        isCompleted: true,
        onStart: { },
        onReplay: { print("Review tapped") }
    )
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Daily Lesson Card - Resume") {
    let lesson = Lesson(
        title: "How to Make Wudu",
        lessonDescription: "Learn the steps of making wudu correctly",
        category: .wudu,
        durationMinutes: 5,
        xpReward: 20,
        order: 2,
        weekNumber: 1
    )
    
    return DailyLessonCard(
        lesson: lesson,
        isCompleted: false,
        hasPartialProgress: true,
        onStart: { print("Resume tapped") }
    )
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Daily Lesson Card - No Lessons") {
    DailyLessonCard(
        lesson: nil,
        isCompleted: false,
        onStart: { }
    )
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Category Icons") {
    HStack(spacing: Spacing.md) {
        CategoryIconView(category: .aqeedah, size: 60)
        CategoryIconView(category: .salah, size: 60)
        CategoryIconView(category: .quran, size: 60)
        CategoryIconView(category: .duaa, size: 60)
    }
    .padding()
    .background(Color.backgroundSecondary)
}
