//
//  AudioQueueService.swift
//  Sidrat
//
//  Manages sequential audio playback for multi-segment lessons
//  Supports queuing, auto-advance, and segment tracking
//

import Foundation
import Combine

// MARK: - Audio Segment

/// Represents a single audio segment in a queue
struct AudioSegment: Identifiable, Equatable {
    let id: String
    let fileName: String
    let title: String?
    let duration: TimeInterval?
    
    init(id: String = UUID().uuidString, fileName: String, title: String? = nil, duration: TimeInterval? = nil) {
        self.id = id
        self.fileName = fileName
        self.title = title
        self.duration = duration
    }
    
    static func == (lhs: AudioSegment, rhs: AudioSegment) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Audio Queue Service

/// Service for managing sequential audio playback
@Observable
final class AudioQueueService {
    
    // MARK: - Properties
    
    /// The underlying audio player
    let audioPlayer: AudioPlayerService
    
    /// Current queue of segments
    private(set) var queue: [AudioSegment] = []
    
    /// Index of currently playing segment
    private(set) var currentIndex: Int = 0
    
    /// Whether to auto-advance to next segment
    var autoAdvance: Bool = true
    
    /// Delay between segments (in seconds)
    var interSegmentDelay: TimeInterval = 0.5
    
    /// Whether the queue is currently playing
    var isPlaying: Bool {
        audioPlayer.playbackState.isPlaying
    }
    
    /// Current segment being played
    var currentSegment: AudioSegment? {
        guard currentIndex >= 0 && currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }
    
    /// Whether there's a next segment
    var hasNext: Bool {
        currentIndex < queue.count - 1
    }
    
    /// Whether there's a previous segment
    var hasPrevious: Bool {
        currentIndex > 0
    }
    
    /// Progress through the entire queue (0.0 - 1.0)
    var queueProgress: Double {
        guard queue.count > 0 else { return 0 }
        let segmentProgress = audioPlayer.progress / Double(queue.count)
        let completedSegments = Double(currentIndex) / Double(queue.count)
        return completedSegments + segmentProgress
    }
    
    /// Callback when queue finishes
    var onQueueComplete: (() -> Void)?
    
    /// Callback when segment changes
    var onSegmentChange: ((AudioSegment, Int) -> Void)?
    
    // MARK: - Initialization
    
    init(audioPlayer: AudioPlayerService = AudioPlayerService()) {
        self.audioPlayer = audioPlayer
    }
    
    // MARK: - Queue Management
    
    /// Load a queue of audio segments
    /// - Parameter segments: Array of audio segments
    func loadQueue(_ segments: [AudioSegment]) {
        stop()
        queue = segments
        currentIndex = 0
        
        if let first = segments.first {
            audioPlayer.loadAudio(named: first.fileName)
            onSegmentChange?(first, 0)
        }
    }
    
    /// Add a segment to the end of the queue
    func enqueue(_ segment: AudioSegment) {
        queue.append(segment)
        
        // If queue was empty, load the first segment
        if queue.count == 1 {
            audioPlayer.loadAudio(named: segment.fileName)
            onSegmentChange?(segment, 0)
        }
    }
    
    /// Remove a segment from the queue
    func dequeue(at index: Int) {
        guard index >= 0 && index < queue.count else { return }
        queue.remove(at: index)
        
        // Adjust current index if needed
        if index < currentIndex {
            currentIndex -= 1
        } else if index == currentIndex && currentIndex >= queue.count {
            currentIndex = max(0, queue.count - 1)
        }
    }
    
    /// Clear the entire queue
    func clearQueue() {
        stop()
        queue = []
        currentIndex = 0
    }
    
    // MARK: - Playback Control
    
    /// Start playing the queue from the current position
    func play() {
        audioPlayer.play { [weak self] in
            self?.handleSegmentFinished()
        }
    }
    
    /// Pause playback
    func pause() {
        audioPlayer.pause()
    }
    
    /// Toggle play/pause
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    /// Stop playback and reset to beginning
    func stop() {
        audioPlayer.stop()
        currentIndex = 0
    }
    
    /// Skip to next segment
    func next() {
        guard hasNext else {
            handleQueueComplete()
            return
        }
        
        currentIndex += 1
        loadCurrentSegment()
        
        if autoAdvance {
            play()
        }
    }
    
    /// Go to previous segment
    func previous() {
        // If more than 3 seconds into current segment, restart it
        if audioPlayer.currentTime > 3 {
            audioPlayer.replay()
            return
        }
        
        guard hasPrevious else { return }
        
        currentIndex -= 1
        loadCurrentSegment()
        
        if isPlaying {
            play()
        }
    }
    
    /// Jump to a specific segment
    func jumpTo(index: Int) {
        guard index >= 0 && index < queue.count else { return }
        
        let wasPlaying = isPlaying
        currentIndex = index
        loadCurrentSegment()
        
        if wasPlaying {
            play()
        }
    }
    
    /// Jump to segment by ID
    func jumpTo(segmentId: String) {
        guard let index = queue.firstIndex(where: { $0.id == segmentId }) else { return }
        jumpTo(index: index)
    }
    
    // MARK: - Private Methods
    
    private func loadCurrentSegment() {
        guard let segment = currentSegment else { return }
        audioPlayer.loadAudio(named: segment.fileName)
        onSegmentChange?(segment, currentIndex)
    }
    
    private func handleSegmentFinished() {
        if hasNext && autoAdvance {
            // Delay before next segment
            DispatchQueue.main.asyncAfter(deadline: .now() + interSegmentDelay) { [weak self] in
                self?.next()
            }
        } else {
            handleQueueComplete()
        }
    }
    
    private func handleQueueComplete() {
        onQueueComplete?()
    }
}

// MARK: - Convenience Initializers

extension AudioQueueService {
    /// Create a queue from file names
    static func fromFileNames(_ fileNames: [String]) -> AudioQueueService {
        let service = AudioQueueService()
        let segments = fileNames.enumerated().map { index, fileName in
            AudioSegment(id: "\(index)", fileName: fileName)
        }
        service.loadQueue(segments)
        return service
    }
    
    /// Create a queue for a lesson's phases
    static func forLesson(category: String, phases: [String]) -> AudioQueueService {
        let service = AudioQueueService()
        let segments = phases.map { phase in
            AudioSegment(
                id: "\(category)_\(phase)",
                fileName: "\(category)_\(phase).mp3",
                title: phase.capitalized
            )
        }
        service.loadQueue(segments)
        return service
    }
}

// MARK: - Preview Helper

#if DEBUG
extension AudioQueueService {
    static var preview: AudioQueueService {
        let service = AudioQueueService()
        service.loadQueue([
            AudioSegment(fileName: "intro.mp3", title: "Introduction"),
            AudioSegment(fileName: "story.mp3", title: "Story"),
            AudioSegment(fileName: "practice.mp3", title: "Practice")
        ])
        return service
    }
}
#endif
