//
//  LearningTreeViewModel.swift
//  Sidrat
//
//  ViewModel for Learning Tree visualization
//  Manages tree nodes, paths, growth state, and animations
//

import SwiftUI
import SwiftData

// MARK: - Tree Models

/// Represents a lesson node on the tree
struct TreeNode: Identifiable {
    let id: UUID
    let position: TreeNodePosition
    let category: LessonCategory
    let lessonId: UUID
    let lessonTitle: String
    let isCompleted: Bool
    let branchLevel: Int
    let weekNumber: Int
}

enum TreeNodePosition {
    case left
    case right
}

/// Represents a path segment connecting two nodes
struct TreePathSegment: Identifiable {
    let id = UUID()
    let startPoint: CGPoint
    let endPoint: CGPoint
    let isCompleted: Bool
}

/// Tree growth state based on completion percentage
enum TreeGrowthState {
    case skeleton      // 0-25% completion
    case sprouting     // 26-50% completion
    case growing       // 51-75% completion
    case flourishing   // 76-100% completion
    
    var treeColor: Color {
        switch self {
        case .skeleton: return .textTertiary
        case .sprouting: return .brandPrimary.opacity(0.3)
        case .growing: return .brandSecondary.opacity(0.6)
        case .flourishing: return .brandSecondary
        }
    }
    
    var detailLevel: Double {
        switch self {
        case .skeleton: return 0.2
        case .sprouting: return 0.4
        case .growing: return 0.7
        case .flourishing: return 1.0
        }
    }
    
    var description: String {
        switch self {
        case .skeleton: return "Just starting - keep learning!"
        case .sprouting: return "Your tree is sprouting! 🌱"
        case .growing: return "Growing strong! 🌿"
        case .flourishing: return "Flourishing beautifully! 🌳"
        }
    }
}

// MARK: - ViewModel

@Observable
final class LearningTreeViewModel {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    
    // MARK: - State
    var treeNodes: [TreeNode] = []
    var pathSegments: [TreePathSegment] = []
    var growthState: TreeGrowthState = .skeleton
    var selectedNode: TreeNode?
    var hasNewAchievement: Bool = false
    var shouldShowCelebration: Bool = false
    var isLoading: Bool = false
    
    // Animation states
    var treeAppearProgress: Double = 0
    var nodeAnimationDelays: [UUID: Double] = [:]
    
    // Debouncing
    private var selectionTask: Task<Void, Never>?
    
    // Tree dimensions (can be adjusted for different screen sizes)
    private let horizontalOffset: CGFloat = 80
    private let verticalSpacing: CGFloat = 120
    private let treeTopPadding: CGFloat = 100
    
    // MARK: - Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Actions
    
    /// Load tree data for current child (async to prevent UI blocking)
    func loadTreeData(for child: Child, lessons: [Lesson]) async {
        isLoading = true
        
        // Extract necessary data from child on main actor before detached task
        let childName = child.name
        let childAchievements = child.achievements
        
        // Perform heavy computation off main thread
        let result: (nodes: [TreeNode], segments: [TreePathSegment], growth: TreeGrowthState, completion: Double) = await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { 
                return ([], [], .skeleton, 0.0) 
            }
            
            // Calculate completion and growth state
            let completionPercentage = self.calculateCompletionPercentage(child: child, lessons: lessons)
            let growthState = self.determineGrowthState(completionPercentage: completionPercentage)
            
            // Build tree structure
            let nodes = self.buildTreeNodes(child: child, lessons: lessons)
            let segments = self.buildPathSegments(nodes: nodes)
            
            return (nodes, segments, growthState, completionPercentage)
        }.value
        
        // Update UI on main thread
        await MainActor.run {
            self.treeNodes = result.nodes
            self.pathSegments = result.segments
            self.growthState = result.growth
            
            // Calculate animation delays (fast operation, safe on main thread)
            self.calculateAnimationDelays()
            
            // Check for new achievements using extracted data
            self.checkForNewAchievements(achievements: childAchievements)
            
            self.isLoading = false
            
            #if DEBUG
            print("[LearningTreeViewModel] Loaded \(self.treeNodes.count) nodes for \(childName)")
            print("[LearningTreeViewModel] Growth: \(self.growthState), Completion: \(Int(result.completion * 100))%")
            #endif
        }
    }
    
    /// Handle node tap (debounced to prevent UI blocking)
    func selectNode(_ node: TreeNode) {
        // Cancel any pending selection
        selectionTask?.cancel()
        
        // Debounce selection to prevent rapid taps
        selectionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled else { return }
            
            // Provide haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            selectedNode = node
        }
    }
    
    /// Start tree appearance animation
    func startTreeAnimation() {
        withAnimation(.easeOut(duration: 1.5)) {
            treeAppearProgress = 1.0
        }
    }
    
    /// Mark celebration as seen and clear isNew flag on achievements
    func markCelebrationSeen(for child: Child) {
        #if DEBUG
        print("[LearningTreeViewModel] Marking \(child.achievements.filter { $0.isNew }.count) achievements as seen")
        #endif
        
        shouldShowCelebration = false
        
        // Clear isNew flag on all achievements so they don't show again
        for achievement in child.achievements where achievement.isNew {
            achievement.isNew = false
        }
        
        // Save the changes to persist the update
        do {
            try modelContext.save()
            #if DEBUG
            print("[LearningTreeViewModel] Successfully saved achievement state")
            #endif
        } catch {
            #if DEBUG
            print("[LearningTreeViewModel] ERROR saving achievement state: \(error)")
            #endif
            // Silently fail - non-critical operation
        }
    }
    
    /// Calculate position for a node on the screen
    func nodePosition(for node: TreeNode, screenWidth: CGFloat = UIScreen.main.bounds.width) -> CGPoint {
        let centerX = screenWidth / 2
        let offset = node.position == .left ? -horizontalOffset : horizontalOffset
        let y = CGFloat(node.branchLevel) * verticalSpacing + treeTopPadding
        
        return CGPoint(x: centerX + offset, y: y)
    }
    
    /// Calculate total tree height
    func calculateTreeHeight() -> CGFloat {
        guard !treeNodes.isEmpty else { return 1000 }
        return CGFloat(treeNodes.count) * verticalSpacing + treeTopPadding + 200
    }
    
    // MARK: - Private Helpers
    
    /// Build tree nodes from lessons (alternating left/right)
    private func buildTreeNodes(child: Child, lessons: [Lesson]) -> [TreeNode] {
        var nodes: [TreeNode] = []
        let sortedLessons = lessons.sorted { $0.order < $1.order }
        
        for (index, lesson) in sortedLessons.enumerated() {
            // Check if lesson is completed
            let isCompleted = child.lessonProgress.contains {
                $0.lessonId == lesson.id && $0.isCompleted
            }
            
            // Alternate position (left/right)
            let position: TreeNodePosition = index % 2 == 0 ? .left : .right
            
            // Create node
            let node = TreeNode(
                id: lesson.id,
                position: position,
                category: lesson.category,
                lessonId: lesson.id,
                lessonTitle: lesson.title,
                isCompleted: isCompleted,
                branchLevel: index,
                weekNumber: lesson.weekNumber
            )
            
            nodes.append(node)
        }
        
        return nodes
    }
    
    /// Build winding path segments connecting nodes
    private func buildPathSegments(nodes: [TreeNode]) -> [TreePathSegment] {
        var segments: [TreePathSegment] = []
        
        guard nodes.count > 1 else { return segments }
        
        for i in 0..<(nodes.count - 1) {
            let currentNode = nodes[i]
            let nextNode = nodes[i + 1]
            
            // Calculate positions
            let startPoint = nodePosition(for: currentNode)
            let endPoint = nodePosition(for: nextNode)
            
            // Segment is completed if both connected nodes are complete
            let isCompleted = currentNode.isCompleted && nextNode.isCompleted
            
            let segment = TreePathSegment(
                startPoint: startPoint,
                endPoint: endPoint,
                isCompleted: isCompleted
            )
            
            segments.append(segment)
        }
        
        return segments
    }
    
    /// Calculate completion percentage
    private func calculateCompletionPercentage(child: Child, lessons: [Lesson]) -> Double {
        guard !lessons.isEmpty else { return 0 }
        
        let completedCount = child.lessonProgress.filter { progress in
            progress.isCompleted
        }.count
        
        return Double(completedCount) / Double(lessons.count)
    }
    
    /// Determine tree growth state based on completion
    private func determineGrowthState(completionPercentage: Double) -> TreeGrowthState {
        switch completionPercentage {
        case 0..<0.25:
            return .skeleton
        case 0.25..<0.50:
            return .sprouting
        case 0.50..<0.75:
            return .growing
        default:
            return .flourishing
        }
    }
    
    /// Calculate animation delays for staggered node reveal (optimized)
    private func calculateAnimationDelays() {
        // Only calculate delays for first 10 nodes to reduce overhead
        // Later nodes appear instantly for better performance
        let maxAnimatedNodes = 10
        nodeAnimationDelays.removeAll(keepingCapacity: true)
        
        for node in treeNodes.prefix(maxAnimatedNodes) {
            let delay = Double(node.branchLevel) * 0.05
            nodeAnimationDelays[node.id] = delay
        }
    }
    
    /// Check for new achievements
    private func checkForNewAchievements(achievements: [Achievement]) {
        let newAchievements = achievements.filter { $0.isNew }
        
        #if DEBUG
        if !newAchievements.isEmpty {
            print("[LearningTreeViewModel] Found \(newAchievements.count) new achievement(s):")
            for achievement in newAchievements {
                print("  - \(achievement.achievementType.title)")
            }
        }
        #endif
        
        hasNewAchievement = !newAchievements.isEmpty
        shouldShowCelebration = hasNewAchievement
    }
}
