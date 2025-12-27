//
//  FamilyActivityDetailView.swift
//  Sidrat
//
//  Detailed view for a family activity with full instructions
//

import SwiftUI
import SwiftData

struct FamilyActivityDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let activity: FamilyActivity
    @State private var currentStep = 0
    @State private var completedSteps: Set<Int> = []
    @State private var showingCompletion = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    headerSection
                    
                    // Progress tracker
                    progressSection
                    
                    // Current step
                    currentStepSection
                    
                    // Parent tips
                    parentTipsSection
                    
                    // Conversation prompts
                    conversationSection
                }
                .padding()
            }
            .background(Color.backgroundSecondary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.textTertiary)
                            .font(.title2)
                    }
                }
            }
            .alert("Activity Complete!", isPresented: $showingCompletion) {
                Button("Great!") {
                    completeActivity()
                    dismiss()
                }
            } message: {
                Text("MashaAllah! You completed the family activity together. These special moments help build a strong Islamic foundation.")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.error.opacity(0.8), Color.error.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.error.opacity(0.3), radius: 12, y: 6)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            
            Text(activity.title)
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.textPrimary)
            
            HStack(spacing: Spacing.md) {
                Label("\(activity.durationMinutes) min", systemImage: "clock")
                Label("Week \(activity.weekNumber)", systemImage: "calendar")
            }
            .font(.labelSmall)
            .foregroundStyle(.textSecondary)
            
            Text(activity.activityDescription)
                .font(.bodyMedium)
                .multilineTextAlignment(.center)
                .foregroundStyle(.textSecondary)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Steps")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
                
                Spacer()
                
                Text("\(completedSteps.count)/\(activity.instructions.count)")
                    .font(.labelMedium)
                    .foregroundStyle(.brandPrimary)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 8)
                    
                    let progress = activity.instructions.isEmpty ? 0 : Double(completedSteps.count) / Double(activity.instructions.count)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.spring(response: 0.4), value: completedSteps.count)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Current Step Section
    
    private var currentStepSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Instructions")
                .font(.title3)
                .foregroundStyle(.textPrimary)
            
            VStack(spacing: Spacing.sm) {
                ForEach(Array(activity.instructions.enumerated()), id: \.offset) { index, step in
                    StepRow(
                        stepNumber: index + 1,
                        text: step,
                        isCompleted: completedSteps.contains(index),
                        isCurrent: index == currentStep && !completedSteps.contains(index)
                    ) {
                        withAnimation(.spring(response: 0.4)) {
                            if completedSteps.contains(index) {
                                completedSteps.remove(index)
                            } else {
                                completedSteps.insert(index)
                                // Auto-advance current step
                                if index == currentStep && currentStep < activity.instructions.count - 1 {
                                    currentStep = currentStep + 1
                                }
                            }
                            
                            // Check if all complete
                            if completedSteps.count == activity.instructions.count {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showingCompletion = true
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Parent Tips Section
    
    private var parentTipsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.brandAccent)
                Text("Tips for Parents")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(activity.parentTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.brandSecondary)
                            .font(.caption)
                        
                        Text(tip)
                            .font(.bodySmall)
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.brandAccent.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }
    
    // MARK: - Conversation Section
    
    private var conversationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "message.fill")
                    .foregroundStyle(.brandPrimary)
                Text("Talk About It")
                    .font(.title3)
                    .foregroundStyle(.textPrimary)
            }
            
            Text("Use these prompts during or after the activity:")
                .font(.bodySmall)
                .foregroundStyle(.textSecondary)
            
            VStack(spacing: Spacing.sm) {
                ForEach(activity.conversationPrompts, id: \.self) { prompt in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "quote.opening")
                            .foregroundStyle(.brandPrimary)
                            .font(.caption)
                        
                        Text(prompt)
                            .font(.bodyMedium)
                            .foregroundStyle(.textPrimary)
                            .italic()
                    }
                    .padding()
                    .background(Color.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                }
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Actions
    
    private func completeActivity() {
        activity.isCompleted = true
        activity.completedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            print(" Error saving activity completion: \(error)")
        }
    }
}

// MARK: - Step Row

struct StepRow: View {
    let stepNumber: Int
    let text: String
    let isCompleted: Bool
    let isCurrent: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Step number / checkmark
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.brandSecondary : (isCurrent ? Color.brandPrimary : Color.backgroundTertiary))
                        .frame(width: 36, height: 36)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.labelSmall)
                            .foregroundStyle(.white)
                    } else {
                        Text("\(stepNumber)")
                            .font(.labelSmall)
                            .foregroundStyle(isCurrent ? .white : .textSecondary)
                    }
                }
                
                Text(text)
                    .font(.bodyMedium)
                    .foregroundStyle(isCompleted ? .textTertiary : .textPrimary)
                    .strikethrough(isCompleted)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding()
            .background(isCurrent && !isCompleted ? Color.brandPrimary.opacity(0.05) : Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .stroke(isCurrent && !isCompleted ? Color.brandPrimary.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FamilyActivityDetailView(activity: .sampleWuduActivity)
}
