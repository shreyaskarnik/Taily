import SwiftUI

struct SavedStoryView: View {
    let savedStory: SavedStory
    @ObservedObject var libraryManager: StoryLibraryManager
    @StateObject private var storyGenerator = StoryGenerator()
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    @State private var modificationText = ""
    @State private var showingModificationField = false
    @State private var showingDeleteAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Debug: Show what story data we have
                if currentStory.title.isEmpty || currentStory.content.isEmpty {
                    VStack {
                        Text("Debug: Story data issue")
                            .foregroundColor(.red)
                        Text("Title: '\(currentStory.title)'")
                        Text("Content length: \(currentStory.content.count)")
                        Text("SavedStory title: '\(savedStory.story.title)'")
                        Text("SavedStory content length: \(savedStory.story.content.count)")
                    }
                    .padding()
                }
                
                // Story content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Story header
                        HStack {
                            VStack(alignment: .leading) {
                                Text("A story for \(savedStory.parameters.childName)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                HStack {
                                    Label(savedStory.parameters.tone.rawValue, systemImage: "sparkles")
                                    Spacer()
                                    Label(savedStory.parameters.setting.rawValue, systemImage: "location")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        Divider()
                        
                        // Story title and emoji
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(currentStory.emoji)
                                    .font(.system(size: 40))
                                HighlightedText(
                                    text: currentStory.title,
                                    highlightRange: speechSynthesizer.isSpeakingTitle ? speechSynthesizer.currentWordRange : nil,
                                    font: .title,
                                    lineSpacing: 0
                                )
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            }
                            .padding(.horizontal)
                            
                            // Story text with highlighting
                            HighlightedText(
                                text: currentStory.content,
                                highlightRange: speechSynthesizer.isSpeakingContent ? speechSynthesizer.currentWordRange : nil,
                                font: .body,
                                lineSpacing: 6
                            )
                            .padding(.horizontal)
                            
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
                        
                        // Story metadata
                        VStack(alignment: .leading, spacing: 8) {
                            Divider()
                                .padding(.top)
                            
                            Text("Story Details")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Created: \(savedStory.dateCreated, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if savedStory.dateModified != savedStory.dateCreated {
                                    Text("Last modified: \(savedStory.dateModified, style: .date)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Values: \(savedStory.parameters.values.map { $0.rawValue }.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Themes: \(savedStory.parameters.themes.map { $0.rawValue }.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
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
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("Saved Story")
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
            .alert("Delete Story", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteStory()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this story? This action cannot be undone.")
            }
            .alert("Error", isPresented: .constant(storyGenerator.errorMessage != nil)) {
                Button("OK") {
                    storyGenerator.errorMessage = nil
                }
            } message: {
                Text(storyGenerator.errorMessage ?? "")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var currentStory: GeneratedStory {
        // Convert partial story to complete story if available, otherwise use saved story
        if let partialStory = storyGenerator.generatedStory,
           let title = partialStory.title,
           let emoji = partialStory.emoji,
           let content = partialStory.content {
            return GeneratedStory(
                title: title,
                emoji: emoji,
                content: content,
                ssmlContent: partialStory.ssmlContent,
                storyIllustration: partialStory.storyIllustration
            )
        }
        return savedStory.story
    }
    
    private func modifyStory() {
        Task {
            await storyGenerator.regenerateStory(with: savedStory.parameters, modification: modificationText)
            
            // If modification was successful, save the updated story
            if let partialStory = storyGenerator.generatedStory,
               let title = partialStory.title,
               let emoji = partialStory.emoji,
               let content = partialStory.content {
                let completeStory = GeneratedStory(
                    title: title,
                    emoji: emoji,
                    content: content,
                    ssmlContent: partialStory.ssmlContent,
                    storyIllustration: partialStory.storyIllustration
                )
                libraryManager.updateStory(savedStory, with: completeStory)
            }
            
            showingModificationField = false
            modificationText = ""
        }
    }
    
    private func toggleSpeech() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.pauseSpeaking()
        } else {
            let story = currentStory
            speechSynthesizer.speakStory(title: story.title, content: story.content, ssmlContent: story.ssmlContent, for: savedStory.parameters.ageGroup)
        }
    }
    
    private func deleteStory() {
        libraryManager.deleteStory(savedStory)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    SavedStoryView(
        savedStory: SavedStory(
            story: GeneratedStory(
                title: "The Brave Little Fox",
                emoji: "🦊",
                content: "Once upon a time, in a magical forest, there lived a brave little fox named Luna...",
                ssmlContent: nil,
                storyIllustration: nil
            ),
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
        ),
        libraryManager: StoryLibraryManager()
    )
}