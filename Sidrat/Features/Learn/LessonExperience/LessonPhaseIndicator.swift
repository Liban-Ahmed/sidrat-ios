//
//  LessonPhaseIndicator.swift
//  Sidrat
//
//  Visual progress indicator showing the 4 phases of a lesson
//  Hook → Teach → Practice → Reward
//

import SwiftUI

// MARK: - Phase Indicator

/// Visual indicator showing lesson phase progress
struct LessonPhaseIndicator: View {
    let currentPhase: LessonPhase
    let progress: LessonPhaseProgress
    
    @Environment(\.isReduceMotionEnabled) private var reduceMotion
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(LessonPhase.allCases) { phase in
                PhaseNode(
                    phase: phase,
                    state: stateForPhase(phase),
                    isLast: phase == .reward
                )
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(Color.surfaceSecondary)
        )
    }
    
    private func stateForPhase(_ phase: LessonPhase) -> PhaseNodeState {
        if phase.rawValue < currentPhase.rawValue {
            return .completed
        } else if phase == currentPhase {
            return .current
        } else {
            return .upcoming
        }
    }
}

// MARK: - Phase Node State

private enum PhaseNodeState {
    case completed
    case current
    case upcoming
    
    var opacity: Double {
        switch self {
        case .completed, .current: return 1.0
        case .upcoming: return 0.4
        }
    }
    
    var scale: CGFloat {
        switch self {
        case .current: return 1.15
        case .completed, .upcoming: return 1.0
        }
    }
}

// MARK: - Phase Node

private struct PhaseNode: View {
    let phase: LessonPhase
    let state: PhaseNodeState
    let isLast: Bool
    
    @Environment(\.isReduceMotionEnabled) private var reduceMotion
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Phase circle with icon
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)
                    .shadow(
                        color: state == .current ? phase.color.opacity(0.4) : .clear,
                        radius: 6,
                        y: 2
                    )
                
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .scaleEffect(reduceMotion ? 1.0 : (state == .current ? (isAnimating ? 1.1 : 1.0) : 1.0))
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .accessibilityLabel("\(phase.title), \(accessibilityState)")
            
            // Connector line (except for last phase)
            if !isLast {
                Rectangle()
                    .fill(connectorColor)
                    .frame(width: 24, height: 3)
                    .clipShape(Capsule())
            }
        }
        .onAppear {
            if state == .current && !reduceMotion {
                isAnimating = true
            }
        }
        .onChange(of: state) { _, newState in
            isAnimating = newState == .current && !reduceMotion
        }
    }
    
    private var backgroundColor: Color {
        switch state {
        case .completed:
            return phase.color
        case .current:
            return phase.color
        case .upcoming:
            return Color.surfaceTertiary
        }
    }
    
    private var iconName: String {
        switch state {
        case .completed:
            return "checkmark"
        case .current, .upcoming:
            return phase.icon
        }
    }
    
    private var iconColor: Color {
        switch state {
        case .completed, .current:
            return .white
        case .upcoming:
            return .textSecondary
        }
    }
    
    private var connectorColor: Color {
        switch state {
        case .completed:
            return phase.color
        case .current, .upcoming:
            return Color.surfaceTertiary
        }
    }
    
    private var accessibilityState: String {
        switch state {
        case .completed: return "completed"
        case .current: return "in progress"
        case .upcoming: return "not started"
        }
    }
}

// MARK: - Compact Phase Indicator

/// Compact version of phase indicator for smaller spaces
struct CompactPhaseIndicator: View {
    let currentPhase: LessonPhase
    let overallProgress: Double
    
    var body: some View {
        VStack(spacing: Spacing.xxs) {
            // Phase label
            Text(currentPhase.title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.textSecondary)
                .tracking(0.5)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.surfaceTertiary)
                    
                    // Progress
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [currentPhase.color, currentPhase.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * overallProgress)
                }
            }
            .frame(height: 6)
            
            // Phase dots
            HStack(spacing: Spacing.xs) {
                ForEach(LessonPhase.allCases) { phase in
                    Circle()
                        .fill(dotColor(for: phase))
                        .frame(width: 8, height: 8)
                        .scaleEffect(phase == currentPhase ? 1.2 : 1.0)
                }
            }
        }
    }
    
    private func dotColor(for phase: LessonPhase) -> Color {
        if phase.rawValue < currentPhase.rawValue {
            return phase.color
        } else if phase == currentPhase {
            return currentPhase.color
        } else {
            return .surfaceTertiary
        }
    }
}

// MARK: - Phase Title View

/// Displays the current phase title with animation
struct PhaseTitle: View {
    let phase: LessonPhase
    let subtitle: String?
    
    @Environment(\.isReduceMotionEnabled) private var reduceMotion
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: phase.icon)
                    .font(.headline)
                    .foregroundStyle(phase.color)
                
                Text(phase.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.textPrimary)
            }
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : 10)
            
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .offset(y: isVisible ? 0 : 5)
            }
        }
        .onAppear {
            guard !reduceMotion else {
                isVisible = true
                return
            }
            
            withAnimation(.easeOut(duration: 0.4)) {
                isVisible = true
            }
        }
        .onChange(of: phase) { _, _ in
            isVisible = false
            
            guard !reduceMotion else {
                isVisible = true
                return
            }
            
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Phase Indicator") {
    VStack(spacing: 40) {
        ForEach(LessonPhase.allCases) { phase in
            LessonPhaseIndicator(
                currentPhase: phase,
                progress: LessonPhaseProgress(currentPhase: phase)
            )
        }
    }
    .padding()
}

#Preview("Compact Indicator") {
    VStack(spacing: 20) {
        CompactPhaseIndicator(currentPhase: .hook, overallProgress: 0.1)
        CompactPhaseIndicator(currentPhase: .teach, overallProgress: 0.35)
        CompactPhaseIndicator(currentPhase: .practice, overallProgress: 0.65)
        CompactPhaseIndicator(currentPhase: .reward, overallProgress: 0.95)
    }
    .padding()
}
