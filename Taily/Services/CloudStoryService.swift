import Foundation
import FirebaseFunctions
import FirebaseAuth
import FirebaseAppCheck
import Combine

/// Cloud story generation service using Firebase GenKit
/// Provides AI-powered story generation for iOS 18+ devices
@MainActor
class CloudStoryService: ObservableObject {
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
    
    /// Generate a personalized bedtime story using cloud AI
    /// - Parameters:
    ///   - parameters: Story generation parameters
    ///   - subscriptionManager: Subscription manager for usage tracking
    /// - Returns: Generated story with metadata
    func generateStory(
        with parameters: StoryParameters,
        subscriptionManager: SubscriptionManager
    ) async throws -> CloudStoryResponse {
        guard !parameters.childName.isEmpty else {
            throw CloudStoryError.invalidInput("Child name cannot be empty")
        }
        
        isGenerating = true
        errorMessage = nil
        
        defer {
            isGenerating = false
        }
        
        do {
            // Map StoryParameters to cloud function parameters
            let requestData = mapParametersToCloudRequest(parameters, subscriptionManager: subscriptionManager)
            
            print("🌟 Requesting cloud story generation for \(parameters.childName)...")
            
            // Call the cloud story generation function
            let callable = functions.httpsCallable("generateStoryCloud")
            let result = try await callable.call(requestData)
            
            // Parse response
            guard let data = result.data as? [String: Any],
                  let storyData = data["story"] as? [String: Any],
                  let usageData = data["usage"] as? [String: Any],
                  let metadataData = data["metadata"] as? [String: Any] else {
                throw CloudStoryError.invalidResponse("Invalid response format")
            }
            
            // Parse story data
            guard let title = storyData["title"] as? String,
                  let content = storyData["content"] as? String,
                  let emoji = storyData["emoji"] as? String else {
                throw CloudStoryError.invalidResponse("Missing required story fields")
            }
            
            let moral = storyData["moral"] as? String
            
            // Parse usage data
            let remaining = usageData["remaining"] as? Int ?? 0
            let subscriptionStatus = usageData["subscriptionStatus"] as? String ?? "unknown"
            
            // Parse metadata
            let characterCount = metadataData["characterCount"] as? Int ?? content.count
            let model = metadataData["model"] as? String ?? "gemini-1.5-flash"
            let theme = metadataData["theme"] as? String
            let childAge = metadataData["childAge"] as? Int
            
            // Create GeneratedStory compatible with existing app structure
            let generatedStory = GeneratedStory(
                title: title,
                emoji: emoji,
                content: content,
                storyIllustration: nil // Cloud generation doesn't include illustrations yet
            )
            
            // Create usage info for subscription manager
            let usageInfo = CloudStoryUsage(
                remaining: remaining,
                subscriptionStatus: subscriptionStatus
            )
            
            // Create metadata
            let metadata = CloudStoryMetadata(
                model: model,
                characterCount: characterCount,
                theme: theme,
                childAge: childAge,
                generatedAt: Date()
            )
            
            print("✅ Cloud story generated successfully - \(remaining) stories remaining")
            
            return CloudStoryResponse(
                story: generatedStory,
                usage: usageInfo,
                metadata: metadata
            )
            
        } catch {
            print("❌ Cloud Story Error: \(error)")
            
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
                    errorMessage = "Invalid story parameters. Please check your inputs."
                default:
                    errorMessage = "Story generation unavailable: \(functionsError.localizedDescription)"
                }
            } else {
                errorMessage = "Network error: \(error.localizedDescription)"
            }
            
            throw CloudStoryError.serviceError(errorMessage ?? "Unknown error")
        }
    }
    
    /// Map StoryParameters to cloud function request format
    private func mapParametersToCloudRequest(
        _ parameters: StoryParameters,
        subscriptionManager: SubscriptionManager
    ) -> [String: Any] {
        // Map themes to simple theme strings
        let themeMapping: [CharacterTheme: String] = [
            .animals: "friendly animals",
            .robots: "space adventure",
            .fairy: "magical forest",
            .superhero: "brave hero",
            .space: "space adventure",
            .pirate: "treasure hunt",
            .detective: "mystery solving",
            .wizard: "magical kingdom"
        ]
        
        // Use first theme or default
        let primaryTheme = parameters.themes.first ?? .fairy
        let cloudTheme = themeMapping[primaryTheme] ?? "magical forest"
        
        // Map age group to integer age
        let ageMapping: [AgeGroup: Int] = [
            .toddler: 3,
            .preschool: 5,
            .earlyElementary: 7,
            .elementary: 9
        ]
        
        let childAge = ageMapping[parameters.ageGroup] ?? 5
        
        // Build additional preferences from custom notes and values
        var preferences: [String] = []
        
        if let customNotes = parameters.customNotes, !customNotes.isEmpty {
            preferences.append(customNotes)
        }
        
        if !parameters.values.isEmpty {
            let valuesList = parameters.values.map { $0.rawValue }.joined(separator: ", ")
            preferences.append("Values to emphasize: \(valuesList)")
        }
        
        preferences.append("Setting: \(parameters.setting.rawValue)")
        preferences.append("Tone: \(parameters.tone.rawValue)")
        preferences.append("Length: \(parameters.length.description)")
        
        let additionalPreferences = preferences.joined(separator: ". ")
        
        // Get subscription status for usage tracking
        let subscriptionStatus = subscriptionManager.subscriptionStatus.cloudServiceString
        
        return [
            "childName": parameters.childName,
            "childAge": childAge,
            "theme": cloudTheme,
            "additionalPreferences": additionalPreferences,
            "subscriptionStatus": subscriptionStatus
        ]
    }
}

// MARK: - Data Models

struct CloudStoryResponse {
    let story: GeneratedStory
    let usage: CloudStoryUsage
    let metadata: CloudStoryMetadata
}

struct CloudStoryUsage {
    let remaining: Int
    let subscriptionStatus: String
}

struct CloudStoryMetadata {
    let model: String
    let characterCount: Int
    let theme: String?
    let childAge: Int?
    let generatedAt: Date
}

// MARK: - Error Types

enum CloudStoryError: LocalizedError {
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

// MARK: - Extensions

extension SubscriptionStatus {
    var cloudServiceString: String {
        switch self {
        case .free:
            return "free"
        case .unlimited:
            return "unlimited"
        }
    }
}

// Extension moved to avoid redeclaration conflict
// The hasCustomNotes property is already defined in StoryGenerator.swift