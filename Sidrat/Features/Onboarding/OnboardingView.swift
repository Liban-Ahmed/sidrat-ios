//
//  OnboardingView.swift
//  Sidrat
//
//  Premium onboarding experience with COPPA-compliant child profile creation
//  and Sign in with Apple for parent account creation
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    
    /// Total number of intro pages (before account creation)
    private var introPageCount: Int { pages.count }
    
    /// Index of the account creation page
    private var accountPageIndex: Int { pages.count }
    
    /// Index of the child setup page
    private var childSetupPageIndex: Int { pages.count + 1 }
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Assalamu Alaikum!",
            subtitle: "Welcome to Sidrat",
            description: "The fun way for your child to learn about Islam—with you by their side.",
            imageName: "sparkles",
            color: .brandPrimary
        ),
        OnboardingPage(
            title: "5 Minutes a Day",
            subtitle: "Daily App Lessons",
            description: "Interactive games, stories, and quizzes designed for ages 5-7. Voice narration means no reading required!",
            imageName: "gamecontroller.fill",
            color: .brandSecondary
        ),
        OnboardingPage(
            title: "15 Minutes a Week",
            subtitle: "Family Activities",
            description: "Simple activities to do together—no prep needed. Reinforce what they learned and make memories.",
            imageName: "heart.fill",
            color: .brandAccent
        ),
        OnboardingPage(
            title: "Watch Them Grow",
            subtitle: "Track Progress",
            description: "See exactly what they've learned. Get conversation prompts to keep the learning going.",
            imageName: "chart.line.uptrend.xyaxis",
            color: .brandPrimary
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.backgroundSecondary
                .ignoresSafeArea()
            
            // Decorative background circles
            GeometryReader { geo in
                Circle()
                    .fill(Color.brandPrimary.opacity(0.06))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -50)
                
                Circle()
                    .fill(Color.brandSecondary.opacity(0.06))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: geo.size.width - 100, y: geo.size.height - 200)
                
                Circle()
                    .fill(Color.brandAccent.opacity(0.06))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .offset(x: geo.size.width / 2, y: 100)
            }
            
            VStack(spacing: 0) {
                // Skip button - only show on intro pages
                HStack {
                    Spacer()
                    if currentPage < introPageCount {
                        Button("Skip") {
                            withAnimation(.spring(response: 0.5)) {
                                currentPage = accountPageIndex
                            }
                        }
                        .font(.labelMedium)
                        .foregroundStyle(.textSecondary)
                        .padding()
                    }
                }
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                    
                    // Account creation page (Sign in with Apple)
                    AccountCreationView(onComplete: { result in
                        appState.setParentAccount(from: result)
                        withAnimation(.spring(response: 0.5)) {
                            currentPage = childSetupPageIndex
                        }
                    })
                    .tag(accountPageIndex)
                    
                    // Child profile setup page (US-102)
                    ChildProfileCreationView(
                        isOnboarding: true,
                        requiresParentalGate: true,
                        onComplete: {
                            // Profile creation is handled internally by ChildProfileCreationView
                            // including saving to SwiftData and updating appState
                            #if DEBUG
                            print("✅ Child profile created via ChildProfileCreationView")
                            #endif
                        }
                    )
                    .tag(childSetupPageIndex)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5), value: currentPage)
                
                // Bottom section - only show for intro pages
                if currentPage < introPageCount {
                    VStack(spacing: Spacing.lg) {
                        // Page indicators (include account page in dots)
                        HStack(spacing: Spacing.xs) {
                            ForEach(0...introPageCount, id: \.self) { index in
                                Capsule()
                                    .fill(currentPage == index ? Color.brandPrimary : Color.textTertiary.opacity(0.3))
                                    .frame(width: currentPage == index ? 28 : 8, height: 8)
                                    .animation(.spring(response: 0.4), value: currentPage)
                            }
                        }
                        
                        // Navigation buttons
                        Button {
                            withAnimation(.spring(response: 0.5)) {
                                currentPage += 1
                            }
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Text(currentPage == introPageCount - 1 ? "Get Started" : "Continue")
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .font(.labelLarge)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md + 2)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                            .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.bottom, Spacing.xl)
                }
            }
        }
    }
    
    // Note: Profile creation is now handled by ChildProfileCreationView (US-102)
    // which includes parental gate, validation, and persistence
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let color: Color
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Animated icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.color.opacity(0.2), page.color.opacity(0)],
                            center: .center,
                            startRadius: 60,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(isAnimated ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimated)
                
                // Inner circle
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.color, page.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: page.color.opacity(0.4), radius: 20, y: 10)
                
                Image(systemName: page.imageName)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(.white)
            }
            .onAppear { isAnimated = true }
            
            VStack(spacing: Spacing.md) {
                // Subtitle badge
                Text(page.subtitle.uppercased())
                    .font(.captionBold)
                    .foregroundStyle(page.color)
                    .tracking(2)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(page.color.opacity(0.1))
                    .clipShape(Capsule())
                
                // Title
                Text(page.title)
                    .font(.displayMedium)
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(page.description)
                    .font(.bodyLarge)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, Spacing.lg)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Account Creation View (Sign in with Apple)

/// View for parent account creation with Sign in with Apple
/// Privacy-first: No email scope requested (COPPA compliance)
struct AccountCreationView: View {
    let onComplete: (AuthenticationResult) -> Void
    
    @State private var errorMessage: String?
    @State private var showError = false
    
    private let authService = AuthenticationService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                Spacer()
                    .frame(height: Spacing.xxl)
                
                // Icon
                iconSection
                
                // Text content
                textSection
                
                // Sign in options
                signInSection
                
                // Privacy note
                privacyNote
                
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred. Please try again.")
        }
    }
    
    // MARK: - Icon Section
    
    private var iconSection: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.brandPrimary.opacity(0.2), Color.brandPrimary.opacity(0)],
                        center: .center,
                        startRadius: 60,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
            
            // Inner circle
            Circle()
                .fill(Color.brandPrimary.opacity(0.1))
                .frame(width: 160, height: 160)
            
            // Icon background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: Color.brandPrimary.opacity(0.4), radius: 20, y: 10)
            
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Text Section
    
    private var textSection: some View {
        VStack(spacing: Spacing.md) {
            // Subtitle badge
            Text("PARENT ACCOUNT")
                .font(.captionBold)
                .foregroundStyle(Color.brandPrimary)
                .tracking(2)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Color.brandPrimary.opacity(0.1))
                .clipShape(Capsule())
            
            // Title
            Text("Quick & Secure Setup")
                .font(.displayMedium)
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
            
            // Description
            Text("Sign in to sync progress across devices and keep your child's learning safe. We never share your information.")
                .font(.bodyLarge)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Spacing.md)
        }
    }
    
    // MARK: - Sign In Section
    
    private var signInSection: some View {
        VStack(spacing: Spacing.md) {
            // Sign in with Apple button
            StyledSignInWithAppleButton(
                onSuccess: { result in
                    onComplete(result)
                },
                onError: { error in
                    // Don't show error for user cancellation
                    guard !error.isUserCanceled else { return }
                    errorMessage = error.localizedDescription
                    showError = true
                }
            )
            .frame(height: 56)
            
            // Divider with "or"
            HStack(spacing: Spacing.md) {
                Rectangle()
                    .fill(Color.textTertiary.opacity(0.3))
                    .frame(height: 1)
                
                Text("or")
                    .font(.labelSmall)
                    .foregroundStyle(.textTertiary)
                
                Rectangle()
                    .fill(Color.textTertiary.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical, Spacing.xs)
            
            // Continue without account button
            ContinueWithoutAccountButton { result in
                onComplete(result)
            }
            .frame(height: 56)
        }
        .padding(.top, Spacing.lg)
    }
    
    // MARK: - Privacy Note
    
    private var privacyNote: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.brandSecondary)
            
            Text("Privacy-first: We only use an anonymous identifier. No email or personal data stored.")
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .padding(.top, Spacing.md)
    }
    
    }

#Preview {
    OnboardingView()
        .environment(AppState())
        .modelContainer(for: Child.self, inMemory: true)
}
