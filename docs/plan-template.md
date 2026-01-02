---
title: [Feature Name]
user_story: [US-XXX]
date_created: [YYYY-MM-DD]
status: [draft | approved | implemented]
---

# Implementation Plan: [Feature Name]

## User Story Reference
**ID**: US-XXX  
**Title**: [User story title]  
**Epic**: [Epic name]

**As a** [user type]  
**I want** [action]  
**So that** [benefit]

### Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Current State Analysis

### What Exists
[From `docs/IMPLEMENTATION_STATUS.md`]
- Completed: [list]
- In Progress: [list]

### Dependencies
- Required features: [list features that must exist first]
- Required models: [list data models needed]
- Required components: [list UI components needed]

## Architecture & Design

### Data Models

#### Existing Models to Use
- `Child`: [how it's used]
- `Lesson`: [how it's used]
- `LessonProgress`: [how it's used]

#### New Models Required
```swift
@Model
class NewModel {
    var id: UUID
    var property: Type
    // ...
}
```

#### Model Modifications
```swift
// Modify existing model
// Before:
var oldProperty: Type

// After:
var newProperty: Type
var oldProperty: Type // Keep for migration
```

### View Hierarchy
```
{Feature}View
├── HeaderSection
├── ContentSection
│   ├── ItemCard (from Components.swift)
│   └── CustomComponent
└── FooterSection
    └── PrimaryButton (from Components.swift)
```

### ViewModel Design

#### State Properties
```swift
@Observable
final class {Feature}ViewModel {
    // Loading & Error
    var isLoading = false
    var errorMessage: String?
    
    // Feature-specific state
    var property1: Type = defaultValue
    var property2: Type = defaultValue
    
    // Dependencies
    private let modelContext: ModelContext
}
```

#### Actions/Methods
- `func action1()`: [description]
- `func action2()`: [description]
- `func action3()`: [description]

### Navigation Flow
- Entry point: [how user reaches this view]
- Navigation type: [sheet | fullScreenCover | push]
- Exit points: [how user leaves this view]

## Design System Usage

### Colors
- Primary: `Color.brandPrimary`
- Text: `Color.textPrimary`, `Color.textSecondary`
- Background: `Color.backgroundPrimary`

### Typography
- Headers: `Font.displayMedium`, `Font.title2`
- Body: `Font.bodyLarge`, `Font.bodyMedium`
- Labels: `Font.labelLarge`

### Components
- `PrimaryButton`: [usage]
- `LessonCard`: [usage]
- Custom component: [if needed, describe]

### Spacing
- Section padding: `Spacing.xl`
- Item spacing: `Spacing.md`
- Inline spacing: `Spacing.sm`

## Implementation Tasks

### Phase 1: ViewModel
- [ ] **Task 1.1**: Create `{Feature}ViewModel.swift`
  - Location: `Features/{Feature}/ViewModels/`
  - Properties: [list all @Published properties]
  - Methods: [list all action methods]
  - Dependencies: ModelContext, AppState

### Phase 2: View
- [ ] **Task 2.1**: Create `{Feature}View.swift`
  - Location: `Features/{Feature}/Views/`
  - Layout: [describe UI structure]
  - State management: [how it uses ViewModel]
  - Navigation: [how it handles navigation]

- [ ] **Task 2.2**: Add Preview
  - Mock data setup
  - Environment configuration
  - Test different states (loading, error, success)

### Phase 3: Integration
- [ ] **Task 3.1**: Wire up navigation
  - From: [source view]
  - To: `{Feature}View`
  - Type: [sheet | fullScreenCover | push]

- [ ] **Task 3.2**: Connect to data models
  - SwiftData queries
  - Data mutations
  - Sync handling

### Phase 4: Polish
- [ ] **Task 4.1**: Add animations
  - Transition effects
  - Loading states
  - Success/error feedback

- [ ] **Task 4.2**: Accessibility
  - VoiceOver labels
  - Dynamic type support
  - Reduced motion handling

## COPPA Compliance Checklist

- [ ] **No PII collected**: Verified no email, name, address, etc.
- [ ] **Parental gate added**: If accessing settings/external links
- [ ] **Local storage only**: No data sent to third parties
- [ ] **No tracking**: No analytics for child actions

### Parental Gate Locations
- [Location 1]: [reason]
- [Location 2]: [reason]

## Business Logic Implementation

### Calculations
[From `docs/BUSINESS_LOGIC.md`]

#### [Calculation Name]
```swift
// Formula: [describe formula]
let result = baseValue * multiplier + bonus

// Example:
// Base XP: 100
// Streak multiplier: 1.5 (5 days)
// First attempt bonus: 1.5
// Total: 100 * 1.5 * 1.5 = 225 XP
```

### Rules & Constraints
- Rule 1: [description]
- Rule 2: [description]

### Edge Cases
- Case 1: [scenario and handling]
- Case 2: [scenario and handling]

## Testing Strategy

### Unit Tests (Future)
- Test ViewModel actions
- Test business logic calculations
- Test data model relationships

### Manual Testing Checklist
- [ ] Builds without errors
- [ ] Works offline (airplane mode test)
- [ ] Preview renders correctly
- [ ] All acceptance criteria met
- [ ] Design system followed
- [ ] COPPA compliant
- [ ] Animations smooth
- [ ] Accessible (VoiceOver test)

### Test Scenarios
1. **Happy path**: [describe]
2. **Error case**: [describe]
3. **Edge case**: [describe]
4. **Offline**: [describe]

## Open Questions

1. **Question 1**: [description]
   - Impact: [what's blocked]
   - Options: [possible solutions]
   - Decision needed by: [date]

2. **Question 2**: [description]

## Implementation Notes

### Performance Considerations
- [Note 1]
- [Note 2]

### Future Enhancements
- [Enhancement 1]
- [Enhancement 2]

### Known Limitations
- [Limitation 1]
- [Limitation 2]

## Success Criteria

✅ **Implementation Complete When:**
- [ ] All tasks checked off
- [ ] All acceptance criteria met
- [ ] Code follows Sidrat standards
- [ ] COPPA compliant
- [ ] Tested on device
- [ ] Implementation status updated

---

**Plan Status**: [draft | approved | implemented]  
**Last Updated**: [YYYY-MM-DD]  
**Approved By**: [name]  
**Implemented By**: [name]