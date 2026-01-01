# Sidrat iOS Project Context

> **Reference Document for AI Agents** - Read this FIRST before implementing any user story.

---

## 1. Project Overview

**Sidrat** is an Islamic learning app for children ages 5-7, featuring daily 5-minute lessons and weekly 15-minute family activities. The app is built with SwiftUI, SwiftData, and targets iOS 17+.

### Key Principles
- **Offline-first**: Core lessons bundled, progress saved locally
- **COPPA compliant**: No PII collection, parental gates required
- **Kids Category ready**: No third-party analytics, age-appropriate content
- **Family-focused**: Parent controls, multi-child support

---

## 2. Project Structure

```
Sidrat/
├── App/                          # App entry and navigation
│   ├── SidratApp.swift          # @main, AppState, SwiftData container
│   ├── RootView.swift           # Onboarding/Main switch, data seeding
│   └── MainTabView.swift        # Tab navigation (5 tabs)
│
├── Core/
│   └── Models/                   # SwiftData models
│       ├── Child.swift          # Child profile with progress
│       ├── Lesson.swift         # Lesson content and metadata
│       ├── LessonProgress.swift # Per-lesson completion tracking
│       ├── Achievement.swift    # Badges/achievements
│       └── FamilyActivity.swift # Weekly family activities
│
├── Features/                     # Feature modules (MVVM)
│   ├── Onboarding/              # US-102, US-103
│   ├── Home/                    # US-201
│   ├── Learn/                   # US-202, US-203, US-204, US-205
│   │   ├── LearnView.swift
│   │   ├── LessonDetailView.swift
│   │   ├── LessonPlayerView.swift
│   │   └── LessonCompletionView.swift
│   ├── Family/                  # US-401, US-402, US-403
│   ├── Progress/                # US-301, US-302, US-303, US-304
│   └── Settings/                # US-501, US-502, US-503, US-504
│
├── UI/
│   ├── Theme/
│   │   └── Theme.swift          # Colors, typography, spacing, shadows
│   └── Components/
│       └── Components.swift     # Reusable UI components
│
└── Resources/
    ├── Assets.xcassets/         # Images, colors, app icon
    └── Preview Content/         # Preview assets
```

---

## 3. Architecture Pattern: MVVM

All new features should follow this pattern:

```
Features/{FeatureName}/
├── Views/
│   └── {Feature}View.swift      # SwiftUI View
├── ViewModels/
│   └── {Feature}ViewModel.swift # @Observable class
└── Components/                  # Feature-specific components (optional)
```

### ViewModel Template
```swift
import SwiftUI
import SwiftData

@Observable
final class {Feature}ViewModel {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    
    // MARK: - Published State
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Actions
    func performAction() {
        // Implementation
    }
}
```

### View Template
```swift
import SwiftUI
import SwiftData

struct {Feature}View: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var viewModel: {Feature}ViewModel?
    
    var body: some View {
        content
            .onAppear {
                if viewModel == nil {
                    viewModel = {Feature}ViewModel(modelContext: modelContext)
                }
            }
    }
    
    @ViewBuilder
    private var content: some View {
        // View implementation
    }
}
```

---

## 4. Design System Reference

### Colors (from Theme.swift)
```swift
// Primary Brand Colors
Color.brandPrimary      // Teal #0C7489
Color.brandPrimaryLight // #0E8FA6
Color.brandPrimaryDark  // #095A6B

// Secondary Colors
Color.brandSecondary    // Green #488B49
Color.brandAccent       // Gold #DAA520

// Backgrounds
Color.backgroundPrimary   // White
Color.backgroundSecondary // Light gray #F5F5F5
Color.backgroundTertiary  // #EDEDED

// Text
Color.textPrimary    // #2C3E3F
Color.textSecondary  // #6B7280
Color.textTertiary   // #9CA3AF

// Semantic
Color.success  // Green
Color.warning  // Gold
Color.error    // Red #DC2626
```

### Typography (from Theme.swift)
```swift
Font.displayLarge   // 40pt bold rounded
Font.displayMedium  // 34pt bold rounded
Font.title1         // 28pt bold rounded
Font.title2         // 22pt bold rounded
Font.title3         // 20pt semibold rounded
Font.bodyLarge      // 18pt regular
Font.bodyMedium     // 16pt regular
Font.bodySmall      // 14pt regular
Font.labelLarge     // 17pt semibold rounded
Font.labelMedium    // 15pt semibold rounded
Font.labelSmall     // 13pt semibold rounded
Font.caption        // 12pt regular
```

### Spacing (from Theme.swift)
```swift
Spacing.xxs  // 4pt
Spacing.xs   // 8pt
Spacing.sm   // 12pt
Spacing.md   // 16pt
Spacing.lg   // 24pt
Spacing.xl   // 32pt
Spacing.xxl  // 48pt
Spacing.xxxl // 64pt
```

### Corner Radius
```swift
CornerRadius.small      // 8pt
CornerRadius.medium     // 12pt
CornerRadius.large      // 16pt
CornerRadius.extraLarge // 24pt
CornerRadius.xxl        // 32pt
```

### Shadows (View Modifiers)
```swift
.subtleShadow()    // Light shadow for subtle elevation
.cardShadow()      // Standard card elevation
.elevatedShadow()  // High elevation
.glowShadow()      // Colored glow effect
```

### Button Styles
```swift
Button("Action") { }
    .buttonStyle(.primary)   // Teal gradient, white text
    .buttonStyle(.secondary) // Outlined, teal text
    .buttonStyle(.accent)    // Gold gradient
```

### Gradients
```swift
LinearGradient.primaryGradient   // Teal gradient
LinearGradient.secondaryGradient // Green gradient
LinearGradient.accentGradient    // Gold gradient
LinearGradient.heroGradient      // Teal → Green → Gold
```

---

## 5. Existing Components (Components.swift)

| Component | Usage |
|-----------|-------|
| `PrimaryButton(title:icon:action:)` | Main CTA buttons |
| `SecondaryButton(title:icon:action:)` | Secondary actions |
| `IconBadge(icon:color:size:)` | Circular icon badges |
| `ProgressRing(progress:lineWidth:color:)` | Circular progress indicator |
| `XPBadge(xp:)` | XP display pill |
| `LessonCard(...)` | Lesson list item |
| `EmptyState(icon:title:message:actionTitle:action:)` | Empty state placeholder |

---

## 6. Data Models Reference

### Child
```swift
@Model class Child {
    var id: UUID
    var name: String
    var age: Int
    var avatarName: String
    var createdAt: Date
    var currentStreak: Int
    var longestStreak: Int
    var totalLessonsCompleted: Int
    var totalXP: Int
    @Relationship(deleteRule: .cascade) var lessonProgress: [LessonProgress]
    @Relationship(deleteRule: .cascade) var achievements: [Achievement]
}
```

### Lesson
```swift
@Model class Lesson {
    var id: UUID
    var title: String
    var lessonDescription: String
    var category: LessonCategory  // .aqeedah, .salah, .wudu, .quran, .seerah, .adab, .duaa, .stories
    var difficulty: Difficulty    // .beginner, .intermediate, .advanced
    var durationMinutes: Int
    var xpReward: Int
    var order: Int
    var weekNumber: Int
    var content: [LessonContent]
}
```

### LessonProgress
```swift
@Model class LessonProgress {
    var id: UUID
    var lessonId: UUID
    var isCompleted: Bool
    var completedAt: Date?
    var score: Int
    var xpEarned: Int
    var attempts: Int
    @Relationship var child: Child?
}
```

### Achievement
```swift
@Model class Achievement {
    var id: UUID
    var achievementType: AchievementType
    var unlockedAt: Date
    var isNew: Bool
    @Relationship var child: Child?
}
```

### FamilyActivity
```swift
@Model class FamilyActivity {
    var id: UUID
    var title: String
    var activityDescription: String
    var instructions: [String]
    var durationMinutes: Int
    var weekNumber: Int
    var relatedCategory: LessonCategory
    var isCompleted: Bool
    var completedAt: Date?
    var parentTips: [String]
    var conversationPrompts: [String]
}
```

---

## 7. AppState Reference

```swift
@Observable class AppState {
    var isOnboardingComplete: Bool  // Persisted to UserDefaults
    var currentChildId: String?     // UUID string of active child
    var dailyStreak: Int
    var lastCompletedDate: Date?
}
```

**Access pattern:**
```swift
@Environment(AppState.self) private var appState
```

---

## 8. Common Patterns

### Accessing Current Child
```swift
@Query private var children: [Child]
@Environment(AppState.self) private var appState

private var currentChild: Child? {
    guard let childId = appState.currentChildId,
          let uuid = UUID(uuidString: childId) else { return nil }
    return children.first { $0.id == uuid }
}
```

### Parental Gate Pattern (US-104)
```swift
struct ParentalGateView: View {
    @State private var firstNumber = Int.random(in: 10...20)
    @State private var secondNumber = Int.random(in: 1...10)
    @State private var userAnswer = ""
    let onSuccess: () -> Void
    
    var body: some View {
        // Math problem verification
    }
}
```

### Navigation Pattern
```swift
@State private var selectedItem: ItemType?

.sheet(item: $selectedItem) { item in
    DetailView(item: item)
}

// OR for full screen
.fullScreenCover(isPresented: $showingCover) {
    FullScreenView()
}
```

### SwiftData Queries
```swift
@Query private var items: [Item]
@Query(sort: \Item.order) private var sortedItems: [Item]
@Query(filter: #Predicate<Item> { $0.isActive }) private var activeItems: [Item]
```

---

## 9. File Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Views | `{Name}View.swift` | `HomeView.swift` |
| ViewModels | `{Name}ViewModel.swift` | `HomeViewModel.swift` |
| Models | `{Name}.swift` | `Child.swift` |
| Components | Descriptive name | `LessonCard.swift` |

---

## 10. Adding New Files to project.pbxproj

When adding new files, you must update `project.pbxproj` with:

1. **PBXFileReference** - File registration
2. **PBXBuildFile** - Build phase inclusion
3. **PBXGroup** - Group membership

Use incremental IDs following existing patterns:
- `SRC00XX` for source files
- `FEA00XX` for feature build files
- `GRP00XX` for groups

---

## 11. Testing on Physical Device

**Important**: No simulators are installed. All testing must be done on a physical device.

- Ensure all previews use `#Preview` macro with proper environment setup
- Include mock data for previews
- Test offline functionality

---

## 12. COPPA Compliance Requirements

- ✅ No email collection from children
- ✅ Parental gate for settings/external links
- ✅ No third-party analytics (Firebase Analytics removed)
- ✅ No behavioral advertising
- ✅ Data stored locally or in user's private CloudKit
- ✅ Privacy policy accessible

---

## 13. Dependencies

Currently the project uses only Apple frameworks:
- SwiftUI
- SwiftData
- Foundation

Future additions (not yet integrated):
- Lottie (animations)
- Firebase Auth (authentication)
- CloudKit (sync)

---

## 14. Quick Reference Commands

```bash
# Project location
cd /path/to/sidrat-ios

# Build (Xcode)
xcodebuild -project Sidrat.xcodeproj -scheme Sidrat -destination 'platform=iOS,name=iPhone'
```

---

*Last Updated: December 2024*
