import SwiftUI
import AVFoundation
import Combine

struct VoiceSelectionView: View {
    @StateObject private var ttsService = TTSService()
    @State private var selectedVoice: VoiceConfig = VoiceConfig.warmMother
    @State private var previewingVoice: VoiceConfig?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var isPaused = false
    @State private var isLoadingPreview = false
    @AppStorage("selectedVoiceName") private var selectedVoiceName: String = VoiceConfig.warmMother.name ?? ""
    @StateObject private var audioDelegate = AudioPlayerDelegate()
    
    let childAge: Int
    let onVoiceSelected: (VoiceConfig) -> Void
    
    init(childAge: Int, onVoiceSelected: @escaping (VoiceConfig) -> Void) {
        self.childAge = childAge
        self.onVoiceSelected = onVoiceSelected
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Choose a Storyteller")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select the perfect voice for your bedtime stories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(VoiceConfig.allVoices, id: \.name) { voice in
                            VoiceOptionCard(
                                voice: voice,
                                isSelected: selectedVoice.name == voice.name,
                                isPreviewing: previewingVoice?.name == voice.name,
                                isPlaying: isPlaying && previewingVoice?.name == voice.name,
                                isLoadingPreview: isLoadingPreview && previewingVoice?.name == voice.name,
                                isRecommended: voice.name == VoiceConfig.ageAppropriate(for: childAge).name,
                                onSelect: {
                                    selectedVoice = voice
                                    selectedVoiceName = voice.name ?? ""
                                },
                                onPreview: {
                                    previewVoice(voice)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    if ttsService.isGenerating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Generating voice sample...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button("Use This Voice") {
                        onVoiceSelected(selectedVoice)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(ttsService.isGenerating)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onVoiceSelected(selectedVoice)
                    }
                }
            }
        }
        .onAppear {
            // Load previously selected voice
            if let savedVoice = VoiceConfig.allVoices.first(where: { $0.name == selectedVoiceName }) {
                selectedVoice = savedVoice
            } else {
                selectedVoice = VoiceConfig.ageAppropriate(for: childAge)
            }
        }
        .onDisappear {
            stopPreview()
        }
    }
    
    private func previewVoice(_ voice: VoiceConfig) {
        // If this voice is already playing, toggle pause/resume
        if previewingVoice?.name == voice.name && audioPlayer != nil {
            if isPlaying {
                pausePreview()
            } else {
                resumePreview()
            }
            return
        }
        
        // Start new preview
        stopPreview()
        previewingVoice = voice
        isLoadingPreview = true
        
        // Use bundled voice samples instead of TTS API calls
        guard let sampleData = VoiceSampleManager.shared.getVoiceSample(for: voice) else {
            print("⚠️ No bundled sample available for \(voice.displayName)")
            previewingVoice = nil
            isLoadingPreview = false
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(data: sampleData)
            audioPlayer?.delegate = audioDelegate
            audioPlayer?.prepareToPlay()
            
            // Set up audio session
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Set up completion handler for when audio finishes
            audioDelegate.onCompletion = {
                DispatchQueue.main.async {
                    stopPreview()
                }
            }
            
            // Play sample
            audioPlayer?.play()
            isPlaying = true
            isLoadingPreview = false
            
        } catch {
            print("❌ Audio playback error: \(error)")
            previewingVoice = nil
            isLoadingPreview = false
        }
    }
    
    private func stopPreview() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        isPaused = false
        previewingVoice = nil
        isLoadingPreview = false
    }
    
    private func pausePreview() {
        audioPlayer?.pause()
        isPlaying = false
        isPaused = true
    }
    
    private func resumePreview() {
        audioPlayer?.play()
        isPlaying = true
        isPaused = false
    }
    
    private func getPlayButtonIcon() -> String {
        if previewingVoice != nil && audioPlayer != nil {
            if isPlaying {
                return "pause.circle.fill"
            } else if isPaused {
                return "play.circle.fill"
            }
        }
        return "play.circle.fill"
    }
}

struct VoiceOptionCard: View {
    let voice: VoiceConfig
    let isSelected: Bool
    let isPreviewing: Bool
    let isPlaying: Bool
    let isLoadingPreview: Bool
    let isRecommended: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    
    private var playButtonIcon: String {
        if isPreviewing && isPlaying {
            return "pause.circle.fill"
        } else if isPreviewing && !isPlaying && isLoadingPreview == false {
            return "play.circle.fill"
        }
        return "play.circle.fill"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(voice.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if isRecommended {
                        Text("RECOMMENDED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                
                Text(voice.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Best for: \(voice.ageRange)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Button(action: onPreview) {
                    Group {
                        if isLoadingPreview {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.blue)
                        } else {
                            Image(systemName: playButtonIcon)
                                .font(.title2)
                        }
                    }
                    .foregroundColor(.blue)
                    .frame(width: 28, height: 28)
                }
                .disabled(isLoadingPreview)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Audio Player Delegate

class AudioPlayerDelegate: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var onCompletion: (() -> Void)?
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onCompletion?()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("❌ Audio decode error: \(error)")
        }
        onCompletion?()
    }
}

#Preview {
    VoiceSelectionView(childAge: 5) { voice in
        print("Selected voice: \(voice.displayName)")
    }
}
