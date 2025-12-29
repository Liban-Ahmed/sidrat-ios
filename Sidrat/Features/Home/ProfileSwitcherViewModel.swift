//
//  ProfileSwitcherViewModel.swift
//  Sidrat
//
//  ViewModel for profile switching functionality
//  Implements US-103: Child Profile Switching
//

import Foundation
import SwiftUI
import SwiftData

/// ViewModel managing profile switching logic and state
/// Follows MVVM pattern per PROJECT_CONTEXT.md requirements
@Observable
final class ProfileSwitcherViewModel {
    // MARK: - Published Properties
    
    /// All children profiles sorted by name
    private(set) var children: [Child] = []
    
    /// Whether a profile switch is in progress
    private(set) var isSwitching: Bool = false
    
    /// Timing for the last switch operation (for performance validation)
    private(set) var lastSwitchDuration: TimeInterval = 0
    
    /// Whether the add child sheet is shown
    var showingAddChildSheet: Bool = false
    
    /// Whether the parental gate is shown
    var showingParentalGate: Bool = false
    
    /// Error message to display
    var errorMessage: String?
    
    /// Whether to show error alert
    var showingError: Bool = false
    
    // MARK: - Dependencies
    
    private let appState: AppState
    private var modelContext: ModelContext?
    
    // MARK: - Performance Tracking
    
    /// Maximum acceptable switch time in seconds (per acceptance criteria)
    static let maxSwitchTime: TimeInterval = 0.5
    
    // MARK: - Initialization
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    // MARK: - Setup
    
    /// Configure the view model with the model context
    /// - Parameter context: The SwiftData model context
    func configure(with context: ModelContext) {
        self.modelContext = context
        loadChildren()
    }
    
    // MARK: - Data Loading
    
    /// Load all children from the data store
    func loadChildren() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Child>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            children = try context.fetch(descriptor)
        } catch {
            handleError("Failed to load profiles", error: error)
        }
    }
    
    // MARK: - Profile Switching
    
    /// Switch to a different child profile
    /// - Parameter child: The child to switch to
    /// - Returns: Whether the switch was successful
    @discardableResult
    func switchToProfile(_ child: Child) -> Bool {
        // Don't switch if already selected
        guard child.id.uuidString != appState.currentChildId else {
            return true
        }
        
        // Track timing for performance validation
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Begin switch
        isSwitching = true
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Perform the switch
        appState.currentChildId = child.id.uuidString
        
        // Calculate switch duration
        lastSwitchDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Log performance warning if switch took too long
        if lastSwitchDuration > Self.maxSwitchTime {
            print("⚠️ Profile switch took \(String(format: "%.2f", lastSwitchDuration * 1000))ms - exceeds \(Self.maxSwitchTime * 1000)ms target")
        } else {
            print("✅ Profile switch completed in \(String(format: "%.2f", lastSwitchDuration * 1000))ms")
        }
        
        // Reset switching state after brief delay for UI
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            isSwitching = false
        }
        
        return true
    }
    
    /// Check if a child is the currently active profile
    /// - Parameter child: The child to check
    /// - Returns: Whether the child is active
    func isActive(_ child: Child) -> Bool {
        child.id.uuidString == appState.currentChildId
    }
    
    // MARK: - Current Child
    
    /// Get the currently active child
    var currentChild: Child? {
        guard let currentId = appState.currentChildId,
              let uuid = UUID(uuidString: currentId) else {
            return nil
        }
        return children.first { $0.id == uuid }
    }
    
    /// Get the current child's avatar
    var currentAvatar: AvatarOption? {
        currentChild?.avatar
    }
    
    /// Get the current child's name
    var currentChildName: String {
        currentChild?.name ?? "Select Profile"
    }
    
    // MARK: - Profile Count
    
    /// Number of child profiles
    var profileCount: Int {
        children.count
    }
    
    /// Whether there are multiple profiles
    var hasMultipleProfiles: Bool {
        children.count > 1
    }
    
    /// Whether profiles exist
    var hasProfiles: Bool {
        !children.isEmpty
    }
    
    // MARK: - Add Child Flow
    
    /// Begin the add child flow (with parental gate)
    func beginAddChild() {
        showingParentalGate = true
    }
    
    /// Called when parental gate is passed successfully
    func onParentalGatePassed() {
        showingParentalGate = false
        showingAddChildSheet = true
    }
    
    /// Add a new child profile
    /// - Parameters:
    ///   - name: Child's name
    ///   - avatar: Selected avatar
    ///   - birthYear: Optional birth year
    /// - Returns: The created child or nil on failure
    @discardableResult
    func addChild(name: String, avatar: AvatarOption, birthYear: Int? = nil) -> Child? {
        guard let context = modelContext else {
            handleError("Cannot add child - no data context")
            return nil
        }
        
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            handleError("Please enter a name")
            return nil
        }
        
        // Use provided birthYear or calculate default (assuming age 5)
        let finalBirthYear = birthYear ?? (Calendar.current.component(.year, from: Date()) - 5)
        
        // Create new child
        let child = Child(
            name: trimmedName,
            birthYear: finalBirthYear,
            avatarId: avatar.id
        )
        
        // Insert into context
        context.insert(child)
        
        do {
            try context.save()
            
            // Reload children
            loadChildren()
            
            // Switch to new child
            switchToProfile(child)
            
            // Close sheet
            showingAddChildSheet = false
            
            // Haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            return child
        } catch {
            handleError("Failed to save profile", error: error)
            return nil
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ message: String, error: Error? = nil) {
        errorMessage = message
        showingError = true
        
        if let error = error {
            print("❌ ProfileSwitcherViewModel Error: \(message) - \(error.localizedDescription)")
        } else {
            print("❌ ProfileSwitcherViewModel Error: \(message)")
        }
    }
    
    /// Dismiss the error alert
    func dismissError() {
        showingError = false
        errorMessage = nil
    }
}

// MARK: - Preview Support

extension ProfileSwitcherViewModel {
    /// Create a preview instance with mock data
    static var preview: ProfileSwitcherViewModel {
        let viewModel = ProfileSwitcherViewModel(appState: AppState())
        // Note: Preview data would be loaded from mock context
        return viewModel
    }
}
