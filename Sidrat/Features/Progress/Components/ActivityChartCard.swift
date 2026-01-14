//
//  ActivityChartCard.swift
//  Sidrat
//
//  Activity chart card for Parent Progress Dashboard
//  Shows daily activity for the last 7 days
//

import SwiftUI

struct ActivityChartCard: View {
    let dailyActivity: [DailyActivity]
    let periodLessons: Int
    
    @State private var chartOpacity: Double = 0
    
    // Find maximum value for scale calculation
    private var maxLessons: Int {
        max(dailyActivity.map { $0.lessonsCompleted }.max() ?? 1, 5) // At least 5 for scale
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Activity History")
                        .font(.labelLarge)
                        .foregroundStyle(.textPrimary)
                    
                    Text("Last 7 Days")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
                
                Spacer()
                
                // Total Badge
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "book.fill")
                        .font(.caption)
                    Text("\(periodLessons) lessons")
                        .font(.caption.bold())
                }
                .foregroundStyle(.brandPrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(Color.brandPrimary.opacity(0.1))
                .clipShape(Capsule())
            }
            
            // Chart visualization
            if dailyActivity.isEmpty {
                 Text("No activity data available")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
            } else {
                HStack(alignment: .bottom, spacing: Spacing.xs) {
                    ForEach(dailyActivity) { activity in
                         barView(for: activity)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 150)
                .padding(.top, Spacing.sm)
                .opacity(chartOpacity)
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                chartOpacity = 1
            }
        }
    }
    
    // MARK: - Bar View
    
    private func barView(for activity: DailyActivity) -> some View {
        VStack(spacing: Spacing.xxs) {
            Spacer(minLength: 0)
            
            // Count label (only show if count > 0)
            if activity.lessonsCompleted > 0 {
                Text("\(activity.lessonsCompleted)")
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
                    .transition(.scale)
            } else {
                // Invisible spacer for alignment
                Text(" ")
                    .font(.caption2)
                    .opacity(0)
            }
            
            // The Bar with fixed height
            ZStack(alignment: .bottom) {
                // Empty track
                Capsule()
                    .fill(Color.backgroundSecondary)
                    .frame(width: 8, height: 100)
                
                // Filled bar
                if activity.lessonsCompleted > 0 {
                    let ratio = Double(activity.lessonsCompleted) / Double(maxLessons)
                    let height = max(ratio * 100, 8)
                    
                    Capsule()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 8, height: height)
                } else {
                    Circle()
                        .fill(Color.textTertiary.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .padding(.bottom, 2)
                }
            }
            
            // Date label
            Text(activity.dayAbbreviation)
                .font(.caption2)
                .foregroundStyle(isToday(activity.date) ? .brandPrimary : .textTertiary)
                .fontWeight(isToday(activity.date) ? .bold : .regular)
                .lineLimit(1)
                .fixedSize()
        }
    }
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}
