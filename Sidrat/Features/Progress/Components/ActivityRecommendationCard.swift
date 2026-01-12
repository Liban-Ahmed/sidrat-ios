//
//  ActivityRecommendationCard.swift
//  Sidrat
//
//  Activity recommendation card for Parent Progress Dashboard (US-304)
//  Shows suggested family activities with relevance tags
//

import SwiftUI

struct ActivityRecommendationCard: View {
    let recommendation: ActivityRecommendation
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(RecommendationCardStyle())
    }
    
    // MARK: - Card Content
    
    private var cardContent: some View {
        HStack(spacing: Spacing.md) {
            // Activity icon
            activityIcon
            
            // Activity details
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Title
                Text(recommendation.activity.title)
                    .font(.labelMedium)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(2)
                
                // Duration and relevance
                HStack(spacing: Spacing.sm) {
                    // Duration
                    Label("\(recommendation.activity.durationMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                    
                    // Relevance tag
                    relevanceTag
                }
                
                // Reason
                Text(recommendation.relevanceReason)
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundStyle(.brandPrimary)
        }
        .padding(Spacing.md)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Activity Icon
    
    private var activityIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(
                    LinearGradient(
                        colors: [.brandSecondary.opacity(0.2), .brandPrimary.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
            
            Image(systemName: activityIconName)
                .font(.title2)
                .foregroundStyle(.brandSecondary)
        }
        .accessibilityHidden(true)
    }
    
    // MARK: - Relevance Tag
    
    private var relevanceTag: some View {
        Text(relevanceLabel)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(relevanceColor)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(relevanceColor.opacity(0.12))
            .clipShape(Capsule())
    }
    
    // MARK: - Computed Properties
    
    /// Icon based on the related category
    private var activityIconName: String {
        switch recommendation.activity.relatedCategory {
        case .aqeedah:
            return "heart.fill"
        case .salah:
            return "hands.sparkles"
        case .wudu:
            return "drop.fill"
        case .quran:
            return "book.fill"
        case .adab:
            return "star.fill"
        case .seerah:
            return "person.fill"
        case .duaa:
            return "bubble.left.fill"
        case .stories:
            return "book.closed.fill"
        }
    }
    
    private var relevanceLabel: String {
        if recommendation.relevanceScore >= 0.8 {
            return "Perfect Match"
        } else if recommendation.relevanceScore >= 0.6 {
            return "Great Fit"
        } else if recommendation.relevanceScore >= 0.4 {
            return "Good Option"
        } else {
            return "Try This"
        }
    }
    
    private var relevanceColor: Color {
        if recommendation.relevanceScore >= 0.8 {
            return .success
        } else if recommendation.relevanceScore >= 0.6 {
            return .brandPrimary
        } else if recommendation.relevanceScore >= 0.4 {
            return .brandSecondary
        } else {
            return .textSecondary
        }
    }
}

// MARK: - Button Style

private struct RecommendationCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Activity Recommendations Section

/// Section header and list of activity recommendations
struct ActivityRecommendationsSection: View {
    let recommendations: [ActivityRecommendation]
    let onActivityTap: (FamilyActivity) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            HStack {
                Image(systemName: "heart.text.square")
                    .font(.title3)
                    .foregroundStyle(.brandSecondary)
                
                Text("Suggested Activities")
                    .font(.labelLarge)
                    .foregroundStyle(.textPrimary)
                
                Spacer()
                
                Text("\(recommendations.count) available")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            
            // Activity cards
            if recommendations.isEmpty {
                emptyState
            } else {
                ForEach(recommendations.prefix(3)) { recommendation in
                    ActivityRecommendationCard(recommendation: recommendation) {
                        onActivityTap(recommendation.activity)
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        HStack {
            Spacer()
            
            VStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.success)
                
                Text("All caught up!")
                    .font(.labelMedium)
                    .foregroundStyle(.textPrimary)
                
                Text("No new activity suggestions right now")
                    .font(.bodySmall)
                    .foregroundStyle(.textSecondary)
            }
            .padding(Spacing.xl)
            
            Spacer()
        }
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

// MARK: - Preview

#Preview("Recommendation Card") {
    let sampleActivity = FamilyActivity(
        title: "The Beautiful Names of Allah",
        activityDescription: "Learn about Allah's names together",
        instructions: ["Step 1", "Step 2"],
        durationMinutes: 20,
        weekNumber: 1,
        relatedCategory: .aqeedah,
        parentTips: ["Be patient"],
        conversationPrompts: ["Why is this important?"]
    )
    
    VStack(spacing: Spacing.md) {
        ActivityRecommendationCard(
            recommendation: ActivityRecommendation(
                activity: sampleActivity,
                relevanceScore: 0.9,
                relevanceReason: "Reinforces recent Aqeedah lessons"
            )
        ) {
            print("Tapped activity")
        }
        
        ActivityRecommendationCard(
            recommendation: ActivityRecommendation(
                activity: sampleActivity,
                relevanceScore: 0.5,
                relevanceReason: "Good for family bonding"
            )
        ) {
            print("Tapped activity")
        }
    }
    .padding()
    .background(Color.backgroundSecondary)
}
