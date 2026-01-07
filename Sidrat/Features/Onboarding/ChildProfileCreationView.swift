//
//  ChildProfileCreationView.swift
//  Sidrat
//
//  Child profile creation with parental gate protection
//  Implements US-102: Child Profile Creation
//

import SwiftUI
import SwiftData

/// A comprehensive child profile creation view with:
/// - Parental gate verification before showing the form
/// - Display name field (not requiring real name for COPPA compliance)
/// - Avatar selector with 75pt+ touch targets
/// - Birth year picker (not exact date for privacy)
/// - Maximum 4 profiles validation
/// - Local persistence with SwiftData
struct ChildProfileCreationView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    // MARK: - Query
    
    @Query private var existingChildren: [Child]
    
    // MARK: - State
    
    @State private var displayName: String = ""
    @State private var selectedBirthYear: Int
    @State private var selectedAvatar: AvatarOption = .cat
    @State private var showParentalGate: Bool
    @State private var hasPassedParentalGate: Bool = false
    @State private var showMaxProfilesAlert = false
    @State private var showValidationError = false
    @State private var validationErrorMessage = ""
    @FocusState private var isNameFocused: Bool
    
    // MARK: - Callbacks
    
    /// Called when profile creation completes successfully
    let onComplete: () -> Void
    
    /// Whether this is being used during onboarding (vs. adding additional child)
    let isOnboarding: Bool
    
    /// Whether to require parental gate before showing form
    let requiresParentalGate: Bool
    
    // MARK: - Constants
    
    /// Maximum number of child profiles allowed per parent account
    static let maxChildProfiles = 4
    
    /// Birth years for ages 4-10 (target audience is 5-7)
    private var birthYearOptions: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 10)...(currentYear - 4)).reversed()
    }
    
    // MARK: - Computed Properties
    
    /// Whether the form is valid for submission
    private var isFormValid: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Whether more profiles can be added
    private var canAddProfile: Bool {
        existingChildren.count < Self.maxChildProfiles
    }
    
    /// Current profile count message
    private var profileCountMessage: String {
        if isOnboarding {
            return "Create your first child profile"
        }
        return "\(existingChildren.count) of \(Self.maxChildProfiles) profiles created"
    }
    
    /// Selected age based on birth year
    private var selectedAge: Int {
        Calendar.current.component(.year, from: Date()) - selectedBirthYear
    }
    
    // MARK: - Initialization
    
    init(
        isOnboarding: Bool = false,
        requiresParentalGate: Bool = true,
        onComplete: @escaping () -> Void
    ) {
        self.isOnboarding = isOnboarding
        self.requiresParentalGate = requiresParentalGate
        self.onComplete = onComplete
        
        // Default birth year for age 6
        let defaultYear = Calendar.current.component(.year, from: Date()) - 6
        _selectedBirthYear = State(initialValue: defaultYear)
        
        // Show parental gate immediately if required
        _showParentalGate = State(initialValue: requiresParentalGate)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color.backgroundSecondary
                .ignoresSafeArea()
            
            if hasPassedParentalGate || !requiresParentalGate {
                // Main form content
                formContent
            } else {
                // Placeholder while parental gate is showing
                VStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Verifying...")
                        .font(.bodyMedium)
                        .foregroundStyle(.textSecondary)
                        .padding(.top, Spacing.sm)
                }
            }
        }
        .navigationTitle(isOnboarding ? "" : "Create Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showParentalGate) {
            ParentalGateView(
                onSuccess: {
                    showParentalGate = false
                    hasPassedParentalGate = true
                },
                onDismiss: {
                    showParentalGate = false
                    if !hasPassedParentalGate {
                        dismiss()
                    }
                },
                context: "Parent verification is required to create a child profile."
            )
            .interactiveDismissDisabled()
        }
        .alert("Maximum Profiles Reached", isPresented: $showMaxProfilesAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can have up to \(Self.maxChildProfiles) child profiles. Please remove an existing profile to add a new one.")
        }
        .alert("Validation Error", isPresented: $showValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationErrorMessage)
        }
        .onAppear {
            #if DEBUG
            print("📝 ChildProfileCreationView appeared - existing children: \(existingChildren.count)")
            #endif
        }
    }
    
    // MARK: - Form Content
    
    private var formContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header with avatar preview
                headerSection
                    .padding(.top, Spacing.lg)
                
                // Form fields card
                formCard
                
                // Create profile button
                createProfileButton
                    .padding(.bottom, Spacing.xl)
            }
            .padding(.horizontal, Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            // Dismiss keyboard when tapping outside TextField
            isNameFocused = false
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // Selected avatar preview (animated)
            AvatarPreview(avatar: selectedAvatar, size: 100)
                .animation(.spring(response: 0.3), value: selectedAvatar)
            
            // Title
            Text(isOnboarding ? "Create Child Profile" : "Add Child Profile")
                .font(.title1)
                .fontWeight(.bold)
                .foregroundStyle(.textPrimary)
            
            // Subtitle
            Text(profileCountMessage)
                .font(.bodySmall)
                .foregroundStyle(.textSecondary)
        }
    }
    
    // MARK: - Form Card
    
    private var formCard: some View {
        VStack(spacing: Spacing.lg) {
            // Display name field
            displayNameField
            
            // Avatar selector
            AvatarSelector(
                selectedAvatar: $selectedAvatar,
                title: "Choose an Avatar",
                columns: 4,
                avatarSize: 75,
                showCheckmark: true
            )
            
            // Birth year picker
            birthYearSection
        }
        .padding(Spacing.lg)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.extraLarge))
        .cardShadow()
    }
    
    // MARK: - Display Name Field
    
    private var displayNameField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Display Name")
                .font(.labelSmall)
                .foregroundStyle(.textSecondary)
                .textCase(.uppercase)
                .tracking(1)
            
            TextField("Enter a name", text: $displayName)
                .font(.bodyLarge)
                .padding()
                .frame(height: 56)
                .background(Color.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .focused($isNameFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit {
                    isNameFocused = false
                }
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(isNameFocused ? Color.brandPrimary : Color.clear, lineWidth: 2)
                }
                .focused($isNameFocused)
                .textContentType(.nickname)
                .autocorrectionDisabled()
                .accessibilityLabel("Child's display name")
                .accessibilityHint("Enter a display name for your child (not required to be real name)")
            
            // Helper text
            Text("This can be a nickname - no real name required")
                .font(.caption)
                .foregroundStyle(.textTertiary)
        }
    }
    
    // MARK: - Birth Year Section
    
    private var birthYearSection: some View {
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
                ForEach(birthYearOptions, id: \.self) { year in
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
            
            // Helper text showing birth year
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
            createProfile()
        } label: {
            HStack(spacing: Spacing.sm) {
                Text(isOnboarding ? "Create Profile" : "Add Child")
                Image(systemName: isOnboarding ? "checkmark.circle.fill" : "plus.circle.fill")
            }
            .font(.labelLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
            .background {
                if isFormValid && canAddProfile {
                    LinearGradient.primaryGradient
                } else {
                    Color.textTertiary
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .shadow(
                color: isFormValid && canAddProfile ? Color.brandPrimary.opacity(0.3) : .clear,
                radius: 8,
                y: 4
            )
        }
        .disabled(!isFormValid || !canAddProfile)
        .accessibilityLabel(isOnboarding ? "Create profile" : "Add child")
        .accessibilityHint(
            !isFormValid ? "Enter a display name first" :
                !canAddProfile ? "Maximum profiles reached" :
                "Creates a new child profile"
        )
    }
    
    // MARK: - Actions
    
    private func createProfile() {
        // Validate max profiles
        guard canAddProfile else {
            showMaxProfilesAlert = true
            return
        }
        
        // Validate form
        guard isFormValid else { return }
        
        // Create child with trimmed name
        let child = Child(
            name: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            birthYear: selectedBirthYear,
            avatarId: selectedAvatar.rawValue
        )
        
        // Validate child data
        let validationErrors = child.validate()
        if !validationErrors.isEmpty {
            validationErrorMessage = validationErrors.joined(separator: "\n")
            showValidationError = true
            #if DEBUG
            print("⚠️ Validation errors: \(validationErrors)")
            #endif
            return
        }
        
        // Insert and save
        #if DEBUG
        print("✅ Creating child profile: \(child.name), Age: \(child.currentAge), Avatar: \(child.avatar.accessibilityLabel)")
        #endif
        
        modelContext.insert(child)
        
        do {
            try modelContext.save()
            
            #if DEBUG
            print("💾 Child saved successfully. ID: \(child.id)")
            
            // Verify
            let descriptor = FetchDescriptor<Child>()
            let allChildren = try modelContext.fetch(descriptor)
            print("📊 Total children after save: \(allChildren.count)")
            for c in allChildren {
                print("  - \(c.name) (Age \(c.currentAge))")
            }
            #endif
            
            // Update app state
            DispatchQueue.main.async {
                appState.currentChildId = child.id.uuidString
                
                if isOnboarding {
                    appState.isOnboardingComplete = true
                }
                
                onComplete()
            }
            
        } catch {
            #if DEBUG
            print("❌ Error saving child: \(error)")
            #endif
            validationErrorMessage = "Failed to save profile. Please try again."
            showValidationError = true
        }
    }
}

// MARK: - Preview

#Preview("Child Profile Creation - Onboarding") {
    NavigationStack {
        ChildProfileCreationView(
            isOnboarding: true,
            requiresParentalGate: false,
            onComplete: { print("Profile created!") }
        )
    }
    .environment(AppState())
    .modelContainer(for: Child.self, inMemory: true)
}

#Preview("Child Profile Creation - Add Child") {
    NavigationStack {
        ChildProfileCreationView(
            isOnboarding: false,
            requiresParentalGate: false,
            onComplete: { print("Child added!") }
        )
    }
    .environment(AppState())
    .modelContainer(for: Child.self, inMemory: true)
}
