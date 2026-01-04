//
//  AchievementDetailView.swift
//  Sidrat
//
//  Detailed view for individual achievements
//

import SwiftUI
import SwiftData

struct AchievementDetailView: View {
    // MARK: - Properties
    
    let achievement: AchievementType
    let isUnlocked: Bool
    let progress: AchievementProgress?
    let child: Child
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showShareSheet = false
    @State private var showParentalGate = false
    @State private var badgeRotation: Double = 0
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Large badge display
                    badgeSection
                    
                    // Achievement info
                    infoSection
                    
                    // Progress section (if locked)
                    if !isUnlocked {
                        progressSection
                    }
                    
                    // Unlock details (if unlocked)
                    if isUnlocked, let unlockDate = getUnlockDate() {
                        unlockDetailsSection(date: unlockDate)
                    }
                    
                    // Related achievements
                    relatedAchievementsSection
                    
                    Spacer(minLength: Spacing.xl)
                }
                .padding(Spacing.lg)
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if isUnlocked {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showParentalGate = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showParentalGate) {
            ParentalGateView(
                onSuccess: {
                    showParentalGate = false
                    // Brief delay before showing share sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showShareSheet = true
                    }
                },
                onDismiss: {
                    showParentalGate = false
                },
                context: "Would you like to share \(child.name)'s achievement with family and friends?"
            )
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(items: [shareText])
        }
    }
    
    // MARK: - Badge Section
    
    private var badgeSection: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                // Rarity glow
                if !reduceMotion && isUnlocked {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    rarityColor.opacity(0.4),
                                    rarityColor.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 60,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 30)
                }
                
                // Badge
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Color.surfaceSecondary : Color.surfaceTertiary)
                        .shadow(
                            color: isUnlocked ? rarityColor.opacity(0.3) : Color.clear,
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            isUnlocked
                                ? LinearGradient(
                                    colors: [rarityColor, rarityColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.textTertiary, Color.textTertiary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .opacity(isUnlocked ? 1.0 : 0.3)
                }
                .frame(width: 180, height: 180)
                .rotation3DEffect(
                    .degrees(badgeRotation),
                    axis: (x: 0, y: 1, z: 0)
                )
            }
            .onAppear {
                if !reduceMotion && isUnlocked {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        badgeRotation = 10
                    }
                }
            }
        }
        .padding(.top, Spacing.lg)
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(spacing: Spacing.md) {
            // Title
            Text(achievement.title)
                .font(.title.bold())
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
            
            // Description
            Text(achievement.description)
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            
            // Rarity and category
            HStack(spacing: Spacing.md) {
                // Rarity
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(rarityColor)
                        .frame(width: 8, height: 8)
                    
                    Text(achievement.rarity.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(rarityColor)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(
                    Capsule()
                        .fill(rarityColor.opacity(0.15))
                )
                
                // Category
                HStack(spacing: Spacing.xs) {
                    Image(systemName: achievement.category.icon)
                        .font(.caption)
                    
                    Text(achievement.category.title)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(
                    Capsule()
                        .fill(Color.surfaceTertiary)
                )
            }
            
            // XP reward
            if isUnlocked {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.body)
                    Text("Earned +\(achievement.xpReward) XP")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(Color.brandAccent)
                .padding(.top, Spacing.sm)
            } else {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.body)
                    Text("Reward: \(achievement.xpReward) XP")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(Color.textSecondary)
                .padding(.top, Spacing.sm)
            }
        }
    }
    
    // MARK: - Progress Section
    
    @ViewBuilder
    private var progressSection: some View {
        if let progress = progress {
            VStack(spacing: Spacing.md) {
                Divider()
                
                VStack(spacing: Spacing.sm) {
                    HStack {
                        Text("Progress")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        Spacer()
                        
                        Text("\(Int(progress.percentage * 100))%")
                            .font(.headline)
                            .foregroundStyle(Color.brandPrimary)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.surfaceTertiary)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.brandPrimary, Color.brandAccent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress.percentage)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text(progress.progressText)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        
                        Spacer()
                        
                        Text(achievement.unlockRequirement.description)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .fill(Color.surfaceSecondary)
                )
            }
        } else {
            VStack(spacing: Spacing.md) {
                Divider()
                
                VStack(spacing: Spacing.sm) {
                    Text("How to Unlock")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(achievement.unlockRequirement.description)
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .fill(Color.surfaceSecondary)
                )
            }
        }
    }
    
    // MARK: - Unlock Details Section
    
    private func unlockDetailsSection(date: Date) -> some View {
        VStack(spacing: Spacing.md) {
            Divider()
            
            VStack(spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.brandPrimary)
                    
                    Text("Unlocked")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    Text(date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                
                if let daysAgo = daysSinceUnlock(date: date), daysAgo > 0 {
                    Text("\(daysAgo) day\(daysAgo == 1 ? "" : "s") ago")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color.surfaceSecondary)
            )
        }
    }
    
    // MARK: - Related Achievements
    
    private var relatedAchievementsSection: some View {
        VStack(spacing: Spacing.md) {
            Divider()
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Related Achievements")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                
                Text("Other \(achievement.category.title) achievements")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(getRelatedAchievements(), id: \.self) { related in
                            RelatedAchievementCard(achievement: related)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var rarityColor: Color {
        Color(hex: achievement.rarity.color)
    }
    
    private var shareText: String {
        "\(child.name) just unlocked the '\(achievement.title)' achievement in Sidrat! 🎉"
    }
    
    // MARK: - Helper Methods
    
    private func getUnlockDate() -> Date? {
        child.achievements.first { $0.achievementType == achievement }?.unlockedAt
    }
    
    private func daysSinceUnlock(date: Date) -> Int? {
        Calendar.current.dateComponents([.day], from: date, to: Date()).day
    }
    
    private func getRelatedAchievements() -> [AchievementType] {
        AchievementType.allCases
            .filter { $0.category == achievement.category && $0 != achievement }
            .prefix(5)
            .map { $0 }
    }
}

// MARK: - Related Achievement Card

struct RelatedAchievementCard: View {
    let achievement: AchievementType
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(Color.surfaceTertiary)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .frame(width: 50, height: 50)
            
            Text(achievement.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 70)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Activity View Controller (Share Sheet)

struct ActivityViewController: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Unlocked Achievement") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Child.self, Achievement.self, configurations: config)
    let context = container.mainContext
    
    let child = Child(name: "Aisha", birthYear: 2019)
    let achievement = Achievement(achievementType: .streak7, unlockedAt: Date().addingTimeInterval(-86400 * 3))
    achievement.child = child
    child.achievements.append(achievement)
    context.insert(child)
    
    let _ = context  // Silence unused variable warning
    
    return AchievementDetailView(
        achievement: .streak7,
        isUnlocked: true,
        progress: nil,
        child: child
    )
    .modelContainer(container)
}

#Preview("Locked Achievement") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Child.self, configurations: config)
    let context = container.mainContext
    
    let child = Child(name: "Omar", birthYear: 2020)
    child.currentStreak = 5
    context.insert(child)
    
    let _ = context  // Silence unused variable warning
    
    let progress = AchievementProgress(type: .streak7, current: 5, required: 7)
    
    return AchievementDetailView(
        achievement: .streak7,
        isUnlocked: false,
        progress: progress,
        child: child
    )
    .modelContainer(container)
}
