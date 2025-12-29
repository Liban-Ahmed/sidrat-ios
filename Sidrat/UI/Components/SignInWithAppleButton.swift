//
//  SignInWithAppleButton.swift
//  Sidrat
//
//  Custom Sign in with Apple button with SwiftUI integration
//  Implements US-101: Parent account creation
//

import SwiftUI
import AuthenticationServices

// MARK: - Sign In With Apple Button

/// A SwiftUI wrapper for the native Sign in with Apple button
/// Provides consistent styling and handles authentication flow
struct SignInWithAppleButton: View {
    
    // MARK: - Properties
    
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Initialization
    
    init(
        onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
        onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void
    ) {
        self.onRequest = onRequest
        self.onCompletion = onCompletion
    }
    
    // MARK: - Body
    
    var body: some View {
        SignInWithAppleButtonViewRepresentable(
            type: .signIn,
            style: colorScheme == .dark ? .white : .black,
            onRequest: onRequest,
            onCompletion: onCompletion
        )
        .frame(height: 56)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

// MARK: - UIKit Representable

/// UIViewRepresentable wrapper for ASAuthorizationAppleIDButton
private struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.cornerRadius = CornerRadius.medium
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleAuthorizationAppleIDButtonPress),
            for: .touchUpInside
        )
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void
        
        init(
            onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
            onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void
        ) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }
        
        @objc func handleAuthorizationAppleIDButtonPress() {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            onRequest(request)
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
        
        // MARK: - ASAuthorizationControllerDelegate
        
        func authorizationController(
            controller: ASAuthorizationController,
            didCompleteWithAuthorization authorization: ASAuthorization
        ) {
            onCompletion(.success(authorization))
        }
        
        func authorizationController(
            controller: ASAuthorizationController,
            didCompleteWithError error: Error
        ) {
            onCompletion(.failure(error))
        }
        
        // MARK: - ASAuthorizationControllerPresentationContextProviding
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else {
                fatalError("No window available")
            }
            return window
        }
    }
}

// MARK: - Styled Sign In Button

/// A styled Sign in with Apple button matching the app's design system
struct StyledSignInWithAppleButton: View {
    
    // MARK: - Properties
    
    @StateObject private var authService = AuthenticationService.shared
    let onSuccess: (AuthenticationResult) -> Void
    let onError: ((AuthenticationError) -> Void)?
    
    @State private var isLoading = false
    
    // MARK: - Initialization
    
    init(
        onSuccess: @escaping (AuthenticationResult) -> Void,
        onError: ((AuthenticationError) -> Void)? = nil
    ) {
        self.onSuccess = onSuccess
        self.onError = onError
    }
    
    // MARK: - Body
    
    var body: some View {
        Button {
            Task {
                await signIn()
            }
        } label: {
            HStack(spacing: Spacing.md) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 20, weight: .medium))
                }
                
                Text("Sign in with Apple")
                    .font(.labelLarge)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
        .disabled(isLoading)
        .accessibilityLabel("Sign in with Apple")
        .accessibilityHint("Creates a private account using your Apple ID")
    }
    
    // MARK: - Private Methods
    
    private func signIn() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await authService.signInWithApple()
            onSuccess(result)
        } catch let error as AuthenticationError {
            if !error.isUserCanceled {
                onError?(error)
            }
        } catch {
            onError?(.failed(error.localizedDescription))
        }
    }
}

// MARK: - Continue Without Account Button

/// Button for offline/local-only mode
struct ContinueWithoutAccountButton: View {
    
    let onContinue: (AuthenticationResult) -> Void
    
    var body: some View {
        Button {
            let result = AuthenticationService.shared.createLocalAccount()
            onContinue(result)
        } label: {
            Text("Continue without account")
                .font(.labelMedium)
                .foregroundStyle(.textSecondary)
                .underline()
        }
        .accessibilityLabel("Continue without account")
        .accessibilityHint("Creates a local account that stays on this device only")
    }
}

// MARK: - Previews

#Preview("Sign In Buttons") {
    VStack(spacing: Spacing.lg) {
        StyledSignInWithAppleButton { result in
            print("Success: \(result.userIdentifier)")
        }
        
        ContinueWithoutAccountButton { result in
            print("Local: \(result.userIdentifier)")
        }
    }
    .padding()
}
