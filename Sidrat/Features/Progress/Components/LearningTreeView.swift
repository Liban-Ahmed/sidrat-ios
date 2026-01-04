//
//  LearningTreeView.swift
//  Sidrat
//
//  Main learning tree visualization component
//  Composes tree background, nodes, and paths into scrollable view
//

import SwiftUI
import SwiftData

struct LearningTreeView: View {
    let child: Child
    let lessons: [Lesson]
    
    @State private var viewModel: LearningTreeViewModel?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(child: Child, lessons: [Lesson], modelContext: ModelContext) {
        self.child = child
        self.lessons = lessons
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                if let vm = viewModel {
                    // Background tree structure
                    TreeBackgroundView(
                        growthState: vm.growthState,
                        appearProgress: vm.treeAppearProgress,
                        treeHeight: vm.calculateTreeHeight()
                    )
                    .frame(width: geometry.size.width, height: vm.calculateTreeHeight())
                    
                    // Winding path connecting nodes
                    WindingPathView(
                        segments: vm.pathSegments,
                        appearProgress: vm.treeAppearProgress
                    )
                    .frame(width: geometry.size.width, height: vm.calculateTreeHeight())
                    
                    // Tree nodes overlay
                    ForEach(vm.treeNodes) { node in
                        CategoryBranchNode(
                            node: node,
                            position: vm.nodePosition(for: node, screenWidth: geometry.size.width),
                            onTap: { vm.selectNode(node) }
                        )
                        .modifier(
                            TreeRevealModifier(
                                progress: vm.treeAppearProgress,
                                delay: vm.nodeAnimationDelays[node.id] ?? 0
                            )
                        )
                    }
                } else {
                    // Loading state
                    VStack(spacing: Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.brandPrimary)
                        
                        Text("Growing your tree...")
                            .font(.bodyMedium)
                            .foregroundStyle(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                }
            }
            .frame(width: geometry.size.width, height: viewModel?.calculateTreeHeight() ?? 1000)
        }
        .frame(height: viewModel?.calculateTreeHeight() ?? 1000)
        .sheet(item: Binding(
            get: { viewModel?.selectedNode },
            set: { viewModel?.selectedNode = $0 }
        )) { node in
            NodeDetailSheet(node: node, child: child, lessons: lessons)
        }
        .overlay {
            if viewModel?.shouldShowCelebration == true {
                CelebrationOverlay {
                    viewModel?.markCelebrationSeen(for: child)
                }
            }
        }
        .onAppear {
            setupViewModel()
            refreshTreeData()
        }
        .onChange(of: child.totalLessonsCompleted) { _, _ in
            // Reload tree when lessons completed count changes
            refreshTreeData()
        }
        .accessibilityLabel("Learning tree showing your progress")
    }
    
    private func setupViewModel() {
        if viewModel == nil {
            let vm = LearningTreeViewModel(modelContext: modelContext)
            viewModel = vm
            
            // Load data asynchronously to prevent UI blocking
            Task {
                await vm.loadTreeData(for: child, lessons: lessons)
                
                // Start animation after data loads
                try? await Task.sleep(for: .milliseconds(100))
                vm.startTreeAnimation()
            }
        }
    }
    
    private func refreshTreeData() {
        guard let vm = viewModel else { return }
        
        Task {
            await vm.loadTreeData(for: child, lessons: lessons)
        }
    }
}

// MARK: - Tree Reveal Modifier

private struct TreeRevealModifier: ViewModifier {
    let progress: Double
    let delay: Double
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            let adjustedProgress = max(0, min(1, (progress - delay) * 1.5))
            
            content
                .opacity(min(adjustedProgress * 2, 1.0))
                .scaleEffect(0.8 + (adjustedProgress * 0.2))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Child.self, Lesson.self, LessonProgress.self, configurations: config)
    
    // Create sample child
    let child = Child(name: "Ahmed", birthYear: 2019, avatarId: "cat")
    container.mainContext.insert(child)
    
    // Create sample lessons
    let categories: [LessonCategory] = [.aqeedah, .salah, .wudu, .quran, .duaa]
    var lessons: [Lesson] = []
    
    for (index, category) in categories.enumerated() {
        let lesson = Lesson(
            title: "\(category.rawValue) Lesson \(index + 1)",
            lessonDescription: "Learn about \(category.rawValue)",
            category: category,
            durationMinutes: 5,
            xpReward: 20,
            order: index,
            weekNumber: 1
        )
        container.mainContext.insert(lesson)
        lessons.append(lesson)
        
        // Mark first 2 as completed
        if index < 2 {
            let progress = LessonProgress(
                lessonId: lesson.id,
                lastCompletedPhase: "reward",
                phaseProgress: [:],
                lastAccessedAt: Date()
            )
            progress.isCompleted = true
            progress.completedAt = Date()
            progress.xpEarned = 20
            progress.child = child
            container.mainContext.insert(progress)
        }
    }
    
    return NavigationStack {
        LearningTreeView(child: child, lessons: lessons, modelContext: container.mainContext)
            .background(Color.backgroundSecondary)
    }
    .modelContainer(container)
    .environment(AppState())
}
