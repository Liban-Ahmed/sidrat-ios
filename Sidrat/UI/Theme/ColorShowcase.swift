//
//  ColorShowcase.swift
//  Sidrat
//
//  Debug view to showcase all theme colors in light and dark modes
//

import SwiftUI

#if DEBUG

struct ColorShowcase: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var previewMode: ColorScheme? = nil
    
    private var effectiveColorScheme: ColorScheme {
        previewMode ?? colorScheme
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Mode Picker
                    modePicker
                    
                    // Current Mode Indicator
                    modeIndicator
                    
                    // Brand Colors
                    colorSection(title: "Brand Colors") {
                        ColorSwatch(name: "Primary", color: .brandPrimary)
                        ColorSwatch(name: "Primary Light", color: .brandPrimaryLight)
                        ColorSwatch(name: "Primary Dark", color: .brandPrimaryDark)
                        ColorSwatch(name: "Secondary", color: .brandSecondary)
                        ColorSwatch(name: "Secondary Light", color: .brandSecondaryLight)
                        ColorSwatch(name: "Secondary Dark", color: .brandSecondaryDark)
                        ColorSwatch(name: "Accent", color: .brandAccent)
                        ColorSwatch(name: "Accent Light", color: .brandAccentLight)
                        ColorSwatch(name: "Accent Dark", color: .brandAccentDark)
                    }
                    
                    // Backgrounds (Adaptive)
                    colorSection(title: "Backgrounds (Adaptive)") {
                        ColorSwatch(name: "Primary", color: .backgroundPrimary, outlined: true)
                        ColorSwatch(name: "Secondary", color: .backgroundSecondary, outlined: true)
                        ColorSwatch(name: "Tertiary", color: .backgroundTertiary, outlined: true)
                    }
                    
                    // Surfaces (Adaptive)
                    colorSection(title: "Surfaces (Adaptive)") {
                        ColorSwatch(name: "Primary", color: .surfacePrimary, outlined: true)
                        ColorSwatch(name: "Secondary", color: .surfaceSecondary, outlined: true)
                        ColorSwatch(name: "Tertiary", color: .surfaceTertiary, outlined: true)
                        ColorSwatch(name: "Elevated", color: .surfaceElevated, outlined: true)
                    }
                    
                    // Text Colors (Adaptive)
                    colorSection(title: "Text Colors (Adaptive)") {
                        TextColorSwatch(name: "Primary", color: .textPrimary)
                        TextColorSwatch(name: "Secondary", color: .textSecondary)
                        TextColorSwatch(name: "Tertiary", color: .textTertiary)
                    }
                    
                    // Semantic Colors
                    colorSection(title: "Semantic Colors") {
                        ColorSwatch(name: "Success", color: .success)
                        ColorSwatch(name: "Warning", color: .warning)
                        ColorSwatch(name: "Error", color: .error)
                    }
                    
                    // Separator
                    colorSection(title: "Separator") {
                        ColorSwatch(name: "Separator", color: .separator, outlined: true)
                    }
                    
                    // Sample Cards
                    sampleCards
                    
                    // Sample Buttons
                    sampleButtons
                }
                .padding()
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Color Showcase")
            .preferredColorScheme(previewMode)
        }
    }
    
    // MARK: - Mode Picker
    
    private var modePicker: some View {
        Picker("Mode", selection: $previewMode) {
            Text("System").tag(nil as ColorScheme?)
            Text("Light").tag(ColorScheme.light as ColorScheme?)
            Text("Dark").tag(ColorScheme.dark as ColorScheme?)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    // MARK: - Mode Indicator
    
    private var modeIndicator: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: effectiveColorScheme == .dark ? "moon.fill" : "sun.max.fill")
                .font(.title2)
                .foregroundStyle(effectiveColorScheme == .dark ? .brandPrimary : .brandAccent)
            
            Text(effectiveColorScheme == .dark ? "Dark Mode" : "Light Mode")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    // MARK: - Color Section
    
    private func colorSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.textPrimary)
            
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 100), spacing: Spacing.md)
                ],
                spacing: Spacing.md
            ) {
                content()
            }
        }
    }
    
    // MARK: - Sample Cards
    
    private var sampleCards: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Sample Cards")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.textPrimary)
            
            VStack(spacing: Spacing.md) {
                // Primary card
                sampleCard(
                    title: "Primary Card",
                    subtitle: "With card shadow",
                    color: .brandPrimary
                )
                .cardShadow()
                
                // Secondary card
                sampleCard(
                    title: "Secondary Card",
                    subtitle: "With subtle shadow",
                    color: .brandSecondary
                )
                .subtleShadow()
                
                // Elevated card
                sampleCard(
                    title: "Elevated Card",
                    subtitle: "With elevated shadow",
                    color: .brandAccent
                )
                .elevatedShadow()
            }
        }
    }
    
    private func sampleCard(title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.labelLarge)
                    .foregroundStyle(.textPrimary)
                
                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundStyle(.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    // MARK: - Sample Buttons
    
    private var sampleButtons: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Sample Buttons")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.textPrimary)
            
            VStack(spacing: Spacing.md) {
                Button("Primary Button") {}
                    .buttonStyle(.primary)
                
                Button("Secondary Button") {}
                    .buttonStyle(.secondary)
                
                Button("Accent Button") {}
                    .buttonStyle(.accent)
            }
        }
    }
}

// MARK: - Color Swatch

private struct ColorSwatch: View {
    let name: String
    let color: Color
    var outlined: Bool = false
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(color)
                .frame(height: 60)
                .overlay {
                    if outlined {
                        RoundedRectangle(cornerRadius: CornerRadius.small)
                            .strokeBorder(Color.separator, lineWidth: 1)
                    }
                }
            
            Text(name)
                .font(.caption)
                .foregroundStyle(.textSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Text Color Swatch

private struct TextColorSwatch: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(Color.backgroundSecondary)
                .frame(height: 60)
                .overlay {
                    Text("Aa")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                }
            
            Text(name)
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    ColorShowcase()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ColorShowcase()
        .preferredColorScheme(.dark)
}

#endif
