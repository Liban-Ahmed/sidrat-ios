//
//  ThisWeeksFocusCard.swift
//  Sidrat
//
//  Actionable recommendations for parents - "What should I do TODAY?"
//  Shows 1-3 prioritized actions based on child's progress and needs
//

import SwiftUI

struct ThisWeeksFocusCard: View {
    let actions: [PersonalizedAction]
    let onDismiss: ((PersonalizedAction) -> Void)?
    
    init(actions: [PersonalizedAction], onDismiss: ((PersonalizedAction) -> Void)? = nil) {
        self.actions = actions
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack(spacing: Spacing.xs) {
                Image(systemName: "target")
                    .font(.title3)
                    .foregroundStyle(.brandPrimary)
                
                Text("This Week's Focus")
                    .font(.labelLarge)
                    .foregroundStyle(.textPrimary)
                
                Spacer()
                
                // Action count badge
                if !actions.isEmpty {
                    Text("\(actions.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.brandPrimary))
                }
            }
            
            if actions.isEmpty {
                emptyState
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                        actionRow(action, index: index)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Action Row
    
    private func actionRow(_ action: PersonalizedAction, index: Int) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Priority indicator
            priorityBadge(action.priority)
            
            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Title
                Text(action.title)
                    .font(.bodyMedium)
                    .foregroundStyle(.textPrimary)
                
                // Description
                Text(action.description)
                    .font(.bodySmall)
                    .foregroundStyle(.textSecondary)
                    .lineLimit(2)
                
                // Metadata row
                HStack(spacing: Spacing.md) {
                    // Time estimate
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(action.estimatedMinutes) min")
                            .font(.caption)
                    }
                    .foregroundStyle(.textTertiary)
                    
                    // Impact
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text(action.impact)
                            .font(.caption)
                    }
                    .foregroundStyle(.brandAccent)
                }
                .padding(.top, Spacing.xxs)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Dismiss button (if handler provided)
            if let onDismiss = onDismiss {
                Button {
                    withAnimation {
                        onDismiss(action)
                    }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.success)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark as complete")
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(priorityBackgroundColor(action.priority))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .strokeBorder(priorityBorderColor(action.priority), lineWidth: 1)
        )
    }
    
    // MARK: - Priority Badge
    
    private func priorityBadge(_ priority: ActionPriority) -> some View {
        VStack(spacing: Spacing.xxs) {
            ZStack {
                Circle()
                    .fill(priorityColor(priority))
                    .frame(width: 32, height: 32)
                
                Image(systemName: priorityIcon(priority))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text(priorityLabel(priority))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(priorityColor(priority))
                .textCase(.uppercase)
        }
        .frame(width: 50)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(.success)
            
            Text("All caught up!")
                .font(.labelMedium)
                .foregroundStyle(.textPrimary)
            
            Text("No urgent actions needed right now. Keep up the great work!")
                .font(.bodySmall)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
    }
    
    // MARK: - Priority Styling
    
    private func priorityColor(_ priority: ActionPriority) -> Color {
        switch priority {
        case .high: return .error
        case .medium: return .warning
        case .low: return .brandPrimary
        }
    }
    
    private func priorityIcon(_ priority: ActionPriority) -> String {
        switch priority {
        case .high: return "exclamationmark"
        case .medium: return "arrow.up"
        case .low: return "info"
        }
    }
    
    private func priorityLabel(_ priority: ActionPriority) -> String {
        switch priority {
        case .high: return "High"
        case .medium: return "Med"
        case .low: return "Low"
        }
    }
    
    private func priorityBackgroundColor(_ priority: ActionPriority) -> Color {
        switch priority {
        case .high: return Color.error.opacity(0.05)
        case .medium: return Color.warning.opacity(0.05)
        case .low: return Color.brandPrimary.opacity(0.03)
        }
    }
    
    private func priorityBorderColor(_ priority: ActionPriority) -> Color {
        switch priority {
        case .high: return Color.error.opacity(0.2)
        case .medium: return Color.warning.opacity(0.2)
        case .low: return Color.brandPrimary.opacity(0.15)
        }
    }
}

// MARK: - Models

enum ActionPriority: String, Codable {
    case high
    case medium
    case low
}

struct PersonalizedAction: Identifiable, Codable {
    let id: UUID
    let priority: ActionPriority
    let title: String
    let description: String
    let estimatedMinutes: Int
    let impact: String
    let actionType: ActionType
    
    init(
        id: UUID = UUID(),
        priority: ActionPriority,
        title: String,
        description: String,
        estimatedMinutes: Int,
        impact: String,
        actionType: ActionType
    ) {
        self.id = id
        self.priority = priority
        self.title = title
        self.description = description
        self.estimatedMinutes = estimatedMinutes
        self.impact = impact
        self.actionType = actionType
    }
}

enum ActionType: String, Codable {
    case completeLesson
    case reviewStrugglingTopic
    case familyActivity
    case streakMaintenance
    case celebrateMilestone
    case reviewCategory
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.lg) {
        // With actions
        ThisWeeksFocusCard(
            actions: [
                PersonalizedAction(
                    priority: .high,
                    title: "Review Wudu steps together",
                    description: "Zainab got 2/5 questions wrong on the Wudu lesson",
                    estimatedMinutes: 10,
                    impact: "Reinforces 3 concepts",
                    actionType: .reviewStrugglingTopic
                ),
                PersonalizedAction(
                    priority: .medium,
                    title: "Complete this week's family activity",
                    description: "Build on yesterday's Salah lesson with hands-on practice",
                    estimatedMinutes: 15,
                    impact: "Strengthen family bond",
                    actionType: .familyActivity
                ),
                PersonalizedAction(
                    priority: .low,
                    title: "Celebrate 7-day streak achievement",
                    description: "Zainab earned the Week Warrior badge!",
                    estimatedMinutes: 5,
                    impact: "Boost motivation",
                    actionType: .celebrateMilestone
                )
            ],
            onDismiss: { action in
                print("Dismissed: \(action.title)")
            }
        )
        
        // Empty state
        ThisWeeksFocusCard(actions: [])
        
        Spacer()
    }
    .padding(Spacing.md)
    .background(Color.backgroundSecondary)
}
