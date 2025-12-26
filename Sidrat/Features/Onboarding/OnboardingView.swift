//
//  OnboardingView.swift
//  Sidrat
//
//  Premium onboarding experience
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @State private var childName = ""
    @State private var childAge = 6
    
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
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count {
                        Button("Skip") {
                            withAnimation(.spring(response: 0.5)) {
                                currentPage = pages.count
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
                    
                    ChildSetupView(
                        childName: $childName,
                        childAge: $childAge,
                        onComplete: completeOnboarding
                    )
                    .tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5), value: currentPage)
                
                // Bottom section
                VStack(spacing: Spacing.lg) {
                    // Page indicators
                    HStack(spacing: Spacing.xs) {
                        ForEach(0...pages.count, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? Color.brandPrimary : Color.textTertiary.opacity(0.3))
                                .frame(width: currentPage == index ? 28 : 8, height: 8)
                                .animation(.spring(response: 0.4), value: currentPage)
                        }
                    }
                    
                    // Navigation buttons
                    if currentPage < pages.count {
                        Button {
                            withAnimation(.spring(response: 0.5)) {
                                currentPage += 1
                            }
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
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
                }
                .padding(.bottom, Spacing.xl)
            }
        }
    }
    
    private func completeOnboarding() {
        // Create and save child profile
        let child = Child(name: childName, age: childAge)
        modelContext.insert(child)
        
        // Save the context to persist the child
        do {
            try modelContext.save()
            #if DEBUG
            print("✅ Child saved: \(child.name), ID: \(child.id)")
            #endif
        } catch {
            print("❌ Error saving child: \(error)")
            return
        }
        
        // Update app state on main thread
        DispatchQueue.main.async {
            appState.currentChildId = child.id.uuidString
            appState.isOnboardingComplete = true
            
            #if DEBUG
            print("✅ Onboarding complete! Navigating to home...")
            #endif
        }
    }
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

// MARK: - Child Setup View

struct ChildSetupView: View {
    @Binding var childName: String
    @Binding var childAge: Int
    let onComplete: () -> Void
    
    @FocusState private var isNameFocused: Bool
    private let ages = [5, 6, 7]
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Header
            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.brandPrimary)
                }
                
                Text("Create Profile")
                    .font(.title1)
                    .foregroundStyle(.textPrimary)
                
                Text("Set up your child's learning profile")
                    .font(.bodyMedium)
                    .foregroundStyle(.textSecondary)
            }
            
            // Form card
            VStack(spacing: Spacing.lg) {
                // Name field
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Child's Name")
                        .font(.labelSmall)
                        .foregroundStyle(.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    TextField("Enter name", text: $childName)
                        .font(.bodyLarge)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .stroke(isNameFocused ? Color.brandPrimary : Color.clear, lineWidth: 2)
                        )
                        .focused($isNameFocused)
                }
                
                // Age picker
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Age")
                        .font(.labelSmall)
                        .foregroundStyle(.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    HStack(spacing: Spacing.sm) {
                        ForEach(ages, id: \.self) { age in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    childAge = age
                                }
                            } label: {
                                VStack(spacing: Spacing.xxs) {
                                    Text("\(age)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("years")
                                        .font(.caption)
                                }
                                .foregroundStyle(childAge == age ? .white : .textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 72)
                                .background(
                                    childAge == age 
                                        ? AnyShapeStyle(LinearGradient.primaryGradient)
                                        : AnyShapeStyle(Color.backgroundTertiary)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                                .shadow(color: childAge == age ? Color.brandPrimary.opacity(0.3) : .clear, radius: 8, y: 4)
                            }
                        }
                    }
                }
            }
            .padding(Spacing.lg)
            .background(Color.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.extraLarge))
            .cardShadow()
            .padding(.horizontal, Spacing.lg)
            
            Spacer()
            
            // Complete button
            Button {
                onComplete()
            } label: {
                HStack(spacing: Spacing.sm) {
                    Text("Start Learning")
                    Image(systemName: "sparkles")
                }
                .font(.labelLarge)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md + 2)
                .background(
                    childName.isEmpty
                        ? AnyShapeStyle(Color.textTertiary)
                        : AnyShapeStyle(LinearGradient.primaryGradient)
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .shadow(color: childName.isEmpty ? .clear : Color.brandPrimary.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(childName.isEmpty)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
        .modelContainer(for: Child.self, inMemory: true)
}
