//
//  SoundEffectsService.swift
//  Sidrat
//
//  Lightweight service for playing UI sound effects
//  Quiz correct/incorrect, completion celebrations, etc.
//

import Foundation
import AVFoundation
import UIKit
import SwiftUI

// MARK: - Sound Effects Service

/// Service for playing short UI sound effects
/// Optimized for low-latency playback of bundled sounds
@Observable
final class SoundEffectsService {
    
    // MARK: - Sound Types
    
    enum SoundEffect: String, CaseIterable {
        // Quiz sounds
        case correct = "quiz_correct"
        case incorrect = "quiz_incorrect"
        case tryAgain = "quiz_try_again"
        
        // Progress sounds
        case lessonComplete = "lesson_complete"
        case achievementUnlocked = "achievement_unlocked"
        case starEarned = "star_earned"
        case xpGained = "xp_gained"
        
        // UI sounds
        case buttonTap = "button_tap"
        case swipe = "swipe"
        case success = "success"
        case notification = "notification"
        
        // Phase transition sounds
        case phaseComplete = "phase_complete"
        case hookStart = "hook_start"
        case practiceStart = "practice_start"
        case rewardStart = "reward_start"
        
        var fileName: String { rawValue }
        
        /// Fallback system sound if custom sound not found
        var systemSoundFallback: SystemSoundID {
            switch self {
            case .correct, .success, .lessonComplete, .achievementUnlocked:
                return 1025 // Success sound
            case .incorrect, .tryAgain:
                return 1053 // Error sound
            case .starEarned, .xpGained:
                return 1057 // Positive sound
            case .buttonTap:
                return 1104 // Tap sound
            case .swipe:
                return 1105 // Swipe sound
            case .notification:
                return 1007 // Notification
            case .phaseComplete, .hookStart, .practiceStart, .rewardStart:
                return 1054 // Transition sound
            }
        }
    }
    
    // MARK: - Properties
    
    /// Whether sound effects are enabled (respects user preference)
    var isEnabled: Bool = true
    
    /// Volume level for sound effects (0.0 - 1.0)
    var volume: Float = 1.0
    
    /// Preloaded audio players for low-latency playback
    private var preloadedPlayers: [SoundEffect: AVAudioPlayer] = [:]
    
    /// Audio session reference
    private let audioSession = AVAudioSession.sharedInstance()
    
    // MARK: - Singleton
    
    static let shared = SoundEffectsService()
    
    // MARK: - Initialization
    
    init() {
        preloadCommonSounds()
    }
    
    // MARK: - Preloading
    
    /// Preload commonly used sounds for instant playback
    private func preloadCommonSounds() {
        let commonSounds: [SoundEffect] = [
            .correct, .incorrect, .buttonTap, .success, .starEarned
        ]
        
        for sound in commonSounds {
            preloadSound(sound)
        }
    }
    
    /// Preload a specific sound effect
    private func preloadSound(_ sound: SoundEffect) {
        guard let url = soundURL(for: sound) else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = volume
            preloadedPlayers[sound] = player
        } catch {
            print("SoundEffectsService: Failed to preload \(sound.rawValue): \(error)")
        }
    }
    
    // MARK: - Playback
    
    /// Play a sound effect
    /// - Parameters:
    ///   - sound: The sound effect to play
    ///   - haptic: Optional haptic feedback to accompany the sound
    func play(_ sound: SoundEffect, haptic: UIImpactFeedbackGenerator.FeedbackStyle? = nil) {
        guard isEnabled else { return }
        
        // Trigger haptic feedback if requested
        if let hapticStyle = haptic {
            let generator = UIImpactFeedbackGenerator(style: hapticStyle)
            generator.impactOccurred()
        }
        
        // Try preloaded player first
        if let player = preloadedPlayers[sound] {
            player.currentTime = 0
            player.volume = volume
            player.play()
            return
        }
        
        // Try loading from bundle
        if let url = soundURL(for: sound) {
            playSound(at: url)
            return
        }
        
        // Fall back to system sound
        AudioServicesPlaySystemSound(sound.systemSoundFallback)
    }
    
    /// Play correct answer sound with success haptic
    func playCorrect() {
        play(.correct, haptic: .medium)
    }
    
    /// Play incorrect answer sound with error haptic
    func playIncorrect() {
        play(.incorrect, haptic: .heavy)
    }
    
    /// Play lesson completion celebration
    func playLessonComplete() {
        play(.lessonComplete, haptic: .heavy)
    }
    
    /// Play star earned sound
    func playStarEarned() {
        play(.starEarned, haptic: .light)
    }
    
    /// Play XP gained sound
    func playXPGained() {
        play(.xpGained, haptic: .light)
    }
    
    /// Play achievement unlocked sound
    func playAchievementUnlocked() {
        play(.achievementUnlocked, haptic: .heavy)
    }
    
    /// Play button tap feedback
    func playButtonTap() {
        play(.buttonTap, haptic: .light)
    }
    
    // MARK: - Sequence Playback
    
    /// Play a sequence of sounds with delays
    /// - Parameters:
    ///   - sounds: Array of (sound, delay) tuples
    func playSequence(_ sounds: [(sound: SoundEffect, delay: TimeInterval)]) {
        guard isEnabled else { return }
        
        var cumulativeDelay: TimeInterval = 0
        
        for (sound, delay) in sounds {
            cumulativeDelay += delay
            
            DispatchQueue.main.asyncAfter(deadline: .now() + cumulativeDelay) { [weak self] in
                self?.play(sound)
            }
        }
    }
    
    /// Play celebration sequence (for lesson completion)
    func playCelebrationSequence() {
        playSequence([
            (.success, 0),
            (.starEarned, 0.3),
            (.starEarned, 0.5),
            (.starEarned, 0.7),
            (.lessonComplete, 1.0)
        ])
    }
    
    // MARK: - Helper Methods
    
    private func soundURL(for sound: SoundEffect) -> URL? {
        // Try common audio extensions
        for ext in ["mp3", "m4a", "wav", "aac", "caf"] {
            if let url = Bundle.main.url(forResource: sound.fileName, withExtension: ext) {
                return url
            }
            
            // Try in Audio subdirectory
            if let url = Bundle.main.url(forResource: sound.fileName, withExtension: ext, subdirectory: "Audio") {
                return url
            }
        }
        return nil
    }
    
    private func playSound(at url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.play()
        } catch {
            print("SoundEffectsService: Failed to play sound: \(error)")
        }
    }
    
    // MARK: - Volume Control
    
    /// Update volume for all preloaded players
    func updateVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        for player in preloadedPlayers.values {
            player.volume = volume
        }
    }
}

// MARK: - SwiftUI Environment

private struct SoundEffectsServiceKey: EnvironmentKey {
    static let defaultValue = SoundEffectsService.shared
}

extension EnvironmentValues {
    var soundEffects: SoundEffectsService {
        get { self[SoundEffectsServiceKey.self] }
        set { self[SoundEffectsServiceKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Play a sound effect when a value changes
    func playSound(_ sound: SoundEffectsService.SoundEffect, when condition: Bool) -> some View {
        onChange(of: condition) { _, newValue in
            if newValue {
                SoundEffectsService.shared.play(sound)
            }
        }
    }
}
