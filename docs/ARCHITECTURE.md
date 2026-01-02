# Sidrat: System Architecture

## Technology Stack
- **UI**: SwiftUI (iOS 17+)
- **Data**: SwiftData for local persistence
- **Sync**: CloudKit (private database) for child progress
- **Auth**: Firebase Auth (Sign in with Apple only)
- **Storage**: Firebase Storage + bundled assets
- **Offline**: Offline-first with automatic sync

## Architecture Pattern: MVVM

### Structure
```
Features/{FeatureName}/
├── Views/{Feature}View.swift
├── ViewModels/{Feature}ViewModel.swift
└── Components/ (optional)
```

### Data Flow
1. View reads from SwiftData via @Query
2. User actions trigger ViewModel methods
3. ViewModel updates ModelContext
4. SwiftData propagates changes to Views
5. CloudKit syncs changes in background

## Core Services

### Authentication Service
- **Location**: `Core/Services/AuthenticationService.swift`
- **Purpose**: Sign in with Apple authentication
- **Features**:
  - Privacy-first (no email collection)
  - Local-only account fallback for offline mode
  - Keychain integration for credential storage
  - COPPA-compliant implementation

### Audio Services
- **AudioPlayerService**: Core audio playback engine
- **AudioQueueService**: Audio queue management for playlists
- **AudioNarrationService**: Lesson narration with automatic phase progression
- **SoundEffectsService**: UI sound effects and feedback
- **ElevenLabsService**: AI voice generation integration (future)

## Data Models

### Relationships
```
Child (1) ──< (many) LessonProgress
Child (1) ──< (many) Achievement
Lesson (1) ──< (many) LessonProgress
```

### Child Model Properties
- `birthYear`: Privacy-compliant (year only, not exact birthdate)
- `avatarId`: String reference to AvatarOption enum
- `lastAccessedAt`: For profile switching optimization
- `currentWeekNumber`: Tracks curriculum progression
- `totalXP`, `currentStreak`, `longestStreak`: Gamification metrics

### Sync Strategy
- **Local-first**: All operations work offline
- **Last-write-wins with intelligent merge**: Learning progress never decreases
- **Conflict resolution**: Highest completion percentage wins
- **Aggregate time**: Sum time spent across devices

## Key Design Decisions

### Why SwiftData over Core Data?
- Modern Swift-first API
- Less boilerplate
- Better SwiftUI integration
- Automatic CloudKit sync (future)

### Why CloudKit for child data?
- Data stored in user's iCloud (maximum privacy)
- No third-party exposure (COPPA compliant)
- Free for reasonable usage
- Native iOS integration

### Why Firebase Auth?
- Sign in with Apple integration
- No email collection needed
- 50K free monthly active users
- Familiar to most developers

### Why offline-first?
- Target audience may have limited connectivity
- Better user experience (instant feedback)
- COPPA compliance (less data transmission)
- Core learning should never be blocked

## Design System

### Colors (Theme.swift)
```swift
// Primary Brand
Color.brandPrimary       // Teal #0C7489
Color.brandSecondary     // Green #488B49
Color.brandAccent        // Gold #DAA520

// Backgrounds
Color.backgroundPrimary   // White
Color.backgroundSecondary // Light gray #F5F5F5
Color.surfacePrimary      // Same as backgroundPrimary
Color.surfaceSecondary    // Same as backgroundSecondary

// Text
Color.textPrimary    // #2C3E3F
Color.textSecondary  // #6B7280
Color.textTertiary   // #9CA3AF

// Semantic
Color.success  // Green
Color.warning  // Gold
Color.error    // Red #DC2626
```

### Typography (Theme.swift)
```swift
Font.displayLarge   // 40pt bold rounded
Font.displayMedium  // 34pt bold rounded
Font.title1         // 28pt bold rounded
Font.title2         // 22pt bold rounded
Font.bodyLarge      // 18pt regular
Font.bodyMedium     // 16pt regular
Font.bodySmall      // 14pt regular
Font.labelLarge     // 17pt semibold rounded
Font.labelMedium    // 15pt semibold rounded
Font.caption        // 12pt regular
```

### Spacing (Theme.swift)
```swift
Spacing.xxs  // 4pt
Spacing.xs   // 8pt
Spacing.sm   // 12pt
Spacing.md   // 16pt
Spacing.lg   // 24pt
Spacing.xl   // 32pt
Spacing.xxl  // 48pt
```

### Shadows and Effects
```swift
.cardShadow()      // Standard card elevation
.elevatedShadow()  // Higher elevation for floating elements
```

### Components (Components.swift)
- **PrimaryButton**: Main CTA button with gradient
- **SecondaryButton**: Secondary actions
- **LessonCard**: Lesson preview card
- **EmptyState**: Empty state with icon and message
- **IconBadge**: Circular icon badge (small/medium/large)
- **StreakCounter**: Animated streak display
- **XPBadge**: Experience points display
- **ParentalGateView**: COPPA-compliant verification

## Performance Targets
- App launch: < 2 seconds
- Lesson load: < 500ms
- Child profile switch: < 500ms
- Offline lesson playback: Instant
- CloudKit sync: Background, non-blocking

## Security & Privacy
- No child PII collected
- All child data in CloudKit private database
- Parental gate for sensitive actions
- No third-party analytics
- Data deletion available