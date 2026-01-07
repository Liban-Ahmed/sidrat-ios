//
//  ProfileSwitcherView.swift
//  Sidrat
//
//  Profile switching interface for managing multiple child profiles
//  Implements US-103: Child profile switching
//

import SwiftUI
import SwiftData

// MARK: - Profile Switcher View

/// A sheet view that displays all child profiles and allows quick switching between them.
/// Designed for one-tap switching with clear visual indicators for the active profile.
struct ProfileSwitcherView: View {
    // MARK: - Environment
    
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Queries
    
    @Query(sort: \Child.lastAccessedAt, order: .reverse) private var children: [Child]
    
    // MARK: - State
    
    @State private var isLoading = false
    @State private var switchStartTime: Date?
    @State private var showingAddChild = false
    @State private var refreshTrigger = UUID()
    
    // MARK: - Computed Properties
    
    /// The currently active child based on AppState
    private var currentChild: Child? {
        guard let childId = appState.currentChildId,
              let uuid = UUID(uuidString: childId) else { return nil }
        return children.first { $0.id == uuid }
    }
    
    /// Whether there's room for more profiles (max 4)
    private var canAddMoreProfiles: Bool {
        children.count < 4
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header info
                    headerSection
                    
                    // Profiles list
                    profilesSection
                    
                    // Add profile button (if room)
                    if canAddMoreProfiles {
                        addProfileButton
                    }
                    
                    #if DEBUG
                    // Debug info
                    Text("Children count: \(children.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #endif
                }
                .padding()
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Switch Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.labelMedium)
                    .foregroundStyle(.brandPrimary)
                }
            }
            .sheet(isPresented: $showingAddChild, onDismiss: {
                // Force refresh when sheet dismisses
                refreshTrigger = UUID()
                #if DEBUG
                print("📋 AddChild sheet dismissed, refreshing...")
                #endif
            }) {
                AddChildSheetView()
            }
        }
        .id(refreshTrigger) // Force view refresh when trigger changes
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            #if DEBUG
            print("📋 ProfileSwitcherView appeared with \(children.count) children")
            for child in children {
                print("  - \(child.name) (ID: \(child.id.uuidString.prefix(8))...)")
            }
            #endif
        }
        .onChange(of: children.count) { oldValue, newValue in
            #if DEBUG
            print(" ProfileSwitcherView children count changed: \(oldValue) -> \(newValue)")
            #endif
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Spacing.xs) {
            Text("Who's learning today?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.textPrimary)
            
            Text("\(children.count) of 4 profiles")
                .font(.bodySmall)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Profiles Section
    
    private var profilesSection: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(children) { child in
                ProfileCardView(
                    child: child,
                    isActive: child.id.uuidString == appState.currentChildId,
                    isLoading: isLoading && child.id.uuidString == appState.currentChildId,
                    onSelect: {
                        switchToProfile(child)
                    }
                )
            }
        }
    }
    
    // MARK: - Add Profile Button
    
    private var addProfileButton: some View {
        Button {
            showingAddChild = true
        } label: {
            HStack(spacing: Spacing.md) {
                // Plus icon
                ZStack {
                    Circle()
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                        )
                        .foregroundStyle(.textTertiary)
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.textTertiary)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Add Another Child")
                        .font(.labelLarge)
                        .foregroundStyle(.textPrimary)
                    
                    Text("Create a new profile")
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.labelSmall)
                    .foregroundStyle(.textTertiary)
            }
            .padding()
            .background(Color.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .cardShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add another child profile")
        .accessibilityHint("Opens form to create a new child profile")
    }
    
    // MARK: - Actions
    
    /// Switch to a different child profile
    /// - Parameter child: The child profile to switch to
    private func switchToProfile(_ child: Child) {
        // Don't switch if already active
        guard child.id.uuidString != appState.currentChildId else {
            dismiss()
            return
        }
        
        // Track switch start time for performance monitoring
        switchStartTime = Date()
        isLoading = true
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Perform switch with minimal delay for UI feedback
        // Using Task to ensure smooth animation
        Task { @MainActor in
            // Update app state (this triggers data reload)
            appState.currentChildId = child.id.uuidString
            
            // Mark as accessed for sorting
            child.markAsAccessed()
            
            // Save context
            do {
                try modelContext.save()
            } catch {
                #if DEBUG
                print(" Error saving child access time: \(error)")
                #endif
            }
            
            // Log performance in debug
            #if DEBUG
            if let startTime = switchStartTime {
                let elapsed = Date().timeIntervalSince(startTime) * 1000
                print(" Profile switch completed in \(String(format: "%.0f", elapsed))ms")
            }
            #endif
            
            isLoading = false
            
            // Dismiss after brief delay for visual feedback
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
            dismiss()
        }
    }
}

// MARK: - Profile Card View

/// Individual profile card with avatar, name, stats, and active indicator
struct ProfileCardView: View {
    // MARK: - Properties
    
    let child: Child
    let isActive: Bool
    let isLoading: Bool
    let onSelect: () -> Void
    
    // MARK: - State
    
    @State private var isPressed = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Avatar
                avatarView
                
                // Info
                infoSection
                
                Spacer()
                
                // Active indicator or chevron
                trailingIndicator
            }
            .padding()
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .stroke(Color.brandPrimary, lineWidth: 2)
                }
            }
            .cardShadow()
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint(isActive ? "Currently selected" : "Double tap to switch to this profile")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
    
    // MARK: - Subviews
    
    private var avatarView: some View {
        AvatarView.large(avatar: child.avatar, isSelected: isActive)
            .accessibilityHidden(true)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                Text(child.name)
                    .font(.labelLarge)
                    .foregroundStyle(.textPrimary)
                
                if isActive {
                    ActiveBadge()
                }
            }
            
            Text("Age \(child.currentAge)")
                .font(.bodySmall)
                .foregroundStyle(.textSecondary)
            
            // Quick stats
            HStack(spacing: Spacing.sm) {
                StatPill(icon: "star.fill", value: "\(child.totalXP)", color: .brandAccent)
                StatPill(icon: "flame.fill", value: "\(child.currentStreak)", color: .brandPrimary)
            }
        }
    }
    
    private var trailingIndicator: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(.brandPrimary)
            } else if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.brandPrimary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.labelSmall)
                    .foregroundStyle(.textTertiary)
            }
        }
    }
    
    private var cardBackground: Color {
        isActive ? Color.brandPrimary.opacity(0.05) : Color.backgroundPrimary
    }
    
    private var accessibilityDescription: String {
        "\(child.name), age \(child.currentAge), \(child.totalXP) XP, \(child.currentStreak) day streak"
    }
}

// MARK: - Supporting Views

/// Small badge indicating the active profile
struct ActiveBadge: View {
    var body: some View {
        Text("Active")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.brandPrimary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(Color.brandPrimary.opacity(0.1))
            .clipShape(Capsule())
    }
}

/// Compact stat display with icon and value
struct StatPill: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.textSecondary)
        }
    }
}

// MARK: - Profile Switcher Button

/// A compact button to trigger the profile switcher from the home view
struct ProfileSwitcherButton: View {
    // MARK: - Environment
    
    @Environment(AppState.self) private var appState
    @Query private var children: [Child]
    
    // MARK: - Bindings
    
    @Binding var showingSwitcher: Bool
    
    // MARK: - Computed Properties
    
    private var currentChild: Child? {
        guard let childId = appState.currentChildId,
              let uuid = UUID(uuidString: childId) else { return nil }
        return children.first { $0.id == uuid }
    }
    
    private var hasMultipleChildren: Bool {
        children.count > 1
    }
    
    // MARK: - Body
    
    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showingSwitcher = true
        } label: {
            HStack(spacing: Spacing.xs) {
                // Avatar - using AvatarView component
                if let child = currentChild {
                    AvatarView.small(avatar: child.avatar)
                } else {
                    PlaceholderAvatarView(size: 36)
                }
                
                // Dropdown indicator (only if multiple children)
                if hasMultipleChildren {
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(Color.backgroundTertiary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(currentChild.map { "\($0.name)'s profile" } ?? "Profile")
        .accessibilityHint(hasMultipleChildren ? "Double tap to switch profiles" : "Double tap to view profile options")
    }
}

// MARK: - Add Child Sheet View

/// A sheet view for adding a new child profile
/// This is presented as a sheet from ProfileSwitcherView to ensure proper context handling
struct AddChildSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var existingChildren: [Child]
    
    @State private var name: String = ""
    @State private var selectedBirthYear: Int = {
        Calendar.current.component(.year, from: Date()) - 6 // Default to age 6
    }()
    @State private var selectedAvatar: AvatarOption = .cat
    @State private var showParentalGate = false
    @State private var showMaxProfilesAlert = false
    @FocusState private var isNameFocused: Bool
    
    // Birth year options for ages 4-10
    private let birthYears: [Int] = {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 10)...(current - 4)).reversed()
    }()
    
    private var canAddMoreProfiles: Bool {
        existingChildren.count < 4
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
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
                        
                        Text("Add Child Profile")
                            .font(.title1)
                            .fontWeight(.bold)
                            .foregroundStyle(.textPrimary)
                        
                        Text("\(existingChildren.count) of 4 profiles created")
                            .font(.bodySmall)
                            .foregroundStyle(.textSecondary)
                    }
                    .padding(.top, Spacing.lg)
                    
                    // Form card
                    VStack(spacing: Spacing.lg) {
                        // Name field
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Display Name")
                                .font(.labelSmall)
                                .foregroundStyle(.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            TextField("Enter child's name", text: $name)
                                .textFieldStyle(.plain)
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
                        }
                        
                        // Avatar selection
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Choose Avatar")
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
                                                
                                                Circle()
                                                    .fill(Color.brandPrimary)
                                                    .frame(width: 24, height: 24)
                                                    .overlay {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 12, weight: .bold))
                                                            .foregroundStyle(.white)
                                                    }
                                                    .offset(x: 25, y: -25)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(avatar.accessibilityLabel) avatar")
                                    .accessibilityAddTraits(selectedAvatar == avatar ? [.isSelected] : [])
                                }
                            }
                        }
                        
                        // Birth year picker - age selection grid
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Child's Age")
                                .font(.labelSmall)
                                .foregroundStyle(.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1)
                            
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
                            
                            Text(verbatim: "Born in \(selectedBirthYear)")
                                .font(.caption)
                                .foregroundStyle(.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, Spacing.xxs)
                        }
                    }
                    .padding(Spacing.lg)
                    .background(Color.backgroundPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.extraLarge))
                    .cardShadow()
                    
                    // Add button (requires parental gate)
                    Button {
                        if canAddMoreProfiles {
                            showParentalGate = true
                        } else {
                            showMaxProfilesAlert = true
                        }
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Text("Add Child")
                            Image(systemName: "plus.circle")
                        }
                        .font(.labelLarge)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 60)
                        .background {
                            if name.isEmpty || !canAddMoreProfiles {
                                Color.textTertiary
                            } else {
                                LinearGradient.primaryGradient
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        .shadow(
                            color: name.isEmpty || !canAddMoreProfiles ? .clear : Color.brandPrimary.opacity(0.3),
                            radius: 8,
                            y: 4
                        )
                    }
                    .disabled(name.isEmpty)
                    .accessibilityLabel("Add child")
                    .accessibilityHint(name.isEmpty ? "Enter a name first" : "Opens parent verification")
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.backgroundSecondary)
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.textSecondary)
                }
            }
            .sheet(isPresented: $showParentalGate) {
                ParentalGateView(
                    onSuccess: {
                        showParentalGate = false
                        addChild()
                    },
                    onDismiss: {
                        showParentalGate = false
                    },
                    context: "Parent verification is required to add a child profile."
                )
                .interactiveDismissDisabled()
            }
            .alert("Maximum Profiles Reached", isPresented: $showMaxProfilesAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You can have a maximum of 4 child profiles. Please remove an existing profile to add a new one.")
            }
        }
        .onAppear {
            #if DEBUG
            print("📝 AddChildSheetView appeared - existing children: \(existingChildren.count)")
            #endif
        }
    }
    
    private func addChild() {
        // Create child with proper birth year and avatar
        let child = Child(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            birthYear: selectedBirthYear,
            avatarId: selectedAvatar.rawValue
        )
        
        // Validate
        let errors = child.validate()
        if !errors.isEmpty {
            #if DEBUG
            print(" Validation errors: \(errors.joined(separator: ", "))")
            #endif
            return
        }
        
        #if DEBUG
        print(" Inserting child: \(child.name)")
        #endif
        
        modelContext.insert(child)
        
        do {
            try modelContext.save()
            #if DEBUG
            print(" Child saved successfully: \(child.name), ID: \(child.id.uuidString)")
            
            // Verify by fetching
            let descriptor = FetchDescriptor<Child>()
            let allChildren = try modelContext.fetch(descriptor)
            print("📊 Total children in database after save: \(allChildren.count)")
            for c in allChildren {
                print("  - \(c.name) (ID: \(c.id.uuidString.prefix(8))...)")
            }
            #endif
            
            // Dismiss the sheet after successful save
            dismiss()
        } catch {
            #if DEBUG
            print(" Error saving child: \(error)")
            #endif
        }
    }
}

// MARK: - Previews

#Preview("Profile Switcher") {
    ProfileSwitcherView()
        .environment(AppState())
        .modelContainer(for: Child.self, inMemory: true)
}

#Preview("Profile Card - Active") {
    ProfileCardView(
        child: Child.sample,
        isActive: true,
        isLoading: false,
        onSelect: {}
    )
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Profile Card - Inactive") {
    ProfileCardView(
        child: Child.sample2,
        isActive: false,
        isLoading: false,
        onSelect: {}
    )
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Profile Switcher Button") {
    ProfileSwitcherButton(showingSwitcher: .constant(false))
        .environment(AppState())
        .modelContainer(for: Child.self, inMemory: true)
        .padding()
}
