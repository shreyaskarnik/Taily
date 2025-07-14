import SwiftUI
import AVFoundation

struct VoiceSelectionView: View {
    @StateObject private var ttsService = TTSService()
    @State private var selectedVoice: VoiceConfig = VoiceConfig.warmMother
    @State private var previewingVoice: VoiceConfig?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @AppStorage("selectedVoiceName") private var selectedVoiceName: String = VoiceConfig.warmMother.name ?? ""
    
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
        stopPreview()
        previewingVoice = voice
        
        // Use bundled voice samples instead of TTS API calls
        guard let sampleData = VoiceSampleManager.shared.getVoiceSample(for: voice) else {
            print("⚠️ No bundled sample available for \(voice.displayName)")
            previewingVoice = nil
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(data: sampleData)
            audioPlayer?.prepareToPlay()
            
            // Set up audio session
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Play sample
            audioPlayer?.play()
            isPlaying = true
            
            // Auto-stop after audio finishes (samples are ~8 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                stopPreview()
            }
            
        } catch {
            print("❌ Audio playback error: \(error)")
            previewingVoice = nil
        }
    }
    
    private func stopPreview() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        previewingVoice = nil
    }
}

struct VoiceOptionCard: View {
    let voice: VoiceConfig
    let isSelected: Bool
    let isPreviewing: Bool
    let isPlaying: Bool
    let isRecommended: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    
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
                    Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(isPreviewing && !isPlaying)
                
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

#Preview {
    VoiceSelectionView(childAge: 5) { voice in
        print("Selected voice: \(voice.displayName)")
    }
}