//
//  Components.swift
//  Sidrat
//
//  Reusable UI components
//

import SwiftUI

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.labelLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(LinearGradient.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.labelLarge)
            .foregroundStyle(.primaryGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.primaryGreen.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.primaryGreen.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Icon Badge

struct IconBadge: View {
    let icon: String
    let color: Color
    let size: Size
    
    enum Size {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 48
            case .large: return 64
            }
        }
        
        var iconSize: Font {
            switch self {
            case .small: return .body
            case .medium: return .title3
            case .large: return .title
            }
        }
    }
    
    init(_ icon: String, color: Color, size: Size = .medium) {
        self.icon = icon
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: size.dimension, height: size.dimension)
            
            Image(systemName: icon)
                .font(size.iconSize)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    
    init(progress: Double, lineWidth: CGFloat = 4, color: Color = .primaryGreen) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

// MARK: - XP Badge

struct XPBadge: View {
    let xp: Int
    
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "star.fill")
                .foregroundStyle(.secondaryGold)
            
            Text("\(xp) XP")
                .font(.labelSmall)
                .foregroundStyle(.textPrimary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(Color.secondaryGold.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Enhanced Streak Badge (US-303)

/// Enhanced streak badge with freeze indicator and optional tap action
struct EnhancedStreakBadge: View {
    let streak: Int
    let hasFreeze: Bool
    let hoursRemaining: Int?
    let onTap: (() -> Void)?
    
    init(
        streak: Int,
        hasFreeze: Bool = false,
        hoursRemaining: Int? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.streak = streak
        self.hasFreeze = hasFreeze
        self.hoursRemaining = hoursRemaining
        self.onTap = onTap
    }
    
    var body: some View {
        Group {
            if let action = onTap {
                Button(action: action) {
                    badgeContent
                }
                .buttonStyle(.plain)
            } else {
                badgeContent
            }
        }
    }
    
    private var badgeContent: some View {
        VStack(spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.brandAccent)
                
                Text("\(streak)")
                    .font(.labelLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(.textPrimary)
                
                if hasFreeze {
                    Image(systemName: "snowflake")
                        .font(.caption)
                        .foregroundStyle(.brandPrimary)
                }
            }
            
            if let hours = hoursRemaining, hours > 0, hours <= 3 {
                Text("\(hours)h left")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.brandAccent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }
    
    private var accessibilityText: String {
        var text = "Current streak: \(streak) day"
        if streak != 1 { text += "s" }
        if hasFreeze {
            text += ", freeze available"
        }
        if let hours = hoursRemaining, hours > 0, hours <= 3 {
            text += ", \(hours) hours remaining today"
        }
        return text
    }
}

// MARK: - Streak Milestone Progress (US-303)

/// Progress bar showing distance to next streak milestone
struct StreakMilestoneProgress: View {
    let currentStreak: Int
    let nextMilestone: StreakMilestone?
    
    var progress: Double {
        guard let milestone = nextMilestone else { return 1.0 }
        let previousMilestone = getPreviousMilestone(for: milestone.days)
        let range = Double(milestone.days - previousMilestone)
        let current = Double(currentStreak - previousMilestone)
        return min(max(current / range, 0), 1.0)
    }
    
    var body: some View {
        if let milestone = nextMilestone {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(milestoneText)
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                    
                    Spacer()
                    
                    Text("\(daysRemaining)")
                        .font(.labelMedium)
                        .foregroundStyle(.brandPrimary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: CornerRadius.small)
                            .fill(Color.backgroundSecondary)
                            .frame(height: 8)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: CornerRadius.small)
                            .fill(
                                LinearGradient(
                                    colors: [.brandPrimary, .brandSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                        
                        // Flame icon at progress position
                        if progress > 0.05 {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(.brandAccent)
                                .offset(x: (geometry.size.width * progress) - 8)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                        }
                    }
                }
                .frame(height: 8)
            }
            .padding(Spacing.md)
            .background(Color.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .cardShadow()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Progress to \(milestone.achievementType.title): \(daysRemaining) to next milestone")
        } else {
            // All milestones achieved
            HStack(spacing: Spacing.sm) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.brandAccent)
                
                Text("All streak milestones achieved!")
                    .font(.bodyMedium)
                    .foregroundStyle(.textPrimary)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .background(Color.success.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
    }
    
    private var milestoneText: String {
        guard let milestone = nextMilestone else { return "" }
        return "Next: \(milestone.achievementType.title)"
    }
    
    private var daysRemaining: String {
        guard let milestone = nextMilestone else { return "" }
        let remaining = milestone.days - currentStreak
        return "\(remaining) day\(remaining == 1 ? "" : "s")"
    }
    
    private func getPreviousMilestone(for days: Int) -> Int {
        let milestones = [0, 3, 7, 30, 100]
        for (index, milestone) in milestones.enumerated() {
            if milestone >= days && index > 0 {
                return milestones[index - 1]
            }
        }
        return milestones.last ?? 0
    }
}

// MARK: - Lesson Card

struct LessonCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let duration: Int
    let xp: Int
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                IconBadge(icon, color: color, size: .large)
                
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(.labelLarge)
                        .foregroundStyle(.textPrimary)
                    
                    Text(description)
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                        .lineLimit(2)
                    
                    HStack(spacing: Spacing.sm) {
                        Label("\(duration) min", systemImage: "clock")
                        Label("\(xp) XP", systemImage: "star.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                }
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.primaryGreen)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.textTertiary)
                }
            }
            .padding()
            .background(Color.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.textTertiary)
            
            Text(title)
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            Text(message)
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle, let action {
                PrimaryButton(actionTitle, action: action)
                    .padding(.horizontal, Spacing.xl)
            }
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Previews

#Preview("Buttons") {
    VStack(spacing: 20) {
        PrimaryButton("Get Started", icon: "arrow.right") {}
        SecondaryButton("Learn More", icon: "book") {}
    }
    .padding()
}

#Preview("Components") {
    VStack(spacing: 20) {
        HStack {
            IconBadge("star.fill", color: .secondaryGold, size: .small)
            IconBadge("star.fill", color: .secondaryGold, size: .medium)
            IconBadge("star.fill", color: .secondaryGold, size: .large)
        }
        
        XPBadge(xp: 100)
        
        ProgressRing(progress: 0.7)
            .frame(width: 60, height: 60)
    }
    .padding()
}
