//
//  AvatarView.swift
//  Sidrat
//
//  Reusable avatar display component for child profiles
//  Implements US-103: Child Profile Switching
//

import SwiftUI

/// A reusable avatar display component that shows a child's avatar
/// with optional selection ring and size customization.
///
/// Usage:
/// ```swift
/// // Simple avatar display
/// AvatarView(avatar: child.avatar, size: 56)
///
/// // With selection indicator
/// AvatarView(avatar: child.avatar, size: 56, isSelected: true)
///
/// // With child model directly
/// AvatarView(child: child, size: 56, isSelected: isActive)
/// ```
struct AvatarView: View {
    // MARK: - Properties
    
    /// The avatar option to display
    let avatar: AvatarOption
    
    /// Size of the avatar (width and height)
    var size: CGFloat = 56
    
    /// Whether to show the selection ring around the avatar
    var isSelected: Bool = false
    
    /// Width of the selection ring stroke
    var selectionRingWidth: CGFloat = 3
    
    /// Color of the selection ring (defaults to brandPrimary)
    var selectionColor: Color = .brandPrimary
    
    /// Whether to show a checkmark badge when selected
    var showCheckmarkBadge: Bool = false
    
    // MARK: - Computed Properties
    
    /// Font size for the emoji, scaled to avatar size
    private var emojiSize: CGFloat {
        size * 0.6
    }
    
    /// Size of the checkmark badge
    private var badgeSize: CGFloat {
        min(24, size * 0.4)
    }
    
    // MARK: - Initialization
    
    /// Initialize with an avatar option
    init(
        avatar: AvatarOption,
        size: CGFloat = 56,
        isSelected: Bool = false,
        selectionRingWidth: CGFloat = 3,
        selectionColor: Color = .brandPrimary,
        showCheckmarkBadge: Bool = false
    ) {
        self.avatar = avatar
        self.size = size
        self.isSelected = isSelected
        self.selectionRingWidth = selectionRingWidth
        self.selectionColor = selectionColor
        self.showCheckmarkBadge = showCheckmarkBadge
    }
    
    /// Convenience initializer with a Child model
    init(
        child: Child,
        size: CGFloat = 56,
        isSelected: Bool = false,
        selectionRingWidth: CGFloat = 3,
        selectionColor: Color = .brandPrimary,
        showCheckmarkBadge: Bool = false
    ) {
        self.avatar = child.avatar
        self.size = size
        self.isSelected = isSelected
        self.selectionRingWidth = selectionRingWidth
        self.selectionColor = selectionColor
        self.showCheckmarkBadge = showCheckmarkBadge
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background circle with avatar color
            Circle()
                .fill(avatar.backgroundColor.opacity(0.2))
                .frame(width: size, height: size)
            
            // Avatar emoji
            Text(avatar.emoji)
                .font(.system(size: emojiSize))
            
            // Selection ring
            if isSelected {
                Circle()
                    .stroke(selectionColor, lineWidth: selectionRingWidth)
                    .frame(width: size + selectionRingWidth, height: size + selectionRingWidth)
                
                // Checkmark badge
                if showCheckmarkBadge {
                    checkmarkBadge
                }
            }
        }
        .accessibilityLabel("\(avatar.accessibilityLabel) avatar\(isSelected ? ", selected" : "")")
    }
    
    // MARK: - Subviews
    
    private var checkmarkBadge: some View {
        Circle()
            .fill(selectionColor)
            .frame(width: badgeSize, height: badgeSize)
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: badgeSize * 0.5, weight: .bold))
                    .foregroundStyle(.white)
            }
            .offset(x: size * 0.35, y: -size * 0.35)
            .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Size Presets

extension AvatarView {
    /// Small avatar (36pt) - for compact displays like toolbar buttons
    static func small(avatar: AvatarOption, isSelected: Bool = false) -> AvatarView {
        AvatarView(avatar: avatar, size: 36, isSelected: isSelected, selectionRingWidth: 2)
    }
    
    /// Medium avatar (56pt) - standard size for profile switcher
    static func medium(avatar: AvatarOption, isSelected: Bool = false) -> AvatarView {
        AvatarView(avatar: avatar, size: 56, isSelected: isSelected)
    }
    
    /// Large avatar (64pt) - for profile cards and detail views
    static func large(avatar: AvatarOption, isSelected: Bool = false) -> AvatarView {
        AvatarView(avatar: avatar, size: 64, isSelected: isSelected, showCheckmarkBadge: true)
    }
    
    /// Extra large avatar (100pt) - for profile creation/editing
    static func extraLarge(avatar: AvatarOption, isSelected: Bool = false) -> AvatarView {
        AvatarView(avatar: avatar, size: 100, isSelected: isSelected, selectionRingWidth: 4, showCheckmarkBadge: true)
    }
}

// MARK: - Tappable Avatar View

/// An avatar view that can be tapped to select
struct TappableAvatarView: View {
    let avatar: AvatarOption
    var size: CGFloat = 56
    var isSelected: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AvatarView(
                avatar: avatar,
                size: size,
                isSelected: isSelected,
                showCheckmarkBadge: isSelected
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityLabel("\(avatar.accessibilityLabel) avatar")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
    }
}

// MARK: - Avatar Row View

/// A horizontal row of avatars with the current avatar highlighted
struct AvatarRowView: View {
    let avatars: [AvatarOption]
    @Binding var selectedAvatar: AvatarOption
    var size: CGFloat = 56
    var spacing: CGFloat = Spacing.sm
    var onSelectionChanged: ((AvatarOption) -> Void)?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(avatars, id: \.id) { avatar in
                    TappableAvatarView(
                        avatar: avatar,
                        size: size,
                        isSelected: selectedAvatar == avatar
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedAvatar = avatar
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSelectionChanged?(avatar)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }
}

// MARK: - Placeholder Avatar View

/// A placeholder avatar view when no child is selected
struct PlaceholderAvatarView: View {
    var size: CGFloat = 56
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.brandPrimary.opacity(0.1))
                .frame(width: size, height: size)
            
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundStyle(.brandPrimary)
        }
        .accessibilityLabel("No profile selected")
    }
}

// MARK: - Previews

#Preview("Avatar View - Sizes") {
    VStack(spacing: Spacing.lg) {
        HStack(spacing: Spacing.lg) {
            VStack {
                AvatarView.small(avatar: .cat)
                Text("Small (36pt)")
                    .font(.caption)
            }
            
            VStack {
                AvatarView.medium(avatar: .dog)
                Text("Medium (56pt)")
                    .font(.caption)
            }
            
            VStack {
                AvatarView.large(avatar: .lion)
                Text("Large (64pt)")
                    .font(.caption)
            }
            
            VStack {
                AvatarView.extraLarge(avatar: .butterfly)
                Text("XL (100pt)")
                    .font(.caption)
            }
        }
        
        Divider()
        
        HStack(spacing: Spacing.lg) {
            VStack {
                AvatarView.large(avatar: .owl, isSelected: true)
                Text("Selected")
                    .font(.caption)
            }
            
            VStack {
                AvatarView.large(avatar: .rabbit, isSelected: false)
                Text("Not Selected")
                    .font(.caption)
            }
        }
        
        Divider()
        
        PlaceholderAvatarView(size: 64)
    }
    .padding()
}

#Preview("Avatar Row") {
    struct PreviewWrapper: View {
        @State private var selectedAvatar: AvatarOption = .cat
        
        var body: some View {
            VStack(spacing: Spacing.lg) {
                AvatarView.extraLarge(avatar: selectedAvatar, isSelected: true)
                
                AvatarRowView(
                    avatars: AvatarOption.allCases,
                    selectedAvatar: $selectedAvatar
                )
            }
            .padding(.vertical)
        }
    }
    
    return PreviewWrapper()
}
