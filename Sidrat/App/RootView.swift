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
    
    var body: some View {
        Group {
            if appState.isOnboardingComplete {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isOnboardingComplete)
        .onAppear {
            seedTestDataIfNeeded()
        }
    }
    
    // MARK: - Test Data Seeding
    
    private func seedTestDataIfNeeded() {
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

#Preview {
    RootView()
        .environment(AppState())
}
