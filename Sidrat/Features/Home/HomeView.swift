//
//  HomeView.swift
//  Sidrat
//
//  Main home/dashboard view
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var children: [Child]
    @Query(sort: \Lesson.order) private var lessons: [Lesson]
    @State private var selectedLesson: Lesson?
    
    private var currentChild: Child? {
        guard let childId = appState.currentChildId,
              let uuid = UUID(uuidString: childId) else { return nil }
        return children.first { $0.id == uuid }
    }
    
    // Get the next uncompleted lesson or the first lesson
    private var nextLesson: Lesson? {
        guard let child = currentChild else {
            return lessons.first
        }
        
        let completedLessonIds = Set(child.lessonProgress.filter { $0.isCompleted }.map { $0.lessonId })
        return lessons.first { !completedLessonIds.contains($0.id) } ?? lessons.first
    }
    
    // Get lessons completed today
    private var lessonsCompletedToday: Int {
        guard let child = currentChild else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return child.lessonProgress.filter { progress in
            guard let completedAt = progress.completedAt else { return false }
            return calendar.startOfDay(for: completedAt) == today
        }.count
    }
    
    // Calculate which days this week have been completed
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
                    
                    // Today's lesson card
                    todayLessonCard
                    
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
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailView(lesson: lesson)
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
    
    // MARK: - Today's Lesson
    
    private var todayLessonCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Today's Lesson")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
                
                Spacer()
                
                if let lesson = nextLesson {
                    Text("Week \(lesson.weekNumber)")
                        .font(.labelSmall)
                        .foregroundStyle(.brandPrimary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.brandPrimary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            if let lesson = nextLesson {
                // Lesson preview card
                Button {
                    selectedLesson = lesson
                } label: {
                    HStack(spacing: Spacing.md) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, y: 4)
                            
                            Image(systemName: lesson.category.icon)
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(lesson.title)
                                .font(.labelLarge)
                                .foregroundStyle(.textPrimary)
                            
                            Text(lesson.lessonDescription)
                                .font(.bodySmall)
                                .foregroundStyle(.textSecondary)
                                .lineLimit(2)
                            
                            HStack(spacing: Spacing.sm) {
                                Label("\(lesson.durationMinutes) min", systemImage: "clock")
                                Label("\(lesson.xpReward) XP", systemImage: "star.fill")
                            }
                            .font(.caption)
                            .foregroundStyle(.textTertiary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.textTertiary)
                    }
                    .padding()
                    .background(Color.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                .buttonStyle(.plain)
            } else {
                // No lessons available
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.brandSecondary)
                    
                    Text("All caught up!")
                        .font(.labelMedium)
                        .foregroundStyle(.textPrimary)
                    
                    Text("You've completed all available lessons")
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            }
            
            // Today's progress
            if lessonsCompletedToday > 0 {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.brandSecondary)
                    Text("\(lessonsCompletedToday) lesson\(lessonsCompletedToday == 1 ? "" : "s") completed today!")
                        .font(.labelSmall)
                        .foregroundStyle(.brandSecondary)
                }
                .padding(.top, Spacing.xs)
            }
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

#Preview {
    HomeView()
        .environment(AppState())
}
