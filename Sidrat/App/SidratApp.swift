//
//  SidratApp.swift
//  Sidrat
//
//  Created with ❤️ for Muslim families
//

import SwiftUI
import SwiftData

@main
struct SidratApp: App {
    @State private var appState = AppState()
    
    init() {
        #if DEBUG
        // 🚨 TEMPORARY: Uncomment to reset onboarding for testing
        // UserDefaults.standard.removeObject(forKey: "isOnboardingComplete")
        // UserDefaults.standard.removeObject(forKey: "lessonsSeeded")
        // print("🔄 App reset")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .modelContainer(for: [
                    Child.self,
                    Lesson.self,
                    LessonProgress.self,
                    Achievement.self,
                    FamilyActivity.self,
                ])
                #if DEBUG
                .onShake {
                    // Shake device or Cmd+Ctrl+Z in simulator to reset
                    appState.resetForTesting()
                }
                #endif
        }
    }
}

// MARK: - App State

@Observable
final class AppState {
    // Use private backing storage to trigger observations
    private var _isOnboardingComplete: Bool = UserDefaults.standard.bool(forKey: "isOnboardingComplete")
    private var _currentChildId: String? = UserDefaults.standard.string(forKey: "currentChildId")
    private var _dailyStreak: Int = UserDefaults.standard.integer(forKey: "dailyStreak")
    private var _lastCompletedDate: Date? = UserDefaults.standard.object(forKey: "lastCompletedDate") as? Date
    
    var isOnboardingComplete: Bool {
        get { _isOnboardingComplete }
        set { 
            _isOnboardingComplete = newValue
            UserDefaults.standard.set(newValue, forKey: "isOnboardingComplete")
        }
    }
    
    var currentChildId: String? {
        get { _currentChildId }
        set { 
            _currentChildId = newValue
            UserDefaults.standard.set(newValue, forKey: "currentChildId")
        }
    }
    
    var dailyStreak: Int {
        get { _dailyStreak }
        set { 
            _dailyStreak = newValue
            UserDefaults.standard.set(newValue, forKey: "dailyStreak")
        }
    }
    
    var lastCompletedDate: Date? {
        get { _lastCompletedDate }
        set { 
            _lastCompletedDate = newValue
            UserDefaults.standard.set(newValue, forKey: "lastCompletedDate")
        }
    }
    
    init() {
        // Load initial values from UserDefaults
        _isOnboardingComplete = UserDefaults.standard.bool(forKey: "isOnboardingComplete")
        _currentChildId = UserDefaults.standard.string(forKey: "currentChildId")
        _dailyStreak = UserDefaults.standard.integer(forKey: "dailyStreak")
        _lastCompletedDate = UserDefaults.standard.object(forKey: "lastCompletedDate") as? Date
    }
    
    #if DEBUG
    /// Reset app state for testing - useful during development
    func resetForTesting() {
        _isOnboardingComplete = false
        _currentChildId = nil
        _dailyStreak = 0
        _lastCompletedDate = nil
        
        UserDefaults.standard.removeObject(forKey: "isOnboardingComplete")
        UserDefaults.standard.removeObject(forKey: "currentChildId")
        UserDefaults.standard.removeObject(forKey: "dailyStreak")
        UserDefaults.standard.removeObject(forKey: "lastCompletedDate")
        print("✅ App state reset - restart app to see onboarding")
    }
    #endif
}

// MARK: - Shake Gesture (Debug)

#if DEBUG
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeModifier(action: action))
    }
}

struct ShakeModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}
#endif

