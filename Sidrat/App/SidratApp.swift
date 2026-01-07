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
    private static let currentDataVersion = 4
    
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
                .onAppear {
                    // Initialize keyboard manager
                    _ = KeyboardManager.shared
                    
                    // Suppress RTI Input System warning logs (cosmetic only)
                    UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
                }
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

/// User's preferred appearance mode
enum AppearanceMode: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    /// SF Symbol icon for each mode
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    /// Color for the icon
    var iconColor: Color {
        switch self {
        case .system: return .textSecondary
        case .light: return .brandAccent
        case .dark: return .brandPrimary
        }
    }
    
    /// The color scheme to apply, or nil for system
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@Observable
final class AppState {
    // Use private backing storage to trigger observations
    private var _isOnboardingComplete: Bool = UserDefaults.standard.bool(forKey: "isOnboardingComplete")
    private var _currentChildId: String? = UserDefaults.standard.string(forKey: "currentChildId")
    private var _dailyStreak: Int = UserDefaults.standard.integer(forKey: "dailyStreak")
    private var _lastCompletedDate: Date? = UserDefaults.standard.object(forKey: "lastCompletedDate") as? Date
    private var _parentUserIdentifier: String? = UserDefaults.standard.string(forKey: "parentUserIdentifier")
    private var _isLocalOnlyAccount: Bool = UserDefaults.standard.bool(forKey: "isLocalOnlyAccount")
    private var _appearanceMode: AppearanceMode = {
        let rawValue = UserDefaults.standard.string(forKey: "appearanceMode") ?? AppearanceMode.system.rawValue
        return AppearanceMode(rawValue: rawValue) ?? .system
    }()
    
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
    
    /// Parent's anonymous Apple ID or local UUID
    var parentUserIdentifier: String? {
        get { _parentUserIdentifier }
        set {
            _parentUserIdentifier = newValue
            UserDefaults.standard.set(newValue, forKey: "parentUserIdentifier")
        }
    }
    
    /// Whether the account is local-only (offline mode)
    var isLocalOnlyAccount: Bool {
        get { _isLocalOnlyAccount }
        set {
            _isLocalOnlyAccount = newValue
            UserDefaults.standard.set(newValue, forKey: "isLocalOnlyAccount")
        }
    }
    
    /// Whether a parent account exists (either Apple ID or local)
    var hasParentAccount: Bool {
        parentUserIdentifier != nil
    }
    
    /// User's preferred appearance mode (system/light/dark)
    var appearanceMode: AppearanceMode {
        get { _appearanceMode }
        set {
            _appearanceMode = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "appearanceMode")
        }
    }
    
    init() {
        // Load initial values from UserDefaults
        _isOnboardingComplete = UserDefaults.standard.bool(forKey: "isOnboardingComplete")
        _currentChildId = UserDefaults.standard.string(forKey: "currentChildId")
        _dailyStreak = UserDefaults.standard.integer(forKey: "dailyStreak")
        _lastCompletedDate = UserDefaults.standard.object(forKey: "lastCompletedDate") as? Date
        _parentUserIdentifier = UserDefaults.standard.string(forKey: "parentUserIdentifier")
        _isLocalOnlyAccount = UserDefaults.standard.bool(forKey: "isLocalOnlyAccount")
    }
    
    /// Sets up the parent account from authentication result
    func setParentAccount(from result: AuthenticationResult) {
        parentUserIdentifier = result.userIdentifier
        isLocalOnlyAccount = result.isLocalOnly
        
        #if DEBUG
        print("👤 Parent account set: \(result.userIdentifier.prefix(8))... (local: \(result.isLocalOnly))")
        #endif
    }
    
    /// Automatically completes onboarding if credentials and children exist
    /// Prevents lockout scenarios where credentials persist but onboarding flag was cleared
    /// Call this on app launch before showing onboarding UI
    @MainActor
    func checkAndCompleteOnboardingIfNeeded(modelContext: ModelContext) {
        // If already complete, nothing to do
        guard !isOnboardingComplete else {
            #if DEBUG
            print("ℹ️ Onboarding already complete")
            #endif
            return
        }
        
        // Check if parent account exists
        guard hasParentAccount else {
            #if DEBUG
            print("ℹ️ No parent account found, onboarding needed")
            #endif
            return
        }
        
        // Check if at least one child exists
        do {
            let descriptor = FetchDescriptor<Child>()
            let children = try modelContext.fetch(descriptor)
            
            if !children.isEmpty {
                // We have credentials + children but onboarding not marked complete
                // This can happen after data cleanup or app reinstall
                isOnboardingComplete = true
                
                // Set current child if not already set
                if currentChildId == nil, let firstChild = children.first {
                    currentChildId = firstChild.id.uuidString
                }
                
                #if DEBUG
                print("🔄 Auto-completed onboarding: Found \(children.count) existing children")
                for child in children {
                    print("  - \(child.name) (Age \(child.currentAge))")
                }
                #endif
            } else {
                #if DEBUG
                print("ℹ️ Parent account exists but no children, continue onboarding")
                #endif
            }
        } catch {
            #if DEBUG
            print("❌ Error checking children: \(error)")
            #endif
        }
    }
    
    #if DEBUG
    /// Reset app state for testing - useful during development
    @MainActor func resetForTesting() {
        _isOnboardingComplete = false
        _currentChildId = nil
        _dailyStreak = 0
        _lastCompletedDate = nil
        _parentUserIdentifier = nil
        _isLocalOnlyAccount = false
        _appearanceMode = .system
        
        UserDefaults.standard.removeObject(forKey: "isOnboardingComplete")
        UserDefaults.standard.removeObject(forKey: "currentChildId")
        UserDefaults.standard.removeObject(forKey: "dailyStreak")
        UserDefaults.standard.removeObject(forKey: "lastCompletedDate")
        UserDefaults.standard.removeObject(forKey: "parentUserIdentifier")
        UserDefaults.standard.removeObject(forKey: "isLocalOnlyAccount")
        UserDefaults.standard.removeObject(forKey: "appearanceMode")
        
        // Also sign out from authentication service
        AuthenticationService.shared.signOut()
        
        print("🔄 App state reset - restart app to see onboarding")
    }
    #endif
}

// MARK: - Shake Gesture (Debug)

#if DEBUG
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(DeviceShakeModifier(action: action))
    }
}

struct DeviceShakeModifier: ViewModifier {
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

