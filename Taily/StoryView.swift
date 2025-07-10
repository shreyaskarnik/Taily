import SwiftUI

struct StoryView: View {
    @ObservedObject var storyGenerator: StoryGenerator
    let parameters: StoryParameters
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    @StateObject private var libraryManager = StoryLibraryManager()
    @State private var modificationText = ""
    @State private var showingModificationField = false
    @State private var showingSaveAlert = false

    // Dynamic image height based on device size
    private var dynamicImageHeight: CGFloat {
        #if canImport(UIKit)
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width

        // For iPad (larger screens)
        if min(screenWidth, screenHeight) > 700 {
            return 350
        }
        // For larger iPhones (iPhone Pro Max, etc.)
        else if screenHeight > 800 {
            return 280
        }
        // For standard iPhones
        else {
            return 250
        }
        #else
        // macOS fallback
        return 300
        #endif
    }

    var body: some View {
        contentView
            .navigationTitle("Bedtime Story")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .onDisappear {
                speechSynthesizer.stopSpeaking()
            }
            .alert("Story Saved!", isPresented: $showingSaveAlert) {
                Button("OK") { }
            } message: {
                Text("Your story has been saved to the library.")
            }
    }

    private var contentView: some View {
        VStack(spacing: 0) {
            // Story content
            ScrollView {
                HStack {
                    Spacer()
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
                                        MarkdownText(
                                            title,
                                            font: .title.bold(),
                                            lineSpacing: 0,
                                            highlightRange: speechSynthesizer.isSpeakingTitle ? speechSynthesizer.currentWordRange : nil
                                        )
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

                                // Story text first
                                if let content = story.content {
                                    MarkdownText(
                                        content,
                                        font: .body.weight(.medium), // Increased font weight
                                        lineSpacing: 8, // Increased line spacing
                                        highlightRange: speechSynthesizer.isSpeakingContent ? speechSynthesizer.currentWordRange : nil
                                    )
                                    .font(.system(size: 17)) // Slightly larger font size
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                    .contentTransition(.opacity)
                                    .animation(.easeInOut(duration: 0.3), value: content)
                                } else {
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                        Text("Writing your story...")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal)
                                    .contentTransition(.opacity)
                                }

                                // Story illustration AFTER the text
                                if let illustration = story.storyIllustration {
                                    HStack {
                                        Spacer()
                                        VStack {
                                            if let image = illustration.image {
                                                #if canImport(UIKit)
                                                Image(uiImage: UIImage(cgImage: image))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(maxHeight: dynamicImageHeight)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .accessibilityLabel(illustration.imageDescription)
                                                    .transition(.opacity.combined(with: .scale))
                                                #elseif canImport(AppKit)
                                                Image(nsImage: NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height)))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(maxHeight: dynamicImageHeight)
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
                                                .frame(height: dynamicImageHeight)
                                                .frame(maxWidth: .infinity)
                                                .background(Color(.systemGray6))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            } else {
                                                VStack(spacing: 12) {
                                                    Image("StoryBookPlaceholder")
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(height: dynamicImageHeight * 0.6)
                                                    VStack(spacing: 4) {
                                                        Text("Story Illustration")
                                                            .font(.caption)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(.secondary)
                                                        Text(illustration.imageDescription)
                                                            .font(.caption2)
                                                            .foregroundColor(.secondary)
                                                            .multilineTextAlignment(.center)
                                                            .lineLimit(2)
                                                    }
                                                }
                                                .frame(height: dynamicImageHeight)
                                                .frame(maxWidth: .infinity)
                                                .background(Color(.systemGray6))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: storyGenerator.generatedStory?.content)
                        } else {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Creating your personalized story...")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .background(Color(UIColor.systemGroupedBackground))

            Spacer()

            // Controls
            HStack {
                Spacer()
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
                .frame(maxWidth: .infinity)
                Spacer()
            }
            .padding(.bottom)
            .background(Color(UIColor.systemGroupedBackground))
        }
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
