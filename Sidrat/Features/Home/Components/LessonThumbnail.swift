//
//  LessonThumbnail.swift
//  Sidrat
//
//  Lesson thumbnail component with category-based gradients
//  Extracted from HomeView.swift for maintainability
//

import SwiftUI

// MARK: - Lesson Thumbnail

/// Displays a lesson thumbnail with category icon overlay
/// Falls back to category-colored gradient when no image available
struct LessonThumbnail: View {
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

// MARK: - Preview

#Preview("Lesson Thumbnails") {
    VStack(spacing: Spacing.md) {
        ForEach([LessonCategory.aqeedah, .salah, .wudu, .quran, .seerah, .adab, .duaa, .stories], id: \.self) { category in
            HStack {
                LessonThumbnail(
                    lesson: Lesson(
                        title: "Sample Lesson",
                        lessonDescription: "Description",
                        category: category,
                        durationMinutes: 5,
                        xpReward: 20,
                        order: 1,
                        weekNumber: 1
                    )
                )
                
                Text(category.rawValue)
                    .font(.labelMedium)
                
                Spacer()
            }
        }
    }
    .padding()
}
