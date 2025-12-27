//
//  OnboardingView.swift
//  Sidrat
//
//  Premium onboarding experience with COPPA-compliant child profile creation
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @State private var childName = ""
    @State private var selectedBirthYear: Int = {
        Calendar.current.component(.year, from: Date()) - 6 // Default to age 6
    }()
    @State private var selectedAvatar: AvatarOption = .cat
    
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
                        selectedBirthYear: $selectedBirthYear,
                        selectedAvatar: $selectedAvatar,
                        onComplete: completeOnboarding
                    )
                    .tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5), value: currentPage)
                
                // Bottom section - only show for intro pages, not child setup
                if currentPage < pages.count {
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
                    .padding(.bottom, Spacing.xl)
                }
            }
        }
    }
    
    private func completeOnboarding() {
        // Check profile limit (maximum 4 children per parent account)
        let descriptor = FetchDescriptor<Child>()
        let existingChildren = (try? modelContext.fetch(descriptor)) ?? []
        
        if existingChildren.count >= 4 {
            #if DEBUG
            print(" Maximum of 4 child profiles reached")
            #endif
            // TODO: Show error alert to user
            return
        }
        
        // Create and save child profile with new model structure
        let child = Child(
            name: childName.trimmingCharacters(in: .whitespacesAndNewlines),
            birthYear: selectedBirthYear,
            avatarId: selectedAvatar.rawValue
        )
        
        // Validate child data
        let validationErrors = child.validate()
        if !validationErrors.isEmpty {
            #if DEBUG
            print(" Validation errors: \(validationErrors.joined(separator: ", "))")
            #endif
            // TODO: Show validation errors to user
            return
        }
        
        #if DEBUG
        print(" Inserting first child during onboarding: \(child.name)")
        #endif
        
        modelContext.insert(child)
        
        // Save the context to persist the child
        do {
            try modelContext.save()
            #if DEBUG
            print(" Child saved: \(child.name), Age: \(child.currentAge), Avatar: \(child.avatar.accessibilityLabel), ID: \(child.id)")
            
            // Verify by fetching
            let descriptor = FetchDescriptor<Child>()
            let allChildren = try modelContext.fetch(descriptor)
            print("📊 Total children in database after onboarding save: \(allChildren.count)")
            for c in allChildren {
                print("  - \(c.name) (ID: \(c.id.uuidString.prefix(8))...)")
            }
            #endif
        } catch {
            print(" Error saving child: \(error)")
            return
        }
        
        // Update app state on main thread
        DispatchQueue.main.async {
            appState.currentChildId = child.id.uuidString
            appState.isOnboardingComplete = true
            
            #if DEBUG
            print(" Onboarding complete! Navigating to home...")
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
    @Binding var selectedBirthYear: Int
    @Binding var selectedAvatar: AvatarOption
    let onComplete: () -> Void
    
    @FocusState private var isNameFocused: Bool
    @State private var showParentalGate = false
    
    // Birth year options for ages 4-10
    private let birthYears: [Int] = {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 10)...(current - 4)).reversed()
    }()
    
    /// Whether the form is valid for submission
    private var isFormValid: Bool {
        !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header
                headerSection
                    .padding(.top, Spacing.lg)
                
                // Form card
                formCard
                
                // Complete button (requires parental gate)
                createProfileButton
                    .padding(.bottom, Spacing.xl)
            }
            .padding(.horizontal, Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showParentalGate) {
            ParentalGateView(
                onSuccess: {
                    showParentalGate = false
                    onComplete()
                },
                onDismiss: {
                    showParentalGate = false
                },
                context: "Parent verification is required to create a child profile."
            )
            .interactiveDismissDisabled()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // Selected avatar preview
            ZStack {
                Circle()
                    .fill(selectedAvatar.backgroundColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Text(selectedAvatar.emoji)
                    .font(.system(size: 60))
            }
            .accessibilityLabel("\(selectedAvatar.accessibilityLabel) avatar selected")
            
            Text("Create Child Profile")
                .font(.title1)
                .fontWeight(.bold)
                .foregroundStyle(.textPrimary)
            
            Text("This helps us personalize the learning experience")
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Form Card
    
    private var formCard: some View {
        VStack(spacing: Spacing.lg) {
            // Name field
            nameField
            
            // Avatar selection
            avatarSelection
            
            // Birth year picker
            birthYearPicker
        }
        .padding(Spacing.lg)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.extraLarge))
        .cardShadow()
    }
    
    // MARK: - Name Field
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Display Name")
                .font(.labelSmall)
                .foregroundStyle(.textSecondary)
                .textCase(.uppercase)
                .tracking(1)
            
            TextField("Enter a name", text: $childName)
                .font(.bodyLarge)
                .padding()
                .frame(minHeight: 56)
                .background(Color.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(isNameFocused ? Color.brandPrimary : Color.clear, lineWidth: 2)
                }
                .focused($isNameFocused)
                .textContentType(.nickname)
                .autocorrectionDisabled()
                .accessibilityLabel("Child's display name")
                .accessibilityHint("Enter your child's name (not required to be real name)")
        }
    }
    
    // MARK: - Avatar Selection
    
    private var avatarSelection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Choose an Avatar")
                .font(.labelSmall)
                .foregroundStyle(.textSecondary)
                .textCase(.uppercase)
                .tracking(1)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 75), spacing: Spacing.sm)
            ], spacing: Spacing.sm) {
                ForEach(AvatarOption.allCases) { avatar in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedAvatar = avatar
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(avatar.backgroundColor.opacity(0.2))
                                .frame(width: 75, height: 75)
                            
                            Text(avatar.emoji)
                                .font(.system(size: 40))
                            
                            if selectedAvatar == avatar {
                                Circle()
                                    .stroke(Color.brandPrimary, lineWidth: 3)
                                    .frame(width: 75, height: 75)
                                
                                // Checkmark badge
                                Circle()
                                    .fill(Color.brandPrimary)
                                    .frame(width: 24, height: 24)
                                    .overlay {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    .offset(x: 26, y: -26)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(avatar.accessibilityLabel) avatar")
                    .accessibilityAddTraits(selectedAvatar == avatar ? [.isSelected] : [])
                }
            }
        }
    }
    
    // MARK: - Birth Year Picker
    
    private var birthYearPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Child's Age")
                .font(.labelSmall)
                .foregroundStyle(.textSecondary)
                .textCase(.uppercase)
                .tracking(1)
            
            // Age selection grid - more child-friendly and visual
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                ForEach(birthYears, id: \.self) { year in
                    let age = Calendar.current.component(.year, from: Date()) - year
                    let isSelected = selectedBirthYear == year
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedBirthYear = year
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        VStack(spacing: Spacing.xxs) {
                            Text("\(age)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(isSelected ? .white : .textPrimary)
                            
                            Text("years")
                                .font(.caption2)
                                .foregroundStyle(isSelected ? .white.opacity(0.8) : .textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    .fill(LinearGradient.primaryGradient)
                            } else {
                                RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    .fill(Color.backgroundTertiary)
                            }
                        }
                        .overlay {
                            if isSelected {
                                RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    .stroke(Color.brandPrimary, lineWidth: 2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Age \(age)")
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            
            // Helper text
            Text(verbatim: "Born in \(selectedBirthYear)")
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, Spacing.xxs)
        }
    }
    
    // MARK: - Create Profile Button
    
    private var createProfileButton: some View {
        Button {
            // Dismiss keyboard first
            isNameFocused = false
            // Show parental gate
            showParentalGate = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Text("Create Profile")
                Image(systemName: "checkmark.circle.fill")
            }
            .font(.labelLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
            .background {
                if isFormValid {
                    LinearGradient.primaryGradient
                } else {
                    Color.textTertiary
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .shadow(
                color: isFormValid ? Color.brandPrimary.opacity(0.3) : .clear,
                radius: 8,
                y: 4
            )
        }
        .disabled(!isFormValid)
        .accessibilityLabel("Create profile")
        .accessibilityHint(isFormValid ? "Opens parent verification" : "Enter a name first")
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
        .modelContainer(for: Child.self, inMemory: true)
}
