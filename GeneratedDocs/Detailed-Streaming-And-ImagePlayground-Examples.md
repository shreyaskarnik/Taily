# Detailed Streaming Generation & ImagePlayground Integration Examples

## Overview
This document provides comprehensive, real-world examples of streaming generation and ImagePlayground integration from the FoundationModels framework, extracted from the actual sample projects.

## Part 1: Streaming Generation Deep Dive

### 1.1 Core Streaming Architecture

The streaming generation pattern centers around the `streamResponse()` method that provides partial results in real-time:

```swift
let stream = session.streamResponse(
    generating: Itinerary.self,
    options: GenerationOptions(sampling: .greedy),
    includeSchemaInPrompt: false
) {
    "Generate a \(dayCount)-day itinerary to \(landmark.name)."
}

for try await partialResponse in stream {
    // Update UI with partial data
    itinerary = partialResponse
}
```

### 1.2 Complete Streaming Implementation - ItineraryPlanner

**File: `ItineraryPlanner.swift`**

```swift
import FoundationModels
import Observation

@Observable
@MainActor
final class ItineraryPlanner {
    // The key property - holds partially generated data
    private(set) var itinerary: Itinerary.PartiallyGenerated?
    private(set) var pointOfInterestTool: FindPointsOfInterestTool
    private var session: LanguageModelSession
    
    var error: Error?
    let landmark: Landmark

    init(landmark: Landmark) {
        self.landmark = landmark
        let pointOfInterestTool = FindPointsOfInterestTool(landmark: landmark)
        
        // Session setup with tools and detailed instructions
        self.session = LanguageModelSession(
            tools: [pointOfInterestTool],
            instructions: Instructions {
                "Your job is to create an itinerary for the user."
                "Each day needs an activity, hotel and restaurant."
                
                """
                Always use the findPointsOfInterest tool to find businesses \
                and activities in \(landmark.name), especially hotels \
                and restaurants.
                
                The point of interest categories may include:
                """
                FindPointsOfInterestTool.categories
                
                """
                Here is a description of \(landmark.name) for your reference \
                when considering what activities to generate:
                """
                landmark.description
            }
        )
        self.pointOfInterestTool = pointOfInterestTool
    }

    // Core streaming method
    func suggestItinerary(dayCount: Int) async throws {
        let stream = session.streamResponse(
            generating: Itinerary.self,
            options: GenerationOptions(sampling: .greedy),
            includeSchemaInPrompt: false
        ) {
            "Generate a \(dayCount)-day itinerary to \(landmark.name)."
            "Give it a fun title and description."
            "Here is an example, but don't copy it:"
            Itinerary.exampleTripToJapan
        }

        // Process each partial update
        for try await partialResponse in stream {
            itinerary = partialResponse
        }
    }

    // Performance optimization
    func prewarm() {
        session.prewarm()
    }
}
```

### 1.3 Streaming-Aware UI Implementation

**File: `ItineraryView.swift`**

The UI is designed to handle partial data gracefully:

```swift
struct ItineraryView: View {
    let landmark: Landmark
    let itinerary: Itinerary.PartiallyGenerated  // Key type for streaming

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading) {
                // Optional binding for partial data
                if let title = itinerary.title {
                    Text(title)
                        .contentTransition(.opacity)  // Smooth transitions
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                if let description = itinerary.description {
                    Text(description)
                        .contentTransition(.opacity)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Rationale section with optional content
            if let rationale = itinerary.rationale {
                HStack(alignment: .top) {
                    Image(systemName: "sparkles")
                    Text(rationale)
                        .contentTransition(.opacity)
                }
                .rationaleStyle()
            }
            
            // Dynamic list of days as they're generated
            if let days = itinerary.days {
                ForEach(days) { plan in
                    DayView(landmark: landmark, plan: plan)
                        .transition(.blurReplace)  // Smooth entry animation
                }
            }
        }
        .animation(.easeOut, value: itinerary)  // Animate on data changes
        .itineraryStyle()
    }
}
```

### 1.4 Nested Streaming with PartiallyGenerated Types

```swift
private struct DayView: View {
    let landmark: Landmark
    let plan: DayPlan.PartiallyGenerated  // Nested partial type

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Map updates as destination is generated
            .onChange(of: plan.destination) { _, newValue in
                if let destination = newValue {
                    map.performLookup(location: destination)
                }
            }
            
            VStack(alignment: .leading) {
                // Conditional rendering based on availability
                if let title = plan.title {
                    Text(title)
                        .contentTransition(.opacity)
                        .font(.headline)
                }
                if let subtitle = plan.subtitle {
                    Text(subtitle)
                        .contentTransition(.opacity)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Activities list with streaming updates
            ActivityList(activities: plan.activities ?? [])
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(.easeInOut, value: plan)  // Animate on changes
    }
}
```

### 1.5 Array Streaming Pattern

```swift
private struct ActivityList: View {
    let activities: [Activity].PartiallyGenerated  // Array partial type
    
    var body: some View {
        ForEach(activities) { activity in
            HStack(alignment: .top, spacing: 12) {
                if let title = activity.title {
                    ActivityIcon(symbolName: activity.type?.symbolName)
                    VStack(alignment: .leading) {
                        Text(title)
                            .contentTransition(.opacity)
                            .font(.headline)
                        if let description = activity.description {
                            Text(description)
                                .contentTransition(.opacity)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
```

## Part 2: ImagePlayground Integration Deep Dive

### 2.1 Custom Generable with ImagePlayground

**File: `GenerableImage.swift`**

```swift
import FoundationModels
import ImagePlayground
import SwiftUI

@MainActor
@Observable
final class GenerableImage: Generable, Equatable {
    
    // Equality implementation for Observable
    nonisolated static func == (lhs: GenerableImage, rhs: GenerableImage) -> Bool {
        lhs === rhs
    }

    // AI-generated image description with constraints
    @Guide(description: "Avoid descriptions that look human-like. Stick to animals, plants, or objects.")
    let imageDescription: String
    
    // ImagePlayground style configuration
    let imageStyle: ImagePlaygroundStyle = .sketch

    // State management for image generation
    var isResponding: Bool { task != nil }
    private(set) var image: CGImage?
    private var task: Task<Void, Error>?

    // Custom GenerationSchema implementation
    nonisolated static var generationSchema: GenerationSchema {
        GenerationSchema(
            type: GenerableImage.self,
            description: "A description of an image to be given to a image generation model. The description should be short and non-human-like.",
            properties: [
                GenerationSchema.Property(
                    name: "imageDescription",
                    type: String.self
                )
            ]
        )
    }

    // Content representation for the framework
    nonisolated var generatedContent: GeneratedContent {
        GeneratedContent(properties: [
            "imageDescription": imageDescription
        ])
    }

    // Custom initialization from AI output
    nonisolated init(_ content: GeneratedContent) throws {
        self.imageDescription = try content.value(forProperty: "imageDescription")
        Logging.general.log("Generating image for description: \(self.imageDescription)")
        
        // Automatically start image generation
        Task { try await self.generateImage() }
    }

    // ImagePlayground integration
    private func generateImage() throws {
        task?.cancel()  // Cancel any existing generation
        task = Task {
            do {
                // Create ImagePlayground generator
                let generator = try await ImageCreator()

                // Generate images with constraints
                let generations = generator.images(
                    for: [.text(imageDescription)],
                    style: imageStyle,
                    limit: 1
                )

                // Process generated images
                for try await generation in generations {
                    self.image = generation.cgImage
                    self.task = nil
                    return
                }

            } catch let error {
                self.task = nil
                Logging.general.log("Image generation failed for prompt: \(self.imageDescription). Error: \(error)")
                throw error
            }
        }
    }
}
```

### 2.2 Using GenerableImage in Game NPCs

**File: `EncounterEngine.swift`**

```swift
@Generable
struct NPC: Equatable {
    let name: String
    let coffeeOrder: String
    let picture: GenerableImage  // Embedded image generation
}

@MainActor
@Observable class EncounterEngine {
    var customer: NPC?

    func generateNPC() async throws -> NPC {
        let session = LanguageModelSession {
            """
            A conversation between a user and a helpful assistant. This is a fantasy RPG game that takes
            place at Dream Coffee, the beloved coffee shop of the dream realm. Your role is to use your
            imagination to generate fun game characters.
            """
        }
        
        let prompt = """
            Create an NPC customer with a fun personality suitable for the dream realm. Have the customer order
            coffee. Here are some examples to inspire you:
            {name: "Thimblefoot", imageDescription: "A horse with a rainbow mane",
            coffeeOrder: "I would like a coffee that's refreshing and sweet like grass of a summer meadow"}
            {name: "Spiderkid", imageDescription: "A furry spider with a cool baseball cap",
            coffeeOrder: "An iced coffee please, that's as spooky as me!"}
            {name: "Wise Fairy", imageDescription: "A blue glowing fairy that radiates wisdom and sparkles",
            coffeeOrder: "Something simple and plant-based please, that will restore my wise energy."}
            """
            
        // Generate NPC with embedded image
        let npc = try await session.respond(
            to: prompt,
            generating: NPC.self,
        ).content
        
        return npc
    }
}
```

### 2.3 UI Integration with Generated Images

**File: `CustomerProfileView.swift`**

```swift
struct CustomerProfileView: View {
    var customer: NPC

    var body: some View {
        HStack(alignment: .top) {
            // Generated image display with loading state
            ZStack {
                if let image = customer.picture.image {
                    #if canImport(UIKit)
                    Image(uiImage: UIImage(cgImage: image))
                        .resizable()
                        .accessibilityLabel(customer.picture.imageDescription)
                    #elseif canImport(AppKit)
                    Image(
                        nsImage: NSImage(
                            cgImage: image,
                            size: NSSize(width: image.width, height: image.height)
                        )
                    )
                    .resizable()
                    .accessibilityLabel(customer.picture.imageDescription)
                    #endif
                }
                
                // Loading indicator during generation
                if customer.picture.isResponding {
                    ProgressView()
                }
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: 200, height: 200)

            VStack(alignment: .leading) {
                // Customer details
                LabeledContent("Name:", value: customer.name)
                    .font(.headline)
                    .foregroundStyle(.darkBrown)

                Text(AttributedString(customer.coffeeOrder))
                    .padding(.top)
                    .frame(height: 100)
            }
            .padding()
        }
        .modifier(GameBoxStyle())
    }
}
```

## Part 3: Advanced Patterns and Best Practices

### 3.1 Combining Streaming and Image Generation

Here's a complete example combining both patterns:

```swift
@MainActor
@Observable
final class StreamingImageContentGenerator {
    private(set) var content: StoryContent.PartiallyGenerated?
    private var session: LanguageModelSession
    
    init() {
        self.session = LanguageModelSession(
            instructions: Instructions {
                "Generate story content with accompanying images."
                "Make image descriptions vivid and detailed."
            }
        )
    }
    
    func generateStoryWithImages() async throws {
        let stream = session.streamResponse(
            generating: StoryContent.self,
            options: GenerationOptions(sampling: .greedy)
        ) {
            "Create a fantasy story with character descriptions suitable for image generation."
        }
        
        for try await partialContent in stream {
            self.content = partialContent
            // Images are generated automatically via GenerableImage
        }
    }
}

@Generable
struct StoryContent {
    @Guide(description: "The story title")
    let title: String
    
    @Guide(description: "The main story text")
    let story: String
    
    @Guide(description: "Main character with image")
    let protagonist: Character
    
    @Guide(description: "Supporting characters")
    let supportingCharacters: [Character]
}

@Generable
struct Character {
    let name: String
    let description: String
    let portrait: GenerableImage  // Automatic image generation
}
```

### 3.2 Performance Optimization Strategies

```swift
// 1. Prewarming for better performance
class OptimizedStreamingService {
    private let session: LanguageModelSession
    
    init() {
        self.session = LanguageModelSession()
        // Prewarm immediately
        session.prewarm()
    }
    
    func generateContent() async throws {
        // Faster first generation due to prewarming
        let stream = session.streamResponse(generating: Content.self) {
            "Generate content..."
        }
        
        for try await partial in stream {
            // Handle partial updates
        }
    }
}

// 2. Error handling and retry logic
func robustStreamingGeneration() async throws {
    let maxRetries = 3
    var attempt = 0
    
    while attempt < maxRetries {
        do {
            let stream = session.streamResponse(generating: Content.self) {
                "Generate content..."
            }
            
            for try await partial in stream {
                // Process partial content
                handlePartialUpdate(partial)
            }
            return // Success
            
        } catch {
            attempt += 1
            if attempt >= maxRetries {
                throw error
            }
            // Wait before retry
            try await Task.sleep(for: .seconds(1))
        }
    }
}
```

### 3.3 UI Animation and Transition Best Practices

```swift
struct StreamingContentView: View {
    let content: Content.PartiallyGenerated
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title with smooth transitions
                if let title = content.title {
                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: title)
                }
                
                // Story content with typing effect
                if let story = content.story {
                    Text(story)
                        .font(.body)
                        .contentTransition(.interpolate)
                        .animation(.easeOut(duration: 0.5), value: story)
                }
                
                // Character gallery
                if let characters = content.characters {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))]) {
                        ForEach(characters) { character in
                            CharacterCard(character: character)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.6), value: characters.count)
                }
            }
            .padding()
        }
    }
}

struct CharacterCard: View {
    let character: Character.PartiallyGenerated
    
    var body: some View {
        VStack {
            // Image with loading state
            ZStack {
                if let image = character.portrait?.image {
                    Image(uiImage: UIImage(cgImage: image))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .transition(.opacity.combined(with: .scale))
                } else if character.portrait?.isResponding == true {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(height: 200)
                }
            }
            .frame(height: 200)
            
            // Character name and description
            VStack(alignment: .leading) {
                if let name = character.name {
                    Text(name)
                        .font(.headline)
                        .contentTransition(.opacity)
                }
                
                if let description = character.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}
```

## Part 4: Common Patterns and Troubleshooting

### 4.1 Streaming State Management

```swift
@MainActor
@Observable
final class StreamingState {
    enum GenerationState {
        case idle
        case generating
        case completed
        case failed(Error)
    }
    
    var state: GenerationState = .idle
    var progress: Double = 0.0
    var partialContent: Content.PartiallyGenerated?
    
    func startGeneration() async {
        state = .generating
        progress = 0.0
        
        do {
            let stream = session.streamResponse(generating: Content.self) {
                "Generate content..."
            }
            
            var updateCount = 0
            for try await partial in stream {
                updateCount += 1
                partialContent = partial
                progress = min(Double(updateCount) / 10.0, 1.0) // Estimate progress
            }
            
            state = .completed
        } catch {
            state = .failed(error)
        }
    }
}
```

### 4.2 Memory Management

```swift
// Proper cleanup for streaming operations
class StreamingManager {
    private var currentTask: Task<Void, Error>?
    
    func startStreaming() {
        // Cancel any existing task
        currentTask?.cancel()
        
        currentTask = Task {
            let stream = session.streamResponse(generating: Content.self) {
                "Generate content..."
            }
            
            for try await partial in stream {
                // Check for cancellation
                try Task.checkCancellation()
                await handlePartialUpdate(partial)
            }
        }
    }
    
    func stopStreaming() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    deinit {
        stopStreaming()
    }
}
```

### 4.3 Debugging and Logging

```swift
func debugStreamingGeneration() async throws {
    let stream = session.streamResponse(generating: Content.self) {
        "Generate content..."
    }
    
    var updateCount = 0
    for try await partial in stream {
        updateCount += 1
        
        // Log partial progress
        print("Update \(updateCount):")
        print("  Title: \(partial.title?.prefix(50) ?? "nil")")
        print("  Content length: \(partial.content?.count ?? 0)")
        print("  Images: \(partial.images?.count ?? 0)")
        
        // Track generation completeness
        let completeness = calculateCompleteness(partial)
        print("  Completeness: \(completeness)%")
    }
}

func calculateCompleteness(_ partial: Content.PartiallyGenerated) -> Int {
    var completed = 0
    var total = 0
    
    // Check each expected field
    total += 1; if partial.title != nil { completed += 1 }
    total += 1; if partial.content != nil { completed += 1 }
    total += 1; if partial.images != nil { completed += 1 }
    
    return total > 0 ? (completed * 100) / total : 0
}
```

## Conclusion

This comprehensive guide demonstrates the power of combining streaming generation with ImagePlayground integration. Key takeaways:

1. **Streaming Generation** provides real-time UI updates and better user experience
2. **ImagePlayground Integration** enables seamless text-to-image generation
3. **PartiallyGenerated Types** handle incomplete data gracefully
4. **Performance Optimization** through prewarming and efficient state management
5. **Robust Error Handling** ensures reliable user experience

These patterns enable sophisticated AI-powered applications that feel responsive and engaging while maintaining Apple's high standards for user experience and privacy.