//
//  StreakDetailSheet.swift
//  Sidrat
//
//  Detailed streak information sheet with history and milestones
//  US-303 Phase 3
//

import SwiftUI
import SwiftData

struct StreakDetailSheet: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    // MARK: - Properties
    
    let child: Child
    
    // MARK: - State
    
    @State private var animateFlame = false
    
    // MARK: - Computed Properties
    
    private var streakService: StreakService {
        StreakService(modelContext: modelContext)
    }
    
    private var hoursRemaining: Int {
        streakService.hoursRemainingToday()
    }
    
    private var nextMilestone: StreakMilestone? {
        streakService.getNextMilestone(currentStreak: child.currentStreak)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.textSecondary)
                }
                .accessibilityLabel("Close")
            }
            .padding(.top, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            
            Spacer()
            
            // Pulse Animation Flame
            ZStack {
                // Glow circles
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.brandAccent.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .scaleEffect(animateFlame ? 3.0 : 1.0)
                        .opacity(animateFlame ? 0 : 0.5)
                        .animation(
                            .easeOut(duration: 2.0)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.4),
                            value: animateFlame
                        )
                }
                
                // Main flame
                Image(systemName: "flame.fill")
                    .font(.heroLarge)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.brandAccent, Color.orange, Color.red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.brandAccent.opacity(0.6), radius: 20, y: 10)
                    .scaleEffect(animateFlame ? 1.05 : 0.95)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                        value: animateFlame
                    )
            }
            .frame(height: 180)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Streak flame animation")
            
            // Streak Count
            VStack(spacing: Spacing.xs) {
                Text("\(child.currentStreak)")
                    .font(.heroMedium)
                    .foregroundStyle(.textPrimary)
                    .contentTransition(.numericText())
                
                Text(child.currentStreak == 1 ? "Day Streak" : "Days Streak")
                    .font(.title2)
                    .foregroundStyle(.textSecondary)
            }
            .padding(.bottom, Spacing.lg)
            
            // Footer Info
            VStack(spacing: Spacing.md) {
                if let milestone = nextMilestone {
                    VStack(spacing: Spacing.sm) {
                        Text("Next Milestone: \(milestone.days) Days")
                            .font(.labelLarge)
                            .foregroundStyle(.brandPrimary)
                        
                        // Simple progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.backgroundSecondary)
                                    .frame(height: 8)
                                
                                Capsule()
                                    .fill(Color.brandAccent)
                                    .frame(width: min(CGFloat(child.currentStreak) / CGFloat(milestone.days) * geometry.size.width, geometry.size.width), height: 8)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal, Spacing.xxl)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Progress to next milestone: \(child.currentStreak) out of \(milestone.days) days")
                    }
                }
                
                if hoursRemaining > 0 && hoursRemaining <= 24 {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "clock")
                        Text("\(hoursRemaining) hours left today")
                    }
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                    .padding(.top, Spacing.sm)
                }
            }
            .padding(.bottom, Spacing.xl)
            
            Spacer()
        }
        .background(Color.backgroundPrimary)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            animateFlame = true
        }
    }
    
}

// MARK: - Preview

#Preview("Streak Detail - Active Streak") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Child.self, configurations: config)
    
    let child = Child(
        name: "Test Child",
        birthYear: 2018,
        avatarId: "cat"
    )
    child.currentStreak = 12
    child.longestStreak = 15
    child.totalLessonsCompleted = 25
    
    container.mainContext.insert(child)
    
    return StreakDetailSheet(child: child)
    .modelContainer(container)
    .environment(AppState())
}

#Preview("Streak Detail - No Freeze") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Child.self, configurations: config)
    
    let child = Child(
        name: "Test Child",
        birthYear: 2018,
        avatarId: "cat"
    )
    child.currentStreak = 45
    child.longestStreak = 45
    child.totalLessonsCompleted = 50
    
    container.mainContext.insert(child)
    
    return StreakDetailSheet(child: child)
    .modelContainer(container)
    .environment(AppState())
}
