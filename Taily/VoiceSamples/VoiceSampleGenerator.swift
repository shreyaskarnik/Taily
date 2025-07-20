import Foundation
import SwiftUI

/**
 * Voice Sample Generator View
 *
 * Add this view to your iOS app temporarily to generate voice samples.
 * This uses your existing TTSService and saves files that you can export.
 */

struct VoiceSampleGenerator: View {
    @StateObject private var ttsService = TTSService()
    @State private var isGenerating = false
    @State private var progress = ""
    @State private var generatedSamples: [String] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Voice Sample Generator")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Generate MP3 samples for all voices")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if isGenerating {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text(progress)
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Button("Generate All Voice Samples") {
                        generateAllSamples()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerating)
                }

                if !generatedSamples.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generated Samples:")
                            .font(.headline)

                        ForEach(generatedSamples, id: \.self) { sample in
                            Text("✅ \(sample)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }

                        Text("\nTo export these files:")
                            .font(.caption)
                            .fontWeight(.bold)

                        Text("1. Connect your device to Xcode\n2. Window → Devices and Simulators\n3. Select your device → Installed Apps\n4. Select Dozzi → Download Container\n5. Show Package Contents → Documents")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func generateAllSamples() {
        Task {
            await generateSamples()
        }
    }

    @MainActor
    private func generateSamples() async {
        isGenerating = true
        generatedSamples.removeAll()

        let voices = VoiceConfig.allVoices

        for (index, voice) in voices.enumerated() {
            progress = "Generating \(voice.displayName) (\(index + 1)/\(voices.count))"

            do {
                let response = try await ttsService.generateVoiceSample(for: voice)

                // Convert base64 to audio data
                guard let audioData = Data(base64Encoded: response.audioContent) else {
                    print("❌ Failed to decode audio for \(voice.displayName)")
                    continue
                }

                // Save to documents directory
                let fileName = getFileName(for: voice)
                let success = saveAudioFile(audioData, fileName: fileName)

                if success {
                    generatedSamples.append(fileName)
                    print("✅ Saved \(fileName)")
                } else {
                    print("❌ Failed to save \(fileName)")
                }

                // Add delay to be nice to the API
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            } catch {
                print("❌ Error generating sample for \(voice.displayName): \(error)")
            }
        }

        isGenerating = false
        progress = "Generation complete!"
    }

    private func getFileName(for voice: VoiceConfig) -> String {
        // Map voice names to the expected file names from README
        switch voice.name {
        case "en-US-Neural2-F":
            return "voice_sample_f.mp3"
        case "en-US-Neural2-G":
            return "voice_sample_g.mp3"
        case "en-US-Neural2-C":
            return "voice_sample_c.mp3"
        case "en-US-Neural2-H":
            return "voice_sample_h.mp3"
        case "en-US-Neural2-D":
            return "voice_sample_d.mp3"
        default:
            return "voice_sample_\(voice.name?.suffix(1).lowercased() ?? "unknown").mp3"
        }
    }

    private func saveAudioFile(_ audioData: Data, fileName: String) -> Bool {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                        in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(fileName)

            try audioData.write(to: fileURL)
            print("📁 Saved to: \(fileURL.path)")
            return true
        } catch {
            print("❌ Failed to save \(fileName): \(error)")
            return false
        }
    }
}

// MARK: - Usage Instructions

/*
 How to use this Voice Sample Generator:

 1. Add this file to your Xcode project temporarily

 2. In your ContentView.swift or any navigation, add a debug route:

    #if DEBUG
    NavigationLink("Generate Voice Samples") {
        VoiceSampleGenerator()
    }
    #endif

 3. Run the app on device (not simulator - you need real Firebase auth)

 4. Navigate to the Voice Sample Generator and tap "Generate All Voice Samples"

 5. Wait for generation to complete (about 10-15 seconds total)

 6. Export the files using Xcode:
    - Connect device to Xcode
    - Window → Devices and Simulators
    - Select your device → Installed Apps
    - Select Dozzi → Download Container
    - Show Package Contents → Documents
    - Copy the voice_sample_*.mp3 files

 7. Add the MP3 files to your Xcode project:
    - Drag them into the VoiceSamples folder in Xcode
    - Make sure "Add to target" is checked for your app
    - Verify they appear in the Bundle in the app

 8. Remove this VoiceSampleGenerator from your project when done

 9. Test that VoiceSampleManager now uses the bundled files for offline previews

 Cost: This will use about 5 TTS API calls (one per voice) = ~$0.04 total
*/

#Preview {
    VoiceSampleGenerator()
}
