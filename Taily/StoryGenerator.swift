import Combine
import Foundation

#if canImport(FoundationModels)
    import FoundationModels
#endif

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct GeneratedStoryiOS26 {
    @Guide(description: "A creative, engaging title for the bedtime story that captures the main theme")
    let title: String

    @Guide(description: "A single emoji that represents the story's main theme or setting")
    let emoji: String

    @Guide(description: "The complete bedtime story content in PLAIN TEXT with NO markup or tags - this will be displayed to users in the app interface")
    let content: String

    @Guide(description: "A companion illustration that captures the main scene or character from the story in a colorful, whimsical, child-friendly style")
    let storyIllustration: GenerableImage?
}

// Unified GeneratedStory that works across iOS versions
struct GeneratedStory: Codable {
    let title: String
    let emoji: String
    let content: String
    let ssmlContent: String? = nil
    let storyIllustration: String? // Description string for cloud stories
}
#else
// iOS 18+ version without FoundationModels
struct GeneratedStory: Codable {
    let title: String
    let emoji: String
    let content: String
    let ssmlContent: String? = nil
    let storyIllustration: String? // Description string for cloud stories
}
#endif

extension GeneratedStory {
    init(title: String, emoji: String, content: String, ssmlContent: String? = nil, storyIllustration: String? = nil) {
        self.title = title
        self.emoji = emoji
        self.content = Self.stripSSMLTags(from: content)
        self.storyIllustration = storyIllustration
    }

    // Helper function to strip SSML tags from text
    private static func stripSSMLTags(from text: String) -> String {
        // Remove common SSML tags
        let patterns = [
            "<break[^>]*>",
            "<emphasis[^>]*>",
            "</emphasis>",
            "<prosody[^>]*>",
            "</prosody>",
            "<speak[^>]*>",
            "</speak>",
            "<voice[^>]*>",
            "</voice>",
            "<p[^>]*>",
            "</p>",
            "<s[^>]*>",
            "</s>"
        ]

        var cleanText = text
        for pattern in patterns {
            cleanText = cleanText.replacingOccurrences(
                of: pattern,
                with: "",
                options: .regularExpression
            )
        }

        return cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Custom decoding to handle backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        emoji = try container.decode(String.self, forKey: .emoji)
        let rawContent = try container.decode(String.self, forKey: .content)
        content = Self.stripSSMLTags(from: rawContent)
        storyIllustration = try container.decodeIfPresent(String.self, forKey: .storyIllustrationDescription)
    }

    // Custom encoding 
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(storyIllustration, forKey: .storyIllustrationDescription)
    }

    enum CodingKeys: String, CodingKey {
        case title, emoji, content, ssmlContent, storyIllustrationDescription
    }
}

struct StoryParameters: Codable {
    let childName: String
    let ageGroup: AgeGroup
    let gender: ChildGender?
    let values: [StoryValue]
    let themes: [CharacterTheme]
    let setting: StorySetting
    let tone: StoryTone
    let length: StoryLength
    let customNotes: String?

    init(childName: String, ageGroup: AgeGroup, gender: ChildGender? = nil, values: [StoryValue], themes: [CharacterTheme], setting: StorySetting, tone: StoryTone, length: StoryLength, customNotes: String? = nil) {
        self.childName = childName
        self.ageGroup = ageGroup
        self.gender = gender
        self.values = values
        self.themes = themes
        self.setting = setting
        self.tone = tone
        self.length = length
        self.customNotes = customNotes
    }
}

enum ChildGender: String, CaseIterable, Codable {
    case boy = "Boy"
    case girl = "Girl"
    case nonBinary = "Non-binary"
    case preferNotToSay = "Prefer not to say"

    var pronouns: String {
        switch self {
        case .boy: return "he/him"
        case .girl: return "she/her"
        case .nonBinary: return "they/them"
        case .preferNotToSay: return "they/them"
        }
    }

    var displayName: String {
        switch self {
        case .boy: return "👦 Boy"
        case .girl: return "👧 Girl"
        case .nonBinary: return "🧒 Non-binary"
        case .preferNotToSay: return "✨ Prefer not to say"
        }
    }
}

enum AgeGroup: String, CaseIterable, Codable {
    case toddler = "2-4 years"
    case preschool = "4-6 years"
    case earlyElementary = "6-8 years"
    case elementary = "8-10 years"

    var description: String {
        switch self {
        case .toddler: return "Simple words, short sentences"
        case .preschool: return "Basic vocabulary, colorful descriptions"
        case .earlyElementary: return "Expanded vocabulary, longer stories"
        case .elementary: return "Complex stories, advanced vocabulary"
        }
    }
}

enum StoryValue: String, CaseIterable, Identifiable, Hashable, Codable {
    case kindness = "💖 Kindness"
    case bravery = "🦁 Bravery"
    case friendship = "🤝 Friendship"
    case honesty = "🌟 Honesty"
    case perseverance = "💪 Perseverance"
    case empathy = "🤗 Empathy"
    case gratitude = "🙏 Gratitude"
    case responsibility = "⭐ Responsibility"

    var id: String { rawValue }
}

enum CharacterTheme: String, CaseIterable, Identifiable, Hashable, Codable {
    case animals = "🐾 Animals"
    case robots = "🤖 Robots"
    case fairy = "🧚‍♀️ Fairy Tale"
    case superhero = "🦸‍♂️ Superhero"
    case space = "🚀 Space Explorer"
    case pirate = "🏴‍☠️ Pirate"
    case detective = "🕵️‍♀️ Detective"
    case wizard = "🧙‍♂️ Wizard"

    var id: String { rawValue }
}

enum StorySetting: String, CaseIterable, Codable {
    case forest = "Enchanted Forest"
    case space = "Outer Space"
    case ocean = "Under the Sea"
    case castle = "Magic Castle"
    case jungle = "Jungle Adventure"
    case city = "Big City"
    case farm = "Countryside Farm"
    case mountain = "Mountain Peak"
}

enum StoryTone: String, CaseIterable, Codable {
    case funny = "😄"
    case calming = "😌"
    case adventurous = "🗺️"
    case magical = "✨"
    case inspiring = "🌟"
}

enum StoryLength: String, CaseIterable, Codable {
    case short = "⚡"
    case medium = "📖"
    case long = "📚"

    var wordCount: Int {
        switch self {
        case .short: return 150
        case .medium: return 400
        case .long: return 800
        }
    }

    var description: String {
        switch self {
        case .short: return "Quick (2-3 minutes)"
        case .medium: return "Normal (5-7 minutes)"
        case .long: return "Long (10-12 minutes)"
        }
    }
}

#if canImport(FoundationModels)
    @available(iOS 26.0, *)
    @MainActor
    class StoryGeneratoriOS26: ObservableObject {
        @Published var isGenerating = false
        @Published var generatedStory: GeneratedStory?
        @Published var savedStory: GeneratedStory?
        @Published var errorMessage: String?

        // Computed property to provide a consistent interface for UI
        var currentStory: GeneratedStory? {
            return savedStory ?? generatedStory
        }

        private let model = SystemLanguageModel.default
        private var session: LanguageModelSession?

        init() {
            // Foundation Models are ready to use
        }

        var isModelAvailable: Bool {
            model.availability == .available
        }

        var modelAvailabilityReason: String {
            switch model.availability {
            case .available:
                return "Available"
            case .unavailable(.deviceNotEligible):
                return "Device not eligible for Apple Intelligence"
            case .unavailable(.appleIntelligenceNotEnabled):
                return "Apple Intelligence not enabled"
            case .unavailable(.modelNotReady):
                return "Model downloading or not ready"
            case .unavailable(let other):
                return "Unavailable: \(other)"
            }
        }

        func prewarm() {
            session?.prewarm()
        }

        func generateStory(with parameters: StoryParameters) async {
            isGenerating = true
            errorMessage = nil
            generatedStory = nil

            guard isModelAvailable else {
                errorMessage = "Story generator not available: \(modelAvailabilityReason)"
                isGenerating = false
                return
            }

            do {
                let instructions = Instructions(
                    """
                    You are a creative storyteller who crafts engaging, age-appropriate bedtime stories for children.
                    Create stories that are soothing, positive, and incorporate the values and themes requested.
                    Keep the language simple and appropriate for the child's age group.
                    End stories with a peaceful, satisfying conclusion perfect for bedtime.

                    CRITICAL: Always include a companion illustration description that captures the story's essence and magical atmosphere.
                    ABSOLUTELY CRITICAL: In illustration descriptions, NEVER include human characters of any age (no children, people, boys, girls, etc.).
                    Instead, focus on magical settings, enchanted objects, fantasy creatures, woodland animals, and atmospheric elements that represent the story's mood and theme.
                    The illustration should show the magical world the story takes place in, allowing readers to imagine themselves within that enchanted environment.
                    """
                )

                session = LanguageModelSession(instructions: instructions)
                let prompt = createPrompt(for: parameters)

                // Use streaming response for real-time updates
                let stream = session!.streamResponse(
                    generating: GeneratedStoryiOS26.self,
                    options: GenerationOptions(sampling: .greedy),
                    includeSchemaInPrompt: false
                ) {
                    prompt
                }

                // Process each partial update and convert to unified GeneratedStory
                for try await partialStory in stream {
                    if let title = partialStory.title,
                       let emoji = partialStory.emoji,
                       let content = partialStory.content {
                        let story = GeneratedStory(
                            title: title,
                            emoji: emoji,
                            content: content,
                            storyIllustration: partialStory.storyIllustration?.imageDescription
                        )
                        generatedStory = story
                    }
                }

            } catch {
                print("Story generation error: \(error)")
                errorMessage = "Failed to generate story. Please try again."
            }

            isGenerating = false
        }


        private func createPrompt(for parameters: StoryParameters) -> String {
            let valuesText = parameters.values.map { $0.rawValue }.joined(
                separator: ", "
            )
            let themesText = parameters.themes.map { $0.rawValue }.joined(
                separator: ", "
            )

            let pronounInstruction: String
            if let gender = parameters.gender {
                pronounInstruction = "Use \(gender.pronouns) pronouns when referring to \(parameters.childName)"
            } else {
                pronounInstruction = "Use they/them pronouns when referring to \(parameters.childName) to keep the story inclusive"
            }

            var prompt = """
                Create a personalized bedtime story for \(parameters.childName) (\(parameters.ageGroup.rawValue)).

                🎯 REQUIRED STORY SETTING: \(parameters.setting.rawValue)
                📝 REQUIRED STORY TONE: \(parameters.tone.rawValue)

                CREATIVE TOOLKIT - SELECT AND MIX:
                Choose 2-3 values from: \(valuesText)
                Choose 2-3 character themes from: \(themesText)

                VARIETY MANDATE:
                - You MUST use the specified setting: \(parameters.setting.rawValue)
                - Create stories that feel fresh and different each time
                - Let the chosen setting drive the story's unique atmosphere and possibilities
                - Setting-specific elements to emphasize:
                  • Outer Space: rockets, planets, aliens, zero gravity, space stations
                  • Under the Sea: coral reefs, sea creatures, underwater cities, submarines
                  • Magic Castle: towers, drawbridges, knights, magical artifacts, throne rooms
                  • Jungle Adventure: vines, exotic animals, hidden temples, river crossings
                  • Big City: skyscrapers, busy streets, subways, parks, museums
                  • Countryside Farm: barns, tractors, farm animals, fields, harvest time
                  • Mountain Peak: caves, climbing, snow, wildlife, scenic views

                STORY REQUIREMENTS:
                - Length: approximately \(parameters.length.wordCount) words
                - Age appropriate for: \(parameters.ageGroup.rawValue) (\(parameters.ageGroup.description))
                - Pronouns: \(pronounInstruction)
                - Build the story around the REQUIRED setting and tone
                - Naturally integrate selected values through character actions and story resolution
                """

            // Add custom notes if available
            if let customNotes = parameters.customNotes, !customNotes.isEmpty {
                prompt += """

                🎯 PERSONALIZATION NOTES (PRIORITY):
                \(parameters.childName)'s special interests: \(customNotes)

                WEAVING INSTRUCTIONS:
                - Use these personal details as the foundation for the story
                - Blend them naturally with the selected values and character themes
                - Make \(parameters.childName) feel this story was created specifically for them
                - Reference their interests, favorite things, or special notes throughout
                """
            }

            prompt += """

                CREATIVE GUIDELINES:
                - Use simple, age-appropriate language suitable for \(parameters.ageGroup.rawValue)
                - Make \(parameters.childName) the main character or someone they can relate to
                - Balance engagement with bedtime suitability (calming tone = peaceful, adventurous tone = exciting but resolved)

                SETTING FOCUS:
                - Fully embrace the \(parameters.setting.rawValue) setting with rich, specific details
                - Use unique elements that ONLY this setting can provide
                - Avoid generic "forest" language - be specific to the chosen environment
                - Create adventures that could ONLY happen in \(parameters.setting.rawValue)

                STORY CRAFTING:
                - Naturally incorporate chosen values through character actions and story resolution
                - Let selected character themes drive the story's magical elements and companions
                - End with a peaceful, satisfying conclusion that reinforces the key values
                - Use vivid but gentle descriptions that spark imagination
                - \(pronounInstruction)
                - Create organic connections between the child's interests and the story world
                - Ensure each story feels unique and fresh, never repetitive

                CRITICAL OUTPUT REQUIREMENTS:
                - The 'content' field must contain ONLY PLAIN TEXT with no markup, tags, or special formatting or emojis.
                - The 'content' field will be displayed directly to users in the app interface
                - Never include any SSML tags, HTML tags, or markup in the 'content' field
                - The 'ssmlContent' field (if provided) should be a separate enhanced version with SSML markup
                - Both fields should tell the same story, but 'content' is plain text and 'ssmlContent' has markup
                - ALWAYS include a 'storyIllustration' field with a vivid, child-friendly description for the companion illustration

                ILLUSTRATION: Describe ONLY the magical environment and setting - no people, no names, no characters.

                SSML FORMATTING (OPTIONAL - for ssmlContent field only):
                - Use <break time="500ms"/> for natural pauses between sentences
                - Use <emphasis level="moderate"> for important words or character names
                - Use <prosody rate="slow"> for dramatic moments
                - Use <prosody pitch="high"> for exciting or happy parts (but keep bedtime-appropriate)
                - Add longer pauses <break time="1s"/> between paragraphs
                - Make dialogue more expressive with prosody changes
                - Keep SSML subtle and natural for bedtime listening
                """

            if parameters.hasCustomNotes {
                prompt += """
                - Naturally weave in \(parameters.childName)'s personal interests mentioned in the notes above
                - Make the story feel personally crafted for \(parameters.childName)
                """
            }

            prompt += """

                Story:
                """

            return prompt
        }

        func regenerateStory(
            with parameters: StoryParameters,
            modification: String
        ) async {
            isGenerating = true
            errorMessage = nil

            guard isModelAvailable else {
                errorMessage = "Story generator not available: \(modelAvailabilityReason)"
                isGenerating = false
                return
            }

            do {
                let instructions = Instructions(
                    """
                    You are a creative storyteller who modifies bedtime stories based on user requests.
                    Keep the core story structure and characters while incorporating the requested changes.
                    Maintain age-appropriate language and a peaceful, bedtime-friendly tone.

                    CRITICAL: Always include a companion illustration description that captures the story's essence and magical atmosphere.
                    ABSOLUTELY CRITICAL: In illustration descriptions, NEVER include human characters of any age (no children, people, boys, girls, etc.).
                    Instead, focus on magical settings, enchanted objects, fantasy creatures, woodland animals, and atmospheric elements that represent the story's mood and theme.
                    The illustration should show the magical world the story takes place in, allowing readers to imagine themselves within that enchanted environment.
                    """
                )

                session = LanguageModelSession(instructions: instructions)
                let prompt = """
                    Here's the current story:
                    Title: \(generatedStory?.title ?? "")
                    Content: \(generatedStory?.content ?? "")

                    Please modify this story with the following request: \(modification)

                    Keep the same character (\(parameters.childName)) and maintain the appropriate tone for bedtime.
                    Provide a new title, emoji, complete modified story content, and a new illustration description.

                    ILLUSTRATION: Describe ONLY the magical environment and setting - no people, no names, no characters.
                    """

                // Use streaming response for real-time updates
                let stream = session!.streamResponse(
                    generating: GeneratedStoryiOS26.self,
                    options: GenerationOptions(sampling: .greedy),
                    includeSchemaInPrompt: false
                ) {
                    prompt
                }

                // Process each partial update and convert to unified GeneratedStory
                for try await partialStory in stream {
                    if let title = partialStory.title,
                       let emoji = partialStory.emoji,
                       let content = partialStory.content {
                        let story = GeneratedStory(
                            title: title,
                            emoji: emoji,
                            content: content,
                            storyIllustration: partialStory.storyIllustration?.imageDescription
                        )
                        generatedStory = story
                    }
                }

            } catch {
                print("Story modification error: \(error)")
                errorMessage = "Failed to modify story. Please try again."
            }

            isGenerating = false
        }
    }
#else
    // Note: StoryGenerator is now unified and defined below to work on all iOS versions
#endif

// MARK: - Unified StoryGenerator for all iOS versions

@MainActor
class StoryGenerator: ObservableObject {
    @Published var isGenerating = false
    @Published var generatedStory: GeneratedStory?
    @Published var savedStory: GeneratedStory?
    @Published var errorMessage: String?
    
    #if canImport(FoundationModels)
    private var ios26Generator: Any?
    #endif
    private let cloudStoryService = CloudStoryService()

    // Computed property to provide a consistent interface for UI
    var currentStory: GeneratedStory? {
        return savedStory ?? generatedStory
    }

    var isModelAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if ios26Generator == nil {
                ios26Generator = StoryGeneratoriOS26()
            }
            return (ios26Generator as? StoryGeneratoriOS26)?.isModelAvailable ?? true // Fallback to cloud
        }
        #endif
        return true // Cloud generation is always available
    }
    
    var modelAvailabilityReason: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if ios26Generator == nil {
                ios26Generator = StoryGeneratoriOS26()
            }
            return (ios26Generator as? StoryGeneratoriOS26)?.modelAvailabilityReason ?? "Cloud story generation available"
        }
        #endif
        return "Cloud story generation available"
    }

    func prewarm() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if ios26Generator == nil {
                ios26Generator = StoryGeneratoriOS26()
            }
            (ios26Generator as? StoryGeneratoriOS26)?.prewarm()
        }
        #endif
    }

    func generateStory(with parameters: StoryParameters) async {
        isGenerating = true
        errorMessage = nil
        generatedStory = nil

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if ios26Generator == nil {
                ios26Generator = StoryGeneratoriOS26()
            }
            
            let generator = ios26Generator as? StoryGeneratoriOS26
            if generator?.isModelAvailable == true {
                // Use on-device generation
                await generator?.generateStory(with: parameters)
                generatedStory = generator?.currentStory
                errorMessage = generator?.errorMessage
                isGenerating = false
                return
            }
        }
        #endif
        
        // Fallback to cloud generation
        await generateStoryCloud(with: parameters)
    }

    func regenerateStory(with parameters: StoryParameters, modification: String) async {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if ios26Generator == nil {
                ios26Generator = StoryGeneratoriOS26()
            }
            
            let generator = ios26Generator as? StoryGeneratoriOS26
            if generator?.isModelAvailable == true {
                // Use on-device regeneration
                await generator?.regenerateStory(with: parameters, modification: modification)
                generatedStory = generator?.currentStory
                errorMessage = generator?.errorMessage
                return
            }
        }
        #endif
        
        // Fallback to cloud generation with modified parameters
        let modifiedParameters = StoryParameters(
            childName: parameters.childName,
            ageGroup: parameters.ageGroup,
            gender: parameters.gender,
            values: parameters.values,
            themes: parameters.themes,
            setting: parameters.setting,
            tone: parameters.tone,
            length: parameters.length,
            customNotes: (parameters.customNotes ?? "") + " " + modification
        )
        
        await generateStoryCloud(with: modifiedParameters)
    }
    
    private func generateStoryCloud(with parameters: StoryParameters) async {
        guard let subscriptionManager = getSubscriptionManager() else {
            errorMessage = "Subscription service not available"
            isGenerating = false
            return
        }

        do {
            let response = try await cloudStoryService.generateStory(
                with: parameters,
                subscriptionManager: subscriptionManager
            )
            
            // Update the story
            generatedStory = response.story
            
            // Update subscription manager with new usage info
            await updateSubscriptionManagerUsage(
                subscriptionManager: subscriptionManager,
                usage: response.usage
            )
            
        } catch {
            print("Cloud story generation error: \(error)")
            errorMessage = "Failed to generate story. Please check your connection and try again."
        }

        isGenerating = false
    }
    
    /// Get subscription manager from the app context
    private func getSubscriptionManager() -> SubscriptionManager? {
        // For now, create a new instance - could be improved with dependency injection
        return SubscriptionManager()
    }
    
    /// Update subscription manager with new usage information from cloud response
    private func updateSubscriptionManagerUsage(
        subscriptionManager: SubscriptionManager,
        usage: CloudStoryUsage
    ) async {
        // Update local subscription status based on cloud response
        switch usage.subscriptionStatus {
        case "unlimited":
            subscriptionManager.subscriptionStatus = .unlimited
        case "free":
            subscriptionManager.subscriptionStatus = .free(storiesRemaining: usage.remaining)
        default:
            // Keep current status if unknown
            break
        }
    }
}
