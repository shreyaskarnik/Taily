import SwiftUI

struct StoryView: View {
    @ObservedObject var storyGenerator: StoryGenerator
    let parameters: StoryParameters
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    @StateObject private var libraryManager = StoryLibraryManager()
    @State private var modificationText = ""
    @State private var showingModificationField = false
    @State private var showingSaveAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Story content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Story header
                        HStack {
                            VStack(alignment: .leading) {
                                Text("A story for \(parameters.childName)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                HStack {
                                    Label(parameters.tone.rawValue, systemImage: "sparkles")
                                    Spacer()
                                    Label(parameters.setting.rawValue, systemImage: "location")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        Divider()
                        
                        // Story content with streaming support
                        if let story = storyGenerator.generatedStory {
                            VStack(alignment: .leading, spacing: 16) {
                                // Title and emoji with streaming animation
                                HStack {
                                    if let emoji = story.emoji {
                                        Text(emoji)
                                            .font(.system(size: 40))
                                            .contentTransition(.opacity)
                                    } else {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    
                                    if let title = story.title {
                                        HighlightedText(
                                            text: title,
                                            highlightRange: speechSynthesizer.isSpeakingTitle ? speechSynthesizer.currentWordRange : nil,
                                            font: .title,
                                            lineSpacing: 0
                                        )
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                        .contentTransition(.opacity)
                                    } else {
                                        Text("Creating your story...")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.secondary)
                                            .contentTransition(.opacity)
                                    }
                                }
                                .padding(.horizontal)
                                .animation(.easeInOut(duration: 0.3), value: story.title)
                                .animation(.easeInOut(duration: 0.3), value: story.emoji)
                                
                                // Story illustration with loading state
                                if let illustration = story.storyIllustration {
                                    VStack {
                                        if let image = illustration.image {
                                            #if canImport(UIKit)
                                            Image(uiImage: UIImage(cgImage: image))
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxHeight: 200)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .accessibilityLabel(illustration.imageDescription)
                                                .transition(.opacity.combined(with: .scale))
                                            #elseif canImport(AppKit)
                                            Image(nsImage: NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height)))
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxHeight: 200)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .accessibilityLabel(illustration.imageDescription)
                                                .transition(.opacity.combined(with: .scale))
                                            #endif
                                        } else if illustration.isResponding {
                                            VStack(spacing: 12) {
                                                ProgressView()
                                                    .scaleEffect(1.2)
                                                Text("Creating illustration...")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(height: 200)
                                            .frame(maxWidth: .infinity)
                                            .background(Color(.systemGray6))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        } else {
                                            // Show custom storybook placeholder when image generation isn't available
                                            VStack(spacing: 12) {
                                                Image("StoryBookPlaceholder")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(height: 120)
                                                VStack(spacing: 4) {
                                                    Text("Story Illustration")
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.secondary)
                                                    Text(illustration.imageDescription)
                                                        .font(.caption2)
                                                        .foregroundColor(
                                                            .secondary
                                                        )
                                                        .multilineTextAlignment(.center)
                                                        .lineLimit(2)
                                                }
                                            }
                                            .frame(height: 200)
                                            .frame(maxWidth: .infinity)
                                            .background(Color(.systemGray6))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                    .padding(.horizontal)
                                } else if storyGenerator.isGenerating {
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                        Text("Preparing illustration...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal)
                                }
                                
                                // Show image for saved stories
                                if let savedStory = storyGenerator.generatedStory, savedStory.storyIllustration == nil {
                                    // If this is a saved story being displayed, show a placeholder or default image
                                    VStack(spacing: 12) {
                                        Image("StoryBookPlaceholder")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 120)
                                        Text("Story illustration")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal)
                                }
                                
                                // Story text with streaming animation
                                if let content = story.content {
                                    HighlightedText(
                                        text: content,
                                        highlightRange: speechSynthesizer.isSpeakingContent ? speechSynthesizer.currentWordRange : nil,
                                        font: .body,
                                        lineSpacing: 6
                                    )
                                    .padding(.horizontal)
                                    .contentTransition(.interpolate)
                                    .animation(.easeOut(duration: 0.5), value: content)
                                } else if storyGenerator.isGenerating {
                                    VStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                        Text("Crafting your story...")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 40)
                                }
                                
                                // Reading progress indicator
                                if speechSynthesizer.isSpeaking {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Text("Reading Progress")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("\(Int(speechSynthesizer.speechProgress * 100))%")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        ProgressView(value: speechSynthesizer.speechProgress)
                                            .tint(.blue)
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                }
                            }
                        } else if storyGenerator.isGenerating {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Creating your magical story...")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 60)
                        }
                    }
                }
                
                // Controls
                VStack(spacing: 12) {
                    if showingModificationField {
                        HStack {
                            TextField("How would you like to modify the story?", text: $modificationText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Apply") {
                                modifyStory()
                            }
                            .disabled(modificationText.isEmpty || storyGenerator.isGenerating)
                            
                            Button("Cancel") {
                                showingModificationField = false
                                modificationText = ""
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            Button(action: {
                                showingModificationField.toggle()
                            }) {
                                Label("Edit", systemImage: "pencil")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(10)
                            }
                            .disabled(storyGenerator.isGenerating)
                            
                            Button(action: toggleSpeech) {
                                Label(
                                    speechSynthesizer.isSpeaking ? "Pause" : "Read Story",
                                    systemImage: speechSynthesizer.isSpeaking ? "pause.fill" : "play.fill"
                                )
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(10)
                            }
                            .disabled(storyGenerator.generatedStory?.content == nil)
                        }
                        
                        // Save button
                        Button(action: saveStory) {
                            Label("Save Story", systemImage: "heart.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(10)
                        }
                        .disabled(storyGenerator.generatedStory?.content == nil)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("Bedtime Story")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    speechSynthesizer.stopSpeaking()
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onDisappear {
                speechSynthesizer.stopSpeaking()
            }
            .alert("Story Saved!", isPresented: $showingSaveAlert) {
                Button("OK") { }
            } message: {
                Text("Your story has been saved to the library.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func modifyStory() {
        Task {
            await storyGenerator.regenerateStory(with: parameters, modification: modificationText)
            showingModificationField = false
            modificationText = ""
        }
    }
    
    private func toggleSpeech() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.pauseSpeaking()
        } else {
            if let story = storyGenerator.generatedStory,
               let title = story.title,
               let content = story.content {
                speechSynthesizer.speakStory(title: title, content: content, ssmlContent: story.ssmlContent, for: parameters.ageGroup)
            }
        }
    }
    
    private func saveStory() {
        guard let partialStory = storyGenerator.generatedStory,
              let title = partialStory.title,
              let emoji = partialStory.emoji,
              let content = partialStory.content else { return }
        
        // Create a complete story from the partial one
        let completeStory = GeneratedStory(
            title: title,
            emoji: emoji,
            content: content,
            ssmlContent: partialStory.ssmlContent,
            storyIllustration: partialStory.storyIllustration
        )
        
        libraryManager.saveStory(completeStory, parameters: parameters)
        showingSaveAlert = true
    }
}

#Preview {
    StoryView(
        storyGenerator: StoryGenerator(),
        parameters: StoryParameters(
            childName: "Emma",
            ageGroup: .preschool,
            gender: .girl,
            values: [.kindness, .bravery],
            themes: [.animals, .fairy],
            setting: .forest,
            tone: .calming,
            length: .medium,
            customNotes: "Loves unicorns and rainbow colors"
        )
    )
}
