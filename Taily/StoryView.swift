import SwiftUI
import Lottie
import AVFoundation

struct StoryView: View {
    @ObservedObject var storyGenerator: StoryGenerator
    let parameters: StoryParameters
    @StateObject private var ttsService = TTSService()
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var libraryManager = StoryLibraryManager()
    @StateObject private var speechSynthesizer = SpeechSynthesizer() // Keep for local TTS fallback
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var modificationText = ""
    @State private var showingModificationField = false
    @State private var showingSaveAlert = false
    @State private var audioData: Data?
    @State private var isPlayingAudio = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var wordHighlightTimer: Timer?
    @State private var currentWordIndex: Int = 0
    @State private var storyWords: [String] = []
    @State private var isPreparingCloudAudio = false
    @AppStorage("useCloudTTS") private var useCloudTTS = false // Debug setting
    @AppStorage("selectedCloudVoiceName") private var selectedCloudVoiceName = ""
    
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
    
    // Computed property to check if any TTS is currently speaking
    private var isCurrentlySpeaking: Bool {
        if subscriptionManager.canUseCloudTTS() {
            return isPlayingAudio
        } else {
            return speechSynthesizer.isSpeaking
        }
    }
    
    // Button label based on subscription status
    private var buttonLabel: String {
        if subscriptionManager.canUseCloudTTS() {
            switch subscriptionManager.subscriptionStatus {
            case .unlimited:
                return "Read Story (Premium Voices)"
            case .free(let remaining):
                return "Read Story (Premium Trial \(remaining)/2)"
            }
        } else {
            return "Read Story (Upgrade for Premium)"
        }
    }
    
    // Button background color
    private var buttonBackgroundColor: Color {
        if subscriptionManager.canUseCloudTTS() {
            return Color.blue.opacity(0.1)
        } else {
            return Color.orange.opacity(0.1) // Upgrade prompt
        }
    }
    
    // Button foreground color
    private var buttonForegroundColor: Color {
        if subscriptionManager.canUseCloudTTS() {
            return .blue
        } else {
            return .orange // Upgrade prompt
        }
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
            // Stop any active TTS
            speechSynthesizer.stopSpeaking()
            audioPlayer?.stop()
            audioPlayer = nil
            isPlayingAudio = false
            audioData = nil
            stopWordHighlighting()
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

                                // Story illustration placeholder (cloud stories include description only)
                                if let illustrationDescription = story.storyIllustration, !illustrationDescription.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.artframe")
                                            .font(.system(size: 40))
                                            .foregroundColor(.secondary)
                                        
                                        VStack(spacing: 4) {
                                            Text("Story Illustration")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                            Text(illustrationDescription)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(3)
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                    .frame(maxWidth: dynamicImageMaxWidth, maxHeight: dynamicImageHeight)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    .accessibilityLabel("Story illustration: \(illustrationDescription)")
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
                                    if isCurrentlySpeaking {
                                        LottieDozziView(
                                            currentAnimation: .constant(.reading),
                                            mood: .constant(.sleepy)
                                        )
                                        .frame(width: 40, height: 40)
                                    }
                                    
                                    Button(action: toggleSpeech) {
                                        Label(
                                            isCurrentlySpeaking ? "Pause" : buttonLabel,
                                            systemImage: isCurrentlySpeaking ? "pause.fill" : "play.fill"
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(buttonBackgroundColor)
                                        .foregroundColor(buttonForegroundColor)
                                        .cornerRadius(10)
                                    }
                                    .disabled(storyGenerator.currentStory?.content == nil || (useCloudTTS && ttsService.isGenerating))
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
                        if let illustrationDescription = story.storyIllustration, !illustrationDescription.isEmpty {
                            // iPad illustration placeholder with description
                            VStack(spacing: 16) {
                                Image(systemName: "photo.artframe")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                
                                VStack(spacing: 8) {
                                    Text("Story Illustration")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    Text(illustrationDescription)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .accessibilityLabel("Story illustration: \(illustrationDescription)")
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
                                
                                if let illustrationDescription = story.storyIllustration, !illustrationDescription.isEmpty {
                                    // Polished illustration placeholder with description
                                    VStack(spacing: 20) {
                                        ZStack {
                                            Circle()
                                                .fill(.white.opacity(0.9))
                                                .frame(width: 120, height: 120)
                                                .shadow(color: .purple.opacity(0.2), radius: 15, x: 0, y: 8)
                                            
                                            Image(systemName: "photo.artframe.circle")
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
                                            Text("Story Illustration")
                                                .font(.title2.weight(.bold))
                                                .foregroundStyle(.primary)
                                            
                                            Text(illustrationDescription)
                                                .font(.body)
                                                .foregroundStyle(.secondary)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 24)
                                        }
                                    }
                                    .frame(maxHeight: 400)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .fill(.regularMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .accessibilityLabel("Story illustration: \(illustrationDescription)")
                                } else if storyGenerator.isGenerating {
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
                            if isCurrentlySpeaking {
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
                                HStack {
                                    if useCloudTTS && ttsService.isGenerating {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                        Text("Generating Audio...")
                                    } else {
                                        Label(
                                            isCurrentlySpeaking ? "Pause Reading" : (useCloudTTS ? "Read Story" : "Read Story"),
                                            systemImage: isCurrentlySpeaking ? "pause.circle.fill" : "play.circle.fill"
                                        )
                                    }
                                }
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.white)
                            }
                            .buttonStyle(LiquidGlassButtonStyle(color: useCloudTTS ? .blue : .green, isPrimary: true))
                            .disabled(storyGenerator.currentStory?.content == nil || (useCloudTTS && ttsService.isGenerating))
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
        // Auto-use cloud TTS for users who have access (including free trial)
        if subscriptionManager.canUseCloudTTS() {
            toggleCloudTTS()
        } else {
            // Only users without any cloud access use local TTS
            toggleLocalTTS()
        }
    }
    
    private func toggleCloudTTS() {
        if isPlayingAudio {
            // Pause/stop cloud audio playback
            audioPlayer?.pause()
            isPlayingAudio = false
            stopWordHighlighting()
        } else {
            // Generate new audio using Firebase TTS
            if let story = storyGenerator.currentStory {
                isPreparingCloudAudio = true
                
                Task {
                    do {
                        print("☁️ Generating TTS with Google Cloud voices ($$)...")
                        let cleanStoryText = stripMarkdown(from: story.content)
                        
                        // Use selected voice or age-appropriate default
                        let selectedVoice: VoiceConfig? = {
                            if !selectedCloudVoiceName.isEmpty {
                                return VoiceConfig.allVoices.first { $0.name == selectedCloudVoiceName }
                            }
                            return nil
                        }()
                        
                        // Get subscription status for proper usage tracking
                        let subscriptionStatus = subscriptionManager.subscriptionStatus == .unlimited ? "unlimited" : "free"
                        
                        let response = try await ttsService.synthesizeStory(
                            story: cleanStoryText,
                            childAge: getChildAge(),
                            selectedVoice: selectedVoice,
                            subscriptionStatus: subscriptionStatus
                        )
                        
                        // Convert base64 to audio data and play
                        if let data = Data(base64Encoded: response.audioContent) {
                            audioData = data
                            
                            do {
                                // Create and configure audio player
                                audioPlayer = try AVAudioPlayer(data: data)
                                audioPlayer?.prepareToPlay()
                                
                                // Set up audio session for playback
                                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                                try AVAudioSession.sharedInstance().setActive(true)
                                
                                // Start playback
                                audioPlayer?.play()
                                isPlayingAudio = true
                                isPreparingCloudAudio = false
                                
                                // Start simulated word highlighting for cloud TTS
                                startWordHighlighting(for: cleanStoryText)
                                
                                print("✅ Cloud TTS playing - \(response.remaining) requests remaining")
                            } catch {
                                print("❌ Audio playback error: \(error)")
                                isPlayingAudio = false
                                isPreparingCloudAudio = false
                            }
                        }
                    } catch {
                        print("❌ Cloud TTS Error: \(error)")
                        // Fallback to local TTS if Firebase fails
                        print("🔄 Falling back to local TTS...")
                        toggleLocalTTS()
                    }
                }
            }
        }
    }
    
    private func toggleLocalTTS() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.pauseSpeaking()
        } else {
            if let story = storyGenerator.currentStory {
                print("📱 Using local iOS TTS (free - Samantha)")
                let cleanStoryText = stripMarkdown(from: story.content)
                // Simplified: just use plain content, no SSML complexity
                speechSynthesizer.speakStory(
                    title: story.title, 
                    content: cleanStoryText, 
                    ssmlContent: nil, // Simplified - no SSML for bedtime stories
                    for: parameters.ageGroup
                )
            }
        }
    }
    
    private func getChildAge() -> Int {
        switch parameters.ageGroup {
        case .toddler: return 3
        case .preschool: return 5
        case .earlyElementary: return 7
        case .elementary: return 9
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

        Task {
            do {
                // Save to Firestore (cloud-synced across devices)
                try await firestoreService.saveStory(completeStory, parameters: parameters)
                
                // Also save locally for offline access
                libraryManager.saveStory(completeStory, parameters: parameters)
                
                showingSaveAlert = true
            } catch {
                print("❌ Failed to save story: \(error)")
                // Fallback to local-only save
                libraryManager.saveStory(completeStory, parameters: parameters)
                showingSaveAlert = true
            }
        }
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

// MARK: - Helper Functions

extension StoryView {
    /// Strip markdown formatting from text for TTS to avoid reading asterisks, brackets, etc.
    private func stripMarkdown(from text: String) -> String {
        var cleanText = text
        
        // Remove bold/italic markers
        cleanText = cleanText.replacingOccurrences(of: "**", with: "")
        cleanText = cleanText.replacingOccurrences(of: "*", with: "")
        cleanText = cleanText.replacingOccurrences(of: "_", with: "")
        
        // Remove headers
        cleanText = cleanText.replacingOccurrences(of: "# ", with: "")
        cleanText = cleanText.replacingOccurrences(of: "## ", with: "")
        cleanText = cleanText.replacingOccurrences(of: "### ", with: "")
        
        // Remove links [text](url) -> text
        let linkPattern = "\\[([^\\]]+)\\]\\([^\\)]+\\)"
        cleanText = cleanText.replacingOccurrences(
            of: linkPattern,
            with: "$1",
            options: .regularExpression
        )
        
        // Remove code blocks and inline code
        cleanText = cleanText.replacingOccurrences(of: "`", with: "")
        
        // Remove list markers
        cleanText = cleanText.replacingOccurrences(of: "- ", with: "")
        cleanText = cleanText.replacingOccurrences(of: "* ", with: "")
        
        // Clean up multiple spaces and newlines
        cleanText = cleanText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanText
    }
    
    // MARK: - Word Highlighting for Cloud TTS
    
    /// Start simulated word highlighting to sync with cloud audio
    private func startWordHighlighting(for text: String) {
        storyWords = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        currentWordIndex = 0
        
        // Estimate timing: average 150 words per minute for bedtime stories
        let wordsPerSecond = 150.0 / 60.0 // ~2.5 words per second
        let intervalPerWord = 1.0 / wordsPerSecond // ~0.4 seconds per word
        
        wordHighlightTimer = Timer.scheduledTimer(withTimeInterval: intervalPerWord, repeats: true) { _ in
            self.advanceWordHighlight()
        }
    }
    
    /// Stop word highlighting timer
    private func stopWordHighlighting() {
        wordHighlightTimer?.invalidate()
        wordHighlightTimer = nil
        currentWordIndex = 0
        
        // Reset speech synthesizer highlighting state for consistency
        speechSynthesizer.currentWordRange = nil
        speechSynthesizer.speechProgress = 0.0
    }
    
    /// Advance to next word in highlighting
    private func advanceWordHighlight() {
        guard currentWordIndex < storyWords.count else {
            stopWordHighlighting()
            return
        }
        
        // Calculate approximate word range for highlighting
        let wordsBeforeCurrent = storyWords.prefix(currentWordIndex)
        let charactersBefore = wordsBeforeCurrent.joined(separator: " ").count + 
                              (currentWordIndex > 0 ? 1 : 0) // Add space before current word
        
        let currentWord = storyWords[currentWordIndex]
        let wordRange = NSRange(location: charactersBefore, length: currentWord.count)
        
        // Update speech synthesizer state for UI consistency
        speechSynthesizer.currentWordRange = wordRange
        speechSynthesizer.speechProgress = Double(currentWordIndex) / Double(storyWords.count)
        speechSynthesizer.isSpeakingContent = true
        
        currentWordIndex += 1
    }
}

