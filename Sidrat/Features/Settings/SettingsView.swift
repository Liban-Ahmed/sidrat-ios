//
//  SettingsView.swift
//  Sidrat
//
//  App settings and profile management
//  Implements parental gate protection for sensitive sections (US-104)
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var children: [Child]
    
    // MARK: - State
    
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var reminderTime = Date()
    @State private var showingResetConfirmation = false
    @State private var showingEditProfile = false
    @State private var showingResetGate = false
    @State private var showingEditGate = false
    
    // Navigation state - managed at NavigationStack level to avoid lazy container issues
    @State private var navigateToCurriculum = false
    @State private var navigateToParentDashboard = false
    @State private var navigateToAddChild = false
    
    // MARK: - Computed Properties
    
    private var currentChild: Child? {
        guard let childId = appState.currentChildId,
              let uuid = UUID(uuidString: childId) else { return nil }
        return children.first { $0.id == uuid }
    }
    
    // Calculate current week based on lessons completed
    private var currentWeek: Int {
        guard let child = currentChild else { return 1 }
        let lessonsCompleted = child.totalLessonsCompleted
        return max(1, (lessonsCompleted / 5) + 1)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // Profile section
                profileSection
                
                // Appearance settings (light/dark mode)
                appearanceSection
                
                // Notifications (gated)
                notificationsSection
                
                // Learning (gated)
                learningSection
                
                // Family (gated)
                familySection
                
                // Support (gated for external links)
                supportSection
                
                // App info
                appInfoSection
            }
            .navigationTitle("Settings")
            // Navigation destinations at NavigationStack level (outside lazy List)
            .navigationDestination(isPresented: $navigateToCurriculum) {
                CurriculumOverviewView()
            }
            .navigationDestination(isPresented: $navigateToParentDashboard) {
                ParentDashboardView()
            }
            .navigationDestination(isPresented: $navigateToAddChild) {
                AddChildView()
            }
            .gatedSheet(
                isPresented: $showingEditProfile,
                context: ParentalGateContext.editProfile
            ) {
                EditProfileView(child: currentChild)
            }
            .parentalGate(
                isPresented: $showingResetGate,
                context: ParentalGateContext.resetProgress
            ) {
                showingResetConfirmation = true
            }
            .alert("Reset Progress", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetProgress()
                }
            } message: {
                Text("This will reset all lesson progress, XP, streaks, and achievements. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section {
            HStack(spacing: Spacing.md) {
                // Avatar - using AvatarView component
                if let child = currentChild {
                    AvatarView.large(avatar: child.avatar)
                } else {
                    PlaceholderAvatarView(size: 64)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(currentChild?.name ?? "Child")
                        .font(.title3)
                        .foregroundStyle(.textPrimary)
                    
                    Text("Age \(currentChild?.currentAge ?? 0) • Week \(currentWeek)")
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                }
                
                Spacer()
                
                // Edit button requires parental gate
                Button {
                    showingEditProfile = true
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Text("Edit")
                            .font(.labelSmall)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                    }
                    .foregroundStyle(.brandPrimary)
                }
            }
            .padding(.vertical, Spacing.xs)
        } header: {
            Text("Child Profile")
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section {
            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.appearanceMode = mode
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(mode.iconColor)
                            .frame(width: 28, height: 28)
                        
                        Text(mode.displayName)
                            .font(.bodyMedium)
                            .foregroundStyle(.textPrimary)
                        
                        Spacer()
                        
                        if appState.appearanceMode == mode {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.brandPrimary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Appearance")
        } footer: {
            Text("Choose System to match your device's appearance settings.")
                .foregroundStyle(.textTertiary)
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                Label("Daily Reminders", systemImage: "bell.fill")
            }
            .tint(Color.brandPrimary)
            
            if notificationsEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
            }
            
            Toggle(isOn: $soundEnabled) {
                Label("Sound Effects", systemImage: "speaker.wave.2.fill")
            }
            .tint(Color.brandPrimary)
        } header: {
            Text("Notifications")
        }
    }
    
    // MARK: - Learning Section
    
    private var learningSection: some View {
        Section {
            // Curriculum - requires parental gate
            GatedNavigationRow(
                context: ParentalGateContext.curriculum,
                isNavigating: $navigateToCurriculum
            ) {
                Label("Curriculum", systemImage: "book.fill")
            }
            
            // Reset Progress - requires parental gate
            Button {
                showingResetGate = true
            } label: {
                HStack {
                    Label("Reset Progress", systemImage: "arrow.counterclockwise")
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
            }
            .foregroundStyle(.error)
        } header: {
            Text("Learning")
        }
    }
    
    // MARK: - Family Section
    
    private var familySection: some View {
        Section {
            // Parent Dashboard - requires parental gate
            GatedNavigationRow(
                context: ParentalGateContext.parentDashboard,
                isNavigating: $navigateToParentDashboard
            ) {
                Label("Parent Dashboard", systemImage: "chart.bar.fill")
            }
            
            // Add Another Child - requires parental gate
            GatedNavigationRow(
                context: ParentalGateContext.addChild,
                isNavigating: $navigateToAddChild
            ) {
                Label("Add Another Child", systemImage: "person.badge.plus")
            }
        } header: {
            Text("Family")
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        Section {
            // Help Center - no gate needed (internal content)
            NavigationLink {
                HelpCenterView()
            } label: {
                Label("Help Center", systemImage: "questionmark.circle.fill")
            }
            
            // Contact Support - requires parental gate (external link)
            SafeExternalLink(
                url: URL(string: "mailto:support@sidrat.app")!,
                context: ParentalGateContext.contactSupport
            ) {
                Label("Contact Support", systemImage: "envelope.fill")
            }
            
            // About - no gate needed (internal content)
            NavigationLink {
                AboutView()
            } label: {
                Label("About", systemImage: "info.circle.fill")
            }
        } header: {
            Text("Support")
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.textSecondary)
            }
        } footer: {
            VStack(spacing: Spacing.sm) {
                Text("Made with ❤️ for Muslim families")
                Text("© 2025 Sidrat")
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.lg)
        }
    }
    
    // MARK: - Actions
    
    private func resetProgress() {
        guard let child = currentChild else { return }
        
        // Clear lesson progress
        child.lessonProgress.removeAll()
        
        // Clear achievements
        child.achievements.removeAll()
        
        // Reset stats
        child.totalXP = 0
        child.totalLessonsCompleted = 0
        child.currentStreak = 0
        child.longestStreak = 0
        
        // Reset app state
        appState.dailyStreak = 0
        appState.lastCompletedDate = nil
        
        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        do {
            try modelContext.save()
            #if DEBUG
            print("✅ Progress reset for \(child.name)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Error resetting progress: \(error)")
            #endif
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let child: Child?
    
    @State private var name: String = ""
    @State private var selectedBirthYear: Int = Calendar.current.component(.year, from: Date()) - 6
    @State private var selectedAvatar: AvatarOption = .cat
    @State private var showParentalGate = false
    @FocusState private var isNameFocused: Bool
    
    // Birth year options for ages 4-10
    private let birthYears: [Int] = {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 10)...(current - 4)).reversed()
    }()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Avatar preview and selection
                    VStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(selectedAvatar.backgroundColor.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Text(selectedAvatar.emoji)
                                .font(.system(size: 60))
                        }
                        
                        Text("Tap to change avatar")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                    }
                    .padding(.top, Spacing.lg)
                    
                    // Form fields
                    VStack(spacing: Spacing.lg) {
                        // Name field
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Display Name")
                                .font(.labelSmall)
                                .foregroundStyle(.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            TextField("Enter a name", text: $name)
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
                        }
                        
                        // Avatar selection
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Choose an Avatar")
                                .font(.labelSmall)
                                .foregroundStyle(.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 65), spacing: Spacing.xs)
                            ], spacing: Spacing.xs) {
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
                                                .frame(width: 65, height: 65)
                                            
                                            Text(avatar.emoji)
                                                .font(.system(size: 32))
                                            
                                            if selectedAvatar == avatar {
                                                Circle()
                                                    .stroke(Color.brandPrimary, lineWidth: 2)
                                                    .frame(width: 65, height: 65)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(avatar.accessibilityLabel) avatar")
                                    .accessibilityAddTraits(selectedAvatar == avatar ? [.isSelected] : [])
                                }
                            }
                        }
                        
                        // Birth year picker
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Birth Year")
                                .font(.labelSmall)
                                .foregroundStyle(.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            Picker("Birth Year", selection: $selectedBirthYear) {
                                ForEach(birthYears, id: \.self) { year in
                                    let age = Calendar.current.component(.year, from: Date()) - year
                                    Text(verbatim: "\(year) (Age \(age))")
                                        .tag(year)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                            .background(Color.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        }
                    }
                    .padding(Spacing.lg)
                    .background(Color.backgroundPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.extraLarge))
                    .cardShadow()
                }
                .padding()
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        showParentalGate = true
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let child = child {
                    name = child.name
                    selectedBirthYear = child.birthYear
                    selectedAvatar = child.avatar
                }
            }
            .sheet(isPresented: $showParentalGate) {
                ParentalGateView(
                    onSuccess: {
                        showParentalGate = false
                        saveChanges()
                    },
                    onDismiss: {
                        showParentalGate = false
                    },
                    context: "Parent verification is required to edit a child profile."
                )
                .interactiveDismissDisabled()
            }
        }
    }
    
    private func saveChanges() {
        guard let child = child else { return }
        
        child.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        child.birthYear = selectedBirthYear
        child.avatarId = selectedAvatar.rawValue
        
        do {
            try modelContext.save()
            #if DEBUG
            print(" Profile updated: \(child.name)")
            #endif
            dismiss()
        } catch {
            #if DEBUG
            print(" Error saving profile: \(error)")
            #endif
        }
    }
}

// MARK: - Curriculum Overview View

struct CurriculumOverviewView: View {
    @Query(sort: \Lesson.order) private var lessons: [Lesson]
    
    var body: some View {
        List {
            ForEach(LessonCategory.allCases, id: \.self) { category in
                let categoryLessons = lessons.filter { $0.category == category }
                
                Section {
                    ForEach(categoryLessons) { lesson in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundStyle(.brandPrimary)
                            
                            VStack(alignment: .leading) {
                                Text(lesson.title)
                                    .font(.labelMedium)
                                
                                Text("Week \(lesson.weekNumber) • \(lesson.durationMinutes) min")
                                    .font(.caption)
                                    .foregroundStyle(.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text("\(lesson.xpReward) XP")
                                .font(.caption)
                                .foregroundStyle(.brandAccent)
                        }
                    }
                } header: {
                    HStack {
                        Text(category.rawValue)
                        Spacer()
                        Text("\(categoryLessons.count) lessons")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
        }
        .navigationTitle("Curriculum")
    }
}

// MARK: - Parent Dashboard View

struct ParentDashboardView: View {
    @Environment(AppState.self) private var appState
    @Query private var children: [Child]
    
    private var currentChild: Child? {
        guard let childId = appState.currentChildId,
              let uuid = UUID(uuidString: childId) else { return nil }
        return children.first { $0.id == uuid }
    }
    
    var body: some View {
        List {
            Section {
                StatRow(label: "Total Lessons", value: "\(currentChild?.totalLessonsCompleted ?? 0)")
                StatRow(label: "Total XP Earned", value: "\(currentChild?.totalXP ?? 0)")
                StatRow(label: "Current Streak", value: "\(currentChild?.currentStreak ?? 0) days")
                StatRow(label: "Longest Streak", value: "\(currentChild?.longestStreak ?? 0) days")
                StatRow(label: "Achievements", value: "\(currentChild?.achievements.count ?? 0)")
            } header: {
                Text("Learning Statistics")
            }
            
            Section {
                Text("Your child is making great progress! Keep encouraging daily learning.")
                    .font(.bodySmall)
                    .foregroundStyle(.textSecondary)
            } header: {
                Text("Insights")
            }
        }
        .navigationTitle("Parent Dashboard")
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.textPrimary)
            Spacer()
            Text(value)
                .foregroundStyle(.brandPrimary)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Add Child View

struct AddChildView: View {
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
                        
                        TextField("Enter a name", text: $name)
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
                            .accessibilityLabel("Child's display name")
                            .accessibilityHint("Enter your child's name (not required to be real name)")
                    }
                    
                    // Avatar selection
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
                    
                    // Birth year picker
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Birth Year")
                            .font(.labelSmall)
                            .foregroundStyle(.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        Picker("Birth Year", selection: $selectedBirthYear) {
                            ForEach(birthYears, id: \.self) { year in
                                let age = Calendar.current.component(.year, from: Date()) - year
                                Text(verbatim: "\(year) (Age \(age))")
                                    .tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        .accessibilityLabel("Select birth year")
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
        .background(Color.backgroundSecondary)
        .navigationTitle("Add Child")
        .navigationBarTitleDisplayMode(.inline)
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
        .onAppear {
            #if DEBUG
            print("📝 AddChildView appeared - existing children: \(existingChildren.count)")
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
            
            // Dismiss after successful save
            dismiss()
        } catch {
            #if DEBUG
            print(" Error saving child: \(error)")
            #endif
        }
    }
}

// MARK: - Help Center View

struct HelpCenterView: View {
    var body: some View {
        List {
            Section {
                FAQRow(question: "How do lessons work?", answer: "Each lesson is 5 minutes and includes stories, quizzes, and activities designed for children ages 5-7.")
                
                FAQRow(question: "What are family activities?", answer: "Weekly activities to do together with your child, reinforcing what they learned in their lessons.")
                
                FAQRow(question: "How does the streak work?", answer: "Complete at least one lesson per day to maintain your streak. The streak resets if you miss a day.")
                
                FAQRow(question: "What are achievements?", answer: "Badges earned by completing milestones like finishing lessons, maintaining streaks, and completing activities.")
            } header: {
                Text("Frequently Asked Questions")
            }
        }
        .navigationTitle("Help Center")
    }
}

struct FAQRow: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(question)
                        .font(.labelMedium)
                        .foregroundStyle(.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(.textTertiary)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.bodySmall)
                    .foregroundStyle(.textSecondary)
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.brandPrimary)
                    
                    Text("Sidrat")
                        .font(.title)
                        .foregroundStyle(.textPrimary)
                    
                    Text("Teaching Islam to children, one lesson at a time")
                        .font(.bodyMedium)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            }
            
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.textSecondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("2025.1")
                        .foregroundStyle(.textSecondary)
                }
            }
            
            Section {
                Link("Privacy Policy", destination: URL(string: "https://sidrat.app/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://sidrat.app/terms")!)
            }
        }
        .navigationTitle("About")
    }
}

#Preview("Light Mode") {
    SettingsView()
        .environment(AppState())
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    SettingsView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
