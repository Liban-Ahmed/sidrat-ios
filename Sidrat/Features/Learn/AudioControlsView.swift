//
//  AudioControlsView.swift
//  Sidrat
//
//  Audio playback controls for lesson player
//  Features: Play/Pause (60pt), Replay (44pt), progress bar, visual indicator
//

import SwiftUI

// MARK: - Audio Controls View

/// Main audio playback controls for lesson content
struct AudioControlsView: View {
    @Bindable var audioPlayer: AudioPlayerService
    
    /// Category for theming (optional)
    var category: LessonCategory?
    
    /// Whether to show the progress bar
    var showProgressBar: Bool = true
    
    /// Compact mode (smaller buttons)
    var isCompact: Bool = false
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // MARK: - Design Constants
    
    private var playButtonSize: CGFloat { isCompact ? 48 : 60 }
    private var secondaryButtonSize: CGFloat { isCompact ? 36 : 44 }
    private let progressBarHeight: CGFloat = 4
    
    private var accentColor: Color {
        category?.color ?? .brandPrimary
    }
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Progress bar
            if showProgressBar {
                progressBar
            }
            
            // Control buttons
            controlButtons
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.surfaceTertiary)
                        .frame(height: progressBarHeight)
                    
                    // Progress fill
                    Capsule()
                        .fill(accentColor)
                        .frame(
                            width: geometry.size.width * audioPlayer.progress,
                            height: progressBarHeight
                        )
                        .animation(reduceMotion ? .none : .linear(duration: 0.1), value: audioPlayer.progress)
                }
            }
            .frame(height: progressBarHeight)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let progress = value.location.x / UIScreen.main.bounds.width
                        audioPlayer.seek(toProgress: max(0, min(1, progress)))
                    }
            )
            
            // Time labels
            if audioPlayer.duration > 0 {
                HStack {
                    Text(audioPlayer.formattedCurrentTime)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.textTertiary)
                    
                    Spacer()
                    
                    // Speed indicator (if not 1x)
                    if audioPlayer.playbackRate != 1.0 {
                        Text("\(speedLabel)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(accentColor)
                    }
                    
                    Spacer()
                    
                    Text(audioPlayer.formattedRemainingTime)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.textTertiary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Audio progress \(audioPlayer.formattedCurrentTime) of \(audioPlayer.formattedDuration)")
        .accessibilityValue("\(Int(audioPlayer.progress * 100))%")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                audioPlayer.skipForward()
            case .decrement:
                audioPlayer.skipBackward()
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: Spacing.md) {
            // Skip backward button
            skipBackwardButton
            
            // Replay button
            replayButton
            
            // Play/Pause button (centered, prominent)
            playPauseButton
            
            // Skip forward button
            skipForwardButton
            
            // Playing indicator or speed button
            if audioPlayer.playbackState.isPlaying {
                speedButton
            } else {
                // Invisible spacer for balance
                Color.clear
                    .frame(width: secondaryButtonSize, height: secondaryButtonSize)
            }
        }
    }
    
    // MARK: - Skip Backward Button
    
    private var skipBackwardButton: some View {
        Button {
            audioPlayer.skipBackward()
            triggerHaptic()
        } label: {
            Image(systemName: "gobackward.10")
                .font(.system(size: isCompact ? 16 : 18, weight: .semibold))
                .foregroundStyle(.textSecondary)
                .frame(width: secondaryButtonSize * 0.85, height: secondaryButtonSize * 0.85)
        }
        .buttonStyle(.plain)
        .disabled(audioPlayer.playbackState == .loading || audioPlayer.currentTime < 1)
        .opacity(audioPlayer.currentTime < 1 ? 0.3 : 1)
        .accessibilityLabel("Skip back 10 seconds")
    }
    
    // MARK: - Replay Button
    
    private var replayButton: some View {
        Button {
            audioPlayer.replay()
            triggerHaptic()
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: isCompact ? 18 : 20, weight: .semibold))
                .foregroundStyle(.textSecondary)
                .frame(width: secondaryButtonSize, height: secondaryButtonSize)
                .background(
                    Circle()
                        .fill(Color.surfaceSecondary)
                )
        }
        .buttonStyle(.plain)
        .disabled(audioPlayer.playbackState == .loading)
        .opacity(audioPlayer.playbackState == .loading ? 0.5 : 1)
        .accessibilityLabel("Replay from beginning")
        .accessibilityHint("Double tap to restart audio from the beginning")
    }
    
    // MARK: - Play/Pause Button
    
    private var playPauseButton: some View {
        Button {
            audioPlayer.togglePlayback()
            triggerHaptic()
        } label: {
            ZStack {
                // Button background
                Circle()
                    .fill(accentColor)
                    .frame(width: playButtonSize, height: playButtonSize)
                    .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
                
                // Icon
                Image(systemName: playPauseIcon)
                    .font(.system(size: playButtonSize * 0.45, weight: .semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(.plain)
        .disabled(audioPlayer.playbackState == .loading)
        .scaleEffect(audioPlayer.playbackState == .loading ? 0.95 : 1)
        .animation(reduceMotion ? .none : .spring(response: 0.3), value: audioPlayer.playbackState)
        .accessibilityLabel(playPauseAccessibilityLabel)
        .accessibilityHint("Double tap to \(audioPlayer.playbackState.isPlaying ? "pause" : "play") audio")
    }
    
    // MARK: - Skip Forward Button
    
    private var skipForwardButton: some View {
        Button {
            audioPlayer.skipForward()
            triggerHaptic()
        } label: {
            Image(systemName: "goforward.10")
                .font(.system(size: isCompact ? 16 : 18, weight: .semibold))
                .foregroundStyle(.textSecondary)
                .frame(width: secondaryButtonSize * 0.85, height: secondaryButtonSize * 0.85)
        }
        .buttonStyle(.plain)
        .disabled(audioPlayer.playbackState == .loading || audioPlayer.currentTime >= audioPlayer.duration - 1)
        .opacity(audioPlayer.currentTime >= audioPlayer.duration - 1 ? 0.3 : 1)
        .accessibilityLabel("Skip forward 10 seconds")
    }
    
    // MARK: - Speed Button
    
    private var speedButton: some View {
        Button {
            audioPlayer.cyclePlaybackSpeed()
            triggerHaptic()
        } label: {
            Text(speedLabel)
                .font(.system(size: isCompact ? 11 : 12, weight: .bold))
                .foregroundStyle(audioPlayer.playbackRate == 1.0 ? .textTertiary : accentColor)
                .frame(width: secondaryButtonSize, height: secondaryButtonSize)
                .background(
                    Circle()
                        .fill(Color.surfaceSecondary)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Playback speed \(speedLabel)")
        .accessibilityHint("Double tap to change speed")
    }
    
    private var speedLabel: String {
        if audioPlayer.playbackRate == 1.0 {
            return "1x"
        } else if audioPlayer.playbackRate == 0.75 {
            return "0.75x"
        } else if audioPlayer.playbackRate == 1.25 {
            return "1.25x"
        } else if audioPlayer.playbackRate == 1.5 {
            return "1.5x"
        } else if audioPlayer.playbackRate == 2.0 {
            return "2x"
        }
        return String(format: "%.1fx", audioPlayer.playbackRate)
    }
    
    private var playPauseIcon: String {
        switch audioPlayer.playbackState {
        case .playing:
            return "pause.fill"
        case .loading:
            return "ellipsis"
        default:
            return "play.fill"
        }
    }
    
    private var playPauseAccessibilityLabel: String {
        switch audioPlayer.playbackState {
        case .playing:
            return "Pause audio"
        case .paused:
            return "Resume audio"
        case .loading:
            return "Loading audio"
        case .finished:
            return "Replay audio"
        default:
            return "Play audio"
        }
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Inline Audio Controls

/// Compact inline audio controls for embedding in content
struct InlineAudioControls: View {
    @Bindable var audioPlayer: AudioPlayerService
    var accentColor: Color = .brandPrimary
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Play/Pause
            Button {
                audioPlayer.togglePlayback()
            } label: {
                Image(systemName: audioPlayer.playbackState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(accentColor)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            
            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.surfaceTertiary)
                        .frame(height: 3)
                    
                    Capsule()
                        .fill(accentColor)
                        .frame(width: geometry.size.width * audioPlayer.progress, height: 3)
                        .animation(reduceMotion ? .none : .linear(duration: 0.1), value: audioPlayer.progress)
                }
            }
            .frame(height: 3)
            
            // Time remaining
            Text(formatTime(audioPlayer.duration - audioPlayer.currentTime))
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .monospacedDigit()
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.surfaceSecondary)
        )
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Floating Audio Controls

/// Floating audio controls overlay
struct FloatingAudioControls: View {
    @Bindable var audioPlayer: AudioPlayerService
    var category: LessonCategory?
    var onDismiss: (() -> Void)?
    
    @State private var isExpanded = false
    
    private var accentColor: Color {
        category?.color ?? .brandPrimary
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedContent
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Main floating button
            mainButton
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
    
    private var mainButton: some View {
        Button {
            if isExpanded {
                audioPlayer.togglePlayback()
            } else {
                withAnimation {
                    isExpanded = true
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(accentColor)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                
                if audioPlayer.playbackState.isPlaying {
                    AudioPlayingIndicator(color: .white, barWidth: 3, barHeight: 12)
                } else {
                    Image(systemName: isExpanded ? "play.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var expandedContent: some View {
        VStack(spacing: Spacing.sm) {
            // Mini progress
            ProgressView(value: audioPlayer.progress)
                .accentColor(accentColor)
            
            // Controls
            HStack(spacing: Spacing.md) {
                Button {
                    audioPlayer.replay()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.textSecondary)
                }
                
                Button {
                    withAnimation {
                        isExpanded = false
                    }
                    onDismiss?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.textTertiary)
                }
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.surfacePrimary)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .padding(.bottom, Spacing.xs)
    }
}

// MARK: - Preview

#Preview("Audio Controls") {
    VStack(spacing: 40) {
        AudioControlsView(
            audioPlayer: AudioPlayerService(),
            category: .salah
        )
        .padding()
        
        AudioControlsView(
            audioPlayer: AudioPlayerService(),
            isCompact: true
        )
        .padding()
    }
}

#Preview("Inline Controls") {
    InlineAudioControls(
        audioPlayer: AudioPlayerService()
    )
    .padding()
}

#Preview("Floating Controls") {
    FloatingAudioControls(
        audioPlayer: AudioPlayerService(),
        category: .quran
    )
    .padding()
}
