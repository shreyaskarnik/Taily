import SwiftUI
import Lottie

struct StoryView: View {
    @ObservedObject var storyGenerator: StoryGenerator
    let parameters: StoryParameters
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    @StateObject private var libraryManager = StoryLibraryManager()
    @State private var modificationText = ""
    @State private var showingModificationField = false
    @State private var showingSaveAlert = false
    
    // Environment for responsive design
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    // Dynamic image height based on device size and content area
    private var dynamicImageHeight: CGFloat {
        #if canImport(UIKit)
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        let minDimension = min(screenWidth, screenHeight)

        // For iPad and large screens - scale based on available width
        if minDimension > 700 {
            // On iPad, limit image to a percentage of available space
            let maxImageWidth = min(600, screenWidth * 0.7)
            let aspectRatio: CGFloat = 16/9 // Assume landscape aspect ratio
            return min(350, maxImageWidth / aspectRatio)
        }
        // For iPhone Pro Max and similar large phones
        else if screenHeight > 850 {
            return 300
        }
        // For iPhone Pro and similar medium phones  
        else if screenHeight > 800 {
            return 280
        }
        // For standard and smaller iPhones
        else {
            return 250
        }
        #else
        // macOS fallback
        return 350
        #endif
    }
    
    // Dynamic max width for the image container
    private var dynamicImageMaxWidth: CGFloat {
        #if canImport(UIKit)
        let screenWidth = UIScreen.main.bounds.width
        let minDimension = min(screenWidth, UIScreen.main.bounds.height)
        
        // For iPad and large screens
        if minDimension > 700 {
            return min(600, screenWidth * 0.7)
        } else {
            return screenWidth - 48 // Account for padding
        }
        #else
        return 600
        #endif
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular && verticalSizeClass == .regular {
                // iPad layout - side by side
                polishedIPadLayout
            } else {
                // iPhone layout - vertical stack
                iPhoneLayout
            }
        }
//        .navigationTitle("Bedtime Story")
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

    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            // Story content
            ScrollView {
                HStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 16) {
                        // Story title as main heading
                        VStack(alignment: .leading, spacing: 8) {
                            if let title = storyGenerator.currentStory?.title {
                                Text(title)
                                    .font(.title.weight(.bold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                HStack {
                                    Text("Created for \(parameters.childName)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Label(parameters.tone.rawValue, systemImage: "sparkles")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Creating your story...")
                                    .font(.title)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text("For \(parameters.childName)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        Divider()

                        // Story content with streaming support
                        if let story = storyGenerator.currentStory {
                            VStack(alignment: .leading, spacing: 16) {
                                // Title and emoji with streaming animation
                                HStack {
                                    Text(story.emoji)
                                        .font(.system(size: 40))
                                        .contentTransition(.opacity)

                                }
                                .padding(.horizontal)
                                .animation(.easeInOut(duration: 0.3), value: story.title)
                                .animation(.easeInOut(duration: 0.3), value: story.emoji)

                                // Story text with streaming animation and markdown formatting
                                if !story.content.isEmpty {
                                    MarkdownText(
                                        story.content,
                                        font: .body,
                                        lineSpacing: 6,
                                        highlightRange: speechSynthesizer.isSpeakingContent ? speechSynthesizer.currentWordRange : nil
                                    )
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                    .contentTransition(.opacity)
                                    .animation(.easeInOut(duration: 0.3), value: story.content)
                                } else {
                                    StoryCreationLoadingView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal)
                                    .contentTransition(.opacity)
                                }

                                // Story illustration with loading state
                                if let illustration = story.storyIllustration {
                                    VStack {
                                        if let image = illustration.image {
                                            #if canImport(UIKit)
                                            Image(uiImage: UIImage(cgImage: image))
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxWidth: dynamicImageMaxWidth, maxHeight: dynamicImageHeight)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                                .accessibilityLabel(illustration.imageDescription)
                                                .transition(.opacity.combined(with: .scale))
                                            #elseif canImport(AppKit)
                                            Image(nsImage: NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height)))
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxWidth: dynamicImageMaxWidth, maxHeight: dynamicImageHeight)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                                .accessibilityLabel(illustration.imageDescription)
                                                .transition(.opacity.combined(with: .scale))
                                            #endif
                                        } else if illustration.isResponding {
                                            IllustrationLoadingView()
                                            .frame(maxWidth: dynamicImageMaxWidth, maxHeight: dynamicImageHeight)
                                            .background(Color(.systemGray6))
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        } else {
                                            // Show custom storybook placeholder when image generation isn't available
                                            VStack(spacing: 12) {
                                                Image("StoryBookPlaceholder")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(maxWidth: dynamicImageMaxWidth * 0.6, maxHeight: dynamicImageHeight * 0.6)
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
                                            .frame(maxWidth: dynamicImageMaxWidth, maxHeight: dynamicImageHeight)
                                            .background(Color(.systemGray6))
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        }
                                    }
                                    .padding(.horizontal)
                                } else if storyGenerator.isGenerating {
                                    IllustrationLoadingView()
                                    .frame(maxWidth: dynamicImageMaxWidth, maxHeight: dynamicImageHeight)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal)
                                }

                                // Show image for saved stories
                                if let savedStory = storyGenerator.currentStory, savedStory.storyIllustration == nil {
                                    // If this is a saved story being displayed, show a placeholder or default image
                                    VStack(spacing: 12) {
                                        Image("StoryBookPlaceholder")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: dynamicImageMaxWidth * 0.6, maxHeight: dynamicImageHeight * 0.6)
                                        Text("Story illustration")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: dynamicImageMaxWidth, maxHeight: dynamicImageHeight)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal)
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: storyGenerator.currentStory?.content)
                        } else {
                            // Initial loading state
                            StoryCreationLoadingView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading) // Use full width available on iPad
                        .padding(.horizontal, 24) // Increased horizontal padding for better spacing
                        Spacer()
                    }
                    .padding(.horizontal, 24) // Increased horizontal padding for better spacing
                }
                .background(Color(UIColor.systemGroupedBackground))

                // Spacer for better visual separation
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

                                HStack {
                                    // Add small Dozzi character during story reading
                                    if speechSynthesizer.isSpeaking {
                                        LottieDozziView(
                                            currentAnimation: .constant(.reading),
                                            mood: .constant(.sleepy)
                                        )
                                        .frame(width: 40, height: 40)
                                    }
                                    
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
                                    .disabled(storyGenerator.currentStory?.content == nil)
                                }
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
                            .disabled(storyGenerator.currentStory?.content == nil)
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity) // Use full width for controls on iPad
                    Spacer()
                }
                .padding(.bottom)
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
    
    private var iPadLayout: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left side - Story content (60% of width)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Story title and header
                        VStack(alignment: .leading, spacing: 8) {
                            if let title = storyGenerator.currentStory?.title {
                                Text(title)
                                    .font(.largeTitle.weight(.bold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                HStack {
                                    Text("Created for \(parameters.childName)")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Label(parameters.tone.rawValue, systemImage: "sparkles")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Creating your story...")
                                    .font(.largeTitle)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text("For \(parameters.childName)")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                        
                        // Story content
                        VStack(alignment: .leading, spacing: 16) {
                            if let story = storyGenerator.currentStory {
                                // Emoji
                                Text(story.emoji)
                                    .font(.system(size: 60))
                                    .contentTransition(.opacity)
                                
                                // Story text - FULL CONTENT ON IPAD
                                if !story.content.isEmpty {
                                    MarkdownText(
                                        story.content,
                                        font: .title3,
                                        lineSpacing: 8,
                                        highlightRange: speechSynthesizer.isSpeaking ? speechSynthesizer.currentWordRange : nil
                                    )
                                    .foregroundColor(.primary)
                                    .contentTransition(.opacity)
                                    .animation(.easeInOut(duration: 0.3), value: story.content)
                                } else {
                                    StoryCreationLoadingView()
                                }
                            } else {
                                StoryCreationLoadingView()
                            }
                        }
                        .padding(.horizontal)
                        
                        // Controls
                        VStack(spacing: 16) {
                            if showingModificationField {
                                HStack {
                                    TextField("How would you like to modify the story?", text: $modificationText)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Button("Apply") {
                                        modifyStory()
                                    }
                                    .disabled(modificationText.isEmpty)
                                    
                                    Button("Cancel") {
                                        showingModificationField = false
                                        modificationText = ""
                                    }
                                }
                            }
                            
                            HStack(spacing: 16) {
                                // Speech controls
                                HStack {
                                    if speechSynthesizer.isSpeaking {
                                        LottieDozziView(
                                            currentAnimation: .constant(.reading),
                                            mood: .constant(.sleepy)
                                        )
                                        .frame(width: 40, height: 40)
                                    }
                                    
                                    Button(action: toggleSpeech) {
                                        Label(
                                            speechSynthesizer.isSpeaking ? "Pause" : "Read Story",
                                            systemImage: speechSynthesizer.isSpeaking ? "pause.fill" : "play.fill"
                                        )
                                    }
                                    .disabled(storyGenerator.currentStory?.content == nil)
                                }
                                
                                Button("Modify Story") {
                                    showingModificationField.toggle()
                                }
                                .disabled(storyGenerator.isGenerating)
                                
                                Button("Save Story") {
                                    saveStory()
                                }
                                .disabled(storyGenerator.currentStory?.content == nil)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
                .frame(width: geometry.size.width * 0.6)
                .background(Color(UIColor.systemGroupedBackground))
                
                // Right side - Illustration (40% of width)
                VStack {
                    if let story = storyGenerator.currentStory {
                        if let illustration = story.storyIllustration {
                            #if canImport(UIKit)
                            if let cgImage = illustration.image {
                                Image(uiImage: UIImage(cgImage: cgImage))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .accessibilityLabel(illustration.imageDescription)
                            }
                            #endif
                        } else if story.storyIllustration?.isResponding == true {
                            IllustrationLoadingView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else if storyGenerator.isGenerating {
                            IllustrationLoadingView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            // Show Lottie Dozzi reading for completed stories without illustrations
                            VStack(spacing: 20) {
                                LottieDozziView(
                                    currentAnimation: .constant(.reading),
                                    mood: .constant(.sleepy)
                                )
                                .frame(width: 100, height: 100)
                                
                                VStack(spacing: 8) {
                                    Text("Story Complete")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Your magical bedtime story is ready to enjoy!")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    } else {
                        // Show Lottie Dozzi creating story for iPad
                        VStack(spacing: 30) {
                            LottieDozziView(
                                currentAnimation: .constant(.magic),
                                mood: .constant(.magical)
                            )
                            .frame(width: 120, height: 120)
                            
                            VStack(spacing: 12) {
                                Text("Creating Your Story")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Dozzi is crafting a magical bedtime story just for you...")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(width: geometry.size.width * 0.4)
                .padding()
            }
        }
    }
    
    private var polishedIPadLayout: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Elegant header section
                VStack(alignment: .leading, spacing: 16) {
                    if let title = storyGenerator.currentStory?.title {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(title)
                                .font(.system(size: 42, weight: .bold, design: .serif))
                                .foregroundStyle(.primary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                            
                            HStack(spacing: 16) {
                                Label("For \(parameters.childName)", systemImage: "heart.fill")
                                    .font(.title2.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                    Text(parameters.tone.rawValue)
                                }
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.purple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.purple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Creating your magical story...")
                                .font(.system(size: 36, weight: .semibold, design: .serif))
                                .foregroundStyle(.primary)
                            
                            Text("For \(parameters.childName)")
                                .font(.title.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Elegant divider
                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 1)
                
                // Story content section
                VStack(alignment: .leading, spacing: 32) {
                    if let story = storyGenerator.currentStory {
                        // Story emoji and content
                        VStack(alignment: .leading, spacing: 24) {
                            HStack {
                                Text(story.emoji)
                                    .font(.system(size: 80))
                                    .contentTransition(.opacity)
                                Spacer()
                            }
                            
                            if !story.content.isEmpty {
                                MarkdownText(
                                    story.content,
                                    font: .system(size: 20, weight: .regular, design: .serif),
                                    lineSpacing: 14,
                                    highlightRange: speechSynthesizer.isSpeaking ? speechSynthesizer.currentWordRange : nil
                                )
                                .foregroundStyle(.primary)
                                .contentTransition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: story.content)
                            } else {
                                VStack(spacing: 24) {
                                    LottieDozziView(
                                        currentAnimation: .constant(.thinking),
                                        mood: .constant(.magical)
                                    )
                                    .frame(width: 100, height: 100)
                                    
                                    Text("Crafting your story with care...")
                                        .font(.title2.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                        }
                        
                        // Illustration section - integrated below story
                        if !story.content.isEmpty {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Story Illustration")
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                
                                if let illustration = story.storyIllustration {
                                    #if canImport(UIKit)
                                    if let cgImage = illustration.image {
                                        Image(uiImage: UIImage(cgImage: cgImage))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxHeight: 400)
                                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                            .background(
                                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                    .fill(.regularMaterial)
                                                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                                            )
                                            .accessibilityLabel(illustration.imageDescription)
                                    }
                                    #endif
                                } else if story.storyIllustration?.isResponding == true {
                                    VStack(spacing: 20) {
                                        IllustrationLoadingView()
                                            .frame(width: 80, height: 80)
                                        
                                        Text("Creating your story's illustration...")
                                            .font(.title3.weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .fill(.regularMaterial)
                                                .opacity(0.7)
                                            
                                            LinearGradient(
                                                colors: [.purple.opacity(0.1), .blue.opacity(0.08)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            
                                            LinearGradient(
                                                colors: [.white.opacity(0.2), .clear],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            .blendMode(.overlay)
                                        }
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                                } else if storyGenerator.isGenerating {
                                    // Show loading while story generation is still in progress
                                    VStack(spacing: 20) {
                                        LottieDozziView(
                                            currentAnimation: .constant(.magic),
                                            mood: .constant(.magical)
                                        )
                                        .frame(width: 80, height: 80)
                                        
                                        Text("Creating your story's illustration...")
                                            .font(.title3.weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .fill(.regularMaterial)
                                                .opacity(0.7)
                                            
                                            LinearGradient(
                                                colors: [.purple.opacity(0.1), .blue.opacity(0.08)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            
                                            LinearGradient(
                                                colors: [.white.opacity(0.2), .clear],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            .blendMode(.overlay)
                                        }
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                                } else {
                                    // Beautiful placeholder for completed stories
                                    VStack(spacing: 24) {
                                        ZStack {
                                            Circle()
                                                .fill(.white.opacity(0.9))
                                                .frame(width: 120, height: 120)
                                                .shadow(color: .purple.opacity(0.2), radius: 15, x: 0, y: 8)
                                            
                                            Image(systemName: "book.closed.fill")
                                                .font(.system(size: 50, weight: .medium))
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [.purple, .blue],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        }
                                        
                                        VStack(spacing: 8) {
                                            Text("Story Complete!")
                                                .font(.title.weight(.bold))
                                                .foregroundStyle(.primary)
                                            
                                            Text("Your magical bedtime story is ready to enchant and delight.")
                                                .font(.body)
                                                .foregroundStyle(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .fill(.regularMaterial)
                                                .opacity(0.8)
                                            
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.95, green: 0.92, blue: 1.0).opacity(0.6),
                                                    Color(red: 0.92, green: 0.95, blue: 1.0).opacity(0.4)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            
                                            LinearGradient(
                                                colors: [.white.opacity(0.3), .clear],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            .blendMode(.overlay)
                                        }
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    } else {
                        // Loading state for story creation
                        VStack(spacing: 32) {
                            ZStack {
                                Circle()
                                    .stroke(.purple.opacity(0.2), lineWidth: 3)
                                    .frame(width: 140, height: 140)
                                
                                Circle()
                                    .fill(.white.opacity(0.9))
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .purple.opacity(0.2), radius: 20, x: 0, y: 10)
                                
                                LottieDozziView(
                                    currentAnimation: .constant(.magic),
                                    mood: .constant(.magical)
                                )
                                .frame(width: 90, height: 90)
                            }
                            
                            VStack(spacing: 16) {
                                Text("Crafting Magic")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                
                                VStack(spacing: 8) {
                                    Text("Weaving a magical tale for")
                                        .font(.title3.weight(.medium))
                                        .foregroundStyle(.secondary)
                                    
                                    Text(parameters.childName)
                                        .font(.title.weight(.bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.purple, .blue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                                .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 80)
                    }
                }
                
                // Controls section
                VStack(spacing: 24) {
                    if showingModificationField {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Modify Your Story")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            HStack(spacing: 12) {
                                TextField("How would you like to modify the story?", text: $modificationText)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body)
                                
                                Button("Apply") {
                                    modifyStory()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(modificationText.isEmpty)
                                
                                Button("Cancel") {
                                    showingModificationField = false
                                    modificationText = ""
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        // Speech control with character
                        HStack(spacing: 12) {
                            if speechSynthesizer.isSpeaking {
                                LottieDozziView(
                                    currentAnimation: .constant(.reading),
                                    mood: .constant(.sleepy)
                                )
                                .frame(width: 40, height: 40)
                            }
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    toggleSpeech()
                                }
                            }) {
                                Label(
                                    speechSynthesizer.isSpeaking ? "Pause Reading" : "Read Story",
                                    systemImage: speechSynthesizer.isSpeaking ? "pause.circle.fill" : "play.circle.fill"
                                )
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.white)
                            }
                            .buttonStyle(LiquidGlassButtonStyle(color: .green, isPrimary: true))
                            .disabled(storyGenerator.currentStory?.content == nil)
                        }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingModificationField.toggle()
                            }
                        }) {
                            Label("Edit Story", systemImage: "pencil")
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(LiquidGlassButtonStyle(color: .blue, isPrimary: false))
                        .disabled(storyGenerator.isGenerating)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                saveStory()
                            }
                        }) {
                            Label("Save to Library", systemImage: "heart.fill")
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(LiquidGlassButtonStyle(color: .purple, isPrimary: true))
                        .disabled(storyGenerator.currentStory?.content == nil)
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(40)
        }
        .background(
            ZStack {
                // Liquid Glass background with depth
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0).opacity(0.8),
                        Color(red: 0.92, green: 0.95, blue: 1.0).opacity(0.6),
                        Color(red: 0.97, green: 0.94, blue: 0.98).opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Multi-layered translucent materials for depth
                Rectangle()
                    .fill(.regularMaterial)
                    .opacity(0.8)
                
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.6)
                    .blendMode(.overlay)
                
                // Subtle dynamic reflections
                LinearGradient(
                    colors: [
                        .white.opacity(0.1),
                        .clear,
                        .white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.overlay)
            }
        )
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
            if let story = storyGenerator.currentStory {
                speechSynthesizer.speakStory(title: story.title, content: story.content, ssmlContent: story.ssmlContent, for: parameters.ageGroup)
            }
        }
    }

    private func saveStory() {
        guard let partialStory = storyGenerator.currentStory else { return }

        // Create a complete story from the partial one
        let completeStory = GeneratedStory(
            title: partialStory.title,
            emoji: partialStory.emoji,
            content: partialStory.content,
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

// MARK: - Liquid Glass Button Style for iOS 26+
struct LiquidGlassButtonStyle: ButtonStyle {
    let color: Color
    let isPrimary: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    if isPrimary {
                        // Primary buttons: filled with translucent color
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(color.opacity(0.8))
                        
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.regularMaterial)
                            .opacity(0.3)
                            .blendMode(.overlay)
                    } else {
                        // Secondary buttons: translucent glass effect
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.regularMaterial)
                            .opacity(0.8)
                        
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    }
                    
                    // Glass reflection effect
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .clear,
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .blendMode(.overlay)
                }
            )
            .shadow(
                color: isPrimary ? color.opacity(0.3) : .black.opacity(0.1),
                radius: configuration.isPressed ? 8 : 12,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

