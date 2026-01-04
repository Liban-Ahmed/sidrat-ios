//
//  WindingPathView.swift
//  Sidrat
//
//  Draws winding path connecting tree nodes
//

import SwiftUI

struct WindingPathView: View {
    let segments: [TreePathSegment]
    let appearProgress: Double
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Canvas { context, size in
            for (index, segment) in segments.enumerated() {
                // Calculate staggered progress for each segment
                let segmentProgress = calculateSegmentProgress(index: index)
                
                if segmentProgress > 0 {
                    drawSegment(segment, context: context, progress: segmentProgress)
                }
            }
        }
        .accessibilityHidden(true)
    }
    
    // MARK: - Drawing
    
    private func drawSegment(_ segment: TreePathSegment, context: GraphicsContext, progress: Double) {
        var path = Path()
        
        // Start point
        path.move(to: segment.startPoint)
        
        // Create smooth bezier curve
        let midX = (segment.startPoint.x + segment.endPoint.x) / 2
        let midY = (segment.startPoint.y + segment.endPoint.y) / 2
        
        // Control point creates the curve (offset slightly upward for organic look)
        let controlPoint = CGPoint(x: midX, y: midY - 30)
        
        path.addQuadCurve(
            to: segment.endPoint,
            control: controlPoint
        )
        
        // Trim path based on progress
        let trimmedPath = path.trimmedPath(from: 0, to: progress)
        
        // Style based on completion
        let strokeColor: Color = segment.isCompleted ? .brandPrimary : .separator
        let lineWidth: CGFloat = 3
        let dashPattern: [CGFloat] = segment.isCompleted ? [] : [5, 5]
        
        context.stroke(
            trimmedPath,
            with: .color(strokeColor),
            style: StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                lineJoin: .round,
                dash: dashPattern
            )
        )
    }
    
    // MARK: - Helpers
    
    private func calculateSegmentProgress(index: Int) -> Double {
        // Stagger animation: each segment starts 0.05s after the previous
        let delay = Double(index) * 0.05
        let adjustedProgress = (appearProgress - delay) * 1.5
        
        return min(max(adjustedProgress, 0), 1.0)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.backgroundSecondary.ignoresSafeArea()
        
        WindingPathView(
            segments: [
                TreePathSegment(
                    startPoint: CGPoint(x: 100, y: 100),
                    endPoint: CGPoint(x: 300, y: 220),
                    isCompleted: true
                ),
                TreePathSegment(
                    startPoint: CGPoint(x: 300, y: 220),
                    endPoint: CGPoint(x: 100, y: 340),
                    isCompleted: true
                ),
                TreePathSegment(
                    startPoint: CGPoint(x: 100, y: 340),
                    endPoint: CGPoint(x: 300, y: 460),
                    isCompleted: false
                )
            ],
            appearProgress: 1.0
        )
    }
    .frame(height: 600)
}
