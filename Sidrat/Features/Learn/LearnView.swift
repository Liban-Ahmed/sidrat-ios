//
//  LearnView.swift
//  Sidrat
//
//  Learning path and lesson selection
//

import SwiftUI
import SwiftData

struct LearnView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Lesson.order) private var allLessons: [Lesson]
    @Query private var children: [Child]
    @State private var selectedCategory: LessonCategory?
    @State private var selectedLesson: Lesson?
    
    private var currentChild: Child? {
        guard let childId = appState.currentChildId,
              let uuid = UUID(uuidString: childId) else { return nil }
        return children.first { $0.id == uuid }
    }
    
    // Get lessons for current week (week 1 for now)
    private var currentWeekLessons: [Lesson] {
        allLessons.filter { $0.weekNumber == 1 }
    }
    
    // Get completed lesson IDs
    private var completedLessonIds: Set<UUID> {
        guard let child = currentChild else { return [] }
        return Set(child.lessonProgress.filter { $0.isCompleted }.map { $0.lessonId })
    }
    
    // Count lessons by category
    private func lessonCount(for category: LessonCategory) -> Int {
        allLessons.filter { $0.category == category }.count
    }
    
    // Check if a lesson is completed
    private func isLessonCompleted(_ lesson: Lesson) -> Bool {
        completedLessonIds.contains(lesson.id)
    }
    
    // Get the current lesson index
    private var currentLessonIndex: Int {
        for (index, lesson) in currentWeekLessons.enumerated() {
            if !isLessonCompleted(lesson) {
                return index
            }
        }
        return currentWeekLessons.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Current week banner
                    currentWeekBanner
                    
                    // Learning path
                    learningPathSection
                    
                    // Categories grid
                    categoriesSection
                }
                .padding()
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Learn")
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailView(lesson: lesson)
            }
        }
    }
    
    // MARK: - Current Week Banner
    
    private var currentWeekBanner: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("WEEK 1")
                        .font(.labelSmall)
                        .foregroundStyle(.white.opacity(0.8))
                        .tracking(1.5)
                    
                    Text(currentWeekLessons.first?.title ?? "Learning About Wudu")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    let completedCount = currentWeekLessons.filter { isLessonCompleted($0) }.count
                    let progress = currentWeekLessons.isEmpty ? 0.0 : Double(completedCount) / Double(currentWeekLessons.count)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(completedCount)/\(currentWeekLessons.count)")
                        .font(.labelSmall)
                        .foregroundStyle(.white)
                }
            }
            
            let remainingCount = currentWeekLessons.filter { !isLessonCompleted($0) }.count
            Text("\(remainingCount) more lesson\(remainingCount == 1 ? "" : "s") to complete this week's family activity")
                .font(.bodySmall)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding()
        .background(LinearGradient.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }
    
    // MARK: - Learning Path
    
    private var learningPathSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Today's Path")
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            if currentWeekLessons.isEmpty {
                Text("No lessons available yet")
                    .font(.bodyMedium)
                    .foregroundStyle(.textSecondary)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(currentWeekLessons.enumerated()), id: \.element.id) { index, lesson in
                        let isCompleted = isLessonCompleted(lesson)
                        let isCurrent = index == currentLessonIndex
                        let isLocked = index > currentLessonIndex
                        
                        Button {
                            if !isLocked {
                                selectedLesson = lesson
                            }
                        } label: {
                            LessonPathItem(
                                lessonNumber: index + 1,
                                title: lesson.title,
                                duration: lesson.durationMinutes,
                                xp: lesson.xpReward,
                                isCompleted: isCompleted,
                                isLocked: isLocked,
                                isCurrent: isCurrent
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isLocked)
                        
                        if index < currentWeekLessons.count - 1 {
                            // Connecting line
                            Rectangle()
                                .fill(isCompleted ? Color.brandSecondary : Color.backgroundTertiary)
                                .frame(width: 3, height: 24)
                                .padding(.leading, 22)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Explore Topics")
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                ForEach(LessonCategory.allCases, id: \.self) { category in
                    CategoryCard(category: category, lessonCount: lessonCount(for: category))
                }
            }
        }
    }
}

// MARK: - Lesson Path Item

struct LessonPathItem: View {
    let lessonNumber: Int
    let title: String
    let duration: Int
    let xp: Int
    let isCompleted: Bool
    let isLocked: Bool
    let isCurrent: Bool
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Circle indicator
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 44, height: 44)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.labelMedium)
                        .foregroundStyle(.white)
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                } else {
                    Text("\(lessonNumber)")
                        .font(.labelMedium)
                        .foregroundStyle(isCurrent ? .white : .textSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.labelMedium)
                    .foregroundStyle(isLocked ? .textTertiary : .textPrimary)
                
                Text("\(duration) min • \(xp) XP")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
            
            Spacer()
            
            if isCurrent {
                Text("Start")
                    .font(.labelSmall)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, Spacing.xs)
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .brandSecondary
        } else if isCurrent {
            return .brandPrimary
        } else if isLocked {
            return .backgroundTertiary
        } else {
            return .backgroundSecondary
        }
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: LessonCategory
    let lessonCount: Int
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(.brandPrimary)
            }
            
            Text(category.rawValue)
                .font(.labelMedium)
                .foregroundStyle(.textPrimary)
            
            Text("\(lessonCount) lessons")
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
    LearnView()
}
