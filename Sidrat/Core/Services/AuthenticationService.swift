//
//  AuthenticationService.swift
//  Sidrat
//
//  Sign in with Apple authentication service
//  Implements US-101: Parent account creation with privacy-first approach
//

import Foundation
import AuthenticationServices
import CryptoKit

// MARK: - Authentication Service

/// Handles Sign in with Apple authentication with privacy-first design
/// - No email scope requested (COPPA compliance, privacy-first)
/// - Uses anonymous identifier for account creation
/// - Supports offline mode with local-only fallback
@MainActor
final class AuthenticationService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    @Published private(set) var error: AuthenticationError?
    
    // MARK: - Private Properties
    
    private var currentNonce: String?
    private var authenticationContinuation: CheckedContinuation<AuthenticationResult, Error>?
    
    // MARK: - Singleton
    
    static let shared = AuthenticationService()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        checkExistingCredentials()
    }
    
    // MARK: - Public Methods
    
    /// Initiates Sign in with Apple flow
    /// - Returns: Authentication result with user identifier
    func signInWithApple() async throws -> AuthenticationResult {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Generate cryptographic nonce for security
        let nonce = generateNonce()
        currentNonce = nonce
        
        // Create the authorization request
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        
        // Privacy-first: Only request name, no email scope
        // This complies with COPPA and minimizes data collection
        request.requestedScopes = [.fullName]
        request.nonce = sha256(nonce)
        
        // Perform the authorization
        return try await withCheckedThrowingContinuation { continuation in
            self.authenticationContinuation = continuation
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
    
    /// Creates a local-only account for offline mode
    /// - Returns: Authentication result with locally generated identifier
    func createLocalAccount() -> AuthenticationResult {
        let localIdentifier = UUID().uuidString
        let result = AuthenticationResult(
            userIdentifier: localIdentifier,
            fullName: nil,
            isLocalOnly: true
        )
        
        // Save to keychain for persistence
        saveCredentials(result)
        isAuthenticated = true
        
        #if DEBUG
        print("📱 Created local-only account: \(localIdentifier.prefix(8))...")
        #endif
        
        return result
    }
    
    /// Signs out the current user
    func signOut() {
        clearCredentials()
        isAuthenticated = false
        
        #if DEBUG
        print("👋 User signed out")
        #endif
    }
    
    /// Checks if there are existing saved credentials
    func checkExistingCredentials() {
        if let _ = loadCredentials() {
            isAuthenticated = true
            #if DEBUG
            print("✅ Found existing credentials")
            #endif
        }
    }
    
    /// Verifies the current Apple ID credential status
    func verifyCredentialState() async {
        guard let credentials = loadCredentials(),
              !credentials.isLocalOnly else {
            return
        }
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        do {
            let state = try await appleIDProvider.credentialState(forUserID: credentials.userIdentifier)
            
            switch state {
            case .authorized:
                isAuthenticated = true
                #if DEBUG
                print("✅ Apple ID credential authorized")
                #endif
                
            case .revoked, .notFound:
                // Credential has been revoked or not found
                clearCredentials()
                isAuthenticated = false
                #if DEBUG
                print("⚠️ Apple ID credential revoked or not found")
                #endif
                
            case .transferred:
                // Account was transferred to a different iCloud account
                #if DEBUG
                print("📦 Apple ID credential transferred")
                #endif
                
            @unknown default:
                break
            }
        } catch {
            #if DEBUG
            print("❌ Error checking credential state: \(error)")
            #endif
        }
    }
    
    // MARK: - Private Methods
    
    /// Generates a cryptographically secure random nonce
    private func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    /// Creates SHA256 hash of the input string
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Keychain Storage
    
    private let keychainService = "com.sidrat.app.auth"
    private let keychainAccount = "parentAccount"
    
    private func saveCredentials(_ result: AuthenticationResult) {
        guard let data = try? JSONEncoder().encode(result) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        #if DEBUG
        if status == errSecSuccess {
            print("🔐 Credentials saved to keychain")
        } else {
            print("❌ Failed to save credentials: \(status)")
        }
        #endif
    }
    
    private func loadCredentials() -> AuthenticationResult? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let credentials = try? JSONDecoder().decode(AuthenticationResult.self, from: data) else {
            return nil
        }
        
        return credentials
    }
    
    private func clearCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        SecItemDelete(query as CFDictionary)
        
        // Also clear from UserDefaults
        UserDefaults.standard.removeObject(forKey: "parentUserIdentifier")
        UserDefaults.standard.removeObject(forKey: "isLocalOnlyAccount")
        
        #if DEBUG
        print("🗑️ Credentials cleared from keychain")
        #endif
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationService: ASAuthorizationControllerDelegate {
    
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                let error = AuthenticationError.invalidCredential
                self.error = error
                self.authenticationContinuation?.resume(throwing: error)
                self.authenticationContinuation = nil
                return
            }
            
            // Extract user information
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            
            // Create authentication result
            let result = AuthenticationResult(
                userIdentifier: userIdentifier,
                fullName: fullName,
                isLocalOnly: false
            )
            
            // Save credentials securely
            saveCredentials(result)
            isAuthenticated = true
            
            #if DEBUG
            print("✅ Sign in with Apple successful")
            print("   User ID: \(userIdentifier.prefix(8))...")
            if let givenName = fullName?.givenName {
                print("   Name: \(givenName)")
            }
            #endif
            
            authenticationContinuation?.resume(returning: result)
            authenticationContinuation = nil
        }
    }
    
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            let authError: AuthenticationError
            
            if let asError = error as? ASAuthorizationError {
                switch asError.code {
                case .canceled:
                    authError = .userCanceled
                case .failed:
                    authError = .failed(asError.localizedDescription)
                case .invalidResponse:
                    authError = .invalidResponse
                case .notHandled:
                    authError = .notHandled
                case .notInteractive:
                    authError = .notInteractive
                case .unknown:
                    authError = .unknown
                @unknown default:
                    authError = .unknown
                }
            } else {
                authError = .failed(error.localizedDescription)
            }
            
            self.error = authError
            
            #if DEBUG
            print("❌ Sign in with Apple failed: \(authError.localizedDescription)")
            #endif
            
            authenticationContinuation?.resume(throwing: authError)
            authenticationContinuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    
    @MainActor
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window for presentation
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("No window available for Sign in with Apple presentation")
        }
        return window
    }
}

// MARK: - Authentication Result

/// Result of successful authentication
struct AuthenticationResult: Codable, Equatable {
    /// Anonymous Apple ID or local UUID
    let userIdentifier: String
    
    /// Optional full name (only provided on first sign-in)
    let givenName: String?
    let familyName: String?
    
    /// Whether this is a local-only account (offline mode)
    let isLocalOnly: Bool
    
    /// Creation date of the account
    let createdAt: Date
    
    init(
        userIdentifier: String,
        fullName: PersonNameComponents? = nil,
        isLocalOnly: Bool = false
    ) {
        self.userIdentifier = userIdentifier
        self.givenName = fullName?.givenName
        self.familyName = fullName?.familyName
        self.isLocalOnly = isLocalOnly
        self.createdAt = Date()
    }
    
    /// Display name for the parent
    var displayName: String? {
        if let givenName = givenName {
            return givenName
        }
        return nil
    }
}

// MARK: - Authentication Error

/// Errors that can occur during authentication
enum AuthenticationError: LocalizedError, Equatable {
    case userCanceled
    case invalidCredential
    case invalidResponse
    case notHandled
    case notInteractive
    case failed(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .userCanceled:
            return "Sign in was canceled"
        case .invalidCredential:
            return "Invalid credential received"
        case .invalidResponse:
            return "Invalid response from Apple"
        case .notHandled:
            return "Request was not handled"
        case .notInteractive:
            return "Sign in requires user interaction"
        case .failed(let message):
            return message
        case .unknown:
            return "An unknown error occurred"
        }
    }
    
    var isUserCanceled: Bool {
        self == .userCanceled
    }
}
