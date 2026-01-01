//
//  AudioPlayerService.swift
//  Sidrat
//
//  AVFoundation-based audio playback service for lesson narration
//  Supports play/pause, replay, background playback (<30 sec),
//  and works offline with bundled audio files
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Audio Player Service

/// Service for managing audio playback during lessons
/// Uses AVAudioPlayer for bundled audio files with background support
@Observable
final class AudioPlayerService: NSObject {
    
    // MARK: - Playback State
    
    enum PlaybackState: Equatable {
        case idle
        case loading
        case playing
        case paused
        case finished
        case error(String)
        
        var isPlaying: Bool { self == .playing }
        var isPaused: Bool { self == .paused }
        var isIdle: Bool { self == .idle }
        var isFinished: Bool { self == .finished }
        
        static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.loading, .loading): return true
            case (.playing, .playing): return true
            case (.paused, .paused): return true
            case (.finished, .finished): return true
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }
    
    // MARK: - Published Properties
    
    /// Current playback state
    private(set) var playbackState: PlaybackState = .idle
    
    /// Current playback time in seconds
    private(set) var currentTime: TimeInterval = 0
    
    /// Total duration of current audio in seconds
    private(set) var duration: TimeInterval = 0
    
    /// Progress through current audio (0.0 - 1.0)
    var progress: Double {
        duration > 0 ? currentTime / duration : 0
    }
    
    /// Whether audio is enabled (respects user preference)
    var isAudioEnabled: Bool = true {
        didSet {
            if !isAudioEnabled {
                pause()
            }
        }
    }
    
    /// Volume level (0.0 - 1.0) - follows system by default
    var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    
    /// Playback speed (0.5 - 2.0)
    var playbackRate: Float = 1.0 {
        didSet {
            audioPlayer?.rate = playbackRate
        }
    }
    
    /// Available playback speeds
    static let availableSpeeds: [Float] = [0.75, 1.0, 1.25, 1.5, 2.0]
    
    /// Skip interval in seconds
    static let skipInterval: TimeInterval = 10
    
    /// Formatted current time string (e.g., "1:23")
    var formattedCurrentTime: String {
        formatTime(currentTime)
    }
    
    /// Formatted duration string (e.g., "3:45")
    var formattedDuration: String {
        formatTime(duration)
    }
    
    /// Formatted remaining time string (e.g., "-2:22")
    var formattedRemainingTime: String {
        "-" + formatTime(duration - currentTime)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(max(0, time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Private Properties
    
    /// AVAudioPlayer instance for playback
    private var audioPlayer: AVAudioPlayer?
    
    /// Timer for progress updates
    private var progressTimer: Timer?
    
    /// Currently loaded audio file name
    private var currentFileName: String?
    
    /// Completion handler for current playback
    private var completionHandler: (() -> Void)?
    
    /// Background task identifier
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Audio Session Configuration
    
    private let audioSession = AVAudioSession.sharedInstance()
    
    // MARK: - Constants
    
    /// Maximum time audio continues in background (30 seconds per spec)
    private let maxBackgroundDuration: TimeInterval = 30
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupAudioSession()
        setupNotifications()
    }
    
    deinit {
        stop()
        endBackgroundTask()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    /// Configure audio session for playback and spoken audio mode
    private func setupAudioSession() {
        do {
            // Use .playback for background audio, .spokenAudio mode for proper handling
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("AudioPlayerService: Failed to configure audio session: \(error)")
        }
    }
    
    /// Setup notifications for app lifecycle and audio interruptions
    private func setupNotifications() {
        let center = NotificationCenter.default
        
        // App lifecycle
        center.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        center.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Audio interruptions (calls, other apps, etc.)
        center.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )
        
        // Route changes (headphones unplugged, etc.)
        center.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession
        )
    }
    
    // MARK: - Public Methods
    
    /// Load audio from a bundled file
    /// - Parameter fileName: Name of the audio file (with extension)
    /// - Returns: Boolean indicating success
    @discardableResult
    func loadAudio(named fileName: String) -> Bool {
        // Check if already loaded
        if currentFileName == fileName && audioPlayer != nil {
            return true
        }
        
        // Stop any current playback
        stop()
        
        playbackState = .loading
        
        // Try to find the file in the main bundle
        guard let url = audioFileURL(for: fileName) else {
            playbackState = .error("Audio file not found: \(fileName)")
            return false
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            
            currentFileName = fileName
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            playbackState = .idle
            
            return true
        } catch {
            playbackState = .error("Failed to load audio: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Load audio from URL (for API-generated audio)
    /// - Parameter url: URL of the audio file
    /// - Returns: Boolean indicating success
    @discardableResult
    func loadAudio(from url: URL) -> Bool {
        stop()
        playbackState = .loading
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            
            currentFileName = url.lastPathComponent
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            playbackState = .idle
            
            return true
        } catch {
            playbackState = .error("Failed to load audio: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Load audio from Data (for API-generated audio)
    /// - Parameter data: Audio data
    /// - Returns: Boolean indicating success
    @discardableResult
    func loadAudio(from data: Data) -> Bool {
        stop()
        playbackState = .loading
        
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            
            currentFileName = "data_audio"
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            playbackState = .idle
            
            return true
        } catch {
            playbackState = .error("Failed to load audio data: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Start or resume playback
    /// - Parameter completion: Called when playback finishes
    func play(completion: (() -> Void)? = nil) {
        guard isAudioEnabled else { return }
        guard let player = audioPlayer else {
            playbackState = .error("No audio loaded")
            return
        }
        
        completionHandler = completion
        
        // Reactivate audio session
        try? audioSession.setActive(true)
        
        if player.play() {
            playbackState = .playing
            startProgressTimer()
        } else {
            playbackState = .error("Failed to start playback")
        }
    }
    
    /// Pause playback
    func pause() {
        guard playbackState == .playing else { return }
        
        audioPlayer?.pause()
        playbackState = .paused
        stopProgressTimer()
    }
    
    /// Toggle between play and pause
    func togglePlayback() {
        switch playbackState {
        case .playing:
            pause()
        case .paused, .idle, .finished:
            play()
        default:
            break
        }
    }
    
    /// Replay from the beginning of current audio
    func replay() {
        guard audioPlayer != nil else { return }
        
        audioPlayer?.currentTime = 0
        currentTime = 0
        
        play()
    }
    
    /// Seek to a specific time
    /// - Parameter time: Target time in seconds
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        
        let clampedTime = max(0, min(time, duration))
        player.currentTime = clampedTime
        currentTime = clampedTime
    }
    
    /// Seek to a specific progress position
    /// - Parameter progress: Target progress (0.0 - 1.0)
    func seek(toProgress progress: Double) {
        let time = duration * progress
        seek(to: time)
    }
    
    /// Skip forward by the skip interval
    func skipForward() {
        let newTime = currentTime + Self.skipInterval
        seek(to: min(newTime, duration))
    }
    
    /// Skip backward by the skip interval
    func skipBackward() {
        let newTime = currentTime - Self.skipInterval
        seek(to: max(newTime, 0))
    }
    
    /// Cycle to the next playback speed
    func cyclePlaybackSpeed() {
        guard let currentIndex = Self.availableSpeeds.firstIndex(of: playbackRate) else {
            playbackRate = 1.0
            return
        }
        let nextIndex = (currentIndex + 1) % Self.availableSpeeds.count
        playbackRate = Self.availableSpeeds[nextIndex]
    }
    
    /// Set specific playback speed
    func setPlaybackSpeed(_ speed: Float) {
        guard Self.availableSpeeds.contains(speed) else { return }
        playbackRate = speed
    }
    
    /// Stop playback and reset state
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        stopProgressTimer()
        
        currentTime = 0
        duration = 0
        currentFileName = nil
        completionHandler = nil
        playbackState = .idle
    }
    
    // MARK: - Helper Methods
    
    /// Get URL for bundled audio file
    private func audioFileURL(for fileName: String) -> URL? {
        // Try with full filename first
        if let url = Bundle.main.url(forResource: fileName, withExtension: nil) {
            return url
        }
        
        // Try extracting name and extension
        let components = fileName.split(separator: ".")
        if components.count == 2 {
            let name = String(components[0])
            let ext = String(components[1])
            return Bundle.main.url(forResource: name, withExtension: ext)
        }
        
        // Try common audio extensions
        for ext in ["mp3", "m4a", "wav", "aac", "aiff"] {
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                return url
            }
        }
        
        // Try in Audio subdirectory
        if let url = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "Audio") {
            return url
        }
        
        return nil
    }
    
    // MARK: - Progress Timer
    
    private func startProgressTimer() {
        stopProgressTimer()
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    // MARK: - Background Task Management
    
    private func beginBackgroundTask() {
        guard backgroundTaskID == .invalid else { return }
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "AudioPlayback") { [weak self] in
            self?.handleBackgroundTimeExpired()
        }
    }
    
    private func endBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }
    
    private func handleBackgroundTimeExpired() {
        // Stop audio if background time expires
        if playbackState == .playing {
            pause()
        }
        endBackgroundTask()
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleAppDidEnterBackground() {
        if playbackState == .playing {
            // Begin background task to continue playing for up to 30 seconds
            beginBackgroundTask()
            
            // Schedule auto-pause after maxBackgroundDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + maxBackgroundDuration) { [weak self] in
                guard let self = self else { return }
                
                // Only pause if still in background and playing
                if UIApplication.shared.applicationState == .background && self.playbackState == .playing {
                    self.pause()
                    self.endBackgroundTask()
                }
            }
        }
    }
    
    @objc private func handleAppWillEnterForeground() {
        endBackgroundTask()
    }
    
    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Pause playback when interrupted
            if playbackState == .playing {
                pause()
            }
            
        case .ended:
            // Resume if appropriate
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && playbackState == .paused {
                    play()
                }
            }
            
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        // Pause when headphones are unplugged (standard iOS behavior)
        if reason == .oldDeviceUnavailable {
            if playbackState == .playing {
                pause()
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopProgressTimer()
        currentTime = duration
        playbackState = .finished
        
        // Save progress (completed)
        if let fileName = currentFileName {
            Self.saveProgress(1.0, for: fileName)
        }
        
        completionHandler?()
        completionHandler = nil
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        stopProgressTimer()
        playbackState = .error(error?.localizedDescription ?? "Decode error")
    }
}

// MARK: - Progress Persistence

extension AudioPlayerService {
    private static let progressKey = "AudioPlayerProgress"
    
    /// Save playback progress for a file
    static func saveProgress(_ progress: Double, for fileName: String) {
        var savedProgress = UserDefaults.standard.dictionary(forKey: progressKey) as? [String: Double] ?? [:]
        savedProgress[fileName] = progress
        UserDefaults.standard.set(savedProgress, forKey: progressKey)
    }
    
    /// Get saved progress for a file
    static func getSavedProgress(for fileName: String) -> Double? {
        let savedProgress = UserDefaults.standard.dictionary(forKey: progressKey) as? [String: Double]
        return savedProgress?[fileName]
    }
    
    /// Clear saved progress for a file
    static func clearProgress(for fileName: String) {
        var savedProgress = UserDefaults.standard.dictionary(forKey: progressKey) as? [String: Double] ?? [:]
        savedProgress.removeValue(forKey: fileName)
        UserDefaults.standard.set(savedProgress, forKey: progressKey)
    }
    
    /// Clear all saved progress
    static func clearAllProgress() {
        UserDefaults.standard.removeObject(forKey: progressKey)
    }
    
    /// Save current progress
    func saveCurrentProgress() {
        guard let fileName = currentFileName, duration > 0 else { return }
        Self.saveProgress(progress, for: fileName)
    }
    
    /// Resume from saved progress
    func resumeFromSavedProgress() {
        guard let fileName = currentFileName,
              let savedProgress = Self.getSavedProgress(for: fileName),
              savedProgress > 0 && savedProgress < 0.99 else {
            return
        }
        
        seek(toProgress: savedProgress)
    }
    
    /// Load audio and optionally resume from saved position
    /// - Parameters:
    ///   - fileName: Name of the audio file
    ///   - resumeIfAvailable: Whether to resume from last position
    /// - Returns: Boolean indicating success
    @discardableResult
    func loadAudio(named fileName: String, resumeIfAvailable: Bool) -> Bool {
        let success = loadAudio(named: fileName)
        
        if success && resumeIfAvailable {
            resumeFromSavedProgress()
        }
        
        return success
    }
}
