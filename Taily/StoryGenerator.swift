import Combine
import Foundation

#if canImport(FoundationModels)
    import FoundationModels
#endif

@Generable
struct GeneratedStory: Codable {
    @Guide(description: "A creative, engaging title for the bedtime story that captures the main theme")
    let title: String

    @Guide(description: "A single emoji that represents the story's main theme or setting")
    let emoji: String

    @Guide(description: "The complete bedtime story content in PLAIN TEXT with NO markup or tags - this will be displayed to users in the app interface")
    let content: String

    @Guide(description: "A separate SSML-enhanced version of the story content with Speech Synthesis Markup Language tags for text-to-speech. This should be the same story as 'content' but enhanced with SSML tags like <break>, <emphasis>, <prosody>. Do NOT include SSML tags in the 'content' field.")
    let ssmlContent: String?

    @Guide(description: "A companion illustration that captures the main scene or character from the story in a colorful, whimsical, child-friendly style")
    let storyIllustration: GenerableImage?

    init(title: String, emoji: String, content: String, ssmlContent: String? = nil, storyIllustration: GenerableImage? = nil) {
        self.title = title
        self.emoji = emoji
        // Strip any SSML tags from content to ensure it's plain text
        self.content = Self.stripSSMLTags(from: content)
        self.ssmlContent = ssmlContent
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
        // Strip any SSML tags that might have been saved in content
        content = Self.stripSSMLTags(from: rawContent)
        // ssmlContent is optional and may not exist in older saved stories
        ssmlContent = try container.decodeIfPresent(String.self, forKey: .ssmlContent)
        // storyIllustration may not exist in older saved stories
        if let imageDescription = try container.decodeIfPresent(String.self, forKey: .storyIllustrationDescription) {
            storyIllustration = GenerableImage(imageDescription: imageDescription)
        } else {
            storyIllustration = nil
        }
    }
    
    // Custom encoding to handle GenerableImage
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(ssmlContent, forKey: .ssmlContent)
        // Encode the image description if available
        try container.encodeIfPresent(storyIllustration?.imageDescription, forKey: .storyIllustrationDescription)
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
    class StoryGenerator: ObservableObject {
        @Published var isGenerating = false
        @Published var generatedStory: GeneratedStory.PartiallyGenerated?
        @Published var errorMessage: String?

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
                    generating: GeneratedStory.self,
                    options: GenerationOptions(sampling: .greedy),
                    includeSchemaInPrompt: false
                ) {
                    prompt
                }

                // Process each partial update
                for try await partialStory in stream {
                    generatedStory = partialStory
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
                Create a bedtime story for a child named \(parameters.childName).

                Story Requirements:
                - Age appropriate for: \(parameters.ageGroup.rawValue) (\(parameters.ageGroup.description))
                - Story length: approximately \(parameters.length.wordCount) words
                - Tone: \(parameters.tone.rawValue)
                - Setting: \(parameters.setting.rawValue)
                - Character themes: \(themesText)
                - Values to emphasize: \(valuesText)
                - Pronouns: \(pronounInstruction)
                """

            // Add custom notes if available
            if let customNotes = parameters.customNotes, !customNotes.isEmpty {
                prompt += """

                IMPORTANT PERSONALIZATION NOTES:
                \(parameters.childName)'s interests and preferences: \(customNotes)
                Please incorporate these personal details naturally into the story to make it more engaging and relatable for \(parameters.childName).
                """
            }

            prompt += """

                Guidelines:
                - Use simple, age-appropriate language
                - Include \(parameters.childName) as the main character or someone they can relate to
                - Make it engaging but suitable for bedtime (not too exciting if tone is calming)
                - Include positive messages about \(valuesText)
                - End with a peaceful, satisfying conclusion
                - Use vivid but gentle descriptions
                - \(pronounInstruction)

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
                    generating: GeneratedStory.self,
                    options: GenerationOptions(sampling: .greedy),
                    includeSchemaInPrompt: false
                ) {
                    prompt
                }

                // Process each partial update
                for try await partialStory in stream {
                    generatedStory = partialStory
                }
                
            } catch {
                print("Story modification error: \(error)")
                errorMessage = "Failed to modify story. Please try again."
            }

            isGenerating = false
        }
    }
#else
    // Fallback implementation when Foundation Models are not available
    @MainActor
    class StoryGenerator: ObservableObject {
        @Published var isGenerating = false
        @Published var generatedStory: GeneratedStory.PartiallyGenerated?
        @Published var errorMessage: String?

        var isModelAvailable: Bool { false }
        var modelAvailabilityReason: String {
            "Foundation Models not available"
        }

        func prewarm() {
            // No-op for fallback
        }

        func generateStory(with parameters: StoryParameters) async {
            isGenerating = true
            errorMessage = "Foundation Models not available on this device"
            isGenerating = false
        }

        func regenerateStory(
            with parameters: StoryParameters,
            modification: String
        ) async {
            isGenerating = true
            errorMessage = "Foundation Models not available on this device"
            isGenerating = false
        }
    }
#endif
