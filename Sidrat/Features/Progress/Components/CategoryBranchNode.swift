//
//  CategoryBranchNode.swift
//  Sidrat
//
//  Individual lesson node displayed on tree branch
//

import SwiftUI

struct CategoryBranchNode: View {
    let node: TreeNode
    let position: CGPoint
    let onTap: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: Spacing.xxs) {
                // Category icon with completion indicator
                ZStack {
                    // Icon badge
                    IconBadge(
                        node.category.icon,
                        color: node.isCompleted ? node.category.color : .textTertiary,
                        size: .medium
                    )
                    
                    // Completion checkmark
                    if node.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.labelSmall)
                            .foregroundStyle(.success)
                            .background(
                                Circle()
                                    .fill(Color.backgroundPrimary)
                                    .frame(width: 18, height: 18)
                            )
                            .offset(x: 16, y: -16)
                    }
                }
                
                // Category label
                Text(node.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(node.isCompleted ? .textPrimary : .textTertiary)
                    .lineLimit(1)
            }
            .padding(Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(Color.surfaceSecondary)
                    .shadow(
                        color: node.isCompleted ? node.category.color.opacity(0.3) : .clear,
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
        .scaleEffect(scale)
        .position(position)
        .accessibilityLabel("\(node.category.rawValue) lesson")
        .accessibilityHint(node.isCompleted ? "Completed" : "Not completed yet")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        // Call tap handler immediately to avoid gesture timeout
        onTap()
        
        // Haptic feedback (non-blocking)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Scale animation (non-blocking)
        if !reduceMotion {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.2
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.backgroundSecondary.ignoresSafeArea()
        
        VStack(spacing: Spacing.xl) {
            // Completed node
            CategoryBranchNode(
                node: TreeNode(
                    id: UUID(),
                    position: .left,
                    category: .aqeedah,
                    lessonId: UUID(),
                    lessonTitle: "Who is Allah?",
                    isCompleted: true,
                    branchLevel: 0,
                    weekNumber: 1
                ),
                position: CGPoint(x: 100, y: 50),
                onTap: { print("Tapped completed node") }
            )
            
            // Incomplete node
            CategoryBranchNode(
                node: TreeNode(
                    id: UUID(),
                    position: .right,
                    category: .salah,
                    lessonId: UUID(),
                    lessonTitle: "How to Pray",
                    isCompleted: false,
                    branchLevel: 1,
                    weekNumber: 1
                ),
                position: CGPoint(x: 250, y: 50),
                onTap: { print("Tapped incomplete node") }
            )
        }
    }
    .frame(height: 200)
}
