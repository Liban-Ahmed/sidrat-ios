//
//  AudioComponentsShowcase.swift
//  Sidrat
//
//  Showcase view demonstrating all audio playback components
//  Use this view to preview audio controls in Xcode Canvas
//

import SwiftUI

// MARK: - Audio Components Showcase

/// Preview showcase for all audio components
struct AudioComponentsShowcase: View {
    @State private var audioPlayer = AudioPlayerService()
    @State private var selectedCategory: LessonCategory = .salah
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    playingIndicatorsSection
                    audioControlsSection
                    floatingControlsSection
                    categoryPickerSection
                    serviceFeaturesSection
                    
                    Spacer(minLength: Spacing.xxl)
                }
                .padding(.vertical, Spacing.lg)
            }
            .background(Color.surfacePrimary)
            .navigationTitle("Audio Components")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Section Views
    
    private var playingIndicatorsSection: some View {
        Group {
            sectionHeader("Playing Indicators")
            
            VStack(spacing: Spacing.lg) {
                // Standard indicator
                showcaseCard(title: "AudioPlayingIndicator", subtitle: "3-bar equalizer") {
                    AudioPlayingIndicator(
                        color: selectedCategory.color,
                        barWidth: 4,
                        barHeight: 20,
                        minBarHeight: 10
                    )
                }
                
                // Large indicator
                showcaseCard(title: "LargeAudioPlayingIndicator", subtitle: "5-bar for full screen") {
                    LargeAudioPlayingIndicator(color: selectedCategory.color)
                }
                
                // Circular indicator
                showcaseCard(title: "CircularAudioIndicator", subtitle: "Pulsing ring") {
                    HStack(spacing: Spacing.lg) {
                        CircularAudioIndicator(color: selectedCategory.color, size: 24)
                        CircularAudioIndicator(color: selectedCategory.color, size: 32)
                        CircularAudioIndicator(color: selectedCategory.color, size: 44)
                    }
                }
                
                // Waveform indicator
                showcaseCard(title: "WaveformIndicator", subtitle: "7-bar wave animation") {
                    WaveformIndicator(
                        color: selectedCategory.color,
                        barCount: 7,
                        barWidth: 3,
                        maxBarHeight: 28
                    )
                }
            }
        }
    }
    
    private var audioControlsSection: some View {
        Group {
            sectionHeader("Audio Controls")
            
            VStack(spacing: Spacing.lg) {
                // Full controls
                showcaseCard(title: "AudioControlsView", subtitle: "Play/Pause (60pt), Replay (44pt), Progress bar") {
                    AudioControlsView(
                        audioPlayer: audioPlayer,
                        category: selectedCategory,
                        showProgressBar: true
                    )
                }
                
                // Compact controls
                showcaseCard(title: "AudioControlsView (Compact)", subtitle: "Smaller buttons for tight spaces") {
                    AudioControlsView(
                        audioPlayer: audioPlayer,
                        category: selectedCategory,
                        isCompact: true
                    )
                }
                
                // Inline controls
                showcaseCard(title: "InlineAudioControls", subtitle: "Embedded in content") {
                    InlineAudioControls(
                        audioPlayer: audioPlayer,
                        accentColor: selectedCategory.color
                    )
                }
            }
        }
    }
    
    private var floatingControlsSection: some View {
        Group {
            sectionHeader("Floating Controls")
            
            showcaseCard(title: "FloatingAudioControls", subtitle: "Expandable overlay (try tapping!)") {
                FloatingAudioControls(
                    audioPlayer: audioPlayer,
                    category: selectedCategory
                )
            }
        }
    }
    
    private var categoryPickerSection: some View {
        Group {
            sectionHeader("Theme by Category")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(LessonCategory.allCases, id: \.self) { category in
                        categoryButton(for: category)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
    }
    
    private var serviceFeaturesSection: some View {
        Group {
            sectionHeader("AudioPlayerService Features")
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                featureRow("PlaybackState", "idle, loading, playing, paused, finished, error")
                featureRow("Background Audio", "Up to 30 seconds when app backgrounded")
                featureRow("Interruptions", "Pauses on calls, resumes after")
                featureRow("Route Changes", "Pauses when headphones unplugged")
                featureRow("Progress Timer", "0.1s updates for smooth UI")
                featureRow("Seek Support", "Drag progress bar to seek")
                featureRow("Skip ±10s", "Skip forward/backward buttons")
                featureRow("Playback Speed", "0.75x, 1x, 1.25x, 1.5x, 2x")
                featureRow("Progress Persistence", "Resume where you left off")
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(Color.surfaceSecondary)
            )
            .padding(.horizontal, Spacing.lg)
            
            sectionHeader("SoundEffectsService")
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                featureRow("Quiz Sounds", "correct, incorrect, tryAgain")
                featureRow("Progress Sounds", "lessonComplete, starEarned, xpGained")
                featureRow("UI Sounds", "buttonTap, swipe, notification")
                featureRow("Haptic Feedback", "Paired with sounds")
                featureRow("Preloading", "Common sounds preloaded for instant playback")
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(Color.surfaceSecondary)
            )
            .padding(.horizontal, Spacing.lg)
            
            // Sound effects test buttons
            sectionHeader("Test Sound Effects")
            
            HStack(spacing: Spacing.md) {
                soundTestButton("Correct", .correct, .green)
                soundTestButton("Incorrect", .incorrect, .red)
                soundTestButton("Star", .starEarned, .yellow)
                soundTestButton("Complete", .lessonComplete, .blue)
            }
            .padding(.horizontal, Spacing.lg)
            
            sectionHeader("AudioQueueService")
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                featureRow("Queue Management", "Load, enqueue, dequeue segments")
                featureRow("Auto-Advance", "Automatically play next segment")
                featureRow("Navigation", "Next, previous, jump to segment")
                featureRow("Callbacks", "onQueueComplete, onSegmentChange")
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(Color.surfaceSecondary)
            )
            .padding(.horizontal, Spacing.lg)
        }
    }
    
    private func soundTestButton(_ title: String, _ sound: SoundEffectsService.SoundEffect, _ color: Color) -> some View {
        Button {
            SoundEffectsService.shared.play(sound, haptic: .medium)
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule()
                        .fill(color)
                )
        }
        .buttonStyle(.plain)
    }
    
    private func categoryButton(for category: LessonCategory) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedCategory = category
            }
        } label: {
            VStack(spacing: Spacing.xs) {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundStyle(category.color)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(category.color.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .stroke(selectedCategory == category ? category.color : .clear, lineWidth: 2)
                    )
                
                Text(category.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title2.weight(.bold))
            .foregroundStyle(.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
    }
    
    private func showcaseCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
            
            content()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color.surfaceSecondary)
        )
        .padding(.horizontal, Spacing.lg)
    }
    
    private func featureRow(_ feature: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.brandPrimary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
        }
    }
}

// MARK: - Preview

#Preview("Audio Components Showcase") {
    AudioComponentsShowcase()
}

#Preview("Dark Mode") {
    AudioComponentsShowcase()
        .preferredColorScheme(.dark)
}
