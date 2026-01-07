//
//  KeyboardManager.swift
//  Sidrat
//
//  Global keyboard and input management to prevent RTI errors and freezing
//  Addresses: XPC interruptions, constraint conflicts, focus management
//

import SwiftUI
import Combine

/// Global keyboard manager to handle keyboard lifecycle and prevent common issues
@MainActor
final class KeyboardManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = KeyboardManager()
    
    // MARK: - Published State
    
    @Published private(set) var isKeyboardVisible = false
    @Published private(set) var keyboardHeight: CGFloat = 0
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var keyboardShowPublisher: NotificationCenter.Publisher
    private var keyboardHidePublisher: NotificationCenter.Publisher
    private var keyboardFramePublisher: NotificationCenter.Publisher
    
    // MARK: - Initialization
    
    private init() {
        keyboardShowPublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        keyboardHidePublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        keyboardFramePublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardDidChangeFrameNotification)
        
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Keyboard show
        keyboardShowPublisher
            .compactMap { notification -> CGFloat? in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                return keyboardFrame.height
            }
            .sink { [weak self] height in
                self?.isKeyboardVisible = true
                self?.keyboardHeight = height
            }
            .store(in: &cancellables)
        
        // Keyboard hide
        keyboardHidePublisher
            .sink { [weak self] _ in
                self?.isKeyboardVisible = false
                self?.keyboardHeight = 0
            }
            .store(in: &cancellables)
        
        // Keyboard frame changes
        keyboardFramePublisher
            .compactMap { notification -> CGFloat? in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                return keyboardFrame.height
            }
            .sink { [weak self] height in
                self?.keyboardHeight = height
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Dismiss keyboard programmatically
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Check if keyboard is currently active
    var isActive: Bool {
        isKeyboardVisible
    }
}

// MARK: - View Extension

extension View {
    /// Dismiss keyboard when tapping outside TextFields
    /// - Parameter isActive: Whether dismissal is active
    /// - Returns: Modified view with tap gesture
    func dismissKeyboardOnTap(isActive: Bool = true) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    if isActive {
                        KeyboardManager.shared.dismissKeyboard()
                    }
                }
        )
    }
    
    /// Add adaptive padding for keyboard
    /// - Returns: Modified view with keyboard-aware padding
    func keyboardAdaptivePadding() -> some View {
        self.padding(.bottom, KeyboardManager.shared.keyboardHeight > 0 ? KeyboardManager.shared.keyboardHeight - 34 : 0)
    }
}

// MARK: - TextField Optimization Extension

extension View {
    /// Apply standard TextField optimizations to prevent freezing
    /// Use this modifier on all TextFields in the app
    func optimizedTextField(
        focusState: FocusState<Bool>.Binding,
        autocorrection: Bool = false,
        capitalization: TextInputAutocapitalization = .words,
        submitLabel: SubmitLabel = .done
    ) -> some View {
        self
            .autocorrectionDisabled(!autocorrection)
            .textInputAutocapitalization(capitalization)
            .submitLabel(submitLabel)
            .onSubmit {
                focusState.wrappedValue = false
            }
    }
}
