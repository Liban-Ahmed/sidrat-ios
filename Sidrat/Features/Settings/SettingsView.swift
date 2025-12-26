//
//  SettingsView.swift
//  Sidrat
//
//  App settings and profile management
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var children: [Child]
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var reminderTime = Date()
    @State private var showingResetConfirmation = false
    @State private var showingEditProfile = false
    
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
    
    var body: some View {
        NavigationStack {
            List {
                // Profile section
                Section {
                    HStack(spacing: Spacing.md) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.brandPrimary.opacity(0.1))
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundStyle(.brandPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(currentChild?.name ?? "Child")
                                .font(.title3)
                                .foregroundStyle(.textPrimary)
                            
                            Text("Age \(currentChild?.age ?? 0) • Week \(currentWeek)")
                                .font(.bodySmall)
                                .foregroundStyle(.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            showingEditProfile = true
                        } label: {
                            Text("Edit")
                                .font(.labelSmall)
                                .foregroundStyle(.brandPrimary)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                } header: {
                    Text("Child Profile")
                }
                
                // Notifications
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
                
                // Learning
                Section {
                    NavigationLink {
                        CurriculumOverviewView()
                    } label: {
                        Label("Curriculum", systemImage: "book.fill")
                    }
                    
                    Button {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset Progress", systemImage: "arrow.counterclockwise")
                            .foregroundStyle(.error)
                    }
                } header: {
                    Text("Learning")
                }
                
                // Parent Mode
                Section {
                    NavigationLink {
                        ParentDashboardView()
                    } label: {
                        Label("Parent Dashboard", systemImage: "chart.bar.fill")
                    }
                    
                    NavigationLink {
                        AddChildView()
                    } label: {
                        Label("Add Another Child", systemImage: "person.badge.plus")
                    }
                } header: {
                    Text("Family")
                }
                
                // Support
                Section {
                    NavigationLink {
                        HelpCenterView()
                    } label: {
                        Label("Help Center", systemImage: "questionmark.circle.fill")
                    }
                    
                    Link(destination: URL(string: "mailto:support@sidrat.app")!) {
                        Label("Contact Support", systemImage: "envelope.fill")
                    }
                    
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle.fill")
                    }
                } header: {
                    Text("Support")
                }
                
                // App info
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
            .navigationTitle("Settings")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(child: currentChild)
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
        
        try? modelContext.save()
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let child: Child?
    @State private var name: String = ""
    @State private var age: Int = 6
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    
                    Picker("Age", selection: $age) {
                        ForEach(3...12, id: \.self) { age in
                            Text("\(age) years old").tag(age)
                        }
                    }
                } header: {
                    Text("Child Information")
                }
            }
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
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let child = child {
                    name = child.name
                    age = child.age
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let child = child else { return }
        child.name = name
        child.age = age
        try? modelContext.save()
        dismiss()
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
    
    @State private var name: String = ""
    @State private var age: Int = 6
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                
                Picker("Age", selection: $age) {
                    ForEach(3...12, id: \.self) { age in
                        Text("\(age) years old").tag(age)
                    }
                }
            } header: {
                Text("Child Information")
            }
            
            Section {
                Button("Add Child") {
                    addChild()
                }
                .disabled(name.isEmpty)
            }
        }
        .navigationTitle("Add Child")
    }
    
    private func addChild() {
        let child = Child(name: name, age: age)
        modelContext.insert(child)
        try? modelContext.save()
        dismiss()
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

#Preview {
    SettingsView()
        .environment(AppState())
}
