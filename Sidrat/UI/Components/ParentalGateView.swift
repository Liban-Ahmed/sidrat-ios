//
//  ParentalGateView.swift
//  Sidrat
//
//  Parental gate for COPPA compliance and Kids Category requirements
//  Implements US-104: Parental Gate Implementation
//

import SwiftUI

/// A modal view that requires solving a simple math problem to proceed.
/// Implements COPPA requirements for parental verification in Kids Category apps.
///
/// Features:
/// - Math problem with sum between 15-30
/// - 30-second timeout that auto-dismisses
/// - Regenerates problem after incorrect answer
/// - Full VoiceOver accessibility support
/// - Haptic feedback on success/error
///
/// Usage:
/// ```swift
/// ParentalGateView(
///     onSuccess: { /* granted access */ },
///     onDismiss: { /* cancelled/timed out */ },
///     context: "Access settings"
/// )
/// ```
struct ParentalGateView: View {
    // MARK: - Properties
    
    /// Callback when the gate is successfully passed
    let onSuccess: () -> Void
    
    /// Callback when the gate is dismissed without success
    let onDismiss: () -> Void
    
    /// Optional context message to explain why parental verification is needed
    let context: String?
    
    // MARK: - State
    
    @State private var firstNumber: Int
    @State private var secondNumber: Int
    @State private var userAnswer = ""
    @State private var showError = false
    @State private var attemptCount = 0
    @State private var timeRemaining = 30
    @State private var isTimedOut = false
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Constants
    
    private let maxAttempts = 5
    private let timeoutDuration = 30
    
    // MARK: - Computed Properties
    
    private var correctAnswer: Int {
        firstNumber + secondNumber
    }
    
    private var shouldShowTimeout: Bool {
        isTimedOut || timeRemaining <= 0
    }
    
    // MARK: - Initialization
    
    init(
        onSuccess: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        context: String? = nil
    ) {
        self.onSuccess = onSuccess
        self.onDismiss = onDismiss
        self.context = context
        
        // Generate initial problem ensuring sum is between 15-30
        // First: 8-18, Second: calculated to ensure sum is 15-30
        let first = Int.random(in: 8...18)
        let minSecond = max(1, 15 - first)  // Ensure sum >= 15
        let maxSecond = min(22, 30 - first) // Ensure sum <= 30
        let second = Int.random(in: minSecond...maxSecond)
        
        _firstNumber = State(initialValue: first)
        _secondNumber = State(initialValue: second)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black
                .opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss keyboard when tapping outside
                    isTextFieldFocused = false
                }
            
            // Main content card
            VStack(spacing: 0) {
                if shouldShowTimeout {
                    timeoutView
                } else {
                    mainContentView
                }
            }
            .frame(maxWidth: 400)
            .background(Color.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.extraLarge))
            .shadow(color: .black.opacity(0.3), radius: 24, y: 12)
            .padding(Spacing.lg)
        }
        .onAppear {
            startTimer()
            // Focus text field after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Parental gate verification")
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        VStack(spacing: Spacing.xl) {
            // Header
            headerSection
            
            // Math problem
            mathProblemSection
            
            // Input field
            inputSection
            
            // Error message
            if showError {
                errorMessageView
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Action buttons
            actionButtonsSection
            
            // Timeout indicator
            timeoutIndicator
        }
        .padding(Spacing.xl)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.1))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.brandPrimary)
            }
            .accessibilityHidden(true)
            
            // Title
            Text("Parent Check")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.textPrimary)
            
            // Context or default message
            Text(context ?? "This section is for parents only.\nPlease solve this simple problem to continue.")
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Parent check. \(context ?? "This section is for parents only. Please solve this simple problem to continue.")")
    }
    
    // MARK: - Math Problem Section
    
    private var mathProblemSection: some View {
        VStack(spacing: Spacing.md) {
            // Use ViewThatFits to handle different screen sizes
            ViewThatFits(in: .horizontal) {
                // Full size layout for larger screens
                mathProblemRow(bubbleSize: 72, fontSize: 32, symbolSize: 36)
                
                // Compact layout for smaller screens
                mathProblemRow(bubbleSize: 60, fontSize: 26, symbolSize: 30)
                
                // Extra compact layout
                mathProblemRow(bubbleSize: 52, fontSize: 22, symbolSize: 26)
            }
        }
    }
    
    private func mathProblemRow(bubbleSize: CGFloat, fontSize: CGFloat, symbolSize: CGFloat) -> some View {
        HStack(spacing: Spacing.xs) {
            // First number
            numberBubble(firstNumber, size: bubbleSize, fontSize: fontSize)
            
            // Plus symbol - fixed width to prevent cutoff
            Text("+")
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(.textSecondary)
                .frame(minWidth: 28)
            
            // Second number
            numberBubble(secondNumber, size: bubbleSize, fontSize: fontSize)
            
            // Equals symbol - fixed width to prevent cutoff
            Text("=")
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(.textSecondary)
                .frame(minWidth: 28)
            
            // Question mark
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.1))
                    .frame(width: bubbleSize, height: bubbleSize)
                
                Text("?")
                    .font(.system(size: fontSize + 8, weight: .bold))
                    .foregroundStyle(.brandAccent)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("What is \(firstNumber) plus \(secondNumber)?")
        .accessibilityHint("Enter your answer in the text field below")
    }
    
    private func numberBubble(_ number: Int, size: CGFloat, fontSize: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.brandPrimary.opacity(0.1))
                .frame(width: size, height: size)
            
            Text("\(number)")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.brandPrimary)
        }
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(spacing: Spacing.xs) {
            TextField("", text: $userAnswer)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .focused($isTextFieldFocused)
                .padding()
                .frame(height: 64)
                .background(Color.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(
                            isTextFieldFocused ? Color.brandPrimary : Color.clear,
                            lineWidth: 2
                        )
                }
                .overlay {
                    if userAnswer.isEmpty {
                        Text("Enter answer")
                            .font(.bodyLarge)
                            .foregroundStyle(.textTertiary)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityLabel("Answer field")
                .accessibilityHint("Enter the sum of \(firstNumber) and \(secondNumber)")
                .accessibilityValue(userAnswer.isEmpty ? "Empty" : userAnswer)
                .onChange(of: userAnswer) { oldValue, newValue in
                    // Limit to reasonable number length
                    if newValue.count > 3 {
                        userAnswer = String(newValue.prefix(3))
                    }
                    // Remove error when user starts typing again
                    if showError && !newValue.isEmpty {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showError = false
                        }
                    }
                }
            
            Text("Attempts: \(attemptCount)/\(maxAttempts)")
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .accessibilityLabel("Attempts used: \(attemptCount) out of \(maxAttempts)")
        }
    }
    
    // MARK: - Error Message View
    
    private var errorMessageView: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
            
            Text(attemptCount >= maxAttempts ? "Too many attempts. Please try again later." : "Incorrect answer. Please try again.")
                .font(.bodySmall)
        }
        .foregroundStyle(.error)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.error.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        HStack(spacing: Spacing.md) {
            // Cancel button
            Button {
                handleDismiss()
            } label: {
                Text("Cancel")
                    .font(.labelLarge)
                    .foregroundStyle(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
            .accessibilityLabel("Cancel")
            .accessibilityHint("Returns to the previous screen without verifying")
            
            // Submit button
            Button {
                checkAnswer()
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text("Submit")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .font(.labelLarge)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    userAnswer.isEmpty || attemptCount >= maxAttempts
                        ? Color.textTertiary
                        : Color.brandPrimary
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
            .disabled(userAnswer.isEmpty || attemptCount >= maxAttempts)
            .accessibilityLabel("Submit answer")
            .accessibilityHint(userAnswer.isEmpty ? "Enter an answer first" : "Submits your answer for verification")
        }
    }
    
    // MARK: - Timeout Indicator
    
    private var timeoutIndicator: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "clock.fill")
                .font(.caption)
            
            Text("\(timeRemaining)s remaining")
                .font(.caption)
        }
        .foregroundStyle(timeRemaining <= 10 ? .error : .textTertiary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(timeRemaining) seconds remaining before timeout")
    }
    
    // MARK: - Timeout View
    
    private var timeoutView: some View {
        VStack(spacing: Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.error.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.error)
            }
            .accessibilityHidden(true)
            
            // Message
            VStack(spacing: Spacing.sm) {
                Text("Time's Up")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.textPrimary)
                
                Text("The verification timed out after 30 seconds.\nPlease try again when you're ready.")
                    .font(.bodyMedium)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Return button
            Button {
                handleDismiss()
            } label: {
                Text("Return")
                    .font(.labelLarge)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
        }
        .padding(Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Time's up. The verification timed out after 30 seconds. Please try again when you're ready.")
    }
    
    // MARK: - Actions
    
    private func checkAnswer() {
        // Increment attempt counter
        attemptCount += 1
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Check if answer is correct
        if let answer = Int(userAnswer), answer == correctAnswer {
            // Success! Dismiss keyboard first
            isTextFieldFocused = false
            
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            // Delay to allow keyboard to fully dismiss before callback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onSuccess()
            }
        } else {
            // Incorrect answer
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showError = true
            }
            
            // Check if max attempts reached
            if attemptCount >= maxAttempts {
                // Force dismiss after max attempts
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    handleDismiss()
                }
            } else {
                // Generate new problem
                generateNewProblem()
                
                // Clear input
                userAnswer = ""
                
                // Hide error after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showError = false
                    }
                }
            }
        }
    }
    
    private func generateNewProblem() {
        // Generate new problem ensuring sum is exactly between 15-30
        firstNumber = Int.random(in: 8...18)
        let minSecond = max(1, 15 - firstNumber)  // Ensure sum >= 15
        let maxSecond = min(22, 30 - firstNumber) // Ensure sum <= 30
        secondNumber = Int.random(in: minSecond...maxSecond)
        
        // Announce new problem for VoiceOver users
        let announcement = "New problem: \(firstNumber) plus \(secondNumber)"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    private func handleDismiss() {
        // Dismiss keyboard first and wait for it to complete
        isTextFieldFocused = false
        
        // Use longer delay to allow keyboard animation to complete
        // This helps reduce RTI input system warnings
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
                
                // Announce time remaining for accessibility at key intervals
                if timeRemaining == 10 {
                    UIAccessibility.post(notification: .announcement, argument: "10 seconds remaining")
                } else if timeRemaining == 5 {
                    UIAccessibility.post(notification: .announcement, argument: "5 seconds remaining")
                }
            } else {
                timer.invalidate()
                isTimedOut = true
                
                // Announce timeout
                UIAccessibility.post(notification: .announcement, argument: "Verification timed out")
                
                // Auto-dismiss after timeout message shown
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    handleDismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Default") {
    Color.backgroundSecondary
        .ignoresSafeArea()
        .overlay {
            ParentalGateView(
                onSuccess: {
                    print("Gate passed")
                },
                onDismiss: {
                    print("Gate dismissed")
                }
            )
        }
}

#Preview("With Context") {
    Color.backgroundSecondary
        .ignoresSafeArea()
        .overlay {
            ParentalGateView(
                onSuccess: {
                    print("Gate passed")
                },
                onDismiss: {
                    print("Gate dismissed")
                },
                context: "Parent verification is required to access settings and manage your child's profile."
            )
        }
}

#Preview("Dark Mode") {
    Color.backgroundSecondary
        .ignoresSafeArea()
        .overlay {
            ParentalGateView(
                onSuccess: {
                    print("Gate passed")
                },
                onDismiss: {
                    print("Gate dismissed")
                }
            )
        }
        .preferredColorScheme(.dark)
}
