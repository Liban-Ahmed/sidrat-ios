//
//  MainTabView.swift
//  Sidrat
//
//  Main tab navigation for the app
//  Implements parental gate for Settings tab (US-104)
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var previousTab: Tab = .home
    @State private var showingSettingsGate = false
    @State private var settingsUnlocked = false
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case learn = "Learn"
        case family = "Family"
        case progress = "Progress"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .learn: return "book.fill"
            case .family: return "heart.fill"
            case .progress: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var selectedIcon: String {
            icon // Same for now, but can be customized
        }
        
        /// Whether this tab requires parental gate
        var requiresParentalGate: Bool {
            self == .settings
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)
            
            LearnView()
                .tabItem {
                    Label(Tab.learn.rawValue, systemImage: Tab.learn.icon)
                }
                .tag(Tab.learn)
            
            FamilyView()
                .tabItem {
                    Label(Tab.family.rawValue, systemImage: Tab.family.icon)
                }
                .tag(Tab.family)
            
            ProgressDashboardView()
                .tabItem {
                    Label(Tab.progress.rawValue, systemImage: Tab.progress.icon)
                }
                .tag(Tab.progress)
            
            // Settings tab with lock indicator
            settingsTabContent
                .tabItem {
                    Label {
                        Text(Tab.settings.rawValue)
                    } icon: {
                        Image(systemName: settingsUnlocked ? Tab.settings.icon : "lock.fill")
                    }
                }
                .tag(Tab.settings)
        }
        .tint(Color.brandPrimary)
        .onChange(of: selectedTab) { oldValue, newValue in
            handleTabChange(from: oldValue, to: newValue)
        }
        .fullScreenCover(isPresented: $showingSettingsGate) {
            ParentalGateView(
                onSuccess: {
                    showingSettingsGate = false
                    settingsUnlocked = true
                    selectedTab = .settings
                },
                onDismiss: {
                    showingSettingsGate = false
                    // Return to previous tab
                    selectedTab = previousTab
                },
                context: ParentalGateContext.settings
            )
            .background(Color.clear)
            .presentationBackground(.clear)
        }
    }
    
    // MARK: - Settings Tab Content
    
    @ViewBuilder
    private var settingsTabContent: some View {
        if settingsUnlocked {
            SettingsView()
        } else {
            // Locked placeholder that triggers the gate
            SettingsLockedView {
                showingSettingsGate = true
            }
        }
    }
    
    // MARK: - Tab Change Handler
    
    private func handleTabChange(from oldTab: Tab, to newTab: Tab) {
        // If switching to settings and not unlocked, show gate
        if newTab == .settings && !settingsUnlocked {
            previousTab = oldTab
            showingSettingsGate = true
        } else if newTab != .settings {
            // Track previous non-settings tab
            previousTab = newTab
        }
    }
}

// MARK: - Settings Locked View

/// Placeholder view shown when Settings tab is locked
struct SettingsLockedView: View {
    let onUnlock: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Lock icon
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.brandPrimary)
                }
                .accessibilityHidden(true)
                
                // Title
                VStack(spacing: Spacing.sm) {
                    Text("Parent Access Required")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.textPrimary)
                    
                    Text("Settings contains options for parents.\nVerification is required to continue.")
                        .font(.bodyMedium)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Unlock button
                Button {
                    onUnlock()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "lock.open.fill")
                        Text("Unlock Settings")
                    }
                    .font(.labelLarge)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    .shadow(color: .brandPrimary.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal, Spacing.xl)
                
                Spacer()
                
                // Info text
                Text("This helps keep your child safe while using the app.")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                    .padding(.bottom, Spacing.xl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundSecondary)
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}

#Preview("Settings Locked") {
    SettingsLockedView {
        print("Unlock tapped")
    }
}
