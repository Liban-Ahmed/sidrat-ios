//
//  AvatarSelector.swift
//  Sidrat
//
//  Child-friendly avatar selection component with large touch targets
//  Implements US-102: Child Profile Creation
//

import SwiftUI

/// A grid-based avatar selector component optimized for children
/// Features:
/// - 75x75pt minimum touch targets (exceeds Apple HIG)
/// - Visual selection indicator with border and checkmark
/// - Full VoiceOver accessibility support
/// - Spring animations for engaging feedback
struct AvatarSelector: View {
    // MARK: - Properties
    
    /// Currently selected avatar
    @Binding var selectedAvatar: AvatarOption
    
    /// Optional title shown above the grid
    var title: String? = "Choose an Avatar"
    
    /// Number of columns in the grid (auto-calculates based on available space)
    var columns: Int = 4
    
    /// Minimum size for each avatar (must be >= 75pt for accessibility)
    var avatarSize: CGFloat = 75
    
    /// Whether to show the selection checkmark badge
    var showCheckmark: Bool = true
    
    /// Callback when avatar selection changes
    var onSelectionChanged: ((AvatarOption) -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section title
            if let title {
                Text(title)
                    .font(.labelSmall)
                    .foregroundStyle(.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            
            // Avatar grid
            avatarGrid
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Avatar selection")
    }
    
    // MARK: - Avatar Grid
    
    private var avatarGrid: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(minimum: avatarSize), spacing: Spacing.sm),
                count: columns
            ),
            spacing: Spacing.sm
        ) {
            ForEach(AvatarOption.allCases) { avatar in
                AvatarButton(
                    avatar: avatar,
                    isSelected: selectedAvatar == avatar,
                    size: avatarSize,
                    showCheckmark: showCheckmark
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedAvatar = avatar
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onSelectionChanged?(avatar)
                }
            }
        }
    }
}

// MARK: - Avatar Button

/// Individual avatar button with selection state
private struct AvatarButton: View {
    let avatar: AvatarOption
    let isSelected: Bool
    let size: CGFloat
    let showCheckmark: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle with avatar color
                Circle()
                    .fill(avatar.backgroundColor.opacity(0.2))
                    .frame(width: size, height: size)
                
                // Avatar emoji
                Text(avatar.emoji)
                    .font(.system(size: size * 0.53)) // Scale emoji to fit
                
                // Selection indicator
                if isSelected {
                    // Border ring
                    Circle()
                        .stroke(Color.brandPrimary, lineWidth: 3)
                        .frame(width: size, height: size)
                    
                    // Checkmark badge
                    if showCheckmark {
                        Circle()
                            .fill(Color.brandPrimary)
                            .frame(width: 24, height: 24)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: size * 0.35, y: -size * 0.35)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(avatar.accessibilityLabel) avatar")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
    }
}

// MARK: - Large Avatar Selector (for prominent displays)

/// A variant of AvatarSelector with larger avatars for prominent displays
struct LargeAvatarSelector: View {
    @Binding var selectedAvatar: AvatarOption
    var title: String? = "Choose an Avatar"
    var onSelectionChanged: ((AvatarOption) -> Void)?
    
    var body: some View {
        AvatarSelector(
            selectedAvatar: $selectedAvatar,
            title: title,
            columns: 3,
            avatarSize: 90,
            showCheckmark: true,
            onSelectionChanged: onSelectionChanged
        )
    }
}

// MARK: - Compact Avatar Selector (for limited space)

/// A compact variant of AvatarSelector for limited space scenarios
struct CompactAvatarSelector: View {
    @Binding var selectedAvatar: AvatarOption
    var title: String? = nil
    var onSelectionChanged: ((AvatarOption) -> Void)?
    
    var body: some View {
        AvatarSelector(
            selectedAvatar: $selectedAvatar,
            title: title,
            columns: 6,
            avatarSize: 60,
            showCheckmark: false,
            onSelectionChanged: onSelectionChanged
        )
    }
}

// MARK: - Avatar Preview

/// A preview component showing the selected avatar prominently
struct AvatarPreview: View {
    let avatar: AvatarOption
    var size: CGFloat = 100
    
    var body: some View {
        ZStack {
            Circle()
                .fill(avatar.backgroundColor.opacity(0.2))
                .frame(width: size, height: size)
            
            Text(avatar.emoji)
                .font(.system(size: size * 0.6))
        }
        .accessibilityLabel("\(avatar.accessibilityLabel) avatar selected")
    }
}

// MARK: - Preview

#Preview("Avatar Selector") {
    struct PreviewWrapper: View {
        @State private var selectedAvatar: AvatarOption = .cat
        
        var body: some View {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Preview header
                    AvatarPreview(avatar: selectedAvatar)
                    
                    Text("Selected: \(selectedAvatar.accessibilityLabel)")
                        .font(.title3)
                    
                    // Default selector
                    GroupBox("Default (4 columns, 75pt)") {
                        AvatarSelector(
                            selectedAvatar: $selectedAvatar,
                            title: "Choose an Avatar"
                        )
                    }
                    
                    // Large selector
                    GroupBox("Large (3 columns, 90pt)") {
                        LargeAvatarSelector(
                            selectedAvatar: $selectedAvatar,
                            title: "Pick Your Buddy"
                        )
                    }
                    
                    // Compact selector
                    GroupBox("Compact (6 columns, 60pt)") {
                        CompactAvatarSelector(
                            selectedAvatar: $selectedAvatar
                        )
                    }
                }
                .padding()
            }
        }
    }
    
    return PreviewWrapper()
}
