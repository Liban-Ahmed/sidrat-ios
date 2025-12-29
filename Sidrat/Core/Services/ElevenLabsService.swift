//
//  ElevenLabsService.swift
//  Sidrat
//
//  ElevenLabs Text-to-Speech API integration service
//  Uses Turbo v2.5 model for optimal performance and cost
//

import Foundation

// MARK: - ElevenLabs Service

/// Service for interacting with ElevenLabs Text-to-Speech API
final class ElevenLabsService {
    
    // MARK: - Singleton
    
    static let shared = ElevenLabsService()
    
    // MARK: - Configuration
    
    /// ElevenLabs API base URL
    private let baseURL = "https://api.elevenlabs.io/v1"
    
    /// Model to use for TTS - Turbo v2.5 for best performance/cost ratio
    private let modelId = "eleven_turbo_v2_5"
    
    /// Voice configuration
    enum Voice: String {
        /// Sana - Calm, Soft and Honest - Ideal for children's Islamic education
        case sana = "XB0fDUnXU5powFXDhCwa"
        
        /// Haytham - Dramatic, Warm and Friendly - Good for storytelling
        case haytham = "4FKcxTRiNQTLmOdfPWmV"
        
        /// MarcoTrox - Warm, Balanced and Polished
        case marcoTrox = "mTSvIrm2hmcnkJFjTgXz"
        
        /// Sanna Hartfield - Direct and Natural
        case sannaHartfield = "l1Ua2KwGNdtDC2DTTAMP"
        
        var name: String {
            switch self {
            case .sana: return "Sana"
            case .haytham: return "Haytham"
            case .marcoTrox: return "MarcoTrox"
            case .sannaHartfield: return "Sanna Hartfield"
            }
        }
    }
    
    /// Default voice for the app - Sana (calm, soft, honest - perfect for children)
    private let defaultVoice: Voice = .sana
    
    /// API Key from environment
    private var apiKey: String? {
        ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"]
    }
    
    /// URLSession for API requests
    private let session: URLSession
    
    /// Audio cache to avoid redundant API calls
    private let audioCache = NSCache<NSString, NSData>()
    
    // MARK: - Initialization
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
        
        // Configure cache
        audioCache.countLimit = 50 // Cache up to 50 audio clips
        audioCache.totalCostLimit = 50 * 1024 * 1024 // 50MB max cache size
    }
    
    // MARK: - Public Methods
    
    /// Synthesize text to speech audio data
    /// - Parameters:
    ///   - text: The text to convert to speech
    ///   - voice: The voice to use (defaults to Sana)
    ///   - stability: Voice stability (0.0 - 1.0), default 0.5
    ///   - similarityBoost: Similarity boost (0.0 - 1.0), default 0.75
    /// - Returns: Audio data in MP3 format
    func synthesize(
        text: String,
        voice: Voice? = nil,
        stability: Double = 0.5,
        similarityBoost: Double = 0.75
    ) async throws -> Data {
        // Check cache first
        let cacheKey = "\(voice?.rawValue ?? defaultVoice.rawValue)_\(text.hashValue)" as NSString
        if let cachedData = audioCache.object(forKey: cacheKey) {
            return cachedData as Data
        }
        
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ElevenLabsError.missingAPIKey
        }
        
        let selectedVoice = voice ?? defaultVoice
        let url = URL(string: "\(baseURL)/text-to-speech/\(selectedVoice.rawValue)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        
        let requestBody = TTSRequest(
            text: text,
            modelId: modelId,
            voiceSettings: VoiceSettings(
                stability: stability,
                similarityBoost: similarityBoost,
                style: 0.0,
                useSpeakerBoost: true
            )
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            // Cache the successful response
            audioCache.setObject(data as NSData, forKey: cacheKey, cost: data.count)
            return data
            
        case 401:
            throw ElevenLabsError.unauthorized
            
        case 429:
            throw ElevenLabsError.rateLimited
            
        case 400...499:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ElevenLabsError.clientError(statusCode: httpResponse.statusCode, message: errorMessage)
            
        case 500...599:
            throw ElevenLabsError.serverError(statusCode: httpResponse.statusCode)
            
        default:
            throw ElevenLabsError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }
    
    /// Clear the audio cache
    func clearCache() {
        audioCache.removeAllObjects()
    }
    
    /// Check if API key is configured
    var isConfigured: Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty
    }
}

// MARK: - Request/Response Models

extension ElevenLabsService {
    
    private struct TTSRequest: Encodable {
        let text: String
        let modelId: String
        let voiceSettings: VoiceSettings
        
        enum CodingKeys: String, CodingKey {
            case text
            case modelId = "model_id"
            case voiceSettings = "voice_settings"
        }
    }
    
    private struct VoiceSettings: Encodable {
        let stability: Double
        let similarityBoost: Double
        let style: Double
        let useSpeakerBoost: Bool
        
        enum CodingKeys: String, CodingKey {
            case stability
            case similarityBoost = "similarity_boost"
            case style
            case useSpeakerBoost = "use_speaker_boost"
        }
    }
}

// MARK: - Errors

enum ElevenLabsError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case unauthorized
    case rateLimited
    case clientError(statusCode: Int, message: String)
    case serverError(statusCode: Int)
    case unexpectedStatusCode(Int)
    case audioPlaybackFailed
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "ElevenLabs API key is not configured"
        case .invalidResponse:
            return "Invalid response from ElevenLabs API"
        case .unauthorized:
            return "Invalid or expired API key"
        case .rateLimited:
            return "API rate limit exceeded. Please try again later."
        case .clientError(let code, let message):
            return "Client error (\(code)): \(message)"
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .unexpectedStatusCode(let code):
            return "Unexpected response (\(code))"
        case .audioPlaybackFailed:
            return "Failed to play audio"
        }
    }
}
