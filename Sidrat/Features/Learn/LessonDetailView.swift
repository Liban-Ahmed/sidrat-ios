//
//  LessonDetailView.swift
//  Sidrat
//
//  Detailed view for a lesson before starting
//

import SwiftUI
import SwiftData

struct LessonDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    let lesson: Lesson
    @Query private var children: [Child]
    @State private var showingLessonPlayer = false
    
    private var currentChild: Child? {
        guard let childId = appState.currentChildId,
              let uuid = UUID(uuidString: childId) else { return nil }
        return children.first { $0.id == uuid }
    }
    
    private var lessonProgress: LessonProgress? {
        currentChild?.lessonProgress.first { $0.lessonId == lesson.id }
    }
    
    private var isCompleted: Bool {
        lessonProgress?.isCompleted ?? false
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Hero section
                    heroSection
                    
                    // Lesson info
                    lessonInfoSection
                    
                    // Learning objectives
                    objectivesSection
                    
                    // Content preview
                    contentPreviewSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color.backgroundSecondary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.textTertiary)
                            .font(.title2)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                startButton
            }
            .fullScreenCover(isPresented: $showingLessonPlayer) {
                LessonPlayerView(lesson: lesson)
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: Spacing.md) {
            // Category icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [categoryColor, categoryColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: categoryColor.opacity(0.4), radius: 16, y: 8)
                
                Image(systemName: lesson.category.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            .padding(.top, Spacing.lg)
            
            // Title
            Text(lesson.title)
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.textPrimary)
            
            // Category badge
            Text(lesson.category.rawValue)
                .font(.labelSmall)
                .foregroundStyle(categoryColor)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(categoryColor.opacity(0.1))
                .clipShape(Capsule())
            
            // Completion status
            if isCompleted {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.success)
                    Text("Completed!")
                        .font(.labelMedium)
                        .foregroundStyle(.success)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Spacing.md)
    }
    
    private var categoryColor: Color {
        switch lesson.category {
        case .aqeedah: return .brandPrimary
        case .salah: return .brandAccent
        case .wudu: return .brandPrimary
        case .quran: return .brandPrimary
        case .seerah: return .brandAccent
        case .adab: return .error
        case .duaa: return .brandPrimary
        case .stories: return .brandSecondary
        }
    }
    
    // MARK: - Info Section
    
    private var lessonInfoSection: some View {
        HStack(spacing: Spacing.lg) {
            InfoItem(
                icon: "clock",
                value: "\(lesson.durationMinutes)",
                label: "Minutes"
            )
            
            InfoItem(
                icon: "star.fill",
                value: "\(lesson.xpReward)",
                label: "XP"
            )
            
            InfoItem(
                icon: "speedometer",
                value: lesson.difficulty.rawValue,
                label: "Level"
            )
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Objectives Section
    
    private var objectivesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("What You'll Learn")
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ObjectiveRow(text: lesson.lessonDescription)
                
                // Generate dynamic objectives based on category
                ForEach(objectivesForLesson, id: \.self) { objective in
                    ObjectiveRow(text: objective)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    private var objectivesForLesson: [String] {
        switch lesson.category {
        case .wudu:
            return ["Understand the importance of cleanliness", "Learn the steps in order"]
        case .salah:
            return ["Know the five daily prayers", "Understand why we pray"]
        case .quran:
            return ["Learn about Allah's book", "Memorize key verses"]
        case .aqeedah:
            return ["Strengthen your belief", "Learn about Allah's names"]
        case .adab:
            return ["Practice good manners", "Be kind to others"]
        case .duaa:
            return ["Learn special prayers", "Talk to Allah"]
        case .seerah:
            return ["Learn about Prophet Muhammad ﷺ", "Follow his example"]
        case .stories:
            return ["Enjoy amazing stories", "Learn important lessons"]
        }
    }
    
    // MARK: - Content Preview
    
    private var contentPreviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Lesson Contents")
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            VStack(spacing: Spacing.sm) {
                ContentPreviewRow(icon: "book.fill", title: "Story", subtitle: "Fun animated story")
                ContentPreviewRow(icon: "questionmark.circle.fill", title: "Quiz", subtitle: "Test your knowledge")
                ContentPreviewRow(icon: "hands.sparkles.fill", title: "Activity", subtitle: "Interactive learning")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                showingLessonPlayer = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: isCompleted ? "arrow.counterclockwise" : "play.fill")
                    Text(isCompleted ? "Practice Again" : "Start Lesson")
                }
                .font(.labelLarge)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md + 2)
                .background(LinearGradient.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, y: 4)
            }
            .padding()
            .background(Color.backgroundPrimary)
        }
    }
}

// MARK: - Supporting Views

struct InfoItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.brandPrimary)
            
            Text(value)
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ObjectiveRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.brandSecondary)
                .font(.body)
            
            Text(text)
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
        }
    }
}

struct ContentPreviewRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundStyle(.brandPrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.labelMedium)
                    .foregroundStyle(.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.textTertiary)
                .font(.caption)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

#Preview {
    LessonDetailView(lesson: .sampleWuduLesson)
        .environment(AppState())
}
