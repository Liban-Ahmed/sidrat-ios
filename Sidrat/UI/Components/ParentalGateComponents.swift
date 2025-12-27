//
//  ParentalGateComponents.swift
//  Sidrat
//
//  Reusable parental gate components for COPPA compliance
//  Implements US-104: Parental Gate Integration
//

import SwiftUI

// MARK: - Parental Gate Modifier

/// A view modifier that presents a parental gate before allowing content access
/// Usage: .parentalGate(isPresented: $showGate, context: "Access settings") { /* on success */ }
struct ParentalGateModifier: ViewModifier {
    @Binding var isPresented: Bool
    let context: String?
    let onSuccess: () -> Void
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                ParentalGateView(
                    onSuccess: {
                        isPresented = false
                        onSuccess()
                    },
                    onDismiss: {
                        isPresented = false
                    },
                    context: context
                )
                .background(Color.clear)
                .presentationBackground(.clear)
            }
    }
}

extension View {
    /// Adds a parental gate that can be triggered programmatically
    /// - Parameters:
    ///   - isPresented: Binding to control gate presentation
    ///   - context: Optional explanation shown to parents
    ///   - onSuccess: Callback when gate is successfully passed
    func parentalGate(
        isPresented: Binding<Bool>,
        context: String? = nil,
        onSuccess: @escaping () -> Void
    ) -> some View {
        modifier(ParentalGateModifier(
            isPresented: isPresented,
            context: context,
            onSuccess: onSuccess
        ))
    }
}

// MARK: - Parental Gate Navigation Link

/// A row component that requires parental verification before triggering navigation
/// Use with navigation state managed at the parent view level to avoid lazy container issues
///
/// Usage:
/// ```
/// // In parent view state:
/// @State private var navigateToCurriculum = false
///
/// // In List:
/// GatedNavigationRow(
///     context: ParentalGateContext.curriculum,
///     isNavigating: $navigateToCurriculum
/// ) {
///     Label("Curriculum", systemImage: "book.fill")
/// }
///
/// // At NavigationStack level:
/// .navigationDestination(isPresented: $navigateToCurriculum) {
///     CurriculumOverviewView()
/// }
/// ```
struct GatedNavigationRow<Label: View>: View {
    let context: String?
    @Binding var isNavigating: Bool
    let label: () -> Label
    
    @State private var showingGate = false
    
    init(
        context: String? = nil,
        isNavigating: Binding<Bool>,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.context = context
        self._isNavigating = isNavigating
        self.label = label
    }
    
    var body: some View {
        Button {
            showingGate = true
        } label: {
            HStack {
                label()
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.textPrimary)
        .fullScreenCover(isPresented: $showingGate) {
            ParentalGateView(
                onSuccess: {
                    showingGate = false
                    // Small delay to ensure gate dismisses before navigation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isNavigating = true
                    }
                },
                onDismiss: {
                    showingGate = false
                },
                context: context
            )
            .background(Color.clear)
            .presentationBackground(.clear)
        }
    }
}

/// Navigation destinations for gated settings navigation
enum GatedSettingsDestination: Hashable {
    case curriculum
    case parentDashboard
    case addChild
}

/// A navigation link that requires parental verification before navigation
/// NOTE: This component should NOT be used inside lazy containers like List or LazyVStack
/// For use inside List, use GatedNavigationRow with navigationDestination at the NavigationStack level
@available(*, deprecated, message: "Use GatedNavigationRow inside List/LazyVStack containers to avoid navigation issues")
struct ParentalGateNavigationLink<Label: View, Destination: View>: View {
    let destination: () -> Destination
    let label: () -> Label
    let context: String?
    
    @State private var showingGate = false
    @State private var isNavigating = false
    
    init(
        context: String? = nil,
        @ViewBuilder destination: @escaping () -> Destination,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.context = context
        self.destination = destination
        self.label = label
    }
    
    var body: some View {
        Button {
            showingGate = true
        } label: {
            HStack {
                label()
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.textPrimary)
        .fullScreenCover(isPresented: $showingGate) {
            ParentalGateView(
                onSuccess: {
                    showingGate = false
                    // Small delay to ensure sheet dismisses before navigation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isNavigating = true
                    }
                },
                onDismiss: {
                    showingGate = false
                },
                context: context
            )
            .background(Color.clear)
            .presentationBackground(.clear)
        }
        .navigationDestination(isPresented: $isNavigating) {
            destination()
        }
    }
}

// MARK: - Parental Gate Button

/// A button that requires parental verification before executing its action
/// Use for sensitive actions like deleting data, purchasing, or changing settings
struct ParentalGateButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    let context: String?
    let role: ButtonRole?
    
    @State private var showingGate = false
    
    init(
        context: String? = nil,
        role: ButtonRole? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.context = context
        self.role = role
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button(role: role) {
            showingGate = true
        } label: {
            HStack {
                label()
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
        }
        .fullScreenCover(isPresented: $showingGate) {
            ParentalGateView(
                onSuccess: {
                    showingGate = false
                    // Small delay for smooth transition
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        action()
                    }
                },
                onDismiss: {
                    showingGate = false
                },
                context: context
            )
            .background(Color.clear)
            .presentationBackground(.clear)
        }
    }
}

// MARK: - Safe External Link

/// A link component that requires parental verification before opening external URLs
/// Required for COPPA compliance in Kids Category apps
struct SafeExternalLink<Label: View>: View {
    let url: URL
    let label: () -> Label
    let context: String?
    
    @Environment(\.openURL) private var openURL
    @State private var showingGate = false
    @State private var showingConfirmation = false
    
    init(
        url: URL,
        context: String? = nil,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.url = url
        self.context = context
        self.label = label
    }
    
    /// Convenience initializer for URL strings
    init(
        destination: String,
        context: String? = nil,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.url = URL(string: destination) ?? URL(string: "about:blank")!
        self.context = context
        self.label = label
    }
    
    var body: some View {
        Button {
            showingGate = true
        } label: {
            HStack {
                label()
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.textPrimary)
        .fullScreenCover(isPresented: $showingGate) {
            ParentalGateView(
                onSuccess: {
                    showingGate = false
                    // Show confirmation before opening external link
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showingConfirmation = true
                    }
                },
                onDismiss: {
                    showingGate = false
                },
                context: context ?? "This will open an external link outside the app."
            )
            .background(Color.clear)
            .presentationBackground(.clear)
        }
        .alert("Open External Link", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Open") {
                openURL(url)
            }
        } message: {
            Text("You're about to leave Sidrat and open:\n\(url.host ?? url.absoluteString)")
        }
    }
}

// MARK: - Gated Tab View

/// A wrapper that requires parental verification to access a specific tab
struct GatedTabContent<Content: View>: View {
    let content: () -> Content
    let context: String?
    let onDismiss: () -> Void
    
    @State private var isUnlocked = false
    @State private var showingGate = true
    
    init(
        context: String? = nil,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.context = context
        self.onDismiss = onDismiss
        self.content = content
    }
    
    var body: some View {
        Group {
            if isUnlocked {
                content()
            } else {
                // Show locked placeholder while gate is displayed
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.textTertiary)
                    
                    Text("Parent Access Required")
                        .font(.title3)
                        .foregroundStyle(.textSecondary)
                    
                    Text("This section requires parental verification.")
                        .font(.bodyMedium)
                        .foregroundStyle(.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.backgroundSecondary)
            }
        }
        .fullScreenCover(isPresented: $showingGate) {
            ParentalGateView(
                onSuccess: {
                    showingGate = false
                    withAnimation(.easeOut(duration: 0.3)) {
                        isUnlocked = true
                    }
                },
                onDismiss: {
                    showingGate = false
                    onDismiss()
                },
                context: context
            )
            .background(Color.clear)
            .presentationBackground(.clear)
        }
    }
}

// MARK: - Gated Sheet Modifier

/// A modifier that wraps sheet content with parental gate verification
struct GatedSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let context: String?
    let sheetContent: () -> SheetContent
    
    @State private var showingGate = false
    @State private var showingSheet = false
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    showingGate = true
                } else {
                    showingSheet = false
                }
            }
            .fullScreenCover(isPresented: $showingGate) {
                ParentalGateView(
                    onSuccess: {
                        showingGate = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingSheet = true
                        }
                    },
                    onDismiss: {
                        showingGate = false
                        isPresented = false
                    },
                    context: context
                )
                .background(Color.clear)
                .presentationBackground(.clear)
            }
            .sheet(isPresented: $showingSheet, onDismiss: {
                isPresented = false
            }) {
                sheetContent()
            }
    }
}

extension View {
    /// Presents a sheet that requires parental gate verification before showing
    /// - Parameters:
    ///   - isPresented: Binding to control presentation
    ///   - context: Optional explanation for the parental gate
    ///   - content: The sheet content to present after verification
    func gatedSheet<Content: View>(
        isPresented: Binding<Bool>,
        context: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(GatedSheetModifier(
            isPresented: isPresented,
            context: context,
            sheetContent: content
        ))
    }
}

// MARK: - Parental Gate Context Presets

/// Common context messages for parental gates
enum ParentalGateContext {
    static let settings = "Parent verification is required to access settings and manage profiles."
    static let addChild = "Parent verification is required to add a new child profile."
    static let editProfile = "Parent verification is required to edit profile information."
    static let deleteProfile = "Parent verification is required to delete a profile."
    static let resetProgress = "Parent verification is required to reset learning progress."
    static let externalLink = "Parent verification is required to open external links."
    static let contactSupport = "Parent verification is required to contact support."
    static let parentDashboard = "Parent verification is required to access the parent dashboard."
    static let familySettings = "Parent verification is required to manage family settings."
    static let curriculum = "Parent verification is required to view curriculum settings."
    static let notifications = "Parent verification is required to change notification settings."
}

// MARK: - Previews

#Preview("Gated Navigation Row") {
    struct PreviewWrapper: View {
        @State private var navigateToSettings = false
        
        var body: some View {
            NavigationStack {
                List {
                    GatedNavigationRow(
                        context: ParentalGateContext.settings,
                        isNavigating: $navigateToSettings
                    ) {
                        Label("Protected Settings", systemImage: "gearshape.fill")
                    }
                    
                    NavigationLink {
                        Text("Regular Content")
                    } label: {
                        Label("Regular Link", systemImage: "link")
                    }
                }
                .navigationDestination(isPresented: $navigateToSettings) {
                    Text("Secret Settings")
                }
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Gated Button") {
    VStack(spacing: 20) {
        ParentalGateButton(
            context: ParentalGateContext.resetProgress,
            role: .destructive
        ) {
            print("Reset executed")
        } label: {
            Label("Reset Progress", systemImage: "arrow.counterclockwise")
        }
        
        ParentalGateButton(context: ParentalGateContext.addChild) {
            print("Add child")
        } label: {
            Text("Add Child")
        }
    }
    .padding()
}

#Preview("Safe External Link") {
    List {
        SafeExternalLink(
            url: URL(string: "mailto:support@sidrat.app")!,
            context: ParentalGateContext.contactSupport
        ) {
            Label("Contact Support", systemImage: "envelope.fill")
        }
        
        SafeExternalLink(
            destination: "https://sidrat.app/privacy",
            context: ParentalGateContext.externalLink
        ) {
            Label("Privacy Policy", systemImage: "hand.raised.fill")
        }
    }
}
