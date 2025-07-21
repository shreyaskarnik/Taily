import Foundation

/// Manages bundled voice samples to avoid TTS costs during preview
class VoiceSampleManager {
    static let shared = VoiceSampleManager()
    
    private init() {}
    
    // MARK: - Bundled Voice Samples
    
    /// Get voice sample from app bundle assets
    func getVoiceSample(for voice: VoiceConfig) -> Data? {
        // Map voice names to asset filenames
        let assetName = assetFileName(for: voice)
        
        // Try to load from main bundle
        guard let sampleURL = Bundle.main.url(forResource: assetName, withExtension: "mp3") else {
            print("⚠️ Voice sample not found: \(assetName).mp3")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: sampleURL)
            print("✅ Loaded voice sample: \(assetName).mp3 (\(data.count) bytes)")
            return data
        } catch {
            print("❌ Failed to load voice sample \(assetName).mp3: \(error)")
            return nil
        }
    }
    
    /// Check if a bundled sample exists for the voice
    func hasBundledSample(for voice: VoiceConfig) -> Bool {
        let assetName = assetFileName(for: voice)
        return Bundle.main.url(forResource: assetName, withExtension: "mp3") != nil
    }
    
    /// Convert voice config to asset filename
    private func assetFileName(for voice: VoiceConfig) -> String {
        guard let voiceName = voice.name else {
            return "voice_sample_default"
        }
        
        // Convert "en-US-Neural2-F" to "voice_sample_f"
        let suffix = voiceName.replacingOccurrences(of: "en-US-Neural2-", with: "").lowercased()
        return "voice_sample_\(suffix)"
    }
    
    /// Get all available voice sample asset names
    var availableVoiceSamples: [String] {
        return VoiceConfig.allVoices.compactMap { voice in
            hasBundledSample(for: voice) ? assetFileName(for: voice) : nil
        }
    }
}

// MARK: - Voice Sample Generation (Dev Only)

#if DEBUG
extension VoiceSampleManager {
    /// Generate and cache voice samples (development only)
    /// This should be run once to create the cached samples
    func generateAndCacheSamples() async {
        let ttsService = TTSService()
        
        for voice in VoiceConfig.allVoices {
            do {
                print("🎤 Generating sample for \(voice.displayName)...")
                let response = try await ttsService.generateVoiceSample(for: voice)
                
                if let audioData = Data(base64Encoded: response.audioContent) {
                    let fileName = "sample_\(voice.name?.replacingOccurrences(of: "en-US-Neural2-", with: "").lowercased() ?? "unknown")"
                    print("📝 Generated \(audioData.count) bytes for \(fileName)")
                    print("📋 Base64 sample for \(voice.name ?? "unknown"):")
                    print(response.audioContent.prefix(100) + "...")
                }
            } catch {
                print("❌ Failed to generate sample for \(voice.displayName): \(error)")
            }
        }
    }
}
#endif
