//
//  LearningHistoryList.swift
//  Sidrat
//
//  List of recently completed lessons
//

import SwiftUI
import SwiftData

struct LearningHistoryList: View {
    let completedLessonsInfo: [(lesson: Lesson, completedAt: Date, xp: Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recent Activity")
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            if completedLessonsInfo.isEmpty {
                emptyState
            } else {
                lessonsList
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Subviews
    
    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.largeTitle)
                .foregroundStyle(.textTertiary)
            
            Text("No lessons completed yet")
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
            
            Text("Complete your first lesson to see it here!")
                .font(.bodySmall)
                .foregroundStyle(.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
    
    private var lessonsList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(Array(completedLessonsInfo.prefix(5).enumerated()), id: \.offset) { index, info in
                HistoryItem(
                    title: info.lesson.title,
                    category: info.lesson.category.rawValue,
                    xp: info.xp,
                    date: formatRelativeDate(info.completedAt)
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfDate = calendar.startOfDay(for: date)
        
        let days = calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day ?? 0
        
        switch days {
        case 0: return "Today"
        case 1: return "Yesterday"
        case 2...6: return "\(days) days ago"
        default:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Supporting View

private struct HistoryItem: View {
    let title: String
    let category: String
    let xp: Int
    let date: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.brandSecondary)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.labelMedium)
                    .foregroundStyle(.textPrimary)
                
                Text(category)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("+\(xp) XP")
                    .font(.labelSmall)
                    .foregroundStyle(.brandAccent)
                
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Lesson.self, configurations: config)
    
    let lesson1 = Lesson(
        title: "Who is Allah?",
        lessonDescription: "Learn about our Creator",
        category: .aqeedah,
        durationMinutes: 5,
        xpReward: 20,
        order: 0,
        weekNumber: 1
    )
    
    let lesson2 = Lesson(
        title: "How to Make Wudu",
        lessonDescription: "Learn the steps of wudu",
        category: .wudu,
        durationMinutes: 5,
        xpReward: 20,
        order: 1,
        weekNumber: 1
    )
    
    container.mainContext.insert(lesson1)
    container.mainContext.insert(lesson2)
    
    let completedLessons = [
        (lesson: lesson1, completedAt: Date(), xp: 20),
        (lesson: lesson2, completedAt: Date().addingTimeInterval(-86400), xp: 20)
    ]
    
    return NavigationStack {
        VStack(spacing: Spacing.md) {
        LearningHistoryList(completedLessonsInfo: completedLessons)
        
        LearningHistoryList(completedLessonsInfo: [])
        }
        .padding()
        .background(Color.backgroundSecondary)
    }
    .modelContainer(container)
}
