# Sidrat iOS

Your personalized Islamic curriculum guide for children ages 5-7.

## Overview

Sidrat combines Duolingo-style daily lessons with weekly family activities—so your child builds Islamic foundations while you stay connected to their growth.

### Key Features

**For Kids (In-App):**
- 🎮 Daily 5-minute interactive lessons (games, stories, quizzes)
- 📚 Friendly animated characters for engagement
- 🏆 Streaks & badges reward system
- 🔊 Voice narration for non-readers

**For Parents:**
- 📅 Weekly family activity suggestions
- 📊 Progress dashboard
- 💬 Conversation prompts
- ⏱️ No prep required activities

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

### 1. Open in Xcode

```bash
cd sidrat-ios
open Sidrat.xcodeproj
```

### 2. Build and Run

1. Select your target device or simulator
2. Press `Cmd + R` to build and run

## Project Structure

```
Sidrat/
├── App/
│   ├── SidratApp.swift          # App entry point
│   └── RootView.swift           # Root navigation
├── Features/
│   ├── Onboarding/              # First-time user experience
│   ├── Home/                    # Daily lessons dashboard
│   ├── Learn/                   # Interactive lessons
│   ├── Progress/                # Progress tracking
│   ├── Family/                  # Weekly family activities
│   └── Settings/                # App settings & profile
├── Core/
│   ├── Models/                  # Data models
│   ├── Services/                # API & business logic
│   └── Extensions/              # Swift extensions
├── UI/
│   ├── Components/              # Reusable UI components
│   ├── Theme/                   # Design system
│   └── Animations/              # Custom animations
└── Resources/
    └── Assets.xcassets/         # Images & colors
```

## Architecture

This app follows **MVVM** with:
- **SwiftUI** for declarative UI
- **Swift Concurrency** (async/await)
- **Observation** framework (iOS 17+)
- **SwiftData** for local persistence

## License

Copyright © 2025 Sidrat. All rights reserved.
