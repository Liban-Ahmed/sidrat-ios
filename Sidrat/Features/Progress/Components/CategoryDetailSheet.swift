//
//  CategoryDetailSheet.swift
//  Sidrat
//
//  Extracted CategoryDetailSheet from ParentProgressDashboardView
//  Shows detailed progress for a specific learning category
//

import SwiftUI

struct CategoryDetailSheet: View {
    let categoryStats: CategoryStats
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Category header
                    categoryHeader
                    
                    // Progress summary
                    progressSummary
                    
                    // Recent lessons
                    if !categoryStats.recentLessons.isEmpty {
                        recentLessonsSection
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.backgroundSecondary)
            .navigationTitle(categoryStats.category.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.brandPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Category Header
    
    private var categoryHeader: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(categoryStats.category.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: categoryStats.category.iconName)
                    .font(.largeTitle)
                    .foregroundStyle(categoryStats.category.color)
            }
            
            Text(categoryStats.category.rawValue)
                .font(.title2)
                .foregroundStyle(.textPrimary)
        }
        .padding(.top, Spacing.md)
    }
    
    // MARK: - Progress Summary
    
    private var progressSummary: some View {
        VStack(spacing: Spacing.sm) {
            // Progress ring would go here
            Text(categoryStats.formattedPercentage)
                .font(.displayMedium)
                .foregroundStyle(.brandPrimary)
            
            Text("\(categoryStats.completedCount) of \(categoryStats.totalCount) lessons completed")
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
            
            if categoryStats.remainingCount > 0 {
                Text("\(categoryStats.remainingCount) remaining")
                    .font(.bodySmall)
                    .foregroundStyle(.textTertiary)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Recent Lessons Section
    
    private var recentLessonsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Lessons")
                .font(.labelLarge)
                .foregroundStyle(.textPrimary)
            
            ForEach(categoryStats.recentLessons) { lesson in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lesson.title)
                            .font(.labelMedium)
                            .foregroundStyle(.textPrimary)
                        
                        Text(lesson.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.textTertiary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.brandAccent)
                        
                        Text("+\(lesson.xpEarned)")
                            .font(.labelSmall)
                            .foregroundStyle(.textSecondary)
                    }
                }
                .padding(Spacing.sm)
                .background(Color.backgroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CategoryDetailSheet(
        categoryStats: CategoryStats(
            category: .aqeedah,
            completedCount: 5,
            totalCount: 10,
            recentLessons: [
                RecentLesson(
                    id: UUID(),
                    title: "Who is Allah?",
                    completedAt: Date(),
                    xpEarned: 100,
                    score: 85
                ),
                RecentLesson(
                    id: UUID(),
                    title: "Names of Allah",
                    completedAt: Date().addingTimeInterval(-86400),
                    xpEarned: 120,
                    score: 90
                )
            ]
        )
    )
}
