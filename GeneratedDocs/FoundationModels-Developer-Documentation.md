# FoundationModels Framework - Developer Documentation

## Overview
The FoundationModels framework provides a comprehensive set of tools for integrating AI-powered features into iOS applications. This documentation analyzes two sample projects demonstrating key concepts and usage patterns.

## Project Structure Analysis

### Project 1: Trip Planner (`AddingIntelligentAppFeaturesWithGenerativeModels`)
- **Purpose**: Demonstrates structured generation for travel itinerary planning
- **Key Features**: Tool integration, streaming responses, structured data generation
- **Files with FoundationModels**: 7 Swift files

### Project 2: Coffee Game (`GenerateDynamicGameContentWithGuidedGenerationAndTools`)  
- **Purpose**: Shows dynamic game content generation with AI
- **Key Features**: Character generation, dialog systems, image generation
- **Files with FoundationModels**: 9 Swift files

## Core Framework Components

### 1. LanguageModelSession
Central class for managing AI conversations and generation tasks.

```swift
// Basic initialization
let session = LanguageModelSession()

// With tools and instructions
let session = LanguageModelSession(
    tools: [pointOfInterestTool],
    instructions: Instructions {
        "Your job is to create an itinerary for the user."
        "Each day needs an activity, hotel and restaurant."
    }
)
```

**Key Methods:**
- `session.respond(to: String)` - Synchronous response generation
- `session.streamResponse(generating: Type.self)` - Streaming partial generation
- `prewarm()` - Optimization for repeated use

### 2. SystemLanguageModel
Handles model availability and specialized use cases.

```swift
// Default model
let model = SystemLanguageModel.default

// Specialized models
let contentTaggingModel = SystemLanguageModel(useCase: .contentTagging)

// Availability checking
switch model.availability {
case .available:
    // Model ready for use
case .unavailable(.appleIntelligenceNotEnabled):
    // Handle unavailable state
}
```

**Use Cases:**
- `.contentTagging` - Specialized for content analysis
- `.default` - General purpose model

### 3. @Generable Decorator
Marks types for structured AI generation.

```swift
@Generable
struct Itinerary: Equatable {
    let title: String
    let destinationName: String
    let days: [DayPlan]
}

@Generable
enum Category: String, CaseIterable {
    case campground, hotel, cafe, museum, marina, restaurant, nationalMonument
}
```

**Requirements:**
- Must be applied to structs, enums, or classes
- Properties should be simple types (String, Int, Array, etc.)
- Can be nested for complex structures

### 4. @Guide Decorator
Provides generation guidance and constraints.

```swift
@Guide(description: "An exciting name for the trip.")
let title: String

@Guide(.anyOf(ModelData.landmarkNames))
let destinationName: String

@Guide(.count(3))
let days: [DayPlan]

@Guide(description: "Avoid descriptions that look human-like. Stick to animals, plants, or objects.")
let imageDescription: String
```

**Constraint Types:**
- `.anyOf(array)` - Must be one of the provided values
- `.count(n)` - Must have exactly n items
- `description: String` - Natural language guidance

### 5. Tool Protocol
Enables function calling within AI sessions.

```swift
struct FindPointsOfInterestTool: Tool {
    let name = "findPointsOfInterest"
    
    @Generable
    struct Arguments {
        @Guide(description: "This is the type of destination to look up for.")
        let pointOfInterest: Category
        
        @Guide(description: "The natural language query of what to search for.")
        let naturalLanguageQuery: String
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        // Implementation logic
        return ToolOutput(results)
    }
}
```

**Components:**
- `name` - Tool identifier
- `Arguments` - @Generable struct for parameters
- `call()` - Implementation method returning ToolOutput

## Advanced Patterns

### 1. Streaming Generation
For real-time UI updates during generation:

```swift
let stream = session.streamResponse(
    generating: Itinerary.self,
    options: GenerationOptions(sampling: .greedy),
    includeSchemaInPrompt: false
) {
    "Generate a \(dayCount)-day itinerary to \(landmark.name)."
}

for try await partialItinerary in stream {
    // Update UI with partial results
    self.itinerary = partialItinerary
}
```

### 2. Custom Generable Implementation
For advanced control over generation:

```swift
@MainActor
@Observable
final class GenerableImage: Generable, Equatable {
    @Guide(description: "Avoid descriptions that look human-like.")
    let imageDescription: String
    
    nonisolated static var generationSchema: GenerationSchema {
        GenerationSchema(
            type: GenerableImage.self,
            description: "A description of an image to be given to a image generation model.",
            properties: [
                GenerationSchema.Property(
                    name: "imageDescription",
                    type: String.self
                )
            ]
        )
    }
    
    nonisolated var generatedContent: GeneratedContent {
        GeneratedContent(properties: [
            "imageDescription": imageDescription
        ])
    }
    
    nonisolated init(_ content: GeneratedContent) throws {
        self.imageDescription = try content.value(forProperty: "imageDescription")
        // Custom initialization logic
    }
}
```

### 3. Multi-turn Conversations
For dialog systems:

```swift
let session = LanguageModelSession(
    tools: [CalendarTool(contactName: customer.displayName)],
    instructions: instructions
)

let response = try await session.respond(to: userInput)
// Session maintains conversation context
```

## Integration with ImagePlayground

The framework seamlessly integrates with ImagePlayground for image generation:

```swift
import ImagePlayground

let generator = try await ImageCreator()
let generations = generator.images(
    for: [.text(imageDescription)],
    style: imageStyle,
    limit: 1
)

for try await generation in generations {
    self.image = generation.cgImage
}
```

## Configuration and Options

### GenerationOptions
```swift
GenerationOptions(
    sampling: .greedy,          // Deterministic output
    temperature: 0.7,           // Creativity control
    topP: 0.9,                  // Token filtering
    maxTokens: 1000            // Response length limit
)
```

### Instructions Builder
```swift
Instructions {
    "Your job is to create an itinerary for the user."
    "Each day needs an activity, hotel and restaurant."
    "Be creative but practical."
}
```

## Error Handling

```swift
do {
    let response = try await session.respond(to: prompt)
    // Handle success
} catch let error as LanguageModelError {
    // Handle specific language model errors
} catch {
    // Handle general errors
}
```

## Best Practices

### 1. Session Management
- Use `prewarm()` for performance optimization
- Reuse sessions for related tasks
- Consider memory implications of long conversations

### 2. @Guide Usage
- Be specific and descriptive
- Use constraints to ensure valid output
- Test with various inputs to verify behavior

### 3. Tool Design
- Keep tools focused on single responsibilities
- Provide clear descriptions and examples
- Handle errors gracefully

### 4. Performance
- Use streaming for long generations
- Batch related operations when possible
- Consider user experience during generation

### 5. Model Availability
- Always check model availability before use
- Provide fallback experiences
- Handle different unavailable states appropriately

## File Location Reference

### Trip Planner Project Files:
- `FindPointsOfInterestTool.swift:1` - Tool implementation
- `Itinerary.swift:1` - Core @Generable structures
- `ItineraryPlanner.swift:1` - Session management and streaming
- `ItineraryView.swift:1` - UI integration with PartiallyGenerated types
- `LandmarkDescriptionView.swift:1` - Specialized model usage
- `LandmarkTripView.swift:1` - Session prewarming
- `TripPlanningView.swift:1` - Availability checking

### Coffee Game Project Files:
- `Characters.swift:1` - Character generation structures
- `DialogEngine.swift:1` - Multi-turn conversation handling
- `EncounterEngine.swift:1` - Game event generation
- `GenerableImage.swift:1` - Custom Generable implementation with ImagePlayground
- `MainMenuView.swift:1` - Model availability UI
- `CoffeeShopScene.swift:1` - Game engine integration
- `RandomCustomerGenerator.swift:1` - Dynamic character creation
- `CalendarTool.swift:1` - Calendar integration tool
- `ContactsTool.swift:1` - Contacts integration tool

## Common Patterns Summary

1. **Session Initialization**: `LanguageModelSession` with optional tools and instructions
2. **Structured Generation**: `@Generable` types with `@Guide` constraints
3. **Streaming**: Real-time UI updates with `streamResponse()`
4. **Tool Integration**: Function calling with `Tool` protocol
5. **Model Management**: Availability checking and specialization
6. **Error Handling**: Comprehensive error management
7. **Performance**: Prewarming and optimization strategies