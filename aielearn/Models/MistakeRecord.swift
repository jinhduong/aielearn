//
//  MistakeRecord.swift
//  aielearn
//
//  Created by AI Assistant
//

import Foundation
import SwiftUI

// MARK: - Mistake Record Model
struct MistakeRecord: Identifiable, Codable {
    let id = UUID()
    let question: String
    let correctAnswer: String
    let userAnswer: String
    let explanation: String
    let feedback: String? // AI-generated feedback if available
    let questionType: QuestionType
    let difficulty: ProficiencyLevel
    let topic: LearningTopic
    let focus: LearningFocus
    let createdAt: Date
    let options: [String]? // For multiple choice questions
    
    // For tracking review progress
    var reviewCount: Int = 0
    var lastReviewedAt: Date?
    var masteredAt: Date? // When user consistently gets it right
    
    var isMastered: Bool {
        return masteredAt != nil
    }
    
    var daysSinceCreated: Int {
        return Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
    
    var needsReview: Bool {
        guard let lastReviewed = lastReviewedAt else { return true }
        let daysSinceReview = Calendar.current.dateComponents([.day], from: lastReviewed, to: Date()).day ?? 0
        
        // Spaced repetition logic
        switch reviewCount {
        case 0: return true
        case 1: return daysSinceReview >= 1
        case 2: return daysSinceReview >= 3
        case 3: return daysSinceReview >= 7
        case 4: return daysSinceReview >= 14
        default: return daysSinceReview >= 30
        }
    }
}

// MARK: - Mistake Manager
class MistakeManager: ObservableObject {
    @Published var mistakes: [MistakeRecord] = []
    @Published var isLoading = false
    
    private let storageKey = "AIELearn_Mistakes"
    
    init() {
        loadMistakes()
    }
    
    // MARK: - Core Functions
    func saveMistake(
        question: String,
        correctAnswer: String,
        userAnswer: String,
        explanation: String,
        feedback: String? = nil,
        questionType: QuestionType,
        difficulty: ProficiencyLevel,
        topic: LearningTopic,
        focus: LearningFocus,
        options: [String]? = nil
    ) {
        let mistake = MistakeRecord(
            question: question,
            correctAnswer: correctAnswer,
            userAnswer: userAnswer,
            explanation: explanation,
            feedback: feedback,
            questionType: questionType,
            difficulty: difficulty,
            topic: topic,
            focus: focus,
            createdAt: Date(),
            options: options
        )
        
        // Check if we already have this exact mistake (to avoid duplicates)
        if !mistakes.contains(where: { $0.question == question && $0.correctAnswer == correctAnswer }) {
            mistakes.insert(mistake, at: 0) // Add to beginning for most recent first
            saveMistakes()
            print("💾 Saved mistake: \(question)")
        }
    }
    
    func markAsReviewed(_ mistake: MistakeRecord, wasCorrect: Bool) {
        if let index = mistakes.firstIndex(where: { $0.id == mistake.id }) {
            var updatedMistake = mistakes[index]
            updatedMistake.reviewCount += 1
            updatedMistake.lastReviewedAt = Date()
            
            // Mark as mastered if answered correctly multiple times
            if wasCorrect && updatedMistake.reviewCount >= 3 {
                updatedMistake.masteredAt = Date()
            }
            
            mistakes[index] = updatedMistake
            saveMistakes()
            print("📚 Updated review for: \(mistake.question)")
        }
    }
    
    func deleteMistake(_ mistake: MistakeRecord) {
        mistakes.removeAll { $0.id == mistake.id }
        saveMistakes()
    }
    
    func clearAllMasteredMistakes() {
        mistakes.removeAll { $0.isMastered }
        saveMistakes()
    }
    
    // MARK: - Computed Properties
    var pendingReviewCount: Int {
        return mistakes.filter { $0.needsReview && !$0.isMastered }.count
    }
    
    var masteredCount: Int {
        return mistakes.filter { $0.isMastered }.count
    }
    
    var totalMistakeCount: Int {
        return mistakes.count
    }
    
    func getMistakesForReview() -> [MistakeRecord] {
        return mistakes.filter { $0.needsReview && !$0.isMastered }
    }
    
    func getMistakesByTopic() -> [LearningTopic: [MistakeRecord]] {
        return Dictionary(grouping: mistakes.filter { !$0.isMastered }) { $0.topic }
    }
    
    func getMistakesByFocus() -> [LearningFocus: [MistakeRecord]] {
        return Dictionary(grouping: mistakes.filter { !$0.isMastered }) { $0.focus }
    }
    
    // MARK: - Data Persistence
    private func loadMistakes() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decodedMistakes = try? JSONDecoder().decode([MistakeRecord].self, from: data) {
            mistakes = decodedMistakes
            print("📚 Loaded \(mistakes.count) mistake records")
        }
    }
    
    private func saveMistakes() {
        if let data = try? JSONEncoder().encode(mistakes) {
            UserDefaults.standard.set(data, forKey: storageKey)
            print("💾 Saved \(mistakes.count) mistake records")
        }
    }
} 