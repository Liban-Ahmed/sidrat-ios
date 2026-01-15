//
//  LearningVelocityCard.swift
//  Sidrat
//
//  Created on 1/14/26.
//

import SwiftUI

struct LearningVelocityCard: View {
    let weeklyLessonCounts: [Int]
    let trend: VelocityTrend
    let isExpanded: Bool
    let onToggle: () -> Void
    
    private let maxValue: Int = 15 // Max lessons for chart scaling
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with toggle
            Button(action: onToggle) {
                HStack(alignment: .center, spacing: Spacing.sm) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.brandPrimary)
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Learning Velocity")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text(trendText)
                            .font(.subheadline)
                            .foregroundColor(trendColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.textSecondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Chart
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Lessons per Week (Last 8 Weeks)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.textSecondary)
                        
                        lineChart
                            .frame(height: 180)
                    }
                    
                    // Insights
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("What This Means")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.textSecondary)
                        
                        Text(insightText)
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                    }
                    .padding(Spacing.md)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(CornerRadius.medium)
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Chart View
    
    private var lineChart: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                gridLines(in: geometry.size)
                
                // Line and area
                chartPath(in: geometry.size)
                
                // Data points
                dataPoints(in: geometry.size)
            }
        }
    }
    
    private func gridLines(in size: CGSize) -> some View {
        Path { path in
            // Horizontal grid lines (0, 5, 10, 15)
            for i in 0...3 {
                let y = size.height - (CGFloat(i) * size.height / 3)
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }
    
    private func chartPath(in size: CGSize) -> some View {
        let points = calculatePoints(in: size)
        
        return ZStack {
            // Area fill
            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                path.addLine(to: CGPoint(x: points.last!.x, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [trendColor.opacity(0.3), trendColor.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Line stroke
            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(trendColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
    
    private func dataPoints(in size: CGSize) -> some View {
        let points = calculatePoints(in: size)
        
        return ForEach(Array(points.enumerated()), id: \.offset) { index, point in
            ZStack {
                // Outer ring
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                
                // Inner dot
                Circle()
                    .fill(trendColor)
                    .frame(width: 6, height: 6)
            }
            .position(point)
            .overlay(
                // Week label
                Text("W\(index + 1)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textTertiary)
                    .offset(y: 20),
                alignment: .bottom
            )
            .overlay(
                // Value label for current week (last point)
                Group {
                    if index == points.count - 1 {
                        Text("\(weeklyLessonCounts[index])")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(trendColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white)
                            .cornerRadius(4)
                            .shadow(color: .black.opacity(0.1), radius: 2)
                            .offset(y: -20)
                    }
                },
                alignment: .top
            )
        }
    }
    
    private func calculatePoints(in size: CGSize) -> [CGPoint] {
        let count = weeklyLessonCounts.count
        guard count > 0 else { return [] }
        
        let spacing = size.width / CGFloat(count - 1)
        
        return weeklyLessonCounts.enumerated().map { index, value in
            let x = CGFloat(index) * spacing
            let normalizedValue = CGFloat(value) / CGFloat(maxValue)
            let y = size.height - (normalizedValue * size.height)
            return CGPoint(x: x, y: y)
        }
    }
    
    // MARK: - Computed Properties
    
    private var trendText: String {
        switch trend {
        case .increasing:
            return "Momentum building"
        case .stable:
            return "Steady pace maintained"
        case .declining:
            return "Needs attention"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .increasing:
            return .brandSecondary
        case .stable:
            return .brandPrimary
        case .declining:
            return .orange
        }
    }
    
    private var insightText: String {
        let currentWeekLessons = weeklyLessonCounts.last ?? 0
        
        switch trend {
        case .increasing:
            return "Great momentum! Your child is learning \(currentWeekLessons) lessons this week, up from previous weeks. This upward trend shows growing engagement and consistency."
        case .stable:
            return "Excellent consistency! Your child maintains a steady pace of \(currentWeekLessons) lessons per week. This reliable rhythm is key to long-term success."
        case .declining:
            return "Learning has slowed to \(currentWeekLessons) lessons this week. Consider re-engaging with family activities or adjusting the daily routine to rebuild momentum."
        }
    }
}

// MARK: - Supporting Types

enum VelocityTrend: String, Codable {
    case increasing
    case stable
    case declining
}

// MARK: - Preview

#Preview("Increasing Trend") {
    VStack(spacing: Spacing.lg) {
        LearningVelocityCard(
            weeklyLessonCounts: [3, 4, 5, 6, 7, 8, 9, 10],
            trend: .increasing,
            isExpanded: true
        ) {}
    }
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Stable Trend") {
    VStack(spacing: Spacing.lg) {
        LearningVelocityCard(
            weeklyLessonCounts: [7, 6, 7, 7, 6, 7, 7, 7],
            trend: .stable,
            isExpanded: true
        ) {}
    }
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Declining Trend") {
    VStack(spacing: Spacing.lg) {
        LearningVelocityCard(
            weeklyLessonCounts: [10, 9, 8, 7, 6, 5, 4, 3],
            trend: .declining,
            isExpanded: true
        ) {}
    }
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Collapsed") {
    VStack(spacing: Spacing.lg) {
        LearningVelocityCard(
            weeklyLessonCounts: [7, 6, 7, 7, 6, 7, 7, 7],
            trend: .stable,
            isExpanded: false
        ) {}
    }
    .padding()
    .background(Color.backgroundSecondary)
}
