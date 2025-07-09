// NOTE: Image generation optimized for Apple ImagePlayground compatibility
// by focusing on magical environments and creatures rather than human characters

import Foundation
import SwiftUI
import NaturalLanguage

#if canImport(FoundationModels)
    import FoundationModels
#endif

#if canImport(ImagePlayground)
    import ImagePlayground
#endif

#if canImport(FoundationModels) && canImport(ImagePlayground)
    @available(iOS 26.0, *)
    @MainActor
    @Observable
    final class GenerableImage: Generable, Equatable {

        nonisolated static func == (lhs: GenerableImage, rhs: GenerableImage)
            -> Bool
        {
            lhs === rhs
        }

        @Guide(
            description:
                "A vivid, child-friendly description of an illustration for a bedtime story. Focus ONLY on magical settings, enchanted objects, fantasy creatures, woodland animals, and atmospheric elements. NEVER include human characters of any age (no children, people, boys, girls, etc.). Use whimsical accessories, colorful environments, and magical elements that create a peaceful, story-book atmosphere. Examples: enchanted forests, magical creatures, glowing objects, friendly animals, castles, starry skies."
        )
        let imageDescription: String

        var isResponding: Bool { task != nil }
        private(set) var image: CGImage?

        private var task: Task<Void, Error>?

        nonisolated static var generationSchema: GenerationSchema {
            GenerationSchema(
                type: GenerableImage.self,
                description:
                    "A description of an illustration to accompany a bedtime story. The description should be colorful, whimsical, and child-friendly.",
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
            let rawDescription = try content.value(forProperty: "imageDescription") as String
            self.imageDescription = rawDescription
            print("Original description: \(rawDescription)")
            Task { @MainActor in
                await self.sanitizeAndGenerateImage()
            }
        }

        // Manual initialization for testing
        init(imageDescription: String) {
            self.imageDescription = imageDescription
            Task { 
                await self.sanitizeAndGenerateImage()
            }
        }
        
        // Use Foundation Model to sanitize illustration descriptions
        @MainActor
        private func sanitizeAndGenerateImage() async {
            let sanitizedDescription = await sanitizeWithFoundationModel(self.imageDescription)
            print("Sanitized description: \(sanitizedDescription)")
            
            // Now generate the image with the clean description
            do {
                try generateImage(with: sanitizedDescription)
            } catch {
                print("Image generation failed: \(error)")
            }
        }
        
        private func sanitizeWithFoundationModel(_ description: String) async -> String {
            #if canImport(FoundationModels)
            // iOS 26.0 availability already checked by class declaration
            
            let model = SystemLanguageModel.default
            guard model.availability == .available else {
                return fallbackSanitize(description)
            }
            
            do {
                let instructions = Instructions(
                    """
                    You are a text sanitizer that removes human characters from image descriptions.
                    Your job is to take an image description and remove ALL references to humans while keeping the environment and setting.
                    
                    RULES:
                    - Remove ALL human characters (children, people, boys, girls, wizards, fairies, etc.)
                    - Remove ALL names and character references
                    - Keep magical environments, animals, objects, and atmospheric elements
                    - Maintain the magical and whimsical tone
                    - Output only the cleaned description, nothing else
                    """
                )
                
                let session = LanguageModelSession(instructions: instructions)
                
                let prompt = """
                    Clean this image description by removing all human characters and names:
                    
                    "\(description)"
                    
                    Return only the cleaned description focusing on the magical environment and setting.
                    """
                
                let response = try await session.respond(to: prompt)
                let sanitized = response.content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                return sanitized.isEmpty ? fallbackSanitize(description) : sanitized
                
            } catch {
                print("Foundation model sanitization failed: \(error)")
                return fallbackSanitize(description)
            }
            #else
            return fallbackSanitize(description)
            #endif
        }
        
        private func fallbackSanitize(_ description: String) -> String {
            // Simple fallback sanitization
            var sanitized = description
            
            let problematicPatterns = [
                "a little girl", "a little boy", "a child", "children",
                "a person", "people", "someone", "anyone",
                "a wizard", "a fairy", "Tilly", "Danny",
                "explores", "with a friend"
            ]
            
            for pattern in problematicPatterns {
                sanitized = sanitized.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
            }
            
            // Clean up extra spaces
            sanitized = sanitized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if sanitized.isEmpty || sanitized.count < 20 {
                sanitized = "A magical enchanted forest with glowing mushrooms, sparkling streams, and gentle woodland creatures beneath ancient trees."
            }
            
            return sanitized
        }

        private func generateImage(with description: String) throws {
            task?.cancel()
            task = Task {
                do {
                    let generator = try await ImageCreator()
//                    guard let imageStyle = generator.availableStyles.first
                    let imageStyle: ImagePlaygroundStyle = .animation
//                    else {
//                        return
//                    }

                    let generations = generator.images(
                        for: [.text(description)],
                        style: imageStyle,
                        limit: 1
                    )

                    for try await generation in generations {
                        self.image = generation.cgImage
                        self.task = nil
                        return
                    }

                } catch let error {
                    self.task = nil
                    print(
                        "Image generation failed for prompt: \(description). Error: \(error)"
                    )
                    // Don't throw error to prevent crashes - just leave image as nil
                }
            }
        }

        // Manually retry image generation
        func retryGeneration() async throws {
            let sanitizedDescription = await sanitizeWithFoundationModel(self.imageDescription)
            try generateImage(with: sanitizedDescription)
        }
    }
#else
    // Fallback implementation when ImagePlayground or FoundationModels are not available
    @MainActor
    @Observable
    final class GenerableImage: Equatable {

        // Equality implementation for Observable
        nonisolated static func == (lhs: GenerableImage, rhs: GenerableImage)
            -> Bool
        {
            lhs === rhs
        }

        let imageDescription: String
        var isResponding: Bool { false }
        private(set) var image: CGImage?

        init(imageDescription: String) {
            self.imageDescription = imageDescription
            self.image = nil
        }

        func retryGeneration() async {
            // No-op for fallback
        }
    }
#endif
