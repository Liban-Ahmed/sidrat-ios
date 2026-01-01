//
//  AudioPlayingIndicator.swift
//  Sidrat
//
//  Visual 3-bar equalizer animation indicating audio playback
//  Specs: 3 bars, 4pt width, 12-20pt height range, brandPrimary color
//

import SwiftUI

// MARK: - Audio Playing Indicator

/// Animated 3-bar equalizer showing audio is playing
struct AudioPlayingIndicator: View {
    /// Bar color (defaults to brandPrimary)
    var color: Color = .brandPrimary
    
    /// Width of each bar
    var barWidth: CGFloat = 4
    
    /// Maximum bar height
    var barHeight: CGFloat = 20
    
    /// Minimum bar height
    var minBarHeight: CGFloat = 12
    
    /// Spacing between bars
    var barSpacing: CGFloat = 3
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var isAnimating = false
    @State private var barScales: [CGFloat] = [0.6, 1.0, 0.8]
    
    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<3, id: \.self) { index in
                AudioBar(
                    width: barWidth,
                    maxHeight: barHeight,
                    minHeight: minBarHeight,
                    color: color,
                    scale: barScales[index],
                    reduceMotion: reduceMotion
                )
            }
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: reduceMotion) { _, _ in
            if reduceMotion {
                stopAnimation()
            } else {
                startAnimation()
            }
        }
        .accessibilityLabel("Audio playing")
        .accessibilityAddTraits(.updatesFrequently)
    }
    
    // MARK: - Animation Control
    
    private func startAnimation() {
        guard !reduceMotion else {
            // Set static scales for reduced motion
            barScales = [0.7, 0.9, 0.8]
            return
        }
        
        isAnimating = true
        animateBar(0)
        
        // Stagger the start of each bar's animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.animateBar(1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.animateBar(2)
        }
    }
    
    private func stopAnimation() {
        isAnimating = false
    }
    
    private func animateBar(_ index: Int) {
        guard isAnimating, !reduceMotion else { return }
        
        // Random target scale between 0.5 and 1.0
        let targetScale = CGFloat.random(in: 0.5...1.0)
        let duration = Double.random(in: 0.2...0.4)
        
        withAnimation(.easeInOut(duration: duration)) {
            barScales[index] = targetScale
        }
        
        // Schedule next animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.animateBar(index)
        }
    }
}

// MARK: - Audio Bar

/// Single animated bar for the equalizer
private struct AudioBar: View {
    let width: CGFloat
    let maxHeight: CGFloat
    let minHeight: CGFloat
    let color: Color
    let scale: CGFloat
    let reduceMotion: Bool
    
    private var currentHeight: CGFloat {
        minHeight + (maxHeight - minHeight) * scale
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: width / 2)
            .fill(color)
            .frame(width: width, height: currentHeight)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.2), value: scale)
    }
}

// MARK: - Large Audio Indicator

/// Larger version of the audio indicator for full-screen displays
struct LargeAudioPlayingIndicator: View {
    var color: Color = .brandPrimary
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: 6, height: barHeight(for: index))
                    .animation(
                        reduceMotion ? .none : .easeInOut(duration: 0.5).repeatForever().delay(Double(index) * 0.1),
                        value: phase
                    )
            }
        }
        .onAppear {
            if !reduceMotion {
                phase = 1
            }
        }
        .accessibilityLabel("Audio playing")
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 16
        let maxAddition: CGFloat = 24
        let offset = sin(phase * .pi * 2 + Double(index) * 0.5) * 0.5 + 0.5
        return baseHeight + maxAddition * CGFloat(offset)
    }
}

// MARK: - Circular Audio Indicator

/// Circular pulsing indicator for audio playback
struct CircularAudioIndicator: View {
    var color: Color = .brandPrimary
    var size: CGFloat = 24
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    
    var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(color.opacity(opacity), lineWidth: 2)
                .frame(width: size * scale, height: size * scale)
            
            // Inner solid circle
            Circle()
                .fill(color)
                .frame(width: size * 0.6, height: size * 0.6)
            
            // Sound wave icon
            Image(systemName: "waveform")
                .font(.system(size: size * 0.3, weight: .semibold))
                .foregroundStyle(.white)
        }
        .onAppear {
            guard !reduceMotion else { return }
            
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scale = 1.4
                opacity = 0.2
            }
        }
        .accessibilityLabel("Audio playing")
    }
}

// MARK: - Wave Form Indicator

/// Animated waveform indicator
struct WaveformIndicator: View {
    var color: Color = .brandPrimary
    var barCount: Int = 7
    var barWidth: CGFloat = 3
    var maxBarHeight: CGFloat = 24
    var spacing: CGFloat = 2
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationPhase: Double = 0
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(color)
                    .frame(width: barWidth, height: barHeight(for: index))
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
        .accessibilityLabel("Audio waveform")
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let minHeight: CGFloat = maxBarHeight * 0.3
        let phase = animationPhase + Double(index) * 0.5
        let sineValue = sin(phase) * 0.5 + 0.5
        return minHeight + (maxBarHeight - minHeight) * CGFloat(sineValue)
    }
}

// MARK: - Preview

#Preview("Audio Playing Indicator") {
    VStack(spacing: 40) {
        // Default
        AudioPlayingIndicator()
        
        // Custom color
        AudioPlayingIndicator(color: .brandSecondary)
        
        // Larger
        AudioPlayingIndicator(
            color: .brandAccent,
            barWidth: 6,
            barHeight: 32,
            minBarHeight: 16
        )
    }
    .padding()
}

#Preview("Large Indicator") {
    LargeAudioPlayingIndicator()
        .padding()
}

#Preview("Circular Indicator") {
    HStack(spacing: 30) {
        CircularAudioIndicator()
        CircularAudioIndicator(color: .brandSecondary, size: 36)
        CircularAudioIndicator(color: .brandAccent, size: 48)
    }
    .padding()
}

#Preview("Waveform Indicator") {
    VStack(spacing: 30) {
        WaveformIndicator()
        WaveformIndicator(color: .brandSecondary, barCount: 9, maxBarHeight: 32)
    }
    .padding()
}
