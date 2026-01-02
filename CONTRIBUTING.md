# Contributing to Sidrat

## Development Setup

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ device for testing
- Git

### Getting Started
1. Clone repository
2. Open `Sidrat.xcodeproj`
3. Build and run on physical device (no simulator)

## Code Standards

### SwiftUI Views
- Use `@ViewBuilder` for complex view logic
- Extract subviews when body exceeds ~15 lines
- Use `#Preview` macro for all views

### Data Models
- All SwiftData models must have default values
- Relationships must be optional for CloudKit compatibility
- Use `@Relationship(deleteRule: .cascade)` for owned relationships

### Naming Conventions
- Views: `{Feature}View.swift`
- ViewModels: `{Feature}ViewModel.swift`
- Components: Descriptive names (e.g., `LessonCard.swift`)

### File Organization
- Place views in `Features/{Feature}/Views/`
- Place ViewModels in `Features/{Feature}/ViewModels/`
- Shared components in `UI/Components/`
- Models in `Core/Models/`

## Design System

### Always Use Theme Constants
```swift
// ✅ Correct
Text("Hello")
    .foregroundColor(.textPrimary)
    .font(.bodyLarge)
    .padding(Spacing.md)

// ❌ Wrong
Text("Hello")
    .foregroundColor(.black)
    .font(.system(size: 18))
    .padding(16)
```

### Use Existing Components
Before creating new components, check `UI/Components/Components.swift`

## COPPA Compliance

### Required for All Features
- Parental gate for settings/external links
- No PII collection from children
- No third-party analytics
- Local-first data storage

## Testing

### Before Submitting
- [ ] Builds without errors
- [ ] Works offline
- [ ] Follows design system
- [ ] Includes Preview
- [ ] COPPA compliant

## Pull Request Process

1. Create feature branch: `feature/US-XXX-description`
2. Implement feature following MVVM pattern
3. Test on physical device
4. Create PR with:
   - User story reference
   - Screenshots/video
   - Testing notes