//
//  AchievementGridView.swift
//  Sidrat
//
//  Grid display of achievements with progress tracking
//

import SwiftUI
import SwiftData

struct AchievementGridView: View {
    private enum Constants {
        static let refreshDelayNanoseconds: UInt64 = 500_000_000 // 0.5 seconds
    }

    // MARK: - Properties
    
    let child: Child
    let achievementService: AchievementService
    
    @Environment(\.modelContext) private var modelContext
    
    /// Callback to replay the unlock animation for an achievement
    var onReplayAnimation: ((AchievementType) -> Void)? = nil
    
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var selectedAchievement: AchievementType? = nil
    @State private var showingDetail = false
    @State private var isRefreshing = false
    
    // MARK: - Computed Properties
    
    private var unlockedAchievements: Set<AchievementType> {
        Set(child.achievements.map { $0.achievementType })
    }
    
    private var achievementProgress: [AchievementType: AchievementProgress] {
        achievementService.getAllProgress(for: child)
    }
    
    private var filteredAchievements: [AchievementType] {
        let achievements = AchievementType.allCases.filter { type in
            // Hide hidden achievements if not unlocked
            if type.isHidden && !unlockedAchievements.contains(type) {
                return false
            }
            
            // Filter by category if selected
            if let category = selectedCategory {
                return type.category == category
            }
            
            return true
        }
        
        // Sort: unlocked first, then by rarity, then alphabetically
        return achievements.sorted { first, second in
            let firstUnlocked = unlockedAchievements.contains(first)
            let secondUnlocked = unlockedAchievements.contains(second)
            
            if firstUnlocked != secondUnlocked {
                return firstUnlocked
            }
            
            // Sort by rarity
            let rarityOrder: [AchievementRarity] = [.platinum, .gold, .silver, .bronze]
            let firstRarityIndex = rarityOrder.firstIndex(of: first.rarity) ?? 999
            let secondRarityIndex = rarityOrder.firstIndex(of: second.rarity) ?? 999
            
            if firstRarityIndex != secondRarityIndex {
                return firstRarityIndex < secondRarityIndex
            }
            
            return first.title < second.title
        }
    }
    
    private var stats: (total: Int, unlocked: Int, percentage: Double) {
        let total = AchievementType.allCases.filter { !$0.isHidden }.count
        let unlocked = unlockedAchievements.count
        let percentage = total > 0 ? Double(unlocked) / Double(total) * 100 : 0
        return (total, unlocked, percentage)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Stats header
                statsHeader
                
                // Category filter
                categoryFilter
                
                // Achievement grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Spacing.md),
                        GridItem(.flexible(), spacing: Spacing.md),
                        GridItem(.flexible(), spacing: Spacing.md)
                    ],
                    spacing: Spacing.md
                ) {
                    ForEach(filteredAchievements, id: \.self) { achievement in
                        let isUnlocked = unlockedAchievements.contains(achievement)
                        AchievementBadgeCell(
                            achievement: achievement,
                            isUnlocked: isUnlocked,
                            progress: achievementProgress[achievement],
                            isNew: child.achievements.first { $0.achievementType == achievement }?.isNew ?? false,
                            onReplayAnimation: isUnlocked ? {
                                // Mark as no longer new when viewed
                                if let achievementRecord = child.achievements.first(where: { $0.achievementType == achievement }) {
                                    achievementRecord.isNew = false
                                    try? modelContext.save()
                                }
                                onReplayAnimation?(achievement)
                            } : nil
                        )
                        .onTapGesture {
                            // Mark as no longer new when tapped
                            if let achievementRecord = child.achievements.first(where: { $0.achievementType == achievement }) {
                                achievementRecord.isNew = false
                                try? modelContext.save()
                            }
                            selectedAchievement = achievement
                            showingDetail = true
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .padding(.vertical, Spacing.md)
        }
        .background(Color.backgroundSecondary)
        .refreshable {
            await refresh()
        }
        .sheet(isPresented: $showingDetail) {
            if let achievement = selectedAchievement {
                AchievementDetailView(
                    achievement: achievement,
                    isUnlocked: unlockedAchievements.contains(achievement),
                    progress: achievementProgress[achievement],
                    child: child
                )
            }
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        VStack(spacing: Spacing.sm) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.surfaceTertiary, lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: stats.percentage / 100)
                    .stroke(
                        LinearGradient(
                            colors: [Color.brandPrimary, Color.brandAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(stats.unlocked)")
                        .font(.title.bold())
                        .foregroundStyle(Color.textPrimary)
                    Text("of \(stats.total)")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            Text("\(Int(stats.percentage))% Complete")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.vertical, Spacing.md)
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // All categories
                CategoryFilterChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = nil
                    }
                }
                
                // Individual categories
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    CategoryFilterChip(
                        title: category.title,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }
    
    // MARK: - Actions
    
    private func refresh() async {
        isRefreshing = true
        
        // Re-check achievements
        let _ = achievementService.checkAndUnlockAchievements(for: child)
        
        // Brief delay for smooth animation
        try? await Task.sleep(nanoseconds: Constants.refreshDelayNanoseconds)
        
        isRefreshing = false
    }
}

// MARK: - Achievement Badge Cell

struct AchievementBadgeCell: View {
    let achievement: AchievementType
    let isUnlocked: Bool
    let progress: AchievementProgress?
    let isNew: Bool
    
    /// Callback to replay the unlock animation (only available for unlocked achievements)
    var onReplayAnimation: (() -> Void)? = nil
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            // Badge
            ZStack(alignment: .topTrailing) {
                // Main badge
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Color.surfaceSecondary : Color.surfaceTertiary)
                        .shadow(
                            color: isUnlocked ? Color(hex: achievement.rarity.color).opacity(0.3) : Color.clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            isUnlocked
                                ? LinearGradient(
                                    colors: [
                                        Color(hex: achievement.rarity.color),
                                        Color(hex: achievement.rarity.color).opacity(0.7)
                                    ],
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
                .frame(width: 56, height: 56)
                
                // New badge indicator
                if isNew {
                    Circle()
                        .fill(Color.error)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.surfaceSecondary, lineWidth: 2)
                        )
                        .offset(x: 4, y: -4)
                }
            }
            
            // Title
            Text(achievement.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(isUnlocked ? Color.textPrimary : Color.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32)
            
            // Progress bar for locked achievements
            if !isUnlocked, let progress = progress {
                VStack(spacing: 2) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.surfaceTertiary)
                            
                            Capsule()
                                .fill(Color.brandPrimary)
                                .frame(width: geometry.size.width * progress.percentage)
                        }
                    }
                    .frame(height: 4)
                    
                    // Progress text
                    Text(progress.progressText)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
            }
            
            // Replay hint for unlocked achievements
            if isUnlocked && onReplayAnimation != nil {
                Text("Hold to replay")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .opacity(0.7)
            }
        }
        .padding(.vertical, Spacing.xs)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.5) {
            // Long press triggers replay animation for unlocked achievements
            if isUnlocked, let replay = onReplayAnimation {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                replay()
            }
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(achievementAccessibilityLabel)
        .accessibilityHint(isUnlocked ? "Double tap for details, hold to replay celebration" : "Double tap for details")
        .accessibilityAddTraits(.isButton)
    }
    
    private var achievementAccessibilityLabel: String {
        var label = achievement.title
        
        if isNew {
            label = "New! " + label
        }
        
        if isUnlocked {
            label += ", unlocked"
        } else {
            label += ", locked"
            if let progress = progress {
                label += ", progress: \(progress.progressText)"
            }
        }
        
        label += ", \(achievement.rarity.title) rarity"
        
        return label
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? Color.white : Color.textSecondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? Color.brandPrimary : Color.surfaceSecondary)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Achievement Grid") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Child.self, Lesson.self, Achievement.self, configurations: config)
    let context = container.mainContext
    
    // Create sample child
    let child = Child(name: "Aisha", birthYear: 2019, avatarId: "cat")
    child.totalXP = 750
    child.currentStreak = 5
    child.totalLessonsCompleted = 15
    
    // Add some achievements
    let achievement1 = Achievement(achievementType: .firstLesson, unlockedAt: Date())
    achievement1.child = child
    child.achievements.append(achievement1)
    
    let achievement2 = Achievement(achievementType: .streak3, unlockedAt: Date(), isNew: true)
    achievement2.child = child
    child.achievements.append(achievement2)
    
    context.insert(child)
    
    let service = AchievementService(modelContext: context)
    
    return NavigationStack {
        AchievementGridView(child: child, achievementService: service)
            .navigationTitle("Achievements")
    }
    .modelContainer(container)
}
