//
//  Article.swift
//  aielearn
//
//  Created by AI Assistant
//

import Foundation
import SwiftUI

// MARK: - Article Model
struct Article: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let topic: LearningTopic
    let difficulty: ProficiencyLevel
    let estimatedReadingTime: Int // in minutes
    let wordCount: Int
    let createdAt: Date
    let tags: [String]
    let summary: String // Brief description of the article
    
    init(title: String, content: String, topic: LearningTopic, difficulty: ProficiencyLevel, estimatedReadingTime: Int, wordCount: Int, tags: [String] = [], summary: String) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.topic = topic
        self.difficulty = difficulty
        self.estimatedReadingTime = estimatedReadingTime
        self.wordCount = wordCount
        self.createdAt = Date()
        self.tags = tags
        self.summary = summary
    }
}

// MARK: - Article Reading Session
struct ArticleReadingSession: Identifiable, Codable {
    let id: UUID
    let articleId: UUID
    let userId: UUID?
    let startTime: Date
    let endTime: Date?
    let isCompleted: Bool
    let readingProgress: Double // 0.0 to 1.0
    
    var readingDuration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    init(articleId: UUID, userId: UUID? = nil) {
        self.id = UUID()
        self.articleId = articleId
        self.userId = userId
        self.startTime = Date()
        self.endTime = nil
        self.isCompleted = false
        self.readingProgress = 0.0
    }
    
    // Method to complete reading session
    func completed(with progress: Double = 1.0) -> ArticleReadingSession {
        return ArticleReadingSession(
            id: self.id,
            articleId: self.articleId,
            userId: self.userId,
            startTime: self.startTime,
            endTime: Date(),
            isCompleted: true,
            readingProgress: progress
        )
    }
    
    private init(id: UUID, articleId: UUID, userId: UUID?, startTime: Date, endTime: Date?, isCompleted: Bool, readingProgress: Double) {
        self.id = id
        self.articleId = articleId
        self.userId = userId
        self.startTime = startTime
        self.endTime = endTime
        self.isCompleted = isCompleted
        self.readingProgress = readingProgress
    }
}

// MARK: - Article Quiz Result
struct ArticleQuizResult: Identifiable, Codable {
    let id: UUID
    let articleId: UUID
    let quizResult: QuizResult
    let comprehensionScore: Double // 0.0 to 1.0
    
    init(articleId: UUID, quizResult: QuizResult) {
        self.id = UUID()
        self.articleId = articleId
        self.quizResult = quizResult
        self.comprehensionScore = quizResult.percentage / 100.0
    }
}

// MARK: - Article Generation Request
struct ArticleGenerationRequest {
    let topic: LearningTopic
    let difficulty: ProficiencyLevel
    let focus: LearningFocus
    let wordCount: Int
    let specificSubject: String? // Optional specific topic within the learning area
    
    init(topic: LearningTopic, difficulty: ProficiencyLevel, focus: LearningFocus, wordCount: Int = 250, specificSubject: String? = nil) {
        self.topic = topic
        self.difficulty = difficulty
        self.focus = focus
        self.wordCount = max(200, wordCount) // Ensure minimum 200 words
        self.specificSubject = specificSubject
    }
}

// MARK: - Article with Questions Response
struct ArticleWithQuestions {
    let article: Article
    let questions: [QuizQuestion]
    let estimatedQuizDuration: Int // in minutes
    
    init(article: Article, questions: [QuizQuestion]) {
        self.article = article
        self.questions = questions
        self.estimatedQuizDuration = max(1, questions.count * 1) // 1 minute per question minimum
    }
}

// MARK: - Article Question Generation Request
struct ArticleQuestionGenerationRequest {
    let article: Article
    let questionCount: Int
    
    init(article: Article, questionCount: Int = 10) {
        self.article = article
        self.questionCount = max(5, min(questionCount, 15)) // Between 5-15 questions
    }
}

// MARK: - Reading Statistics
struct ReadingStats: Codable {
    let totalArticlesRead: Int
    let totalReadingTime: TimeInterval // in seconds
    let averageComprehensionScore: Double
    let articlesCompletedThisWeek: Int
    let currentReadingStreak: Int // consecutive days with reading activity
    let favoriteTopics: [LearningTopic]
    
    var averageReadingTimePerArticle: TimeInterval {
        guard totalArticlesRead > 0 else { return 0 }
        return totalReadingTime / Double(totalArticlesRead)
    }
    
    var formattedTotalReadingTime: String {
        let hours = Int(totalReadingTime) / 3600
        let minutes = Int(totalReadingTime.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    init() {
        self.totalArticlesRead = 0
        self.totalReadingTime = 0
        self.averageComprehensionScore = 0.0
        self.articlesCompletedThisWeek = 0
        self.currentReadingStreak = 0
        self.favoriteTopics = []
    }
} 