//
//  EngagementScoreCard.swift
//  Sidrat
//
//  Engagement quality indicator for parents (Quick Win #3)
//  Shows 0-100 score with meaningful interpretation
//

import SwiftUI

struct EngagementScoreCard: View {
    let score: Int
    let insights: EngagementInsights
    
    @State private var animatedScore: Double = 0
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack(spacing: Spacing.xs) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundStyle(.brandPrimary)
                
                Text("Engagement Quality")
                    .font(.labelLarge)
                    .foregroundStyle(.textPrimary)
                
                Spacer()
                
                // Info button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDetails.toggle()
                    }
                } label: {
                    Image(systemName: showDetails ? "info.circle.fill" : "info.circle")
                        .font(.body)
                        .foregroundStyle(.textTertiary)
                }
                .buttonStyle(.plain)
            }
            
            // Score display
            HStack(spacing: Spacing.lg) {
                // Circular gauge
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.backgroundSecondary, lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: animatedScore / 100)
                        .stroke(
                            scoreColor,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    // Score text
                    VStack(spacing: Spacing.xxs) {
                        Text("\(Int(animatedScore))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(scoreColor)
                        
                        Text("/ 100")
                            .font(.caption)
                            .foregroundStyle(.textTertiary)
                    }
                }
                
                // Interpretation
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Rating label
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: scoreIcon)
                            .font(.body)
                        Text(scoreLabel)
                            .font(.labelLarge)
                    }
                    .foregroundStyle(scoreColor)
                    
                    // Description
                    Text(scoreDescription)
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Details section (expandable)
            if showDetails {
                detailsSection
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedScore = Double(score)
            }
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Divider()
                .padding(.vertical, Spacing.xxs)
            
            Text("How we calculate this")
                .font(.caption.bold())
                .foregroundStyle(.textTertiary)
                .textCase(.uppercase)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                factorRow(
                    icon: "flame.fill",
                    label: "Consistency",
                    value: "\(insights.consistencyScore)%",
                    description: "Maintains learning streak"
                )
                
                factorRow(
                    icon: "calendar",
                    label: "Frequency",
                    value: "\(insights.frequencyScore)%",
                    description: "Lessons per week"
                )
                
                factorRow(
                    icon: "target",
                    label: "Completion Rate",
                    value: "\(insights.completionScore)%",
                    description: "Finishes what they start"
                )
            }
            
            // Overall interpretation
            if !insights.recommendation.isEmpty {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                    Text(insights.recommendation)
                        .font(.caption)
                }
                .foregroundStyle(.brandAccent)
                .padding(Spacing.sm)
                .background(Color.brandAccent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
            }
        }
    }
    
    // MARK: - Factor Row
    
    private func factorRow(icon: String, label: String, value: String, description: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.brandPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(label)
                        .font(.bodySmall)
                        .foregroundStyle(.textPrimary)
                    
                    Spacer()
                    
                    Text(value)
                        .font(.bodySmall.bold())
                        .foregroundStyle(.brandPrimary)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
    
    // MARK: - Score Styling
    
    private var scoreColor: Color {
        switch score {
        case 80...100: return .success
        case 60..<80: return .brandPrimary
        case 40..<60: return .warning
        default: return .error
        }
    }
    
    private var scoreIcon: String {
        switch score {
        case 80...100: return "star.fill"
        case 60..<80: return "checkmark.circle.fill"
        case 40..<60: return "exclamationmark.circle.fill"
        default: return "xmark.circle.fill"
        }
    }
    
    private var scoreLabel: String {
        switch score {
        case 85...100: return "Excellent"
        case 70..<85: return "Very Good"
        case 55..<70: return "Good"
        case 40..<55: return "Fair"
        default: return "Needs Attention"
        }
    }
    
    private var scoreDescription: String {
        switch score {
        case 85...100: return "Highly engaged and consistent! They're genuinely excited about learning."
        case 70..<85: return "Great engagement! They're making steady progress with good focus."
        case 55..<70: return "Moderate engagement. Consider varying activities to boost interest."
        case 40..<55: return "Low engagement. Try shorter sessions or more interactive content."
        default: return "Very low engagement. They may need more parental support and encouragement."
        }
    }
}

// MARK: - Engagement Insights Model

struct EngagementInsights: Codable {
    let consistencyScore: Int
    let frequencyScore: Int
    let completionScore: Int
    let recommendation: String
    
    init(
        consistencyScore: Int,
        frequencyScore: Int,
        completionScore: Int,
        recommendation: String = ""
    ) {
        self.consistencyScore = consistencyScore
        self.frequencyScore = frequencyScore
        self.completionScore = completionScore
        self.recommendation = recommendation
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.lg) {
        // Excellent engagement
        EngagementScoreCard(
            score: 92,
            insights: EngagementInsights(
                consistencyScore: 95,
                frequencyScore: 90,
                completionScore: 90,
                recommendation: "Keep up the excellent work! Consistent daily practice is building strong habits."
            )
        )
        
        // Good engagement
        EngagementScoreCard(
            score: 68,
            insights: EngagementInsights(
                consistencyScore: 70,
                frequencyScore: 65,
                completionScore: 70,
                recommendation: "Try completing lessons at the same time each day to build consistency."
            )
        )
        
        // Low engagement
        EngagementScoreCard(
            score: 35,
            insights: EngagementInsights(
                consistencyScore: 40,
                frequencyScore: 30,
                completionScore: 35,
                recommendation: "Consider shorter sessions and more parental involvement to boost engagement."
            )
        )
        
        Spacer()
    }
    .padding(Spacing.md)
    .background(Color.backgroundSecondary)
}
