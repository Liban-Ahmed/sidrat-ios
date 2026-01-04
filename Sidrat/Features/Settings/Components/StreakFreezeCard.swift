//
//  StreakFreezeCard.swift
//  Sidrat
//
//  Streak freeze management card for Settings view
//  US-303 Phase 4
//

import SwiftUI
import SwiftData

/// Card component for managing streak freezes in Settings
/// Shows availability, explanation, and grant button
struct StreakFreezeCard: View {
    // MARK: - Properties
    
    let child: Child
    let canGrantFreeze: Bool
    let isGranting: Bool
    let error: String?
    let onGrantTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack(spacing: Spacing.sm) {
                Image(systemName: "snowflake")
                    .font(.title2)
                    .foregroundStyle(.brandPrimary)
                
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Streak Freeze")
                        .font(.labelLarge)
                        .foregroundStyle(.textPrimary)
                    
                    Text("For \(child.name)")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
                
                Spacer()
                
                // Freeze count badge
                Text("\(child.availableStreakFreezes)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.brandPrimary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.brandPrimary.opacity(0.1)))
            }
            
            // Explanation
            Text("Protects the streak if a day is missed. You can grant one freeze per week.")
                .font(.bodySmall)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Error message
            if let errorMessage = error {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(errorMessage)
                        .font(.caption)
                }
                .foregroundStyle(.error)
                .padding(.vertical, Spacing.xs)
            }
            
            // Grant button
            Button(action: onGrantTapped) {
                HStack {
                    if isGranting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "snowflake")
                        Text(canGrantFreeze ? "Grant Freeze" : "Already Granted This Week")
                    }
                }
                .font(.labelMedium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(
                    LinearGradient(
                        colors: canGrantFreeze ? [.brandPrimary, .brandSecondary] : [.textSecondary, .textSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
            .disabled(!canGrantFreeze || isGranting)
            .opacity(canGrantFreeze ? 1.0 : 0.6)
            .accessibilityLabel(canGrantFreeze ? "Grant streak freeze" : "Freeze already granted this week")
            
            // Next grant availability
            if !canGrantFreeze, let lastGrantDate = child.lastStreakFreezeGrantedDate {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                    Text("Available again \(nextAvailabilityText(from: lastGrantDate))")
                        .font(.caption)
                }
                .foregroundStyle(.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.brandPrimary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    /// Calculate next availability text
    private func nextAvailabilityText(from lastGrantDate: Date) -> String {
        let calendar = Calendar.current
        
        // Add 7 days to last grant date
        guard let nextAvailableDate = calendar.date(byAdding: .day, value: 7, to: lastGrantDate) else {
            return "soon"
        }
        
        // Calculate components
        let now = Date()
        let components = calendar.dateComponents([.day, .hour], from: now, to: nextAvailableDate)
        
        if let days = components.day, days > 0 {
            return "in \(days) day\(days == 1 ? "" : "s")"
        } else if let hours = components.hour, hours > 0 {
            return "in \(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "soon"
        }
    }
}

// MARK: - Preview

#Preview("Freeze Available") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Child.self, configurations: config)
    
    let child = Child(
        name: "Sara",
        birthYear: 2018,
        avatarId: "cat"
    )
    child.availableStreakFreezes = 0
    child.currentStreak = 12
    
    container.mainContext.insert(child)
    
    return List {
        StreakFreezeCard(
            child: child,
            canGrantFreeze: true,
            isGranting: false,
            error: nil,
            onGrantTapped: {
                print("Grant tapped")
            }
        )
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .listRowBackground(Color.clear)
    }
    .modelContainer(container)
}

#Preview("Freeze Not Available") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Child.self, configurations: config)
    
    let child = Child(
        name: "Sara",
        birthYear: 2018,
        avatarId: "cat"
    )
    child.availableStreakFreezes = 1
    child.currentStreak = 12
    child.lastStreakFreezeGrantedDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
    
    container.mainContext.insert(child)
    
    return List {
        StreakFreezeCard(
            child: child,
            canGrantFreeze: false,
            isGranting: false,
            error: nil,
            onGrantTapped: {
                print("Grant tapped")
            }
        )
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .listRowBackground(Color.clear)
    }
    .modelContainer(container)
}

#Preview("With Error") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Child.self, configurations: config)
    
    let child = Child(
        name: "Sara",
        birthYear: 2018,
        avatarId: "cat"
    )
    child.availableStreakFreezes = 0
    child.currentStreak = 12
    
    container.mainContext.insert(child)
    
    return List {
        StreakFreezeCard(
            child: child,
            canGrantFreeze: true,
            isGranting: false,
            error: "You can only grant one freeze per week",
            onGrantTapped: {
                print("Grant tapped")
            }
        )
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .listRowBackground(Color.clear)
    }
    .modelContainer(container)
}
