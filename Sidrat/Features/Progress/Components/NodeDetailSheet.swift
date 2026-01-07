//
//  NodeDetailSheet.swift
//  Sidrat
//
//  Shows lesson details when tree node is tapped
//

import SwiftUI
import SwiftData

struct NodeDetailSheet: View {
    let node: TreeNode
    let child: Child
    let lessons: [Lesson]
    
    @Environment(\.dismiss) private var dismiss
    @State private var isContentReady = false
    
    // Cached computations (computed once, not on every render)
    @State private var cachedLesson: Lesson?
    @State private var cachedProgress: LessonProgress?
    
    var body: some View {
        NavigationStack {
            Group {
                if isContentReady {
                    contentView
                } else {
                    // Loading state
                    VStack(spacing: Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.brandPrimary)
                        
                        Text("Loading lesson...")
                            .font(.bodySmall)
                            .foregroundStyle(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.backgroundSecondary)
                }
            }
            .navigationTitle("Lesson Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.bodyMedium)
                }
            }
        }
        .task {
            // Load data asynchronously to prevent blocking
            await loadContent()
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if let lesson = cachedLesson {
                    // Category icon
                    IconBadge(
                        lesson.category.icon,
                        color: lesson.category.color,
                        size: .large
                    )
                    .padding(.top, Spacing.md)
                    
                    // Lesson title
                    Text(lesson.title)
                        .font(.title2)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    // Lesson description
                    Text(lesson.lessonDescription)
                        .font(.bodyMedium)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, Spacing.xs)
                    
                    // Status section
                    if node.isCompleted {
                        completedSection
                    } else {
                        notCompletedSection
                    }
                    
                    // Lesson info
                    lessonInfoSection
                    
                    Spacer()
                } else {
                    // Error state
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.error)
                        
                        Text("Lesson Not Found")
                            .font(.title3)
                            .foregroundStyle(.textPrimary)
                        
                        Text("Unable to load lesson details")
                            .font(.bodySmall)
                            .foregroundStyle(.textSecondary)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .background(Color.backgroundSecondary)
    }
    
    // MARK: - Data Loading
    
    private func loadContent() async {
        // For this use case, the dataset is likely small enough that we don't need
        // to perform the lookup off the main thread. SwiftData models must stay
        // on the main actor context.
        let lessonIdToFind = node.lessonId
        
        // Perform lookup on main actor (where SwiftData models live)
        cachedLesson = lessons.first { $0.id == lessonIdToFind }
        cachedProgress = child.lessonProgress.first { $0.lessonId == lessonIdToFind }
        isContentReady = true
    }
    
    // MARK: - Subviews
    
    private var completedSection: some View {
        VStack(spacing: Spacing.md) {
            // Completion badge
            HStack(spacing: Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.success)
                
                Text("Completed!")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
            }
            
            // Completion details
            if let progress = cachedProgress, let completedAt = progress.completedAt {
                Text("Completed on \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                
                // Stats
                HStack(spacing: Spacing.lg) {
                    StatItem(
                        icon: "star.fill",
                        value: "\(progress.xpEarned)",
                        label: "XP",
                        color: .brandAccent
                    )
                    
                    if progress.attempts > 0 {
                        StatItem(
                            icon: "repeat.circle.fill",
                            value: "\(progress.attempts)",
                            label: progress.attempts == 1 ? "Try" : "Tries",
                            color: .brandSecondary
                        )
                    }
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding()
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    private var notCompletedSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.textTertiary)
            
            Text("Not completed yet")
                .font(.bodyMedium)
                .foregroundStyle(.textTertiary)
            
            Text("Complete this lesson to unlock!")
                .font(.caption)
                .foregroundStyle(.textTertiary)
        }
        .padding()
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    private var lessonInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Lesson Info")
                .font(.labelMedium)
                .foregroundStyle(.textSecondary)
            
            if let lesson = cachedLesson {
                InfoRow(label: "Category", value: lesson.category.rawValue)
                InfoRow(label: "Duration", value: "\(lesson.durationMinutes) min")
                InfoRow(label: "Week", value: "\(lesson.weekNumber)")
                InfoRow(label: "XP Reward", value: "\(lesson.xpReward) XP")
            }
        }
        .padding()
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
}

// (Removed formatTime helper as timeSpent property doesn't exist in LessonProgress)

// MARK: - Supporting Views

private struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.labelLarge)
                .foregroundStyle(.textPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.textTertiary)
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.bodySmall)
                .foregroundStyle(.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.bodySmall)
                .foregroundStyle(.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Child.self, Lesson.self, LessonProgress.self, configurations: config)
    
    let child = Child(name: "Sara", birthYear: 2019, avatarId: "cat")
    container.mainContext.insert(child)
    
    let lesson = Lesson(
        title: "Who is Allah?",
        lessonDescription: "Learn about our Creator",
        category: .aqeedah,
        durationMinutes: 5,
        xpReward: 20,
        order: 0,
        weekNumber: 1
    )
    container.mainContext.insert(lesson)
    
    let node = TreeNode(
        id: lesson.id,
        position: .left,
        category: .aqeedah,
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        isCompleted: true,
        branchLevel: 0,
        weekNumber: 1
    )
    
    return NodeDetailSheet(
        node: node,
        child: child,
        lessons: [lesson]
    )
    .modelContainer(container)
}
