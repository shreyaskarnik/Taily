import AVFoundation
import SwiftUI
import Combine

class SpeechSynthesizer: NSObject, ObservableObject {
    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var speechRate: Float = 0.4
    @Published var speechPitch: Float = 1.0
    @Published var selectedVoice: AVSpeechSynthesisVoice?
    @Published var currentWordRange: NSRange?
    @Published var speechProgress: Double = 0.0
    @Published var isSpeakingTitle: Bool = false
    @Published var isSpeakingContent: Bool = false
    
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var fullText: String = ""
    private var titleText: String = ""
    private var contentText: String = ""
    private var titleLength: Int = 0
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
        setupDefaultVoice()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupDefaultVoice() {
        if let voice = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language == "en-US" && $0.quality == .enhanced }) {
            selectedVoice = voice
        } else {
            selectedVoice = AVSpeechSynthesisVoice(language: "en-US")
        }
    }
    
    func speak(text: String, for ageGroup: AgeGroup) {
        guard !text.isEmpty else { return }
        
        if synthesizer.isSpeaking {
            stopSpeaking()
        }
        
        fullText = text
        currentWordRange = nil
        speechProgress = 0.0
        isSpeakingTitle = false
        isSpeakingContent = false
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Adjust speech parameters based on age group
        switch ageGroup {
        case .toddler:
            utterance.rate = 0.35
            utterance.pitchMultiplier = 1.1
        case .preschool:
            utterance.rate = 0.4
            utterance.pitchMultiplier = 1.05
        case .earlyElementary:
            utterance.rate = 0.45
            utterance.pitchMultiplier = 1.0
        case .elementary:
            utterance.rate = 0.5
            utterance.pitchMultiplier = 0.95
        }
        
        // Apply custom settings
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        
        if let voice = selectedVoice {
            utterance.voice = voice
        }
        
        // Add natural pauses
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        
        currentUtterance = utterance
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func speakStory(title: String, content: String, ssmlContent: String? = nil, for ageGroup: AgeGroup) {
        guard !title.isEmpty && !content.isEmpty else { return }
        
        if synthesizer.isSpeaking {
            stopSpeaking()
        }
        
        titleText = title
        contentText = content
        titleLength = title.count + 2 // +2 for ". " separator
        
        // Store plain text for highlighting
        fullText = "\(title). \(content)"
        currentWordRange = nil
        speechProgress = 0.0
        isSpeakingTitle = false
        isSpeakingContent = false
        
        // Note: AVSpeechSynthesizer doesn't support SSML directly, so we use plain text
        // SSML content is stored for potential future use (export, other TTS engines, etc.)
        let utterance = AVSpeechUtterance(string: fullText)
        
        // Adjust speech parameters based on age group
        switch ageGroup {
        case .toddler:
            utterance.rate = 0.3
            utterance.pitchMultiplier = 1.2
        case .preschool:
            utterance.rate = 0.4
            utterance.pitchMultiplier = 1.1
        case .earlyElementary:
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
        case .elementary:
            utterance.rate = 0.6
            utterance.pitchMultiplier = 1.0
        }
        
        if let voice = selectedVoice {
            utterance.voice = voice
        }
        
        // Add natural pauses
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        
        currentUtterance = utterance
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func pauseSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
            isPaused = true
        }
    }
    
    func continueSpeaking() {
        if isPaused {
            synthesizer.continueSpeaking()
            isPaused = false
        }
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        currentUtterance = nil
        currentWordRange = nil
        speechProgress = 0.0
        isSpeakingTitle = false
        isSpeakingContent = false
    }
    
    func adjustSpeechRate(_ rate: Float) {
        speechRate = max(0.1, min(1.0, rate))
    }
    
    func adjustSpeechPitch(_ pitch: Float) {
        speechPitch = max(0.5, min(2.0, pitch))
    }
    
    func setVoice(_ voice: AVSpeechSynthesisVoice) {
        selectedVoice = voice
    }
    
    var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.name < $1.name }
    }
    
    func sampleVoice(_ voice: AVSpeechSynthesisVoice, sampleText: String = "Hello! This is how I sound when reading bedtime stories.") {
        if synthesizer.isSpeaking {
            stopSpeaking()
        }
        
        let utterance = AVSpeechUtterance(string: sampleText)
        utterance.voice = voice
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
}

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.isPaused = false
            self.speechProgress = 0.0
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString range: NSRange, utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // Determine if we're speaking title or content
            if range.location < self.titleLength {
                self.isSpeakingTitle = true
                self.isSpeakingContent = false
                // Adjust range for title text only
                self.currentWordRange = NSRange(location: range.location, length: min(range.length, self.titleLength - range.location))
            } else {
                self.isSpeakingTitle = false
                self.isSpeakingContent = true
                // Adjust range for content text (subtract title length)
                let contentStartLocation = max(0, range.location - self.titleLength)
                self.currentWordRange = NSRange(location: contentStartLocation, length: range.length)
            }
            
            let progress = Double(range.location + range.length) / Double(utterance.speechString.count)
            self.speechProgress = min(progress, 1.0)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = false
            self.currentUtterance = nil
            self.currentWordRange = nil
            self.speechProgress = 1.0
            self.isSpeakingTitle = false
            self.isSpeakingContent = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPaused = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPaused = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = false
            self.currentUtterance = nil
            self.currentWordRange = nil
            self.speechProgress = 0.0
            self.isSpeakingTitle = false
            self.isSpeakingContent = false
        }
    }
}
