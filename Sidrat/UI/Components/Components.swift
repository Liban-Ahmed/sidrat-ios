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
