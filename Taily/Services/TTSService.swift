import Foundation
import FirebaseFunctions
import FirebaseAuth
import FirebaseAppCheck
import Combine

/// Text-to-Speech service that integrates with Firebase Functions
/// Automatically handles authentication and App Check for secure TTS requests
@MainActor
class TTSService: ObservableObject {
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    private let functions = Functions.functions()
    
    init() {
        // Use emulator for development if needed
        #if DEBUG
        // Uncomment for local development with emulator
        // functions.useEmulator(withHost: "localhost", port: 5001)
        #endif
    }
    
    /// Generate speech audio from text using Firebase Functions with App Check security
    /// - Parameters:
    ///   - text: The text to convert to speech
    ///   - voice: Optional voice configuration
    ///   - audioConfig: Optional audio configuration
    ///   - subscriptionStatus: Current subscription status for proper usage tracking
    /// - Returns: Base64 encoded audio data and format info
    func synthesizeSpeech(
        text: String,
        voice: VoiceConfig? = nil,
        audioConfig: AudioConfig? = nil,
        subscriptionStatus: String? = nil
    ) async throws -> TTSResponse {
        guard !text.isEmpty else {
            throw TTSError.invalidInput("Text cannot be empty")
        }
        
        guard text.count <= 5000 else {
            throw TTSError.invalidInput("Text too long (max 5000 characters)")
        }
        
        isGenerating = true
        errorMessage = nil
        
        defer {
            isGenerating = false
        }
        
        do {
            // Prepare request data
            var requestData: [String: Any] = ["text": text]
            
            if let voice = voice {
                requestData["voice"] = [
                    "languageCode": voice.languageCode,
                    "name": voice.name,
                    "ssmlGender": voice.ssmlGender
                ]
            }
            
            if let audioConfig = audioConfig {
                requestData["audioConfig"] = [
                    "audioEncoding": audioConfig.encoding,
                    "speakingRate": audioConfig.speakingRate,
                    "pitch": audioConfig.pitch
                ]
            }
            
            if let subscriptionStatus = subscriptionStatus {
                requestData["subscriptionStatus"] = subscriptionStatus
            }
            
            print("🎤 Requesting TTS for \(text.count) characters...")
            
            // Call the secure Firebase Function
            // App Check and Firebase Auth are automatically handled
            let callable = functions.httpsCallable("synthesizeSpeechCallable")
            let result = try await callable.call(requestData)
            
            // Parse response
            guard let data = result.data as? [String: Any],
                  let audioContent = data["audioContent"] as? String,
                  let audioFormat = data["audioFormat"] as? String else {
                throw TTSError.invalidResponse("Invalid response format")
            }
            
            let remaining = data["remaining"] as? Int ?? 0
            let responseSubscriptionStatus = data["subscriptionStatus"] as? String ?? "unknown"
            
            // Provide better user feedback based on subscription status
            if responseSubscriptionStatus == "unlimited" {
                print("✅ TTS successful - unlimited stories available")
            } else {
                print("✅ TTS successful - \(remaining) stories remaining in trial")
            }
            
            return TTSResponse(
                audioContent: audioContent,
                audioFormat: audioFormat,
                remaining: remaining
            )
            
        } catch {
            print("❌ TTS Error: \(error)")
            
            let functionsError = error as NSError
            if functionsError.domain == "FIRFunctionsErrorDomain" {
                let code = functionsError.code
                switch code {
                case 16: // UNAUTHENTICATED
                    errorMessage = "Authentication required. Please sign in."
                case 9: // FAILED_PRECONDITION
                    errorMessage = "App verification failed. Please update the app."
                case 8: // RESOURCE_EXHAUSTED
                    errorMessage = "Monthly story limit reached. Try again next month or upgrade."
                case 3: // INVALID_ARGUMENT
                    errorMessage = "Invalid text input. Please check your story content."
                default:
                    errorMessage = "TTS service unavailable: \(functionsError.localizedDescription)"
                }
            } else {
                errorMessage = "Network error: \(error.localizedDescription)"
            }
            
            throw TTSError.serviceError(errorMessage ?? "Unknown error")
        }
    }
    
    /// Convert story text to audio for bedtime narration
    /// - Parameters:
    ///   - story: The complete story content
    ///   - childAge: Child's age for appropriate voice selection
    ///   - selectedVoice: Optional custom voice selection (overrides age-based selection)
    ///   - subscriptionStatus: Current subscription status for proper usage tracking
    /// - Returns: Audio data ready for playback
    func synthesizeStory(story: String, childAge: Int = 5, selectedVoice: VoiceConfig? = nil, subscriptionStatus: String? = nil) async throws -> TTSResponse {
        let voice = selectedVoice ?? VoiceConfig.ageAppropriate(for: childAge)
        let audioConfig = AudioConfig.bedtimeOptimized()
        
        return try await synthesizeSpeech(
            text: story,
            voice: voice,
            audioConfig: audioConfig,
            subscriptionStatus: subscriptionStatus
        )
    }
    
    /// Generate a voice sample for preview
    /// - Parameter voice: The voice configuration to preview
    /// - Returns: Short audio sample for voice preview
    func generateVoiceSample(for voice: VoiceConfig) async throws -> TTSResponse {
        let sampleText = "Once upon a time, a little bunny named Luna found a magical star that had fallen from the sky. The star whispered softly that it could grant one special wish before returning home. Luna wished for all the children in the world to have the sweetest dreams, and the star sparkled with joy before floating back up to the moon."
        let audioConfig = AudioConfig.bedtimeOptimized()
        
        return try await synthesizeSpeech(
            text: sampleText,
            voice: voice,
            audioConfig: audioConfig
        )
    }
}

// MARK: - Data Models

struct TTSResponse {
    let audioContent: String  // Base64 encoded audio
    let audioFormat: String   // "MP3", "WAV", etc.
    let remaining: Int        // Remaining requests this month
}

struct VoiceConfig {
    let languageCode: String
    let name: String?
    let ssmlGender: String
    let displayName: String
    let description: String
    let ageRange: String
    
    static func ageAppropriate(for age: Int) -> VoiceConfig {
        if age <= 4 {
            return VoiceConfig.warmMother
        } else if age <= 7 {
            return VoiceConfig.kindTeacher
        } else {
            return VoiceConfig.storyteller
        }
    }
    
    // MARK: - Predefined Voice Options
    
    static let warmMother = VoiceConfig(
        languageCode: "en-US",
        name: "en-US-Neural2-F",
        ssmlGender: "FEMALE",
        displayName: "Warm Mother",
        description: "A gentle, nurturing voice perfect for toddlers",
        ageRange: "2-4 years"
    )
    
    static let kindTeacher = VoiceConfig(
        languageCode: "en-US",
        name: "en-US-Neural2-G",
        ssmlGender: "FEMALE",
        displayName: "Kind Teacher",
        description: "A friendly, clear voice great for preschoolers",
        ageRange: "4-7 years"
    )
    
    static let storyteller = VoiceConfig(
        languageCode: "en-US",
        name: "en-US-Neural2-C",
        ssmlGender: "FEMALE",
        displayName: "Storyteller",
        description: "A mature, expressive voice for older children",
        ageRange: "7+ years"
    )
    
    static let cheerfulAunt = VoiceConfig(
        languageCode: "en-US",
        name: "en-US-Neural2-H",
        ssmlGender: "FEMALE",
        displayName: "Cheerful Aunt",
        description: "An upbeat, energetic voice for adventurous stories",
        ageRange: "All ages"
    )
    
    static let wiseDaddy = VoiceConfig(
        languageCode: "en-US",
        name: "en-US-Neural2-D",
        ssmlGender: "MALE",
        displayName: "Wise Daddy",
        description: "A calm, reassuring male voice for bedtime",
        ageRange: "All ages"
    )
    
    static let allVoices: [VoiceConfig] = [
        .warmMother,
        .kindTeacher,
        .storyteller,
        .cheerfulAunt,
        .wiseDaddy
    ]
}

struct AudioConfig {
    let encoding: String
    let speakingRate: Double
    let pitch: Double
    
    static func bedtimeOptimized() -> AudioConfig {
        return AudioConfig(
            encoding: "MP3",
            speakingRate: 0.85,  // Slightly slower for bedtime
            pitch: 0.0           // Natural pitch
        )
    }
}

// MARK: - Error Types

enum TTSError: LocalizedError {
    case invalidInput(String)
    case invalidResponse(String)
    case serviceError(String)
    case authenticationRequired
    case appCheckFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .serviceError(let message):
            return "Service error: \(message)"
        case .authenticationRequired:
            return "Authentication required"
        case .appCheckFailed:
            return "App verification failed"
        }
    }
}

