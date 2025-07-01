//
//  SpeechService.swift
//  aielearn
//
//  Created by AI Assistant
//

import Foundation
import AVFoundation
import SwiftUI

@MainActor
class SpeechService: NSObject, ObservableObject, @preconcurrency AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    var selectedVoice: AVSpeechSynthesisVoice?
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var currentSpeechText = ""
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    @Published var useOpenAITTS = false
    
    // OpenAI TTS Settings
    enum OpenAIVoice: String, CaseIterable {
        case alloy = "alloy"
        case echo = "echo"
        case fable = "fable"
        case onyx = "onyx"
        case nova = "nova"
        case shimmer = "shimmer"
        
        var displayName: String {
            switch self {
            case .alloy: return "Alloy (Neutral)"
            case .echo: return "Echo (Male)"
            case .fable: return "Fable (British)"
            case .onyx: return "Onyx (Deep)"
            case .nova: return "Nova (Young Female)"
            case .shimmer: return "Shimmer (Soft Female)"
            }
        }
    }
    
    @Published var selectedOpenAIVoice: OpenAIVoice = .nova
    private var openAIService: OpenAIService?
    
    static let shared = SpeechService()
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
        loadAvailableVoices()
        checkSamanthaAvailability() // Check what Samantha voices are available
        applyUserSelectedVoice() // Apply user's voice preference or default to best
        printAvailableVoices() // Debug: show available voices
    }
    
    // MARK: - OpenAI TTS Setup
    func setOpenAIService(_ service: OpenAIService?) {
        openAIService = service
        print("🤖 OpenAI TTS service configured: \(service != nil)")
    }
    
    // MARK: - User Voice Preference
    private func applyUserSelectedVoice() {
        let userVoiceId = UserDefaults.standard.string(forKey: "selectedVoiceIdentifier") ?? ""
        
        if !userVoiceId.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: userVoiceId) {
            selectedVoice = voice
            print("🎤 Applied user selected voice: \(voice.name) (\(userVoiceId))")
        } else {
            // No user preference, default to best quality
            useSamanthaEnhanced()
        }
    }
    
    func updateFromUserProfile() {
        applyUserSelectedVoice()
    }
    
    // MARK: - OpenAI TTS Methods
    func speakWithOpenAI(_ text: String, voice: OpenAIVoice = .nova) {
        guard openAIService != nil else {
            print("❌ OpenAI service not configured")
            speak(text) // Fallback to system TTS
            return
        }
        
        let cleanText = cleanTextForSpeech(text)
        print("🤖 Generating OpenAI TTS for: \(cleanText)")
        
        // Stop any current speech first
        stopSpeaking()
        
        // Immediately set speaking state like system TTS
        currentSpeechText = cleanText
        isSpeaking = true
        
        // Generate and play audio in background
        Task { @MainActor in
            do {
                let audioData = try await generateOpenAIAudio(text: cleanText, voice: voice)
                await playOpenAIAudio(data: audioData)
            } catch {
                print("❌ OpenAI TTS Error: \(error)")
                // Reset speaking state and fallback to system TTS
                isSpeaking = false
                currentSpeechText = ""
                speak(cleanText)
            }
        }
    }
    
    private func generateOpenAIAudio(text: String, voice: OpenAIVoice) async throws -> Data {
        guard let openAIService = openAIService else {
            throw NSError(domain: "SpeechService", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI service not available"])
        }
        
        let url = URL(string: "https://api.openai.com/v1/audio/speech")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(openAIService.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": voice.rawValue,
            "response_format": "mp3"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        
        return data
    }
    
    @MainActor
    private func playOpenAIAudio(data: Data) async {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            // isSpeaking is already set to true when the request started
            audioPlayer?.play()
            print("🤖 Playing OpenAI generated audio")
        } catch {
            print("❌ Error playing OpenAI audio: \(error)")
            isSpeaking = false
            currentSpeechText = ""
        }
    }
    
    // MARK: - Voice Management
    private func loadAvailableVoices() {
        availableVoices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
    }
    
    func setVoice(by identifier: String) {
        if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            selectedVoice = voice
            print("🎤 Manually set voice to: \(voice.name) (\(identifier))")
        }
    }
    
    func setVoice(_ voice: AVSpeechSynthesisVoice) {
        selectedVoice = voice
        print("🎤 Voice set to: \(voice.name)")
    }
    
    // Prioritize Samantha Enhanced (Siri-quality voice)
    func useSamanthaEnhanced() {
        print("🎤 Searching for Samantha Enhanced voice...")
        
        // Try specific Samantha Enhanced identifiers first
        let samanthaEnhancedIds = [
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.voice.premium.en-US.Samantha",
            "com.apple.ttsbundle.Samantha-premium",
            "com.apple.speech.synthesis.voice.samantha.premium",
            "com.apple.speech.synthesis.voice.samantha.enhanced"
        ]
        
        for identifier in samanthaEnhancedIds {
            if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                selectedVoice = voice
                print("🎤 ✅ Found Samantha Enhanced: \(voice.name) (\(identifier))")
                speak("Samantha Enhanced activated", rate: 0.5)
                return
            }
        }
        
        // Look for Samantha by name with Enhanced quality
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let englishVoices = allVoices.filter { $0.language.hasPrefix("en") }
        
        if let samanthaEnhanced = englishVoices.first(where: { 
            $0.name.lowercased().contains("samantha") && $0.quality == .enhanced 
        }) {
            selectedVoice = samanthaEnhanced
            print("🎤 ✅ Found Samantha Enhanced by name: \(samanthaEnhanced.name)")
            speak("Samantha Enhanced found", rate: 0.5)
            return
        }
        
        // Look for any Samantha voice
        if let samanthaAny = englishVoices.first(where: { 
            $0.name.lowercased().contains("samantha") 
        }) {
            selectedVoice = samanthaAny
            print("🎤 ✅ Found Samantha voice: \(samanthaAny.name) (Quality: \(samanthaAny.quality.rawValue))")
            speak("Samantha voice activated", rate: 0.5)
            return
        }
        
        // Fallback to best enhanced voice
        if let enhancedVoice = englishVoices.first(where: { $0.quality == .enhanced }) {
            selectedVoice = enhancedVoice
            print("🎤 ⚠️ Using best enhanced voice: \(enhancedVoice.name)")
            speak("Enhanced voice activated", rate: 0.5)
            return
        }
        
        // Final fallback
        if let firstVoice = englishVoices.first {
            selectedVoice = firstVoice
            print("🎤 ❌ Using fallback voice: \(firstVoice.name)")
            speak("Fallback voice activated", rate: 0.5)
        }
    }

    // Force use Siri Voice 1 (the first high-quality voice)
    func useSiriVoice1() {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let englishVoices = allVoices.filter { $0.language.hasPrefix("en") }
        
        // Common Siri Voice 1 identifiers to try
        let siriVoice1Identifiers = [
            "com.apple.voice.premium.en-US.Zoe",
            "com.apple.voice.enhanced.en-US.Zoe", 
            "com.apple.voice.premium.en-US.Samantha",
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.speech.synthesis.voice.samantha.premium",
            "com.apple.speech.synthesis.voice.Alex"
        ]
        
        // Try each Siri Voice 1 identifier
        for identifier in siriVoice1Identifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                selectedVoice = voice
                print("🎤 Successfully set Siri Voice 1: \(voice.name) (\(identifier))")
                return
            }
        }
        
        // Try to find a voice that sounds like Siri Voice 1 by name
        let potentialSiriVoices = englishVoices.filter { voice in
            voice.name.lowercased().contains("samantha") ||
            voice.name.lowercased().contains("voice 1") ||
            voice.name.lowercased().contains("siri") ||
            voice.name.lowercased().contains("zoe")
        }
        
        if let siriVoice = potentialSiriVoices.first {
            selectedVoice = siriVoice
            print("🎤 Set to potential Siri Voice: \(siriVoice.name) (\(siriVoice.identifier))")
        } else if let firstQualityVoice = englishVoices.first(where: { $0.quality == .enhanced }) {
            selectedVoice = firstQualityVoice
            print("🎤 Set to best enhanced voice: \(firstQualityVoice.name)")
        } else if let firstVoice = englishVoices.first {
            selectedVoice = firstVoice
            print("🎤 Set to first available voice: \(firstVoice.name)")
        }
    }
    
    // Method to manually set voice by index (for testing)
    func setVoiceByIndex(_ index: Int) {
        guard index >= 0 && index < availableVoices.count else {
            print("❌ Invalid voice index: \(index)")
            return
        }
        
        let voice = availableVoices[index]
        selectedVoice = voice
        print("🎤 Set voice by index \(index): \(voice.name) (\(voice.identifier))")
    }
    
    func printAvailableVoices() {
        print("🎤 All available English voices:")
        for (index, voice) in availableVoices.enumerated() {
            let qualityText = voice.quality == .enhanced ? "✨ ENHANCED" : 
                             voice.quality == .default ? "DEFAULT" : "COMPACT"
            let isSamantha = voice.name.lowercased().contains("samantha") ? "🎯 SAMANTHA" : ""
            print("   \(index + 1). \(voice.name) - \(qualityText) \(isSamantha)")
            print("       ID: \(voice.identifier)")
        }
    }
    
    // Test method to try different voices
    func testSiriVoice1() {
        print("🎤 Testing Siri Voice 1 detection...")
        useSiriVoice1()
        if let currentVoice = selectedVoice {
            print("🎤 Current selected voice: \(currentVoice.name) (\(currentVoice.identifier))")
            // Test speak a short phrase
            speak("Hello, I am Siri Voice 1", rate: 0.5)
        } else {
            print("❌ No voice selected")
        }
    }
    
    // Quick method to force Voice 1 from your Siri settings
    func forceUseVoice1() {
        // Try the most likely identifiers for Voice 1 based on iOS versions
        let voice1Identifiers = [
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.voice.premium.en-US.Samantha", 
            "com.apple.voice.compact.en-US.Samantha",
            "com.apple.ttsbundle.Samantha-compact",
            "com.apple.speech.synthesis.voice.samantha"
        ]
        
        for identifier in voice1Identifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                selectedVoice = voice
                print("🎤 FORCED Voice 1: \(voice.name) (\(identifier))")
                speak("Voice 1 activated", rate: 0.5)
                return
            }
        }
        
        // If that fails, use the first available voice
        if let firstVoice = availableVoices.first {
            selectedVoice = firstVoice
            print("🎤 Using first available voice: \(firstVoice.name)")
            speak("Using first available voice", rate: 0.5)
        }
    }
    
    // Method specifically designed to match the Siri voices from your settings screenshot
    func selectSiriVoiceFromSettings(voiceNumber: Int) {
        print("🎤 Attempting to select Siri Voice \(voiceNumber)...")
        
        // Based on your screenshot, try to map to the correct voice
        let voiceMappings: [Int: [String]] = [
            1: ["com.apple.voice.enhanced.en-US.Samantha", "com.apple.voice.premium.en-US.Samantha"],
            2: ["com.apple.voice.enhanced.en-US.Nicky", "com.apple.voice.premium.en-US.Nicky"],
            3: ["com.apple.voice.enhanced.en-US.Aaron", "com.apple.voice.premium.en-US.Aaron"],
            4: ["com.apple.voice.enhanced.en-US.Fred", "com.apple.voice.premium.en-US.Fred"],
            5: ["com.apple.voice.enhanced.en-US.Victoria", "com.apple.voice.premium.en-US.Victoria"]
        ]
        
        if let identifiers = voiceMappings[voiceNumber] {
            for identifier in identifiers {
                if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                    selectedVoice = voice
                    print("🎤 Selected Siri Voice \(voiceNumber): \(voice.name) (\(identifier))")
                    speak("Siri Voice \(voiceNumber) selected", rate: 0.5)
                    return
                }
            }
        }
        
        print("❌ Could not find Siri Voice \(voiceNumber), using default")
        useSamanthaEnhanced()
    }
    
    // Method to specifically check for and report Samantha voices
    func checkSamanthaAvailability() {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let samanthaVoices = allVoices.filter { $0.name.lowercased().contains("samantha") }
        
        print("🎤 Samantha voices found:")
        if samanthaVoices.isEmpty {
            print("   ❌ No Samantha voices available")
            print("   💡 You may need to download voices from iOS Settings > Accessibility > Spoken Content > Voices")
        } else {
            for voice in samanthaVoices {
                let qualityText = voice.quality == .enhanced ? "✨ ENHANCED" : 
                                 voice.quality == .default ? "DEFAULT" : "COMPACT"
                print("   ✅ \(voice.name) - \(qualityText)")
                print("      ID: \(voice.identifier)")
            }
        }
    }
    
    // Force use the best available voice (Enhanced > Default > Compact)
    func useBestAvailableVoice() {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let englishVoices = allVoices.filter { $0.language.hasPrefix("en") }
        
        // Try Enhanced first
        if let enhancedVoice = englishVoices.first(where: { $0.quality == .enhanced }) {
            selectedVoice = enhancedVoice
            print("🎤 ✅ Using best enhanced voice: \(enhancedVoice.name)")
            speak("Enhanced voice activated", rate: 0.5)
            return
        }
        
        // Then Default
        if let defaultVoice = englishVoices.first(where: { $0.quality == .default }) {
            selectedVoice = defaultVoice
            print("🎤 ⚠️ Using default voice: \(defaultVoice.name)")
            speak("Default voice activated", rate: 0.5)
            return
        }
        
        // Finally Compact
        if let compactVoice = englishVoices.first {
            selectedVoice = compactVoice
            print("🎤 ❌ Using compact voice: \(compactVoice.name)")
            speak("Compact voice activated", rate: 0.5)
        }
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Speech Control Methods
    func speak(_ text: String, rate: Float = 0.5, pitch: Float = 1.0, volume: Float = 1.0) {
        // Stop any current speech
        stopSpeaking()
        
        // Clean the text for better pronunciation
        let cleanText = cleanTextForSpeech(text)
        
        let utterance = AVSpeechUtterance(string: cleanText)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume
        
        // Use selected voice or get Siri-like voice as fallback
        utterance.voice = selectedVoice ?? getSiriLikeVoice()
        
        currentSpeechText = text
        synthesizer.speak(utterance)
        
        print("🔊 Speaking: \(cleanText)")
    }
    
    func speakQuestion(_ question: String) {
        speak(question, rate: 0.4) // Slower for questions
    }
    
    func speakAnswer(_ answer: String) {
        speak("The correct answer is: \(answer)", rate: 0.45)
    }
    
    func speakExplanation(_ explanation: String) {
        speak("Explanation: \(explanation)", rate: 0.5)
    }
    
    func speakFeedback(_ feedback: String) {
        speak(feedback, rate: 0.5)
    }
    
    // MARK: - Article Reading Methods
    func speakArticle(_ article: Article) {
        let fullText = "Article: \(article.title). \(article.content)"
        speak(fullText, rate: 0.45) // Slightly slower for article reading
    }
    
    func speakArticleWithOpenAI(_ article: Article, voice: OpenAIVoice = .nova) {
        let fullText = "Article: \(article.title). \(article.content)"
        speakWithOpenAI(fullText, voice: voice)
    }
    
    func speakArticleTitle(_ title: String) {
        speak("Article: \(title)", rate: 0.4)
    }
    
    func speakArticleContent(_ content: String) {
        speak(content, rate: 0.45)
    }
    
    func pauseSpeaking() {
        if isSpeaking && !isPaused {
            synthesizer.pauseSpeaking(at: .immediate)
            isPaused = true
        }
    }
    
    func resumeSpeaking() {
        if isPaused {
            synthesizer.continueSpeaking()
            isPaused = false
        }
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        currentSpeechText = ""
    }
    
    // MARK: - Voice Selection
    private func getSiriLikeVoice() -> AVSpeechSynthesisVoice? {
        // Get all available voices and find Siri Voice 1
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let englishVoices = allVoices.filter { $0.language.hasPrefix("en") }
        
        print("🎤 Available English voices:")
        for voice in englishVoices {
            print("   - \(voice.name) (\(voice.identifier)) - Quality: \(voice.quality.rawValue)")
        }
        
        // Try to find Siri Voice 1 specifically
        let siriVoiceNames = [
            "Siri Voice 1",
            "Voice 1",
            "Samantha",
            "Samantha (Enhanced)",
            "Samantha (Premium)"
        ]
        
        // Look for Siri Voice 1 by name
        for voiceName in siriVoiceNames {
            if let siriVoice = englishVoices.first(where: { $0.name.contains(voiceName) }) {
                print("🎤 Found and using: \(siriVoice.name) (\(siriVoice.identifier))")
                return siriVoice
            }
        }
        
        // Try specific Siri voice identifiers
        let siriIdentifiers = [
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.voice.premium.en-US.Samantha",
            "com.apple.ttsbundle.siri_female_en-US_compact",
            "com.apple.ttsbundle.siri_female_en-US_premium",
            "com.apple.speech.synthesis.voice.samantha",
            "com.apple.voice.compact.en-US.Samantha"
        ]
        
        for identifier in siriIdentifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                print("🎤 Using Siri voice by identifier: \(voice.name) (\(identifier))")
                return voice
            }
        }
        
        // Prefer the highest quality voice available
        if let enhancedVoice = englishVoices.first(where: { $0.quality == .enhanced }) {
            print("🎤 Using best enhanced voice: \(enhancedVoice.name)")
            return enhancedVoice
        }
        
        // Get the first available English voice (often the best one)
        if let firstVoice = englishVoices.first {
            print("🎤 Using first available English voice: \(firstVoice.name)")
            return firstVoice
        }
        
        // Final fallback
        let fallbackVoice = AVSpeechSynthesisVoice(language: "en-US")
        print("🎤 Using system fallback voice: \(fallbackVoice?.name ?? "Default")")
        return fallbackVoice
    }
    
    // MARK: - Text Cleaning
    private func cleanTextForSpeech(_ text: String) -> String {
        var cleanText = text
        
        // Remove special quiz formatting
        cleanText = cleanText.replacingOccurrences(of: "____", with: "blank")
        cleanText = cleanText.replacingOccurrences(of: "___", with: "blank")
        cleanText = cleanText.replacingOccurrences(of: "__", with: "blank")
        cleanText = cleanText.replacingOccurrences(of: "_", with: "blank")
        
        // Handle common contractions for better pronunciation
        cleanText = cleanText.replacingOccurrences(of: "don't", with: "do not")
        cleanText = cleanText.replacingOccurrences(of: "won't", with: "will not")
        cleanText = cleanText.replacingOccurrences(of: "can't", with: "cannot")
        cleanText = cleanText.replacingOccurrences(of: "isn't", with: "is not")
        cleanText = cleanText.replacingOccurrences(of: "wasn't", with: "was not")
        cleanText = cleanText.replacingOccurrences(of: "weren't", with: "were not")
        cleanText = cleanText.replacingOccurrences(of: "hasn't", with: "has not")
        cleanText = cleanText.replacingOccurrences(of: "haven't", with: "have not")
        cleanText = cleanText.replacingOccurrences(of: "hadn't", with: "had not")
        cleanText = cleanText.replacingOccurrences(of: "didn't", with: "did not")
        cleanText = cleanText.replacingOccurrences(of: "doesn't", with: "does not")
        cleanText = cleanText.replacingOccurrences(of: "shouldn't", with: "should not")
        cleanText = cleanText.replacingOccurrences(of: "wouldn't", with: "would not")
        cleanText = cleanText.replacingOccurrences(of: "couldn't", with: "could not")
        
        // Add pauses for better comprehension
        cleanText = cleanText.replacingOccurrences(of: ".", with: ".")
        cleanText = cleanText.replacingOccurrences(of: "?", with: "?")
        cleanText = cleanText.replacingOccurrences(of: "!", with: "!")
        cleanText = cleanText.replacingOccurrences(of: ",", with: ", ")
        
        return cleanText
    }
    
    // MARK: - Convenience Methods
    var canSpeak: Bool {
        return !isSpeaking || isPaused
    }
    
    var speechControlIcon: String {
        if isSpeaking && !isPaused {
            return "pause.circle.fill"
        } else if isPaused {
            return "play.circle.fill"
        } else {
            return "waveform"
        }
    }
    
    var speechControlColor: Color {
        if isSpeaking {
            return .orange
        } else {
            return .blue
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
        isPaused = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
        currentSpeechText = ""
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isPaused = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isPaused = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
        currentSpeechText = ""
    }
}

// MARK: - AVAudioPlayerDelegate
extension SpeechService: @preconcurrency AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isSpeaking = false
        currentSpeechText = ""
        print("🤖 OpenAI audio finished playing")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isSpeaking = false
        currentSpeechText = ""
        if let error = error {
            print("❌ OpenAI audio decode error: \(error)")
        }
    }
}

// MARK: - Speech Control Button View
struct SpeechButton: View {
    let text: String
    let type: SpeechType
    @ObservedObject private var speechService = SpeechService.shared
    
    enum SpeechType {
        case question
        case answer
        case explanation
        case feedback
        case general
        
        var color: Color {
            switch self {
            case .question: return .blue
            case .answer: return .green
            case .explanation: return .orange
            case .feedback: return .purple
            case .general: return .blue
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // System TTS Button
            Button(action: {
                if speechService.isSpeaking && !speechService.isPaused {
                    speechService.pauseSpeaking()
                } else if speechService.isPaused {
                    speechService.resumeSpeaking()
                } else {
                    switch type {
                    case .question:
                        speechService.speakQuestion(text)
                    case .answer:
                        speechService.speakAnswer(text)
                    case .explanation:
                        speechService.speakExplanation(text)
                    case .feedback:
                        speechService.speakFeedback(text)
                    case .general:
                        speechService.speak(text)
                    }
                }
            }) {
                Image(systemName: speechService.speechControlIcon)
                    .font(.title2)
                    .foregroundColor(speechService.isSpeaking ? .orange : type.color)
            }
            .disabled(text.isEmpty)
            
            // OpenAI TTS Button
            Button(action: {
                if speechService.isSpeaking && !speechService.isPaused {
                    speechService.stopSpeaking()
                } else if speechService.isPaused {
                    speechService.resumeSpeaking()
                } else {
                    speechService.speakWithOpenAI(text, voice: speechService.selectedOpenAIVoice)
                }
            }) {
                Image(systemName: speechService.isSpeaking ? "stop.circle.fill" : "waveform.badge.plus")
                    .font(.title2)
                    .foregroundColor(speechService.isSpeaking ? .orange : .purple)
            }
            .disabled(text.isEmpty)
        }
    }
}

// MARK: - Speech Control Row View
struct SpeechControlRow: View {
    let text: String
    let label: String
    let type: SpeechButton.SpeechType
    
    var body: some View {
        HStack(spacing: 12) {
            SpeechButton(text: text, type: type)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(text)
                    .font(.body)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
} 