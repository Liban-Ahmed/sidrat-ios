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
    @State private var showingStreakDetail = false
    @State private var showingMilestoneCelebration = false
    @State private var celebrationMilestone: StreakMilestone?
    @State private var milestoneObserver: NSObjectProtocol?
    @State private var showNextLessonBanner = false
    @State private var bannerLessonTitle: String?
    
    // MARK: - Computed Properties
    
    private var currentChild: Child? {
        guard let childId = appState.currentChildId,
              let uuid = UUID(uuidString: childId) else { return nil }
        return children.first { $0.id == uuid }
    }
    
    private var hasMultipleChildren: Bool {
        children.count > 1
    }
    
    // MARK: - Streak Service (US-303)
    
    private var streakService: StreakService {
        StreakService(modelContext: modelContext)
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
                    // Next lesson ready banner (shown after completing a lesson)
                    if showNextLessonBanner, let nextLesson = todaysLesson {
                        NextLessonBanner(
                            lesson: nextLesson,
                            previousLessonTitle: bannerLessonTitle,
                            onStart: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showNextLessonBanner = false
                                }
                                selectedLesson = nextLesson
                            },
                            onDismiss: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showNextLessonBanner = false
                                }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                    
                    // Header with streak
                    headerSection
                    
                    // Today's lesson card
                    TodayLessonCard(
                        lesson: todaysLesson,
                        isCompleted: isTodaysLessonCompleted,
                        onStartLesson: { lesson in
                            selectedLesson = lesson
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
            .sheet(isPresented: $showingStreakDetail) {
                if let child = currentChild {
                    StreakDetailSheet(child: child)
                }
            }
            .task {
                // Check for expired streaks on app launch (US-303 Phase 2)
                await checkExpiredStreaks()
                
                // Listen for milestone achievements (US-303 Phase 5)
                setupMilestoneNotificationListener()
                
                // Check if we're returning from a completed lesson
                checkForLessonCompletionPrompt()
            }
            .onChange(of: appState.showNextLessonPrompt) { _, newValue in
                if newValue {
                    checkForLessonCompletionPrompt()
                }
            }
            .onDisappear {
                // Remove notification observer to prevent memory leak
                if let observer = milestoneObserver {
                    NotificationCenter.default.removeObserver(observer)
                    milestoneObserver = nil
                }
            }
            .fullScreenCover(isPresented: $showingMilestoneCelebration) {
                if let milestone = celebrationMilestone {
                    StreakMilestoneCelebrationView(
                        milestone: milestone,
                        onDismiss: {
                            showingMilestoneCelebration = false
                            celebrationMilestone = nil
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Streak Check (US-303)
    
    /// Check and reset expired streaks for all children on app launch
    private func checkExpiredStreaks() async {
        let streakService = StreakService(modelContext: modelContext)
        
        for child in children {
            do {
                try await streakService.checkAndResetExpiredStreak(child: child)
            } catch {
#if DEBUG
                print("❌ [HomeView] Failed to check streak for \(child.name): \(error.localizedDescription)")
#endif
            }
        }
    }
    
    /// Setup notification listener for milestone achievements (US-303 Phase 5)
    private func setupMilestoneNotificationListener() {
        milestoneObserver = NotificationCenter.default.addObserver(
            forName: .streakMilestoneAchieved,
            object: nil,
            queue: .main
        ) { [weak appState] notification in
            // Only show celebration for current child
            guard let childId = notification.userInfo?["childId"] as? String,
                  childId == appState?.currentChildId,
                  let milestone = notification.object as? StreakMilestone else {
                return
            }
            
#if DEBUG
            print("🎉 [HomeView] Showing milestone celebration for \(milestone.days) days")
#endif
            
            celebrationMilestone = milestone
            showingMilestoneCelebration = true
        }
    }
    
    // MARK: - Lesson Completion Prompt
    
    /// Check if we should show the "next lesson" prompt after completing a lesson
    private func checkForLessonCompletionPrompt() {
        guard appState.showNextLessonPrompt,
              let completedLessonId = appState.lastCompletedLessonId else {
            return
        }
        
        // Find the completed lesson's title
        let completedLesson = lessons.first { $0.id.uuidString == completedLessonId }
        bannerLessonTitle = completedLesson?.title
        
        // Reset AppState flags
        appState.showNextLessonPrompt = false
        appState.lastCompletedLessonId = nil
        
        // Show the banner with animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showNextLessonBanner = true
        }
        
        // Auto-dismiss after 8 seconds if not interacted with
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            withAnimation(.easeOut(duration: 0.3)) {
                showNextLessonBanner = false
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
            
            // Enhanced streak badge with tap to show details
            if let child = currentChild {
                EnhancedStreakBadge(
                    streak: child.currentStreak,
                    hoursRemaining: streakService.hoursRemainingToday(),
                    onTap: {
                        showingStreakDetail = true
                    }
                )
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

// MARK: - Next Lesson Banner

/// Banner shown after completing a lesson to prompt the next one
struct NextLessonBanner: View {
    let lesson: Lesson
    let previousLessonTitle: String?
    let onStart: () -> Void
    let onDismiss: () -> Void
    
    @State private var iconBounce = false
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                // Success checkmark with celebration
                ZStack {
                    Circle()
                        .fill(Color.brandSecondary.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.brandSecondary)
                        .scaleEffect(iconBounce ? 1.1 : 1.0)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if let previousTitle = previousLessonTitle {
                        Text("Great job completing \(previousTitle)!")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Text("Next up: \(lesson.title)")
                        .font(.labelMedium)
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.textTertiary)
                        .padding(8)
                        .background(Circle().fill(Color.surfaceTertiary.opacity(0.5)))
                }
                .buttonStyle(.plain)
            }
            
            // Start button
            Button(action: onStart) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                    Text("Start Next Lesson")
                        .font(.labelMedium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(
                    LinearGradient(
                        colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color.backgroundPrimary)
                .shadow(color: Color.brandSecondary.opacity(0.15), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(Color.brandSecondary.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            // Bounce animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).repeatCount(2)) {
                iconBounce = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                iconBounce = false
            }
            
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

