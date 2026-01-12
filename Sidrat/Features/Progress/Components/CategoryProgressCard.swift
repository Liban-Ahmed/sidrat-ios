//
//  CategoryProgressCard.swift
//  Sidrat
//
//  Category progress card for Parent Progress Dashboard (US-304)
//  Shows category icon, name, progress bar, and completion percentage
//

import SwiftUI

struct CategoryProgressCard: View {
    let categoryStats: CategoryStats
    let onTap: (() -> Void)?
    
    @State private var isPressed = false
    @State private var animatedProgress: CGFloat = 0
    
    init(categoryStats: CategoryStats, onTap: (() -> Void)? = nil) {
        self.categoryStats = categoryStats
        self.onTap = onTap
    }
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            cardContent
        }
        .buttonStyle(PressableCardStyle())
        .disabled(onTap == nil)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedProgress = categoryStats.completionPercentage
            }
        }
    }
    
    // MARK: - Card Content
    
    private var cardContent: some View {
        HStack(spacing: Spacing.md) {
            // Category icon
            categoryIcon
            
            // Category info and progress
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Category name and count
                HStack {
                    Text(categoryStats.category.rawValue)
                        .font(.labelMedium)
                        .foregroundStyle(.textPrimary)
                    
                    Spacer()
                    
                    Text("\(categoryStats.completedCount)/\(categoryStats.totalCount)")
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                }
                
                // Progress bar
                progressBar
                
                // Status text
                statusText
            }
            
            // Chevron if tappable
            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.bodySmall)
                    .foregroundStyle(.textTertiary)
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .cardShadow()
    }
    
    // MARK: - Category Icon
    
    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(categoryStats.category.color.opacity(0.15))
                .frame(width: 44, height: 44)
            
            Image(systemName: categoryStats.category.iconName)
                .font(.title3)
                .foregroundStyle(categoryStats.category.color)
        }
        .accessibilityHidden(true)
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.backgroundTertiary)
                    .frame(height: 6)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(progressGradient)
                    .frame(width: geometry.size.width * animatedProgress, height: 6)
            }
        }
        .frame(height: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(categoryStats.category.rawValue) progress")
        .accessibilityValue(categoryStats.formattedPercentage)
    }
    
    // MARK: - Progress Gradient
    
    private var progressGradient: LinearGradient {
        if categoryStats.isComplete {
            return LinearGradient(
                colors: [.success, .brandSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [categoryStats.category.color, categoryStats.category.color.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    // MARK: - Status Text
    
    private var statusText: some View {
        HStack {
            if categoryStats.isComplete {
                Label("Complete!", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.success)
            } else if categoryStats.hasProgress {
                Text("\(categoryStats.remainingCount) lesson\(categoryStats.remainingCount == 1 ? "" : "s") remaining")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            } else {
                Text("Not started")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
            
            Spacer()
            
            Text(categoryStats.formattedPercentage)
                .font(.labelSmall)
                .foregroundStyle(categoryStats.isComplete ? .success : .textSecondary)
        }
    }
}

// MARK: - Pressable Card Style

private struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("With Progress") {
    VStack(spacing: Spacing.md) {
        CategoryProgressCard(
            categoryStats: CategoryStats(
                category: .aqeedah,
                completedCount: 3,
                totalCount: 5,
                recentLessons: []
            )
        ) {
            print("Tapped Aqeedah")
        }
        
        CategoryProgressCard(
            categoryStats: CategoryStats(
                category: .salah,
                completedCount: 5,
                totalCount: 5,
                recentLessons: []
            )
        )
        
        CategoryProgressCard(
            categoryStats: CategoryStats(
                category: .quran,
                completedCount: 0,
                totalCount: 8,
                recentLessons: []
            )
        )
    }
    .padding()
    .background(Color.backgroundSecondary)
}
