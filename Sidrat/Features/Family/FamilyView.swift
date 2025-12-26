//
//  FamilyView.swift
//  Sidrat
//
//  Weekly family activities view
//

import SwiftUI
import SwiftData

struct FamilyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [FamilyActivity]
    @State private var showingActivityDetail = false
    
    // Get the current week's activity or create the sample one
    private var currentActivity: FamilyActivity {
        if let existing = activities.first(where: { $0.weekNumber == 1 && !$0.isCompleted }) {
            return existing
        }
        return .sampleWuduActivity
    }
    
    // Get completed activities
    private var completedActivities: [FamilyActivity] {
        activities.filter { $0.isCompleted }.sorted { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // This week's activity
                    thisWeekActivity
                    
                    // Conversation prompts
                    conversationPromptsSection
                    
                    // Past activities
                    pastActivitiesSection
                }
                .padding()
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Family Time")
            .sheet(isPresented: $showingActivityDetail) {
                FamilyActivityDetailView(activity: currentActivity)
            }
            .onAppear {
                seedActivityIfNeeded()
            }
        }
    }
    
    private func seedActivityIfNeeded() {
        // Create the sample activity if no activities exist
        if activities.isEmpty {
            let activity = FamilyActivity.sampleWuduActivity
            modelContext.insert(activity)
            try? modelContext.save()
        }
    }
    
    // MARK: - This Week's Activity
    
    private var thisWeekActivity: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("This Week's Activity")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
                
                Spacer()
                
                Image(systemName: "heart.fill")
                    .foregroundStyle(.error)
            }
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Activity header
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimary.opacity(0.1))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: currentActivity.relatedCategory.icon)
                            .font(.title2)
                            .foregroundStyle(.brandPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(currentActivity.title)
                            .font(.labelLarge)
                            .foregroundStyle(.textPrimary)
                        
                        HStack(spacing: Spacing.sm) {
                            Label("\(currentActivity.durationMinutes) min", systemImage: "clock")
                            Label("Week \(currentActivity.weekNumber)", systemImage: "calendar")
                        }
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                    }
                }
                
                Text(currentActivity.activityDescription)
                    .font(.bodyMedium)
                    .foregroundStyle(.textSecondary)
                
                // Instructions preview
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Steps:")
                        .font(.labelSmall)
                        .foregroundStyle(.textPrimary)
                    
                    ForEach(currentActivity.instructions.prefix(3), id: \.self) { step in
                        HStack(alignment: .top, spacing: Spacing.xs) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.brandSecondary)
                                .padding(.top, 6)
                            
                            Text(step)
                                .font(.bodySmall)
                                .foregroundStyle(.textSecondary)
                        }
                    }
                    
                    if currentActivity.instructions.count > 3 {
                        Text("+ \(currentActivity.instructions.count - 3) more steps")
                            .font(.caption)
                            .foregroundStyle(.brandPrimary)
                    }
                }
                .padding()
                .background(Color.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                
                // Start button
                Button {
                    showingActivityDetail = true
                } label: {
                    Text("Start Activity")
                        .font(.labelLarge)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Conversation Prompts
    
    private var conversationPromptsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Conversation Starters")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
                
                Spacer()
                
                Image(systemName: "message.fill")
                    .foregroundStyle(.brandAccent)
            }
            
            Text("Use these at dinner or bedtime to reinforce learning:")
                .font(.bodySmall)
                .foregroundStyle(.textSecondary)
            
            VStack(spacing: Spacing.sm) {
                ForEach(currentActivity.conversationPrompts, id: \.self) { prompt in
                    ConversationPromptCard(
                        prompt: prompt,
                        icon: "questionmark.circle.fill"
                    )
                }
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
                
                ConversationPromptCard(
                    prompt: "What's your favorite part of making Wudu?",
                    icon: "heart.circle.fill"
                )
                
                ConversationPromptCard(
                    prompt: "How do you feel after making Wudu?",
                    icon: "face.smiling.fill"
                )
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Past Activities
    
    private var pastActivitiesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Past Activities")
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            if completedActivities.isEmpty {
                // Empty state
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(.textTertiary)
                    
                    Text("No past activities yet")
                        .font(.bodyMedium)
                        .foregroundStyle(.textSecondary)
                    
                    Text("Complete this week's activity to see it here!")
                        .font(.bodySmall)
                        .foregroundStyle(.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(completedActivities) { activity in
                        CompletedActivityRow(activity: activity)
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
}

// MARK: - Completed Activity Row

struct CompletedActivityRow: View {
    let activity: FamilyActivity
    
    private var formattedDate: String {
        guard let date = activity.completedAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.brandSecondary.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "checkmark")
                    .font(.labelMedium)
                    .foregroundStyle(.brandSecondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.labelMedium)
                    .foregroundStyle(.textPrimary)
                
                Text("Completed \(formattedDate)")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.textTertiary)
                .font(.caption)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

// MARK: - Conversation Prompt Card

struct ConversationPromptCard: View {
    let prompt: String
    let icon: String
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.accent)
            
            Text(prompt)
                .font(.bodyMedium)
                .foregroundStyle(.textPrimary)
            
            Spacer()
        }
        .padding()
        .background(Color.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

#Preview {
    FamilyView()
}
