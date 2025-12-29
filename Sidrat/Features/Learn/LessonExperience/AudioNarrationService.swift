//
//  AudioNarrationService.swift
//  Sidrat
//
//  Handles audio narration playback for lesson content
//  Primary: ElevenLabs TTS API (Sana voice - calm, soft, honest)
//  Fallback: Apple AVSpeechSynthesizer for offline/error scenarios
//
//  Supports pause, resume, replay, and progress tracking
//

import Foundation
import AVFoundation
import SwiftUI

// MARK: - Audio Narration Service

/// Service for managing audio narration during lessons
/// Uses ElevenLabs API with automatic fallback to system TTS
@Observable
final class AudioNarrationService: NSObject {
    
    // MARK: - Properties
    
    /// Current playback state
    private(set) var playbackState: PlaybackState = .idle
    
    /// Progress through current audio (0.0 - 1.0)
    private(set) var progress: Double = 0
    
    /// Current playback time in seconds
    private(set) var currentTime: TimeInterval = 0
    
    /// Total duration of current audio in seconds
    private(set) var duration: TimeInterval = 0
    
    /// Whether audio is enabled
    var isAudioEnabled: Bool = true
    
    /// Whether currently using ElevenLabs (true) or fallback TTS (false)
    private(set) var isUsingElevenLabs: Bool = false
    
    /// Feature flag to enable/disable ElevenLabs (cost control)
    private let enableElevenLabs = false
    
    /// Current text being spoken (for replay)
    private var currentText: String?
    
    /// Completion handler for current narration
    private var completionHandler: (() -> Void)?
    
    // MARK: - Audio Players
    
    /// AVAudioPlayer for ElevenLabs audio
    private var audioPlayer: AVAudioPlayer?
    
    /// Speech synthesizer for fallback TTS
    private var speechSynthesizer: AVSpeechSynthesizer?
    
    /// Current utterance for fallback TTS
    private var currentUtterance: AVSpeechUtterance?
    
    // MARK: - Timers
    
    /// Timer for progress updates
    private var progressTimer: Timer?
    
    /// Start time of current playback
    private var playbackStartTime: Date?
    
    /// Estimated duration for fallback TTS
    private var estimatedDuration: TimeInterval = 0
    
    // MARK: - Audio Session
    
    /// Audio session configuration
    private let audioSession = AVAudioSession.sharedInstance()
    
    // MARK: - Task Management
    
    /// Current synthesis task
    private var currentTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupAudioSession()
        setupFallbackSynthesizer()
    }
    
    deinit {
        stop()
        progressTimer?.invalidate()
        currentTask?.cancel()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("AudioNarrationService: Failed to setup audio session: \(error)")
        }
    }
    
    private func setupFallbackSynthesizer() {
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer?.delegate = self
    }
    
    // MARK: - Playback Controls
    
    /// Speak the given text with optional completion handler
    /// - Parameters:
    ///   - text: The text to speak
    ///   - rate: Speech rate (0.0 - 1.0), used for fallback TTS only
    ///   - completion: Called when speech completes
    func speak(
        _ text: String,
        rate: Float = 0.45,
        completion: (() -> Void)? = nil
    ) {
        guard isAudioEnabled else {
            // Skip audio but still call completion after estimated time
            let wordCount = text.split(separator: " ").count
            let estimatedTime = Double(wordCount) / 2.5
            
            DispatchQueue.main.asyncAfter(deadline: .now() + estimatedTime) {
                completion?()
            }
            return
        }
        
        // Stop any current playback
        stop()
        
        // Store current text for replay
        currentText = text
        completionHandler = completion
        
        // Set initial state
        playbackState = .loading
        
        // Cancel any existing task
        currentTask?.cancel()
        
        // Try ElevenLabs first, fallback to system TTS
        currentTask = Task { @MainActor in
            do {
                // Check if ElevenLabs is enabled and configured
                guard enableElevenLabs, ElevenLabsService.shared.isConfigured else {
                    throw ElevenLabsError.missingAPIKey
                }
                
                // Synthesize with ElevenLabs
                let audioData = try await ElevenLabsService.shared.synthesize(text: text)
                
                // Check if task was cancelled
                if Task.isCancelled { return }
                
                // Play the audio
                try playElevenLabsAudio(audioData)
                isUsingElevenLabs = true
                
            } catch {
                // Check if task was cancelled
                if Task.isCancelled { return }
                
                print("AudioNarrationService: ElevenLabs failed, using fallback: \(error)")
                
                // Fallback to system TTS
                await MainActor.run {
                    speakWithFallback(text, rate: rate)
                    isUsingElevenLabs = false
                }
            }
        }
    }
    
    /// Play ElevenLabs audio data
    private func playElevenLabsAudio(_ data: Data) throws {
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        
        duration = audioPlayer?.duration ?? 0
        playbackStartTime = Date()
        
        if audioPlayer?.play() == true {
            playbackState = .playing
            startProgressTimer()
        } else {
            throw ElevenLabsError.audioPlaybackFailed
        }
    }
    
    /// Fallback to system TTS
    private func speakWithFallback(_ text: String, rate: Float) {
        // Calculate estimated duration
        let wordCount = text.split(separator: " ").count
        estimatedDuration = Double(wordCount) / 2.0
        duration = estimatedDuration
        
        // Create and configure utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.voice = getFallbackVoice()
        utterance.pitchMultiplier = 1.1
        utterance.volume = 1.0
        
        currentUtterance = utterance
        
        // Start speaking
        playbackState = .playing
        playbackStartTime = Date()
        speechSynthesizer?.speak(utterance)
        
        startProgressTimer()
    }
    
    /// Pause current playback
    func pause() {
        guard playbackState == .playing else { return }
        
        if isUsingElevenLabs {
            audioPlayer?.pause()
        } else {
            speechSynthesizer?.pauseSpeaking(at: .word)
        }
        
        playbackState = .paused
        progressTimer?.invalidate()
    }
    
    /// Resume paused playback
    func resume() {
        guard playbackState == .paused else { return }
        
        if isUsingElevenLabs {
            audioPlayer?.play()
        } else {
            speechSynthesizer?.continueSpeaking()
        }
        
        playbackState = .playing
        startProgressTimer()
    }
    
    /// Toggle play/pause
    func togglePlayPause() {
        switch playbackState {
        case .playing:
            pause()
        case .paused:
            resume()
        case .idle, .finished, .loading:
            break
        }
    }
    
    /// Stop current playback
    func stop() {
        currentTask?.cancel()
        currentTask = nil
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        speechSynthesizer?.stopSpeaking(at: .immediate)
        
        playbackState = .idle
        progressTimer?.invalidate()
        currentUtterance = nil
        progress = 0
        currentTime = 0
    }
    
    /// Replay current text from the beginning
    func replay() {
        guard let text = currentText else { return }
        let completion = completionHandler
        speak(text, completion: completion)
    }
    
    // MARK: - Private Methods
    
    private func getFallbackVoice() -> AVSpeechSynthesisVoice? {
        // Try to get a high-quality English voice
        let preferredVoices = [
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.voice.enhanced.en-GB.Daniel",
            "com.apple.ttsbundle.Samantha-premium",
            "com.apple.ttsbundle.siri_female_en-US_compact"
        ]
        
        for identifier in preferredVoices {
            if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                return voice
            }
        }
        
        return AVSpeechSynthesisVoice(language: "en-US")
    }
    
    private func startProgressTimer() {
        progressTimer?.invalidate()
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func updateProgress() {
        if isUsingElevenLabs, let player = audioPlayer {
            currentTime = player.currentTime
            progress = duration > 0 ? currentTime / duration : 0
        } else if let startTime = playbackStartTime, estimatedDuration > 0 {
            let elapsed = Date().timeIntervalSince(startTime)
            currentTime = min(elapsed, estimatedDuration)
            progress = min(elapsed / estimatedDuration, 1.0)
        }
    }
    
    private func handlePlaybackComplete() {
        progressTimer?.invalidate()
        playbackState = .finished
        progress = 1.0
        currentTime = duration
        completionHandler?()
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioNarrationService: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.handlePlaybackComplete()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        DispatchQueue.main.async { [weak self] in
            print("AudioNarrationService: Decode error: \(error?.localizedDescription ?? "unknown")")
            self?.playbackState = .idle
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension AudioNarrationService: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = .playing
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = .paused
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = .playing
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.handlePlaybackComplete()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.progressTimer?.invalidate()
            self?.playbackState = .idle
        }
    }
}

// MARK: - Playback State

extension AudioNarrationService {
    enum PlaybackState: Equatable {
        case idle
        case loading
        case playing
        case paused
        case finished
        
        var icon: String {
            switch self {
            case .idle, .paused:
                return "play.fill"
            case .loading:
                return "ellipsis"
            case .playing:
                return "pause.fill"
            case .finished:
                return "arrow.counterclockwise"
            }
        }
        
        var accessibilityLabel: String {
            switch self {
            case .idle:
                return "Play"
            case .loading:
                return "Loading"
            case .playing:
                return "Pause"
            case .paused:
                return "Resume"
            case .finished:
                return "Replay"
            }
        }
    }
}

// MARK: - Audio Control Button

/// Reusable audio control button component
struct AudioControlButton: View {
    let playbackState: AudioNarrationService.PlaybackState
    let action: () -> Void
    let replayAction: () -> Void
    
    @Environment(\.isReduceMotionEnabled) private var reduceMotion
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Play/Pause button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if playbackState == .finished {
                        replayAction()
                    } else {
                        action()
                    }
                }
            }) {
                Group {
                    if playbackState == .loading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: playbackState.icon)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.brandPrimary)
                        .shadow(color: .brandPrimary.opacity(0.3), radius: 8, y: 4)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            .buttonStyle(.plain)
            .disabled(playbackState == .loading)
            .accessibilityLabel(playbackState.accessibilityLabel)
            .accessibilityHint("Double tap to \(playbackState.accessibilityLabel.lowercased()) narration")
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !reduceMotion {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isPressed = true
                            }
                        }
                    }
                    .onEnded { _ in
                        if !reduceMotion {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isPressed = false
                            }
                        }
                    }
            )
            
            // Replay button (only show when playing or paused)
            if playbackState == .playing || playbackState == .paused {
                Button(action: replayAction) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.brandPrimary.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Replay from beginning")
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Environment Key for Reduce Motion

private struct ReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isReduceMotionEnabled: Bool {
        get { self[ReduceMotionKey.self] }
        set { self[ReduceMotionKey.self] = newValue }
    }
}
