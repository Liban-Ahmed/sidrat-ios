//
//  PhaseIndicator.swift
//  Sidrat
//
//  Visual 4-phase progress indicator for lesson player
//  Specs: 4 circles, 12pt diameter, 8pt spacing
//  Current phase: brandPrimary fill with glow
//  Completed phases: checkmark
//

import SwiftUI

// MARK: - Phase Indicator

/// Horizontal 4-dot phase indicator showing lesson progress
struct PhaseIndicator: View {
    let currentPhase: LessonPlayerViewModel.Phase
    let completedPhases: Set<LessonPlayerViewModel.Phase>
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // Design specifications
    private let circleSize: CGFloat = 12
    private let circleSpacing: CGFloat = 8
    private let connectorLength: CGFloat = 24
    private let connectorHeight: CGFloat = 2
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(LessonPlayerViewModel.Phase.allCases) { phase in
                PhaseCircle(
                    phase: phase,
                    state: stateForPhase(phase),
                    reduceMotion: reduceMotion
                )
                
                // Connector line between phases
                if phase != .reward {
                    PhaseConnector(
                        isCompleted: completedPhases.contains(phase),
                        currentPhaseIndex: currentPhase.rawValue,
                        phaseIndex: phase.rawValue
                    )
                }
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
    
    // MARK: - State Determination
    
    private func stateForPhase(_ phase: LessonPlayerViewModel.Phase) -> PhaseState {
        if completedPhases.contains(phase) {
            return .completed
        } else if phase == currentPhase {
            return .current
        } else {
            return .upcoming
        }
    }
    
    private var accessibilityDescription: String {
        let phaseNames = LessonPlayerViewModel.Phase.allCases.map { phase -> String in
            let state: String
            if completedPhases.contains(phase) {
                state = "completed"
            } else if phase == currentPhase {
                state = "current"
            } else {
                state = "upcoming"
            }
            return "\(phase.title): \(state)"
        }
        return "Lesson progress: \(phaseNames.joined(separator: ", "))"
    }
}

// MARK: - Phase State

private enum PhaseState {
    case completed
    case current
    case upcoming
    
    var backgroundColor: Color {
        switch self {
        case .completed: return .brandSecondary
        case .current: return .brandPrimary
        case .upcoming: return .surfaceTertiary
        }
    }
    
    var iconColor: Color {
        switch self {
        case .completed, .current: return .white
        case .upcoming: return .textTertiary
        }
    }
    
    var showGlow: Bool {
        self == .current
    }
}

// MARK: - Phase Circle

private struct PhaseCircle: View {
    let phase: LessonPlayerViewModel.Phase
    let state: PhaseState
    let reduceMotion: Bool
    
    @State private var isPulsing = false
    
    private let circleSize: CGFloat = 12
    
    var body: some View {
        ZStack {
            // Glow effect for current phase
            if state.showGlow && !reduceMotion {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.3))
                    .frame(width: circleSize + 8, height: circleSize + 8)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0.5 : 0.8)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }
            
            // Main circle
            Circle()
                .fill(state.backgroundColor)
                .frame(width: circleSize, height: circleSize)
                .shadow(
                    color: state.showGlow ? Color.brandPrimary.opacity(0.4) : .clear,
                    radius: 4,
                    y: 1
                )
            
            // Checkmark for completed phases
            if state == .completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(state.iconColor)
            }
        }
        .onAppear {
            if state == .current && !reduceMotion {
                isPulsing = true
            }
        }
        .onChange(of: state) { _, newState in
            isPulsing = newState == .current && !reduceMotion
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Phase Connector

private struct PhaseConnector: View {
    let isCompleted: Bool
    let currentPhaseIndex: Int
    let phaseIndex: Int
    
    private let connectorLength: CGFloat = 24
    private let connectorHeight: CGFloat = 2
    
    private var fillPercentage: CGFloat {
        if isCompleted {
            return 1.0
        } else if currentPhaseIndex == phaseIndex {
            return 0.5 // Partially filled when on this phase
        } else {
            return 0.0
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(Color.surfaceTertiary)
                    .frame(width: connectorLength, height: connectorHeight)
                
                // Progress fill
                Capsule()
                    .fill(Color.brandSecondary)
                    .frame(width: connectorLength * fillPercentage, height: connectorHeight)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: fillPercentage)
            }
        }
        .frame(width: connectorLength, height: connectorHeight)
        .padding(.horizontal, 8)
    }
}

// MARK: - Compact Phase Indicator

/// A more compact version of the phase indicator for smaller spaces
struct CompactPhaseIndicator: View {
    let currentPhase: LessonPlayerViewModel.Phase
    let completedPhases: Set<LessonPlayerViewModel.Phase>
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let dotSize: CGFloat = 8
    private let dotSpacing: CGFloat = 6
    
    var body: some View {
        HStack(spacing: dotSpacing) {
            ForEach(LessonPlayerViewModel.Phase.allCases) { phase in
                Circle()
                    .fill(fillColor(for: phase))
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(phase == currentPhase ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: currentPhase)
            }
        }
    }
    
    private func fillColor(for phase: LessonPlayerViewModel.Phase) -> Color {
        if completedPhases.contains(phase) {
            return .brandSecondary
        } else if phase == currentPhase {
            return .brandPrimary
        } else {
            return .surfaceTertiary
        }
    }
}

// MARK: - Detailed Phase Indicator

/// A larger phase indicator with labels for each phase
struct DetailedPhaseIndicator: View {
    let currentPhase: LessonPlayerViewModel.Phase
    let completedPhases: Set<LessonPlayerViewModel.Phase>
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(LessonPlayerViewModel.Phase.allCases) { phase in
                VStack(spacing: Spacing.xxs) {
                    // Phase icon
                    ZStack {
                        Circle()
                            .fill(backgroundColor(for: phase))
                            .frame(width: 36, height: 36)
                            .shadow(
                                color: phase == currentPhase ? phase.color.opacity(0.4) : .clear,
                                radius: 6,
                                y: 2
                            )
                        
                        if completedPhases.contains(phase) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: phase.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(iconColor(for: phase))
                        }
                    }
                    
                    // Phase label
                    Text(phase.title)
                        .font(.caption2)
                        .foregroundStyle(labelColor(for: phase))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                
                // Connector
                if phase != .reward {
                    Rectangle()
                        .fill(connectorColor(after: phase))
                        .frame(height: 2)
                        .frame(maxWidth: 20)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }
    
    private func backgroundColor(for phase: LessonPlayerViewModel.Phase) -> Color {
        if completedPhases.contains(phase) {
            return phase.color
        } else if phase == currentPhase {
            return phase.color
        } else {
            return .surfaceTertiary
        }
    }
    
    private func iconColor(for phase: LessonPlayerViewModel.Phase) -> Color {
        if completedPhases.contains(phase) || phase == currentPhase {
            return .white
        } else {
            return .textTertiary
        }
    }
    
    private func labelColor(for phase: LessonPlayerViewModel.Phase) -> Color {
        if completedPhases.contains(phase) || phase == currentPhase {
            return .textPrimary
        } else {
            return .textTertiary
        }
    }
    
    private func connectorColor(after phase: LessonPlayerViewModel.Phase) -> Color {
        if completedPhases.contains(phase) {
            return phase.color
        } else {
            return .surfaceTertiary
        }
    }
}

// MARK: - Preview

#Preview("Phase Indicator - Start") {
    VStack(spacing: 40) {
        PhaseIndicator(
            currentPhase: .hook,
            completedPhases: []
        )
        
        CompactPhaseIndicator(
            currentPhase: .hook,
            completedPhases: []
        )
        
        DetailedPhaseIndicator(
            currentPhase: .hook,
            completedPhases: []
        )
    }
    .padding()
    .background(Color.surfacePrimary)
}

#Preview("Phase Indicator - Practice") {
    VStack(spacing: 40) {
        PhaseIndicator(
            currentPhase: .practice,
            completedPhases: [.hook, .teach]
        )
        
        CompactPhaseIndicator(
            currentPhase: .practice,
            completedPhases: [.hook, .teach]
        )
        
        DetailedPhaseIndicator(
            currentPhase: .practice,
            completedPhases: [.hook, .teach]
        )
    }
    .padding()
    .background(Color.surfacePrimary)
}
