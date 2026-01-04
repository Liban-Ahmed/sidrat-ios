//
//  RootView.swift
//  Sidrat
//
//  Main navigation container
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isShowingLaunchSplash = true
    
    var body: some View {
        ZStack {
            Group {
                if appState.isOnboardingComplete {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .animation(.easeInOut(duration: 0.4), value: appState.isOnboardingComplete)
            .preferredColorScheme(appState.appearanceMode.colorScheme)

            if isShowingLaunchSplash {
                LaunchSplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            let startedAt = Date()
            await seedTestDataIfNeeded()

            // Keep the splash visible briefly to cover launch + initial work.
            let minimumDuration: TimeInterval = reduceMotion ? 0.25 : 3.8
            let elapsed = Date().timeIntervalSince(startedAt)
            if elapsed < minimumDuration {
                let remaining = minimumDuration - elapsed
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }

            withAnimation(.easeOut(duration: 0.8)) {
                isShowingLaunchSplash = false
            }
        }
    }
    
    // MARK: - Test Data Seeding
    
    @MainActor
    private func seedTestDataIfNeeded() async {
        // Only seed once per install
        guard !UserDefaults.standard.bool(forKey: "lessonsSeeded") else { return }
        
        let testLessons = Lesson.generateTestLessons()
        for lesson in testLessons {
            modelContext.insert(lesson)
        }
        
        do {
            try modelContext.save()
            UserDefaults.standard.set(true, forKey: "lessonsSeeded")
            print(" Seeded \(testLessons.count) test lessons")
        } catch {
            print(" Error seeding lessons: \(error)")
        }
    }
}

#Preview("Light Mode") {
    RootView()
        .environment(AppState())
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    RootView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
