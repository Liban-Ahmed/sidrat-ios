//
//  Theme.swift
//  Sidrat
//
//  Design system matching the landing page
//

import SwiftUI

// MARK: - Colors (Matching Landing Page)

extension Color {
    // Primary - Teal (#0C7489)
    static let brandPrimary = Color(hex: "0C7489")
    static let brandPrimaryLight = Color(hex: "0E8FA6")
    static let brandPrimaryDark = Color(hex: "095A6B")
    
    // Secondary - Green (#488B49)
    static let brandSecondary = Color(hex: "488B49")
    static let brandSecondaryLight = Color(hex: "5AA85B")
    static let brandSecondaryDark = Color(hex: "3A7A3B")
    
    // Accent - Gold (#DAA520)
    static let brandAccent = Color(hex: "DAA520")
    static let brandAccentLight = Color(hex: "E8B84A")
    static let brandAccentDark = Color(hex: "C49318")
    
    // Legacy aliases (for existing code)
    static let primaryGreen = brandPrimary
    static let primaryGreenLight = brandPrimaryLight
    static let primaryGreenDark = brandPrimaryDark
    static let secondaryGold = brandAccent
    static let secondaryGoldLight = brandAccentLight
    static let accentBlue = brandPrimary
    static let accentBlueDark = brandPrimaryDark
    
    // Backgrounds
    static let backgroundPrimary = Color(hex: "FFFFFF")
    static let backgroundSecondary = Color(hex: "F5F5F5")
    static let backgroundTertiary = Color(hex: "EDEDED")
    
    // Surface colors (aliases for backgrounds - used in lesson experience)
    static let surfacePrimary = backgroundPrimary
    static let surfaceSecondary = backgroundSecondary
    static let surfaceTertiary = backgroundTertiary
    
    // Text colors
    static let textPrimary = Color(hex: "2C3E3F")
    static let textSecondary = Color(hex: "6B7280")
    static let textTertiary = Color(hex: "9CA3AF")
    
    // Semantic colors
    static let success = Color(hex: "488B49")
    static let warning = Color(hex: "DAA520")
    static let error = Color(hex: "DC2626")
    
    // Gradient colors
    static let gradientStart = brandPrimary
    static let gradientMid = brandSecondary
    static let gradientEnd = brandAccent
}

// MARK: - ShapeStyle Extensions (for foregroundStyle)

extension ShapeStyle where Self == Color {
    static var brandPrimary: Color { Color.brandPrimary }
    static var brandPrimaryLight: Color { Color.brandPrimaryLight }
    static var brandPrimaryDark: Color { Color.brandPrimaryDark }
    static var brandSecondary: Color { Color.brandSecondary }
    static var brandSecondaryLight: Color { Color.brandSecondaryLight }
    static var brandSecondaryDark: Color { Color.brandSecondaryDark }
    static var brandAccent: Color { Color.brandAccent }
    static var brandAccentLight: Color { Color.brandAccentLight }
    static var brandAccentDark: Color { Color.brandAccentDark }
    
    // Legacy aliases
    static var primaryGreen: Color { Color.brandPrimary }
    static var primaryGreenLight: Color { Color.brandPrimaryLight }
    static var primaryGreenDark: Color { Color.brandPrimaryDark }
    static var secondaryGold: Color { Color.brandAccent }
    static var secondaryGoldLight: Color { Color.brandAccentLight }
    static var accentBlue: Color { Color.brandPrimary }
    static var accentBlueDark: Color { Color.brandPrimaryDark }
    
    static var backgroundPrimary: Color { Color.backgroundPrimary }
    static var backgroundSecondary: Color { Color.backgroundSecondary }
    static var backgroundTertiary: Color { Color.backgroundTertiary }
    static var surfacePrimary: Color { Color.surfacePrimary }
    static var surfaceSecondary: Color { Color.surfaceSecondary }
    static var surfaceTertiary: Color { Color.surfaceTertiary }
    static var textPrimary: Color { Color.textPrimary }
    static var textSecondary: Color { Color.textSecondary }
    static var textTertiary: Color { Color.textTertiary }
    static var success: Color { Color.success }
    static var warning: Color { Color.warning }
    static var error: Color { Color.error }
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients

extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [Color.brandPrimary, Color.brandPrimaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let secondaryGradient = LinearGradient(
        colors: [Color.brandSecondary, Color.brandSecondaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [Color.brandAccent, Color.brandAccentLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let heroGradient = LinearGradient(
        colors: [Color.brandPrimary, Color.brandSecondary, Color.brandAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warmGradient = LinearGradient(
        colors: [Color.brandAccent, Color.brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography

extension Font {
    // Display
    static let displayLarge = Font.system(size: 40, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 34, weight: .bold, design: .rounded)
    
    // Headings
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // Body
    static let bodyLarge = Font.system(size: 18, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)
    
    // Labels
    static let labelLarge = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let labelMedium = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let labelSmall = Font.system(size: 13, weight: .semibold, design: .rounded)
    
    // Caption
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionBold = Font.system(size: 12, weight: .semibold, design: .rounded)
}

// MARK: - Spacing

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius

enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 24
    static let xxl: CGFloat = 32
    static let full: CGFloat = 9999
}

// MARK: - Shadows

extension View {
    func subtleShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    func cardShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 8)
    }
    
    func elevatedShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
            .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 12)
    }
    
    func glowShadow(color: Color = .brandPrimary) -> some View {
        self
            .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 4)
            .shadow(color: color.opacity(0.2), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Premium Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelLarge)
            .foregroundStyle(.white)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .background(LinearGradient.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelLarge)
            .foregroundStyle(Color.brandPrimary)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .background(Color.brandPrimary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelLarge)
            .foregroundStyle(.white)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .background(LinearGradient.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == AccentButtonStyle {
    static var accent: AccentButtonStyle { AccentButtonStyle() }
}
