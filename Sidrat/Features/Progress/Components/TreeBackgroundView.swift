//
//  TreeBackgroundView.swift
//  Sidrat
//
//  Draws the tree trunk and branches using Canvas
//

import SwiftUI

struct TreeBackgroundView: View {
    let growthState: TreeGrowthState
    let appearProgress: Double
    let treeHeight: CGFloat
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cachedTrunkPath: Path?
    @State private var cachedSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw root system at base
                drawRoots(context: context, size: size)
                
                // Draw cached trunk with taper and texture
                drawCachedTrunk(context: context, size: size)
                
                // Draw bark texture details
                if growthState.detailLevel > 0.4 {
                    drawBarkTexture(context: context, size: size)
                }
                
                // Draw branches extending left and right
                drawBranches(context: context, size: size)
            }
            .frame(height: treeHeight)
            .opacity(appearProgress)
            .animation(reduceMotion ? .none : .easeOut(duration: 1.0), value: appearProgress)
            .onChange(of: geometry.size) { oldSize, newSize in
                // Update cache when size changes
                if cachedSize != newSize {
                    cachedTrunkPath = createTrunkPath(size: newSize)
                    cachedSize = newSize
                }
            }
            .onAppear {
                // Initial path creation
                if cachedTrunkPath == nil {
                    cachedTrunkPath = createTrunkPath(size: geometry.size)
                    cachedSize = geometry.size
                }
            }
        }
        .frame(height: treeHeight)
    }
    
    // MARK: - Drawing Methods
    
    private func createTrunkPath(size: CGSize) -> Path {
        let centerX = size.width / 2
        
        // Trunk width tapers from wide base to narrow top
        let baseWidth = 20.0 * growthState.detailLevel
        let topWidth = 6.0 * growthState.detailLevel
        
        // Create path for trunk using multiple segments for gradual taper
        let segments = 20
        var trunkPath = Path()
        
        for i in 0...segments {
            let progress = CGFloat(i) / CGFloat(segments)
            let yPosition = progress * (size.height - 50) // Leave space for roots
            
            // Calculate width at this point (linear taper)
            let width = baseWidth - (baseWidth - topWidth) * progress
            
            // Add slight curve for organic feel
            let xOffset = sin(progress * .pi * 2) * 3
            let x = centerX + xOffset
            
            if i == 0 {
                // Start with left edge of trunk base
                trunkPath.move(to: CGPoint(x: x - width / 2, y: yPosition))
            }
            
            // Draw left edge
            trunkPath.addLine(to: CGPoint(x: x - width / 2, y: yPosition))
        }
        
        // Complete the path by drawing back up the right side
        for i in stride(from: segments, through: 0, by: -1) {
            let progress = CGFloat(i) / CGFloat(segments)
            let yPosition = progress * (size.height - 50)
            let width = baseWidth - (baseWidth - topWidth) * progress
            let xOffset = sin(progress * .pi * 2) * 3
            let x = centerX + xOffset
            
            trunkPath.addLine(to: CGPoint(x: x + width / 2, y: yPosition))
        }
        
        trunkPath.closeSubpath()
        return trunkPath
    }
    
    private func drawCachedTrunk(context: GraphicsContext, size: CGSize) {
        // Use cached path if available, otherwise draw directly
        if let path = cachedTrunkPath {
            // Fill the trunk
            context.fill(path, with: .color(growthState.treeColor))
            
            // Add subtle outline
            context.stroke(
                path,
                with: .color(growthState.treeColor.opacity(0.8)),
                style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
            )
        } else {
            // Fallback to direct drawing if cache not ready
            drawTrunk(context: context, size: size)
        }
    }
    
    private func drawRoots(context: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2
        let rootStartY = size.height - 50 // Start roots near bottom
        let rootWidth = 3.0 * growthState.detailLevel
        let rootColor = growthState.treeColor.opacity(0.7)
        
        // Draw 3 main roots spreading from base
        let rootConfigs: [(angle: CGFloat, length: CGFloat)] = [
            (-0.5, 40), // Left root
            (0.0, 30),  // Center root
            (0.5, 40)   // Right root
        ]
        
        for config in rootConfigs {
            var rootPath = Path()
            rootPath.move(to: CGPoint(x: centerX, y: rootStartY))
            
            // Create curved root going down and out
            let endX = centerX + (config.angle * 60)
            let endY = size.height
            let controlX = centerX + (config.angle * 30)
            let controlY = rootStartY + config.length * 0.7
            
            rootPath.addQuadCurve(
                to: CGPoint(x: endX, y: endY),
                control: CGPoint(x: controlX, y: controlY)
            )
            
            context.stroke(
                rootPath,
                with: .color(rootColor),
                style: StrokeStyle(lineWidth: rootWidth, lineCap: .round, lineJoin: .round)
            )
        }
    }
    
    private func drawTrunk(context: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2
        
        // Trunk width tapers from wide base to narrow top
        let baseWidth = 20.0 * growthState.detailLevel
        let topWidth = 6.0 * growthState.detailLevel
        
        // Create path for trunk using multiple segments for gradual taper
        let segments = 20
        var trunkPath = Path()
        
        for i in 0...segments {
            let progress = CGFloat(i) / CGFloat(segments)
            let yPosition = progress * (size.height - 50) // Leave space for roots
            
            // Calculate width at this point (linear taper)
            let width = baseWidth - (baseWidth - topWidth) * progress
            
            // Add slight curve for organic feel
            let xOffset = sin(progress * .pi * 2) * 3
            let x = centerX + xOffset
            
            if i == 0 {
                // Start with left edge of trunk base
                trunkPath.move(to: CGPoint(x: x - width / 2, y: yPosition))
            }
            
            // Draw left edge
            trunkPath.addLine(to: CGPoint(x: x - width / 2, y: yPosition))
        }
        
        // Complete the path by drawing back up the right side
        for i in stride(from: segments, through: 0, by: -1) {
            let progress = CGFloat(i) / CGFloat(segments)
            let yPosition = progress * (size.height - 50)
            let width = baseWidth - (baseWidth - topWidth) * progress
            let xOffset = sin(progress * .pi * 2) * 3
            let x = centerX + xOffset
            
            trunkPath.addLine(to: CGPoint(x: x + width / 2, y: yPosition))
        }
        
        trunkPath.closeSubpath()
        
        // Fill the trunk
        context.fill(trunkPath, with: .color(growthState.treeColor))
        
        // Add subtle outline
        context.stroke(
            trunkPath,
            with: .color(growthState.treeColor.opacity(0.8)),
            style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
        )
    }
    
    private func drawBarkTexture(context: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2
        let textureColor = growthState.treeColor.opacity(0.3)
        
        // Draw vertical bark lines
        let numberOfLines = Int(6 * growthState.detailLevel)
        
        for i in 0..<numberOfLines {
            let progress = CGFloat(i) / CGFloat(numberOfLines)
            let offsetX = (progress - 0.5) * 15 // Spread lines across trunk width
            
            var texturePath = Path()
            
            // Random start position
            let startY = CGFloat.random(in: 50...100)
            let length = CGFloat.random(in: 80...150)
            
            texturePath.move(to: CGPoint(x: centerX + offsetX, y: startY))
            texturePath.addLine(to: CGPoint(x: centerX + offsetX + CGFloat.random(in: -2...2), y: startY + length))
            
            context.stroke(
                texturePath,
                with: .color(textureColor),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
            )
        }
    }
    
    private func drawBranches(context: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2
        let branchWidth = 4.0 * growthState.detailLevel
        let horizontalOffset: CGFloat = 80
        
        // Calculate number of branches based on tree height
        let branchSpacing: CGFloat = 120
        let numberOfBranches = Int(size.height / branchSpacing)
        
        for i in 0..<numberOfBranches {
            let yPosition = CGFloat(i) * branchSpacing + 100
            
            // Alternate left and right branches
            let isLeft = i % 2 == 0
            let endX = isLeft ? centerX - horizontalOffset : centerX + horizontalOffset
            
            // Draw curved branch
            var branchPath = Path()
            branchPath.move(to: CGPoint(x: centerX, y: yPosition))
            
            // Control point for curve
            let controlY = yPosition - 20
            let controlX = centerX + (isLeft ? -horizontalOffset * 0.5 : horizontalOffset * 0.5)
            
            branchPath.addQuadCurve(
                to: CGPoint(x: endX, y: yPosition),
                control: CGPoint(x: controlX, y: controlY)
            )
            
            context.stroke(
                branchPath,
                with: .color(growthState.treeColor),
                style: StrokeStyle(lineWidth: branchWidth, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.xl) {
            // Skeleton State (0-25% completion)
            VStack(spacing: Spacing.sm) {
                Text("Skeleton State (0-25%)")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
                
                Text("Just starting - minimal detail")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                
                TreeBackgroundView(
                    growthState: .skeleton,
                    appearProgress: 1.0,
                    treeHeight: 800
                )
                .frame(height: 800)
                .background(Color.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
            
            Divider()
            
            // Sprouting State (26-50% completion)
            VStack(spacing: Spacing.sm) {
                Text("Sprouting State (26-50%)")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
                
                Text("Starting to grow - bark texture appears")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                
                TreeBackgroundView(
                    growthState: .sprouting,
                    appearProgress: 1.0,
                    treeHeight: 1000
                )
                .frame(height: 1000)
                .background(Color.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
            
            Divider()
            
            // Growing State (51-75% completion)
            VStack(spacing: Spacing.sm) {
                Text("Growing State (51-75%)")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
                
                Text("Getting stronger - more detail")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                
                TreeBackgroundView(
                    growthState: .growing,
                    appearProgress: 1.0,
                    treeHeight: 1200
                )
                .frame(height: 1200)
                .background(Color.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
            
            Divider()
            
            // Flourishing State (76-100% completion)
            VStack(spacing: Spacing.sm) {
                Text("Flourishing State (76-100%)")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
                
                Text("Fully grown - maximum detail")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                
                TreeBackgroundView(
                    growthState: .flourishing,
                    appearProgress: 1.0,
                    treeHeight: 1500
                )
                .frame(height: 1500)
                .background(Color.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
        }
        .padding()
    }
    .background(Color.backgroundPrimary)
}
