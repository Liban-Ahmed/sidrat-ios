//
//  HomeView.swift
//  Sidrat
//
//  Main home/dashboard view with today's lesson card"
//

import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Environment
    
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query(sort: \Child.lastAccessedAt, order: .reverse) private var children: [Child]
    @Query(sort: \Lesson.order) private var lessons: [Lesson]
    
    // MARK: - State
    
    @State private var selectedLesson: Lesson?
    @State private var showingProfileSwitcher = false
    @State private var showLessonPlayer = false
    
    // MARK: - Computed Properties
    
    private var currentChild: Child? {
        guard let childId = appState.currentChildId,
              let uuid = UUID(uuidString: childId) else { return nil }
        return children.first { $0.id == uuid }
    }
    
    private var hasMultipleChildren: Bool {
        children.count > 1
    }
    
    /// Get today's lesson - the next uncompleted lesson in sequence
    private var todaysLesson: Lesson? {
        guard let child = currentChild else {
            return lessons.first
        }
        
        let completedLessonIds = Set(child.lessonProgress.filter { $0.isCompleted }.map { $0.lessonId })
        return lessons.first { !completedLessonIds.contains($0.id) } ?? lessons.first
    }
    
    /// Check if today's lesson has been completed today
    private var isTodaysLessonCompleted: Bool {
        guard let child = currentChild,
              let lesson = todaysLesson else { return false }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return child.lessonProgress.contains { progress in
            progress.lessonId == lesson.id &&
            progress.isCompleted &&
            progress.completedAt.map { calendar.startOfDay(for: $0) == today } ?? false
        }
    }
    
    /// Check if today's lesson has partial progress (US-204)
    private var todaysLessonHasPartialProgress: Bool {
        guard let child = currentChild,
              let lesson = todaysLesson else { return false }
        
        let progressService = LessonProgressService(modelContext: modelContext)
        return progressService.loadPartialProgress(lessonId: lesson.id, childId: child.id) != nil
    }
    
    /// Get lessons completed today
    private var lessonsCompletedToday: Int {
        guard let child = currentChild else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return child.lessonProgress.filter { progress in
            guard let completedAt = progress.completedAt else { return false }
            return calendar.startOfDay(for: completedAt) == today
        }.count
    }
    
    /// Calculate which days this week have been completed
    private var weekDaysCompleted: Set<Int> {
        guard let child = currentChild else { return [] }
        let calendar = Calendar.current
        var completedDays: Set<Int> = []
        
        for progress in child.lessonProgress {
            guard let completedAt = progress.completedAt else { continue }
            let weekday = calendar.component(.weekday, from: completedAt)
            // Only count this week's completions
            let weekOfYear = calendar.component(.weekOfYear, from: completedAt)
            let currentWeek = calendar.component(.weekOfYear, from: Date())
            if weekOfYear == currentWeek {
                completedDays.insert(weekday)
            }
        }
        
        return completedDays
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header with streak
                    headerSection
                    
                    // Today's lesson card - using new DailyLessonCard component
                    DailyLessonCard(
                        lesson: todaysLesson,
                        isCompleted: isTodaysLessonCompleted,
                        hasPartialProgress: todaysLessonHasPartialProgress,
                        onStart: {
                            if let lesson = todaysLesson {
                                selectedLesson = lesson
                            }
                        },
                        onReplay: {
                            if let lesson = todaysLesson {
                                selectedLesson = lesson
                            }
                        }
                    )
                    
                    // Weekly progress
                    weeklyProgressSection
                    
                    // Quick stats
                    statsSection
                }
                .padding()
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Assalamu Alaikum!")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileSwitcherButton(showingSwitcher: $showingProfileSwitcher)
                }
            }
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailView(lesson: lesson)
            }
            .sheet(isPresented: $showingProfileSwitcher) {
                ProfileSwitcherView()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Child avatar and greeting
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Welcome back\(currentChild.map { ", \($0.name)" } ?? "")! 👋")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
                
                Text("Ready to learn something new?")
                    .font(.bodyMedium)
                    .foregroundStyle(.textSecondary)
            }
            
            Spacer()
            
            // Streak badge
            StreakBadge(streak: currentChild?.currentStreak ?? 0)
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Weekly Progress
    
    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("This Week")
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            HStack(spacing: Spacing.sm) {
                let daysData: [(index: Int, label: String, weekday: Int)] = [
                    (0, "Sun", 1),
                    (1, "Mon", 2),
                    (2, "Tue", 3),
                    (3, "Wed", 4),
                    (4, "Thu", 5),
                    (5, "Fri", 6),
                    (6, "Sat", 7)
                ]
                
                ForEach(daysData, id: \.index) { dayData in
                    let isCompleted = weekDaysCompleted.contains(dayData.weekday)
                    let isToday = Calendar.current.component(.weekday, from: Date()) == dayData.weekday
                    
                    VStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(isCompleted ? Color.brandSecondary : Color.backgroundTertiary)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                } else if isToday {
                                    Circle()
                                        .stroke(Color.brandPrimary, lineWidth: 2)
                                }
                            }
                            .shadow(color: isCompleted ? Color.brandSecondary.opacity(0.3) : .clear, radius: 4, y: 2)
                        
                        Text(dayData.label)
                            .font(.caption)
                            .foregroundStyle(isToday ? .brandPrimary : .textSecondary)
                            .fontWeight(isToday ? .semibold : .regular)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: Spacing.md) {
            StatCard(
                title: "Total XP",
                value: "\(currentChild?.totalXP ?? 0)",
                icon: "star.fill",
                color: .brandAccent
            )
            
            StatCard(
                title: "Lessons",
                value: "\(currentChild?.totalLessonsCompleted ?? 0)",
                icon: "book.fill",
                color: .brandSecondary
            )
            
            StatCard(
                title: "Streak",
                value: "\(currentChild?.longestStreak ?? 0)",
                icon: "flame.fill",
                color: .brandPrimary
            )
        }
    }
}

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

// MARK: - Lesson Thumbnail

/// Displays a lesson thumbnail with category icon overlay
/// Falls back to category-colored gradient when no image available
private struct LessonThumbnail: View {
    let lesson: Lesson
    
    /// Category-based gradient colors
    private var thumbnailGradient: LinearGradient {
        switch lesson.category {
        case .aqeedah:
            return LinearGradient(
                colors: [Color.brandPrimary, Color.brandPrimaryLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .salah:
            return LinearGradient(
                colors: [Color.brandAccent, Color.brandAccentLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .wudu:
            return LinearGradient(
                colors: [Color.brandPrimary, Color.brandSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .quran:
            return LinearGradient(
                colors: [Color.brandSecondary, Color.brandSecondaryLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .seerah:
            return LinearGradient(
                colors: [Color.brandAccent, Color.brandPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .adab:
            return LinearGradient(
                colors: [Color.error, Color.brandAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .duaa:
            return LinearGradient(
                colors: [Color.brandPrimary, Color.brandAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .stories:
            return LinearGradient(
                colors: [Color.brandSecondary, Color.brandPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(thumbnailGradient)
                .frame(width: 80, height: 80)
                .shadow(color: Color.brandPrimary.opacity(0.2), radius: 8, y: 4)
            
            // Category icon
            Image(systemName: lesson.category.icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("\(lesson.category.rawValue) lesson thumbnail")
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

// MARK: - Supporting Views

struct StreakBadge: View {
    let streak: Int
    
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.brandAccent)
            
            Text("\(streak)")
                .font(.labelLarge)
                .foregroundStyle(.textPrimary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.brandAccent.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .cardShadow()
    }
}

// MARK: - Previews

#Preview("Home View") {
    HomeView()
        .environment(AppState())
}

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
