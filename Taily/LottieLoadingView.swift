import SwiftUI
import Lottie

// Lottie-based loading animations for different app states
struct LottieLoadingView: View {
    let type: LoadingType
    let message: String?
    
    init(type: LoadingType = .story, message: String? = nil) {
        self.type = type
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Lottie loading animation
            LottieView(animation: .named(type.animationFile))
                .playing(loopMode: .loop)
                .animationSpeed(type.animationSpeed)
                .frame(width: type.size.width, height: type.size.height)
            
            // Loading message
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// Different types of loading animations
enum LoadingType {
    case story           // Creating bedtime story
    case illustration    // Generating story image
    case thinking       // Dozzi thinking/processing
    case magic          // Magical story creation
    case audio          // Audio processing/TTS
    
    var animationFile: String {
        switch self {
        case .story, .thinking:
            return "storybook"          // Magical storybook for story creation
        case .illustration:
            return "magical_dog"        // Magic for image creation
        case .magic:
            return "storybook"          // Magical story elements
        case .audio:
            return "happy_dog"          // Happy Dozzi for audio
        }
    }
    
    var animationSpeed: CGFloat {
        switch self {
        case .story, .thinking:
            return 0.8                  // Thoughtful pace
        case .illustration, .magic:
            return 1.2                  // Magical pace
        case .audio:
            return 1.0                  // Normal pace
        }
    }
    
    var size: CGSize {
        switch self {
        case .story, .thinking, .magic:
            return CGSize(width: 120, height: 120)  // Larger for storybook animation
        case .illustration:
            return CGSize(width: 100, height: 100)
        case .audio:
            return CGSize(width: 60, height: 60)
        }
    }
}

// Convenience loading views for common scenarios
struct StoryCreationLoadingView: View {
    var body: some View {
        LottieLoadingView(
            type: .story,
            message: "Writing your magical bedtime story..."
        )
    }
}

struct IllustrationLoadingView: View {
    var body: some View {
        LottieLoadingView(
            type: .illustration,
            message: "Creating beautiful illustrations..."
        )
    }
}

struct AudioLoadingView: View {
    var body: some View {
        LottieLoadingView(
            type: .audio,
            message: "Preparing story narration..."
        )
    }
}

// Inline progress view replacement with Dozzi character
struct DozziProgressView: View {
    let progress: Double?
    let message: String?
    
    init(value: Double? = nil, message: String? = nil) {
        self.progress = value
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Mini Dozzi animation
            LottieView(animation: .named("smiling_dog"))
                .playing(loopMode: .loop)
                .animationSpeed(1.2)
                .frame(width: 40, height: 40)
            
            // Progress bar if value provided
            if let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(maxWidth: 120)
            }
            
            // Optional message
            if let message = message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// Loading overlay for full-screen loading states
struct LottieLoadingOverlay: View {
    let type: LoadingType
    let message: String
    let isPresented: Bool
    
    var body: some View {
        if isPresented {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                // Loading content
                VStack(spacing: 20) {
                    LottieLoadingView(type: type, message: message)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                )
                .padding(40)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: isPresented)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        Text("Lottie Loading Views")
            .font(.title2)
            .fontWeight(.bold)
        
        StoryCreationLoadingView()
        
        IllustrationLoadingView()
        
        AudioLoadingView()
        
        DozziProgressView(value: 0.7, message: "Almost ready...")
        
        Spacer()
    }
    .padding()
}