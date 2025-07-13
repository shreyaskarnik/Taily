import SwiftUI
import Lottie

// Animation states for Dozzi character
enum DozziAnimation: CaseIterable {
    case idle
    case excited
    case waving
    case celebrate
    case magic
    case thinking
    case sleepy
    case reading
    case listening
    case sad
}

// Mood states for visual effects
enum DozziMood: CaseIterable {
    case neutral
    case happy
    case excited
    case sleepy
    case magical
    case confused
}

// Lottie-based Shiba Inu character for professional animations
struct LottieDozziView: View {
    @Binding var currentAnimation: DozziAnimation
    @Binding var mood: DozziMood
    let enableInteraction: Bool
    
    @State private var currentAnimationFile = "smiling_dog"
    @State private var sparkles: [SparkleParticle] = []
    
    init(currentAnimation: Binding<DozziAnimation>, mood: Binding<DozziMood>, enableInteraction: Bool = false) {
        self._currentAnimation = currentAnimation
        self._mood = mood
        self.enableInteraction = enableInteraction
    }
    
    var body: some View {
        ZStack {
            // Main Lottie animation
            LottieView(animation: .named(currentAnimationFile))
                .playing(loopMode: currentAnimation.shouldLoop ? .loop : .playOnce)
                .animationSpeed(currentAnimation.animationSpeed)
                .frame(width: 120, height: 120)
                .scaleEffect(animationScale)
                .animation(.easeInOut(duration: 0.6), value: currentAnimation)
            
            // Bedtime accessories overlay
            AccessoryOverlay(currentAnimation: currentAnimation)
            
            // Particle effects for magic states
            if currentAnimation == .magic {
                MagicParticles(sparkles: $sparkles)
            }
        }
        .onAppear {
            updateAnimation()
        }
        .onChange(of: currentAnimation) { _, _ in
            updateAnimation()
        }
        .onTapGesture {
            if enableInteraction {
                triggerRandomAnimation()
            }
        }
    }
    
    private var animationScale: CGFloat {
        switch currentAnimation {
        case .excited, .celebrate: return 1.3  // Bigger for excitement
        case .sleepy, .reading: return 0.85  // Smaller for calm bedtime
        case .magic: return 1.15  // Slightly bigger for magic
        case .waving: return 1.1  // Slightly bigger for greeting
        default: return 1.0  // Normal size for idle/listening
        }
    }
    
    private var moodColorEffect: Color {
        switch mood {
        case .magical: return .cyan
        case .sleepy: return .purple.opacity(0.8)
        case .excited: return .orange.opacity(0.8)
        case .happy: return .green.opacity(0.8)
        default: return .primary
        }
    }
    
    private func updateAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentAnimationFile = currentAnimation.lottieFileName
        }
        
        // Create sparkles for magic animation
        if currentAnimation == .magic {
            createSparkles()
        }
    }
    
    private func triggerRandomAnimation() {
        let randomAnimations: [DozziAnimation] = [.excited, .waving, .celebrate, .magic]
        currentAnimation = randomAnimations.randomElement() ?? .excited
    }
    
    private func createSparkles() {
        sparkles = (0..<6).map { _ in
            SparkleParticle(
                position: CGPoint(
                    x: CGFloat.random(in: -20...20),
                    y: CGFloat.random(in: -30...30)
                ),
                size: CGFloat.random(in: 12...20),
                opacity: Double.random(in: 0.5...1.0)
            )
        }
    }
}

struct AccessoryOverlay: View {
    let currentAnimation: DozziAnimation
    
    var body: some View {
        VStack {
            // Nightcap for bedtime states
            if currentAnimation == .sleepy || currentAnimation == .reading {
                Text("🌙")
                    .font(.system(size: 16))
                    .offset(x: -15, y: -25)
            }
            
            Spacer()
            
            // Reading accessories
            if currentAnimation == .reading {
                Text("📖")
                    .font(.system(size: 14))
                    .offset(x: 20, y: 5)
            }
            
            // Magic wand for magic states
            if currentAnimation == .magic {
                Text("🪄")
                    .font(.system(size: 16))
                    .offset(x: 25, y: -5)
                    .rotationEffect(.degrees(45))
            }
        }
    }
}

struct MagicParticles: View {
    @Binding var sparkles: [SparkleParticle]
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            ForEach(sparkles.indices, id: \.self) { index in
                Text("✨")
                    .font(.system(size: sparkles[index].size))
                    .position(
                        x: 60 + sparkles[index].position.x + animationOffset,
                        y: 60 + sparkles[index].position.y
                    )
                    .opacity(sparkles[index].opacity * (1.0 - abs(animationOffset) / 30.0))
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: animationOffset
                    )
            }
        }
        .onAppear {
            withAnimation {
                animationOffset = 10
            }
        }
    }
}

struct SparkleParticle {
    let position: CGPoint
    let size: CGFloat
    let opacity: Double
}

// Animation state mapping for future Lottie integration
extension DozziAnimation {
    var lottieFileName: String {
        switch self {
        case .idle, .listening:
            return "smiling_dog"
        case .excited, .celebrate, .waving:
            return "happy_dog"
        case .magic:
            return "magical_dog"
        case .thinking:
            return "astronaut_dog"
        case .sleepy, .reading:
            return "curious_dog"  // Using curious for calm/reading states
        case .sad:
            return "smiling_dog"  // Keep positive for bedtime
        }
    }
    
    var animationSpeed: CGFloat {
        switch self {
        case .sleepy, .reading: return 0.4  // Very slow for bedtime
        case .excited, .celebrate: return 1.6  // Fast and energetic
        case .magic: return 1.3  // Slightly faster for magic feel
        case .waving: return 1.2  // Moderate speed for greeting
        default: return 1.0  // Normal speed for idle/listening
        }
    }
    
    var shouldLoop: Bool {
        switch self {
        case .idle, .sleepy, .reading, .listening: return true
        case .excited, .celebrate, .magic, .waving: return false
        default: return true
        }
    }
}

// Convenience extension for interactive modifier
extension LottieDozziView {
    func interactive(_ enabled: Bool = true) -> LottieDozziView {
        LottieDozziView(
            currentAnimation: self._currentAnimation,
            mood: self._mood,
            enableInteraction: enabled
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Dozzi Lottie Character")
            .font(.title)
        
        LottieDozziView(
            currentAnimation: .constant(.idle),
            mood: .constant(.happy),
            enableInteraction: true
        )
        .frame(height: 120)
        
        HStack {
            Button("Excited") {
                // Animation trigger
            }
            Button("Sleepy") {
                // Animation trigger  
            }
            Button("Magic") {
                // Animation trigger
            }
        }
    }
    .padding()
}