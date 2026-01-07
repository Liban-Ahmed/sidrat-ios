//
//  RootView.swift
//  Sidrat
//
//  Main navigation container
//

import SwiftUI
import SwiftData

struct RootView: View {    private enum Constants {
        /// Minimum splash duration for reduced motion mode (instant feel)
        static let reducedMotionSplashDuration: TimeInterval = 0.25
        /// Minimum splash duration for full animations (matches LaunchSplashView step3Delay + buffer)
        static let normalSplashDuration: TimeInterval = 3.8
        /// Fade-out animation duration when dismissing splash
        static let splashFadeOutDuration: TimeInterval = 0.8
    }
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
            
            // Auto-complete onboarding if credentials and children exist
            // Prevents lockout when parent account + children exist but flag was cleared
            appState.checkAndCompleteOnboardingIfNeeded(modelContext: modelContext)
            
            await seedTestDataIfNeeded()

            // Keep the splash visible briefly to cover launch + initial work.
            let minimumDuration: TimeInterval = reduceMotion 
                ? Constants.reducedMotionSplashDuration 
                : Constants.normalSplashDuration
            let elapsed = Date().timeIntervalSince(startedAt)
            if elapsed < minimumDuration {
                let remaining = minimumDuration - elapsed
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }

            withAnimation(.easeOut(duration: Constants.splashFadeOutDuration)) {
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
