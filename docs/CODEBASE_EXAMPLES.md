# Sidrat Codebase Examples

> Real implementations to guide code generation

## AppState Pattern
```swift
// File: App/SidratApp.swift (bottom of file - line ~131)
// NOTE: AppState is defined within SidratApp.swift, NOT in a separate file
import SwiftUI

@Observable
final class AppState {
    var isOnboardingComplete: Bool {
        didSet {
            UserDefaults.standard.set(isOnboardingComplete, forKey: "isOnboardingComplete")
        }
    }
    
    var currentChildId: String? {
        didSet {
            UserDefaults.standard.set(currentChildId, forKey: "currentChildId")
        }
    }
    
    var parentUserIdentifier: String?
    var isLocalOnlyAccount: Bool
    var dailyStreak: Int = 0
    var lastCompletedDate: Date?
    
    var hasParentAccount: Bool {
        parentUserIdentifier != nil
    }
    
    init() {
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: "isOnboardingComplete")
        self.currentChildId = UserDefaults.standard.string(forKey: "currentChildId")
        self.parentUserIdentifier = UserDefaults.standard.string(forKey: "parentUserIdentifier")
        self.isLocalOnlyAccount = UserDefaults.standard.bool(forKey: "isLocalOnlyAccount")
    }
}
```

## Child Model (Actual Implementation)
```swift
// File: Core/Models/Child.swift
import Foundation
import SwiftData

@Model
final class Child {
    var id: UUID
    var name: String
    var birthYear: Int  // Privacy: store year only, not exact birthdate (COPPA compliant)
    var avatarId: String  // Stored as String for SwiftData compatibility
    var createdAt: Date
    var lastAccessedAt: Date
    var currentStreak: Int
    var longestStreak: Int
    var totalLessonsCompleted: Int
    var totalXP: Int
    var lastLessonCompletedDate: Date?
    var currentWeekNumber: Int
    
    @Relationship(deleteRule: .cascade) var lessonProgress: [LessonProgress]
    @Relationship(deleteRule: .cascade) var achievements: [Achievement]
    
    // Computed property for current age
    @Transient
    var currentAge: Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - birthYear
    }
    
    // Computed property for avatar enum
    @Transient
    var avatar: AvatarOption {
        AvatarOption(rawValue: avatarId) ?? .cat
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        birthYear: Int,
        avatarId: String,
        createdAt: Date = Date(),
        lastAccessedAt: Date = Date(),
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalLessonsCompleted: Int = 0,
        totalXP: Int = 0,
        lastLessonCompletedDate: Date? = nil,
        currentWeekNumber: Int = 1
    ) {
        self.id = id
        self.name = name
        self.birthYear = birthYear
        self.avatarId = avatarId
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalLessonsCompleted = totalLessonsCompleted
        self.totalXP = totalXP
        self.lastLessonCompletedDate = lastLessonCompletedDate
        self.currentWeekNumber = currentWeekNumber
        self.lessonProgress = []
        self.achievements = []
    }
}
```

## ViewModel Pattern (Standard Template)
```swift
// File: Features/{Feature}/ViewModels/{Feature}ViewModel.swift
import SwiftUI
import SwiftData

@Observable
final class OnboardingViewModel {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    
    // MARK: - Published State
    var childName = ""
    var selectedAvatar = "avatar1"
    var childAge = 5
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Actions
    func createChildProfile(completion: @escaping (Child?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let child = Child(
            name: childName,
            age: childAge,
            avatarName: selectedAvatar
        )
        
        modelContext.insert(child)
        
        do {
            try modelContext.save()
            isLoading = false
            completion(child)
        } catch {
            errorMessage = "Failed to create profile: \(error.localizedDescription)"
            isLoading = false
            completion(nil)
        }
    }
}
```

## View Pattern with ViewModel
```swift
// File: Features/Onboarding/Views/OnboardingView.swift
import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var viewModel: OnboardingViewModel?
    
    var body: some View {
        content
            .onAppear {
                if viewModel == nil {
                    viewModel = OnboardingViewModel(modelContext: modelContext)
                }
            }
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(spacing: Spacing.xl) {
            Text("Create Child Profile")
                .font(.displayMedium)
            
            if let vm = viewModel {
                TextField("Child's Name", text: $vm.childName)
                    .textFieldStyle(.roundedBorder)
                
                PrimaryButton(
                    title: "Create Profile",
                    icon: "plus.circle.fill"
                ) {
                    vm.createChildProfile { child in
                        if let child = child {
                            appState.currentChildId = child.id.uuidString
                            appState.isOnboardingComplete = true
                        }
                    }
                }
                .disabled(vm.childName.isEmpty)
            }
        }
        .padding(Spacing.xl)
    }
}
```

## Component Usage (from Components.swift)
```swift
// Primary Button
PrimaryButton(
    title: "Start Lesson",
    icon: "play.circle.fill"
) {
    // Action
}

// Lesson Card
LessonCard(
    title: "Who is Allah?",
    category: .aqeedah,
    duration: 5,
    isCompleted: false,
    progress: 0.3
) {
    // Tap action
}

// Empty State
EmptyState(
    icon: "book.closed",
    title: "No Lessons Yet",
    message: "Complete onboarding to start learning",
    actionTitle: "Get Started"
) {
    // Action
}
```

## SwiftData Query Pattern
```swift
// Basic query
@Query private var children: [Child]

// Sorted query
@Query(sort: \Lesson.order) private var lessons: [Lesson]

// Filtered query
@Query(filter: #Predicate<Lesson> { 
    $0.category == .aqeedah 
}) private var aqeedahLessons: [Lesson]

// Complex filter
@Query(filter: #Predicate<LessonProgress> { progress in
    progress.isCompleted && progress.child?.id == currentChildId
}) private var completedLessons: [LessonProgress]
```

## Current Child Access Pattern
```swift
@Query private var children: [Child]
@Environment(AppState.self) private var appState

private var currentChild: Child? {
    guard let childId = appState.currentChildId,
          let uuid = UUID(uuidString: childId) else { 
        return nil 
    }
    return children.first { $0.id == uuid }
}

// Usage
if let child = currentChild {
    Text("Hello, \(child.name)!")
}
```

## Error Handling Pattern
```swift
enum AppError: LocalizedError {
    case childNotFound
    case lessonNotFound
    case syncFailed(underlying: Error)
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .childNotFound:
            return "Child profile not found"
        case .lessonNotFound:
            return "Lesson not available"
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}

// In ViewModel
func performAction() {
    do {
        try dangerousOperation()
    } catch let error as AppError {
        errorMessage = error.localizedDescription
    } catch {
        errorMessage = "An unexpected error occurred"
    }
}
```

## LessonProgressService Pattern (US-204)
```swift
// File: Core/Services/LessonProgressService.swift
import SwiftUI
import SwiftData

@Observable
final class LessonProgressService {
    private let modelContext: ModelContext
    var errorMessage: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Save phase progress
    func savePhaseProgress(lessonId: UUID, childId: UUID, phase: String) async throws {
        print("[LessonProgressService] Saving phase: \(phase)")
        
        let descriptor = FetchDescriptor<LessonProgress>(
            predicate: #Predicate<LessonProgress> { progress in
                progress.lessonId == lessonId && progress.child?.id == childId
            }
        )
        
        let existingProgress = try? modelContext.fetch(descriptor).first
        
        if let progress = existingProgress {
            progress.markPhaseComplete(phase)
        } else {
            let newProgress = LessonProgress(
                lessonId: lessonId,
                lastCompletedPhase: phase,
                phaseProgress: [phase: Date()],
                lastAccessedAt: Date()
            )
            modelContext.insert(newProgress)
        }
        
        try modelContext.save()
    }
    
    // Load partial progress for resume
    func loadPartialProgress(lessonId: UUID, childId: UUID) -> String? {
        let descriptor = FetchDescriptor<LessonProgress>(
            predicate: #Predicate<LessonProgress> { progress in
                progress.lessonId == lessonId && progress.child?.id == childId
            }
        )
        
        guard let progress = try? modelContext.fetch(descriptor).first,
              progress.isPartialProgress,
              let lastPhase = progress.lastCompletedPhase else {
            return nil
        }
        
        return lastPhase
    }
}

// Usage in ViewModel
@Observable
final class LessonPlayerViewModel {
    private let progressService: LessonProgressService
    var hasPartialProgress = false
    var resumeFromPhase: Phase?
    
    init(lesson: Lesson, child: Child, modelContext: ModelContext, progressService: LessonProgressService) {
        self.progressService = progressService
        // ...
    }
    
    // Check for partial progress on view appear
    func checkForPartialProgress() async {
        guard let lastPhaseString = progressService.loadPartialProgress(
            lessonId: lesson.id,
            childId: child.id
        ) else { return }
        
        // Map string to phase enum and resume
        hasPartialProgress = true
        resumeFromPhase = mapPhase(lastPhaseString)
        currentPhase = resumeFromPhase!
    }
    
    // Save after each phase transition
    private func savePhaseProgress(_ phase: Phase) {
        Task {
            try? await progressService.savePhaseProgress(
                lessonId: lesson.id,
                childId: child.id,
                phase: phase.rawValue
            )
        }
    }
}

// Usage in View
struct LessonPlayerView: View {
    @State private var viewModel: LessonPlayerViewModel?
    @State private var showResumeBanner = false
    
    var body: some View {
        VStack {
            if showResumeBanner, let resumePhase = viewModel?.resumeFromPhase {
                ResumeBanner(phaseName: resumePhase.title)
            }
            // ... rest of view
        }
        .task {
            if let vm = viewModel {
                await vm.checkForPartialProgress()
                if vm.hasPartialProgress {
                    withAnimation { showResumeBanner = true }
                    Task {
                        try? await Task.sleep(for: .seconds(3))
                        withAnimation { showResumeBanner = false }
                    }
                }
            }
        }
    }
    
    private func setupViewModel() {
        guard let child = currentChild else { return }
        let progressService = LessonProgressService(modelContext: modelContext)
        viewModel = LessonPlayerViewModel(
            lesson: lesson,
            child: child,
            modelContext: modelContext,
            progressService: progressService
        )
    }
}
```