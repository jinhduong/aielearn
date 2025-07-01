//
//  UserProfile.swift
//  aielearn
//
//  Created by AI Assistant
//

import Foundation
import SwiftUI
import AVFoundation

// MARK: - Enums for User Preferences
enum ProficiencyLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var description: String {
        return self.rawValue
    }
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

enum LearningTopic: String, CaseIterable, Codable {
    case general = "General"
    case travel = "Travel"
    case business = "Business"
    case dailyConversation = "Daily Conversation"
    case academic = "Academic"
    case entertainment = "Entertainment"
    case technology = "Technology"
    case grammar = "Grammar"
    
    var icon: String {
        switch self {
        case .general: return "book.pages"
        case .travel: return "airplane"
        case .business: return "briefcase"
        case .dailyConversation: return "message"
        case .academic: return "book"
        case .entertainment: return "tv"
        case .technology: return "laptopcomputer"
        case .grammar: return "textformat"
        }
    }
    
    var color: Color {
        switch self {
        case .general: return .gray
        case .travel: return .blue
        case .business: return .purple
        case .dailyConversation: return .green
        case .academic: return .orange
        case .entertainment: return .pink
        case .technology: return .cyan
        case .grammar: return .red
        }
    }
}

enum LearningFocus: String, CaseIterable, Codable {
    case vocabulary = "Vocabulary"
    case grammar = "Grammar"
    case phrasalVerbs = "Phrasal Verbs"
    case listening = "Listening"
    case speaking = "Speaking"
    case reading = "Reading"
    case writing = "Writing"
    
    var icon: String {
        switch self {
        case .vocabulary: return "textbook"
        case .grammar: return "textformat"
        case .phrasalVerbs: return "text.bubble"
        case .listening: return "ear"
        case .speaking: return "mic"
        case .reading: return "book.pages"
        case .writing: return "square.and.pencil"
        }
    }
}

// MARK: - User Profile Observable Object
class UserProfile: ObservableObject {
    @Published var isOnboardingCompleted: Bool = false
    @Published var proficiencyLevel: ProficiencyLevel = .beginner
    @Published var selectedTopics: Set<LearningTopic> = []
    @Published var learningFocuses: Set<LearningFocus> = []
    @Published var currentStreak: Int = 0
    @Published var totalQuizzesCompleted: Int = 0
    @Published var totalCorrectAnswers: Int = 0
    @Published var totalPoints: Int = 0
    @Published var badges: Set<Badge> = []
    @Published var weeklyProgress: [Date: Int] = [:]
    @Published var selectedVoiceIdentifier: String = ""
    
    // MARK: - Reading Progress (NEW)
    @Published var totalArticlesRead: Int = 0
    @Published var totalReadingTime: TimeInterval = 0 // in seconds
    @Published var averageReadingComprehension: Double = 0.0 // 0.0 to 1.0
    @Published var readingStreak: Int = 0
    @Published var articlesReadThisWeek: Int = 0
    
    init() {
        loadUserData()
    }
    
    // MARK: - User Data Persistence
    private func loadUserData() {
        isOnboardingCompleted = UserDefaults.standard.bool(forKey: "isOnboardingCompleted")
        
        if let levelString = UserDefaults.standard.string(forKey: "proficiencyLevel"),
           let level = ProficiencyLevel(rawValue: levelString) {
            proficiencyLevel = level
        }
        
        if let topicsData = UserDefaults.standard.data(forKey: "selectedTopics"),
           let topics = try? JSONDecoder().decode(Set<LearningTopic>.self, from: topicsData) {
            selectedTopics = topics
        }
        
        if let focusData = UserDefaults.standard.data(forKey: "learningFocuses"),
           let focuses = try? JSONDecoder().decode(Set<LearningFocus>.self, from: focusData) {
            learningFocuses = focuses
        }
        
        currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        totalQuizzesCompleted = UserDefaults.standard.integer(forKey: "totalQuizzesCompleted")
        totalCorrectAnswers = UserDefaults.standard.integer(forKey: "totalCorrectAnswers")
        totalPoints = UserDefaults.standard.integer(forKey: "totalPoints")
        selectedVoiceIdentifier = UserDefaults.standard.string(forKey: "selectedVoiceIdentifier") ?? ""
        
        // Load reading progress
        totalArticlesRead = UserDefaults.standard.integer(forKey: "totalArticlesRead")
        totalReadingTime = UserDefaults.standard.double(forKey: "totalReadingTime")
        averageReadingComprehension = UserDefaults.standard.double(forKey: "averageReadingComprehension")
        readingStreak = UserDefaults.standard.integer(forKey: "readingStreak")
        articlesReadThisWeek = UserDefaults.standard.integer(forKey: "articlesReadThisWeek")
        
        // Set default to best quality voice if not set
        if selectedVoiceIdentifier.isEmpty {
            selectedVoiceIdentifier = getBestQualityVoiceIdentifier()
        }
    }
    
    func saveUserData() {
        UserDefaults.standard.set(isOnboardingCompleted, forKey: "isOnboardingCompleted")
        UserDefaults.standard.set(proficiencyLevel.rawValue, forKey: "proficiencyLevel")
        
        if let topicsData = try? JSONEncoder().encode(selectedTopics) {
            UserDefaults.standard.set(topicsData, forKey: "selectedTopics")
        }
        
        if let focusData = try? JSONEncoder().encode(learningFocuses) {
            UserDefaults.standard.set(focusData, forKey: "learningFocuses")
        }
        
        UserDefaults.standard.set(currentStreak, forKey: "currentStreak")
        UserDefaults.standard.set(totalQuizzesCompleted, forKey: "totalQuizzesCompleted")
        UserDefaults.standard.set(totalCorrectAnswers, forKey: "totalCorrectAnswers")
        UserDefaults.standard.set(totalPoints, forKey: "totalPoints")
        UserDefaults.standard.set(selectedVoiceIdentifier, forKey: "selectedVoiceIdentifier")
        
        // Save reading progress
        UserDefaults.standard.set(totalArticlesRead, forKey: "totalArticlesRead")
        UserDefaults.standard.set(totalReadingTime, forKey: "totalReadingTime")
        UserDefaults.standard.set(averageReadingComprehension, forKey: "averageReadingComprehension")
        UserDefaults.standard.set(readingStreak, forKey: "readingStreak")
        UserDefaults.standard.set(articlesReadThisWeek, forKey: "articlesReadThisWeek")
    }
    
    // MARK: - Progress Tracking
    func completeQuiz(score: Int, totalQuestions: Int) {
        totalQuizzesCompleted += 1
        totalCorrectAnswers += score
        totalPoints += score * 10 // 10 points per correct answer
        
        // Update streak
        let today = Calendar.current.startOfDay(for: Date())
        if weeklyProgress[today] != nil {
            weeklyProgress[today]! += 1
        } else {
            weeklyProgress[today] = 1
            updateStreak()
        }
        
        checkForNewBadges()
        saveUserData()
    }
    
    // MARK: - Reading Progress Tracking (NEW)
    func completeArticleReading(readingTime: TimeInterval) {
        totalArticlesRead += 1
        totalReadingTime += readingTime
        articlesReadThisWeek += 1
        totalPoints += 5 // 5 points for reading an article
        
        // Update reading streak
        let today = Calendar.current.startOfDay(for: Date())
        if weeklyProgress[today] != nil {
            weeklyProgress[today]! += 1
        } else {
            weeklyProgress[today] = 1
            updateReadingStreak()
        }
        
        checkForNewBadges()
        saveUserData()
    }
    
    func recordReadingComprehension(score: Double) {
        // Update average comprehension using running average
        let totalComprehensionScore = averageReadingComprehension * Double(totalArticlesRead - 1) + score
        averageReadingComprehension = totalComprehensionScore / Double(totalArticlesRead)
        
        // Award points based on comprehension
        let comprehensionPoints = Int(score * 10) // Up to 10 points for perfect comprehension
        totalPoints += comprehensionPoints
        
        saveUserData()
    }
    
    private func updateReadingStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        if weeklyProgress[yesterday] != nil || weeklyProgress[today] != nil {
            readingStreak += 1
        } else {
            readingStreak = 1
        }
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        if weeklyProgress[yesterday] != nil || weeklyProgress[today] != nil {
            currentStreak += 1
        } else {
            currentStreak = 1
        }
    }
    
    private func checkForNewBadges() {
        // Check for various badge achievements
        if totalQuizzesCompleted >= 1 && !badges.contains(.firstQuiz) {
            badges.insert(.firstQuiz)
        }
        
        if currentStreak >= 7 && !badges.contains(.weekStreak) {
            badges.insert(.weekStreak)
        }
        
        if totalPoints >= 100 && !badges.contains(.centurion) {
            badges.insert(.centurion)
        }
        
        // Reading badge achievements
        if totalArticlesRead >= 1 && !badges.contains(.firstArticle) {
            badges.insert(.firstArticle)
        }
        
        if totalArticlesRead >= 10 && !badges.contains(.bookworm) {
            badges.insert(.bookworm)
        }
        
        if totalReadingTime >= 3600 && !badges.contains(.speedReader) { // 1 hour of reading
            badges.insert(.speedReader)
        }
        
        if averageReadingComprehension >= 0.9 && totalArticlesRead >= 5 && !badges.contains(.comprehensionExpert) {
            badges.insert(.comprehensionExpert)
        }
        
        if readingStreak >= 7 && !badges.contains(.readingStreak) {
            badges.insert(.readingStreak)
        }
    }
    
    var accuracyPercentage: Double {
        guard totalQuizzesCompleted > 0 else { return 0 }
        return (Double(totalCorrectAnswers) / Double(totalQuizzesCompleted * 10)) * 100 // Assuming 10 questions per quiz
    }
    
    // MARK: - Convenience Properties for Reading Feature
    var preferredTopic: LearningTopic {
        return selectedTopics.first ?? .general
    }
    
    var learningFocus: LearningFocus {
        return learningFocuses.first ?? .reading
    }
    
    // MARK: - Voice Selection Methods
    func getHighQualityVoices() -> [VoiceOption] {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let englishVoices = allVoices.filter { $0.language.hasPrefix("en") }
        
        // Filter for Q2 (Default) and Q3 (Enhanced) quality voices
        let highQualityVoices = englishVoices.filter { voice in
            voice.quality == .enhanced || voice.quality == .default
        }
        
        // Sort by quality (Enhanced first, then Default)
        let sortedVoices = highQualityVoices.sorted { lhs, rhs in
            if lhs.quality == .enhanced && rhs.quality != .enhanced {
                return true
            } else if lhs.quality != .enhanced && rhs.quality == .enhanced {
                return false
            }
            return lhs.name < rhs.name
        }
        
        return sortedVoices.map { voice in
            VoiceOption(
                identifier: voice.identifier,
                name: voice.name,
                quality: voice.quality,
                language: voice.language
            )
        }
    }
    
    func getBestQualityVoiceIdentifier() -> String {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let englishVoices = allVoices.filter { $0.language.hasPrefix("en") }
        
        // Try to find Enhanced Samantha first (Q3 best quality)
        if let enhancedSamantha = englishVoices.first(where: { 
            $0.name.lowercased().contains("samantha") && $0.quality == .enhanced 
        }) {
            return enhancedSamantha.identifier
        }
        
        // Then any Enhanced voice (Q3)
        if let enhancedVoice = englishVoices.first(where: { $0.quality == .enhanced }) {
            return enhancedVoice.identifier
        }
        
        // Fallback to any Samantha voice
        if let samanthaVoice = englishVoices.first(where: { 
            $0.name.lowercased().contains("samantha") 
        }) {
            return samanthaVoice.identifier
        }
        
        // Final fallback to first available voice
        return englishVoices.first?.identifier ?? ""
    }
    
    @MainActor
    func setSelectedVoice(_ voiceIdentifier: String) {
        selectedVoiceIdentifier = voiceIdentifier
        saveUserData()
        
        // Update the speech service to use the new voice
        if let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            SpeechService.shared.setVoice(voice)
        }
    }
}

// MARK: - Badge System
enum Badge: String, CaseIterable, Codable {
    case firstQuiz = "First Quiz"
    case weekStreak = "Week Streak"
    case centurion = "Centurion"
    case perfectScore = "Perfect Score"
    case vocabularyMaster = "Vocabulary Master"
    case grammarGuru = "Grammar Guru"
    
    // Reading badges
    case firstArticle = "First Article"
    case bookworm = "Bookworm"
    case speedReader = "Speed Reader"
    case comprehensionExpert = "Comprehension Expert"
    case readingStreak = "Reading Streak"
    
    var icon: String {
        switch self {
        case .firstQuiz: return "star.fill"
        case .weekStreak: return "flame.fill"
        case .centurion: return "crown.fill"
        case .perfectScore: return "target"
        case .vocabularyMaster: return "book.fill"
        case .grammarGuru: return "pencil.and.ruler.fill"
        case .firstArticle: return "book.pages.fill"
        case .bookworm: return "books.vertical.fill"
        case .speedReader: return "bolt.fill"
        case .comprehensionExpert: return "brain.head.profile"
        case .readingStreak: return "calendar.badge.plus"
        }
    }
    
    var color: Color {
        switch self {
        case .firstQuiz: return .yellow
        case .weekStreak: return .orange
        case .centurion: return .purple
        case .perfectScore: return .green
        case .vocabularyMaster: return .blue
        case .grammarGuru: return .red
        case .firstArticle: return .cyan
        case .bookworm: return .brown
        case .speedReader: return .pink
        case .comprehensionExpert: return .indigo
        case .readingStreak: return .teal
        }
    }
}

// MARK: - Voice Option Model
struct VoiceOption: Identifiable, Hashable {
    let id = UUID()
    let identifier: String
    let name: String
    let quality: AVSpeechSynthesisVoiceQuality
    let language: String
    
    var qualityDisplayName: String {
        switch quality {
        case .enhanced:
            return "✨ Enhanced (Q3)"
        case .default:
            return "🔊 Standard (Q2)"
        default:
            return "📢 Basic (Q1)"
        }
    }
    
    var displayName: String {
        return "\(name) - \(qualityDisplayName)"
    }
}

 