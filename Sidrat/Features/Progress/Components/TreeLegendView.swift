//
//  TreeLegendView.swift
//  Sidrat
//
//  Explains tree colors and growth states
//

import SwiftUI

struct TreeLegendView: View {
    let growthState: TreeGrowthState
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Your Learning Tree")
                .font(.labelMedium)
                .foregroundStyle(.textSecondary)
            
            HStack(spacing: Spacing.sm) {
                // Growth state indicator
                Circle()
                    .fill(growthState.treeColor)
                    .frame(width: 12, height: 12)
                
                Text(growthState.description)
                    .font(.bodySmall)
                    .foregroundStyle(.textSecondary)
                
                Spacer()
            }
        }
        .padding(Spacing.md)
        .background(Color.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        TreeLegendView(growthState: .skeleton)
        TreeLegendView(growthState: .sprouting)
        TreeLegendView(growthState: .growing)
        TreeLegendView(growthState: .flourishing)
    }
    .padding()
    .background(Color.backgroundSecondary)
}
