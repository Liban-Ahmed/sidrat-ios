# Sidrat Business Logic & Rules

## Streak System

### Calculation Rules
- **Increment**: Streak increases by 1 when daily lesson completed before 11:59 PM local time
- **Reset**: Streak resets to 0 after one missed day (unless freeze used)
- **Freeze**: Parent can grant 1 freeze per week
  - Consumed automatically on first missed day
  - Does not roll over to next week
  - Only available if earned through weekly activity

### Streak Milestones
| Days | Achievement | Reward |
|------|-------------|--------|
| 7 | Week Warrior | "7 Days" badge, +100 XP |
| 30 | Consistent Learner | "30 Days" badge, +500 XP |
| 100 | Dedication Master | "100 Days" badge, +2000 XP |

### Edge Cases
- **Lesson completed at 11:58 PM**: Counts for current day
- **Lesson completed at 12:01 AM**: Counts for new day (yesterday's streak broken unless freeze)
- **Multiple lessons in one day**: Only first completion counts for streak
- **Timezone changes**: Use device local time, no retroactive adjustments

## XP (Experience Points) System

### Base XP Calculation
```
XP Earned = Base Lesson XP × Attempt Multiplier × Streak Multiplier
```

### Multipliers
- **First Attempt Bonus**: +50% if completed correctly on first try
- **Streak Multiplier**: +10% per consecutive day (max +100% at 10+ days)
- **Completion Bonus**: +25% for completing all lessons in a category

### Example Calculation
```
Lesson Base XP: 100
First attempt: Yes (+50%)
Current streak: 5 days (+50%)

100 × 1.5 × 1.5 = 225 XP
```

### XP Thresholds (Future: Levels)
| Level | XP Required | Unlock |
|-------|-------------|--------|
| 1 | 0 | Starting level |
| 2 | 500 | Custom avatar colors |
| 3 | 1,500 | Achievement frames |
| 4 | 3,500 | Special animations |
| 5 | 7,500 | Exclusive content |

## Achievement System

### Achievement Types & Triggers

#### Consistency Achievements
- **First Step** (automatic): Complete first lesson
- **Week Warrior**: 7-day streak
- **Consistent Learner**: 30-day streak
- **Dedication Master**: 100-day streak

#### Mastery Achievements
- **Aqeedah Explorer**: Complete all Aqeedah lessons
- **Salah Master**: Complete all Salah lessons
- **Quran Reciter**: Memorize 4 short surahs
- **Story Listener**: Complete all Stories lessons

#### Special Achievements
- **Ramadan Learner**: Complete 30 lessons during Ramadan
- **Eid Celebration**: Complete special Eid lesson
- **Family Time**: Complete 4 weekly family activities

### Achievement Display Rules
- New achievements show celebration animation (3 seconds)
- Badge collection view shows locked badges as silhouettes
- Achievement progress shown for in-progress badges (e.g., "3/5 lessons")
- Notifications sent when achievement unlocked (if enabled)

## Lesson Completion Logic

### Completion Criteria
A lesson is marked complete when:
1. All 4 phases viewed in order (Hook → Teach → Practice → Reward)
2. Practice phase answered (correct or incorrect after 3 attempts)
3. Reward phase animation completed

### Progress Tracking
```swift
// Phase completion states
enum LessonPhase {
    case hook       // Auto-advances after 30-45 seconds
    case teach      // Manual advance with "Continue" button
    case practice   // Requires interaction (quiz/matching)
    case reward     // Auto-advances after 15-30 seconds
}

// Progress saved after each phase
struct PhaseProgress {
    let phase: LessonPhase
    let completedAt: Date
    let attemptsInPractice: Int?  // Only for practice phase
}
```

### Partial Progress Resume
- User can close app mid-lesson
- Resume from last completed phase
- Practice phase answers not saved (restart practice)
- Audio playback position not saved (restart segment)

## Lesson Scheduling & Prerequisites

### Daily Lesson Logic
```
Today's Lesson = lessons
    .filter { !completed }
    .sorted(by: \.order)
    .first
```

### Prerequisites (Future Phase)
- Aqeedah lessons 1-3 must complete before Salah
- Wudu lessons must complete before Salah
- Categories can be learned in parallel if no prerequisites

### Spaced Repetition
- Review intervals: 1 day → 3 days → 1 week → 2 weeks → 1 month
- Review lessons appear as "bonus" lessons (don't block progress)
- Review XP is 50% of original lesson XP

## Family Activity Completion

### Completion Criteria
- Parent opens activity detail
- Parent marks "Complete" (requires parental gate)
- Optional: Select which children participated (multi-select)
- Optional: Add photo (stored locally, never uploaded)

### Rewards
- All participating children earn +50 XP
- Family achievement progress increments
- Weekly activity streak tracked separately from daily

### Family Achievements
- **Family First**: Complete 1 family activity
- **Quality Time**: Complete 4 family activities
- **Together Strong**: Complete 12 family activities (3 months)

## Screen Time Limits

### Daily Limit Options
- 15 minutes
- 30 minutes
- 45 minutes
- 1 hour
- No limit

### Enforcement
- Warning shown at 5 minutes remaining
- At limit: Soft lockout with encouraging message
  - "Great learning today! Come back tomorrow to continue."
  - Shows today's completed lessons
  - "Override" button requires parental gate
- Limit resets at midnight local time
- Time counts only active app usage (not background)

### Time Calculation
```swift
// Count only when lesson player active
struct AppUsageSession {
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval {
        guard let end = endTime else { return 0 }
        return end.timeIntervalSince(startTime)
    }
}
```

## Data Sync & Conflict Resolution

### Conflict Resolution Rules

#### Progress Conflicts
When same lesson has different completion on two devices:
```
Resolved Progress = {
    completedAt: earliest(device1.completedAt, device2.completedAt)
    score: max(device1.score, device2.score)
    xpEarned: max(device1.xpEarned, device2.xpEarned)
    attempts: min(device1.attempts, device2.attempts)  // Best performance wins
}
```

#### Streak Conflicts
```
Resolved Streak = max(device1.currentStreak, device2.currentStreak)
```

### Sync Timing
- Automatic sync on app launch (if online)
- Automatic sync after lesson completion (if online)
- Manual sync available in Settings
- Offline changes queued, sync when connection restored