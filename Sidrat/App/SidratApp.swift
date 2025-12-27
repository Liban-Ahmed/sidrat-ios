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
    
    /// Shared model container for SwiftData persistence
    /// Configured with proper error handling and schema migration support
    let modelContainer: ModelContainer
    
    /// Data version for one-time migrations/cleanups
    private static let currentDataVersion = 2
    
    init() {
        // Check if we need to do a one-time data cleanup
        let savedVersion = UserDefaults.standard.integer(forKey: "dataVersion")
        let needsCleanup = savedVersion < SidratApp.currentDataVersion
        
        if needsCleanup {
            print("🧹 Data version upgrade needed: \(savedVersion) -> \(SidratApp.currentDataVersion)")
            // Delete the old store to start fresh
            if let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let defaultStoreURL = storeURL.appendingPathComponent("default.store")
                let shmURL = storeURL.appendingPathComponent("default.store-shm")
                let walURL = storeURL.appendingPathComponent("default.store-wal")
                
                try? FileManager.default.removeItem(at: defaultStoreURL)
                try? FileManager.default.removeItem(at: shmURL)
                try? FileManager.default.removeItem(at: walURL)
                
                print(" Cleared old data store")
            }
            
            // Reset app state for fresh start
            UserDefaults.standard.removeObject(forKey: "isOnboardingComplete")
            UserDefaults.standard.removeObject(forKey: "currentChildId")
            UserDefaults.standard.removeObject(forKey: "lessonsSeeded")
            
            // Save new version
            UserDefaults.standard.set(SidratApp.currentDataVersion, forKey: "dataVersion")
            print(" Data cleanup complete - starting fresh")
        }
        
        // Configure schema for all model types
        let schema = Schema([
            Child.self,
            Lesson.self,
            LessonProgress.self,
            Achievement.self,
            FamilyActivity.self,
        ])
        
        // Configure model with migration support
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            #if DEBUG
            print(" ModelContainer initialized successfully")
            #endif
        } catch {
            // If migration fails, try to recover by deleting corrupted store
            print(" Failed to initialize ModelContainer: \(error)")
            print(" Attempting recovery by recreating store...")
            
            // Delete the corrupted store
            if let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let defaultStoreURL = storeURL.appendingPathComponent("default.store")
                let shmURL = storeURL.appendingPathComponent("default.store-shm")
                let walURL = storeURL.appendingPathComponent("default.store-wal")
                
                try? FileManager.default.removeItem(at: defaultStoreURL)
                try? FileManager.default.removeItem(at: shmURL)
                try? FileManager.default.removeItem(at: walURL)
                
                print(" Deleted corrupted store files")
            }
            
            // Reset app state since data is lost
            UserDefaults.standard.removeObject(forKey: "isOnboardingComplete")
            UserDefaults.standard.removeObject(forKey: "currentChildId")
            UserDefaults.standard.removeObject(forKey: "lessonsSeeded")
            
            // Try again with fresh store
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print(" ModelContainer recovered successfully")
            } catch {
                // This should never happen, but provide a fallback
                fatalError(" Unrecoverable error creating ModelContainer: \(error)")
            }
        }
        
        #if DEBUG
        // 🚨 TEMPORARY: Uncomment to reset onboarding for testing
        // UserDefaults.standard.removeObject(forKey: "isOnboardingComplete")
        // UserDefaults.standard.removeObject(forKey: "lessonsSeeded")
        // print(" App reset")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .modelContainer(modelContainer)
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
        print(" App state reset - restart app to see onboarding")
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

