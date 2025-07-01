//
//  Quiz.swift
//  aielearn
//
//  Created by AI Assistant
//

import Foundation
import SwiftUI

// MARK: - Quiz Question Types
enum QuestionType: String, CaseIterable, Codable {
    case multipleChoice = "multipleChoice"
    case fillInTheBlank = "fillInTheBlank" 
    case trueFalse = "trueFalse"
    case matching = "matching"
    case translation = "translation"
    case conversation = "conversation" // NEW: Conversation-based quiz
    
    var icon: String {
        switch self {
        case .multipleChoice: return "list.bullet"
        case .fillInTheBlank: return "square.and.pencil"
        case .trueFalse: return "checkmark.circle"
        case .matching: return "arrow.left.arrow.right"
        case .translation: return "globe"
        case .conversation: return "bubble.left.and.bubble.right"
        }
    }
}

// MARK: - Conversation Models
struct ConversationMessage: Identifiable, Codable {
    let id = UUID()
    let speaker: String
    let message: String
    let learningElements: [LearningElement] // Highlighted learning points
}

struct LearningElement: Identifiable, Codable {
    let id = UUID()
    let text: String
    let type: LearningElementType
    let explanation: String
}

enum LearningElementType: String, CaseIterable, Codable {
    case phrasalVerb = "Phrasal Verb"
    case idiom = "Idiom"
    case vocabulary = "Vocabulary"
    case grammar = "Grammar"
    case expression = "Expression"
    
    var color: Color {
        switch self {
        case .phrasalVerb: return .blue
        case .idiom: return .purple
        case .vocabulary: return .green
        case .grammar: return .orange
        case .expression: return .pink
        }
    }
}

struct Conversation: Identifiable, Codable {
    let id = UUID()
    let title: String
    let scenario: String // e.g., "At a restaurant", "Job interview"
    let messages: [ConversationMessage]
    let topic: LearningTopic
    let difficulty: ProficiencyLevel
    let learningFocus: LearningFocus
    let estimatedReadingTime: Int // in minutes
}

// MARK: - Quiz Question Model
struct QuizQuestion: Identifiable, Codable {
    let id: UUID
    let type: QuestionType
    let question: String
    let correctAnswer: String
    let options: [String]? // Made optional for questions that don't need options
    let explanation: String
    let difficulty: ProficiencyLevel
    let topic: LearningTopic
    let focus: LearningFocus
    let conversation: Conversation? // NEW: Associated conversation for conversation-based questions
    
    var isMultipleChoice: Bool {
        return type == .multipleChoice
    }
    
    var isTrueFalse: Bool {
        return type == .trueFalse
    }
    
    var isFillInTheBlank: Bool {
        return type == .fillInTheBlank
    }
    
    var isConversation: Bool {
        return type == .conversation
    }
    
    // Helper to get options safely
    var safeOptions: [String] {
        return options ?? []
    }
    
    init(type: QuestionType, question: String, correctAnswer: String, options: [String]? = nil, explanation: String, difficulty: ProficiencyLevel, topic: LearningTopic, focus: LearningFocus, conversation: Conversation? = nil) {
        self.id = UUID()
        self.type = type
        self.question = question
        self.correctAnswer = correctAnswer
        self.options = options
        self.explanation = explanation
        self.difficulty = difficulty
        self.topic = topic
        self.focus = focus
        self.conversation = conversation
    }
}

// MARK: - Quiz Model
struct Quiz: Identifiable, Codable {
    let id: UUID
    let title: String
    let questions: [QuizQuestion]
    let estimatedDuration: Int // in minutes
    let createdAt: Date
    let topic: LearningTopic
    let difficulty: ProficiencyLevel
    let basedOnMistakes: [UUID]? // NEW: IDs of MistakeRecords if this is a mistake-based quiz
    
    var totalQuestions: Int {
        return questions.count
    }
    
    // Check if this is a mistake-based quiz
    var isMistakeBased: Bool {
        return basedOnMistakes != nil && !(basedOnMistakes?.isEmpty ?? true)
    }
    
    // Convenience initializer for regular quizzes
    init(title: String, questions: [QuizQuestion], estimatedDuration: Int, createdAt: Date, topic: LearningTopic, difficulty: ProficiencyLevel) {
        self.id = UUID()
        self.title = title
        self.questions = questions
        self.estimatedDuration = estimatedDuration
        self.createdAt = createdAt
        self.topic = topic
        self.difficulty = difficulty
        self.basedOnMistakes = nil
    }
    
    // Convenience initializer for mistake-based quizzes
    init(title: String, questions: [QuizQuestion], estimatedDuration: Int, createdAt: Date, topic: LearningTopic, difficulty: ProficiencyLevel, basedOnMistakes: [UUID]) {
        self.id = UUID()
        self.title = title
        self.questions = questions
        self.estimatedDuration = estimatedDuration
        self.createdAt = createdAt
        self.topic = topic
        self.difficulty = difficulty
        self.basedOnMistakes = basedOnMistakes
    }
}

// MARK: - Quiz Result Model
struct QuizResult: Identifiable, Codable {
    let id: UUID
    let quizId: UUID
    let score: Int
    let totalQuestions: Int
    let timeSpent: TimeInterval
    let completedAt: Date
    let answers: [String] // User's answers
    
    var percentage: Double {
        return (Double(score) / Double(totalQuestions)) * 100
    }
    
    var isPerfectScore: Bool {
        return score == totalQuestions
    }
    
    init(quizId: UUID, score: Int, totalQuestions: Int, timeSpent: TimeInterval, completedAt: Date, answers: [String]) {
        self.id = UUID()
        self.quizId = quizId
        self.score = score
        self.totalQuestions = totalQuestions
        self.timeSpent = timeSpent
        self.completedAt = completedAt
        self.answers = answers
    }
}

@MainActor
class QuizManager: ObservableObject {
    @Published var availableQuizzes: [Quiz] = []
    @Published var currentQuiz: Quiz?
    @Published var currentQuestionIndex: Int = 0
    @Published var userAnswers: [String] = []
    @Published var quizHistory: [QuizResult] = []
    @Published var errorMessage: String?
    
    // Loading state manager
    private let loadingManager = LoadingStateManager.shared
    
    // Auto-flow properties
    @Published var shouldAutoStartQuiz: Bool = false
    @Published var autoGeneratedQuiz: Quiz?
    @Published var shouldShowLearningChallenge: Bool = false
    @Published var completedQuizResult: QuizResult?
    
    private var openAIService: OpenAIService?
    
    init() {
        loadQuizHistory()
        // Remove sample quizzes - force AI generation or empty state
    }
    
    // MARK: - Computed Properties for Backward Compatibility
    var isGenerating: Bool {
        loadingManager.isLoading(.quizGeneration)
    }
    
    func setOpenAIService(_ service: OpenAIService?) {
        self.openAIService = service
    }
    
    // MARK: - Quiz Generation (AI-Powered) - ENHANCED
    func generateQuiz(for userProfile: UserProfile) {
        guard let openAIService = openAIService else {
            print("❌ OpenAI service not available - falling back to demo quiz")
            self.errorMessage = "OpenAI service not configured. Using demo quiz."
            self.generateFallbackQuiz(for: userProfile)
            return
        }
        
        print("🤖 Generating AI quiz with OpenAI...")
        
        Task { @MainActor in
            self.errorMessage = nil
            
            do {
                let selectedTopic = userProfile.selectedTopics.randomElement() ?? .dailyConversation
                let selectedFocus = userProfile.learningFocuses.randomElement() ?? .vocabulary
                
                print("📝 AI Request: \(selectedTopic.rawValue) - \(selectedFocus.rawValue) - \(userProfile.proficiencyLevel.rawValue)")
                
                let quiz = try await loadingManager.withLoadingMainActor(.quizGeneration, message: "Creating your personalized quiz...") {
                    let request = AIQuizRequest(
                        proficiencyLevel: userProfile.proficiencyLevel,
                        topic: selectedTopic,
                        focus: selectedFocus,
                        questionCount: 10
                    )
                    
                    let questions = try await openAIService.generateQuiz(request: request)
                    
                    print("✅ AI generated \(questions.count) questions successfully!")
                    
                    return Quiz(
                        title: "AI: \(selectedTopic.rawValue) - \(selectedFocus.rawValue)",
                        questions: questions,
                        estimatedDuration: questions.count * 2,
                        createdAt: Date(),
                        topic: selectedTopic,
                        difficulty: userProfile.proficiencyLevel
                    )
                }
                
                self.availableQuizzes.append(quiz)
                
            } catch {
                print("❌ AI generation failed: \(error.localizedDescription)")
                self.errorMessage = "AI generation failed: \(error.localizedDescription)"
                
                // Fallback to demo quiz if AI fails
                self.generateFallbackQuiz(for: userProfile)
            }
        }
    }
    
    // MARK: - Focused Quiz Generation
    func generateFocusedQuiz(for userProfile: UserProfile, focus: LearningFocus) {
        guard let openAIService = openAIService else {
            print("❌ OpenAI service not available - falling back to demo quiz")
            self.errorMessage = "OpenAI service not configured. Using demo quiz."
            self.generateFallbackFocusedQuiz(for: userProfile, focus: focus)
            return
        }
        
        print("🎯 Generating focused \(focus.rawValue) quiz with OpenAI...")
        
        Task { @MainActor in
            self.errorMessage = nil
            
            do {
                let selectedTopic = userProfile.selectedTopics.randomElement() ?? .dailyConversation
                
                print("📝 Focused AI Request: \(selectedTopic.rawValue) - \(focus.rawValue) - \(userProfile.proficiencyLevel.rawValue)")
                
                let quiz = try await loadingManager.withLoadingMainActor(.quizGeneration, message: "Creating \(focus.rawValue) practice quiz...") {
                    let request = AIQuizRequest(
                        proficiencyLevel: userProfile.proficiencyLevel,
                        topic: selectedTopic,
                        focus: focus,
                        questionCount: 10
                    )
                    
                    let questions = try await openAIService.generateQuiz(request: request)
                    
                    print("✅ AI generated \(questions.count) focused \(focus.rawValue) questions successfully!")
                    
                    return Quiz(
                        title: "\(focus.rawValue) Practice",
                        questions: questions,
                        estimatedDuration: questions.count * 2,
                        createdAt: Date(),
                        topic: selectedTopic,
                        difficulty: userProfile.proficiencyLevel
                    )
                }
                
                self.availableQuizzes.append(quiz)
                
            } catch {
                print("❌ Focused AI generation failed: \(error.localizedDescription)")
                self.errorMessage = "Focused quiz generation failed: \(error.localizedDescription)"
                
                // Fallback to demo quiz if AI fails
                self.generateFallbackFocusedQuiz(for: userProfile, focus: focus)
            }
        }
    }
    
    // MARK: - New Quiz Type Methods
    func generateRandomQuiz(for userProfile: UserProfile) {
        // Select random topic and focus for surprise quiz
        let randomTopic = LearningTopic.allCases.randomElement() ?? .dailyConversation
        let randomFocus = LearningFocus.allCases.randomElement() ?? .vocabulary
        
        guard let openAIService = openAIService else {
            print("❌ OpenAI service not available - falling back to demo quiz")
            self.errorMessage = "OpenAI service not configured. Using demo quiz."
            self.generateFallbackRandomQuiz(for: userProfile)
            return
        }
        
        print("🎲 Generating random quiz: \(randomTopic.rawValue) - \(randomFocus.rawValue)")
        
        Task { @MainActor in
            self.errorMessage = nil
            
            do {
                let quiz = try await loadingManager.withLoadingMainActor(.quizGeneration, message: "Creating random quiz...") {
                    let request = AIQuizRequest(
                        proficiencyLevel: userProfile.proficiencyLevel,
                        topic: randomTopic,
                        focus: randomFocus,
                        questionCount: 10
                    )
                    
                    let questions = try await openAIService.generateQuiz(request: request)
                    
                    return Quiz(
                        title: "Random: \(randomTopic.rawValue) - \(randomFocus.rawValue)",
                        questions: questions,
                        estimatedDuration: questions.count * 2,
                        createdAt: Date(),
                        topic: randomTopic,
                        difficulty: userProfile.proficiencyLevel
                    )
                }
                
                self.availableQuizzes.append(quiz)
                self.autoGeneratedQuiz = quiz
                self.shouldAutoStartQuiz = true
                
            } catch {
                print("❌ Random quiz generation failed: \(error.localizedDescription)")
                self.errorMessage = "Random quiz generation failed: \(error.localizedDescription)"
                self.generateFallbackRandomQuiz(for: userProfile)
            }
        }
    }
    
    func generateVocalQuiz(for userProfile: UserProfile) {
        // Focus on listening and speaking skills
        let selectedTopic = userProfile.selectedTopics.randomElement() ?? .dailyConversation
        
        guard let openAIService = openAIService else {
            print("❌ OpenAI service not available - falling back to demo quiz")
            self.errorMessage = "OpenAI service not configured. Using demo quiz."
            self.generateFallbackVocalQuiz(for: userProfile)
            return
        }
        
        print("🎤 Generating vocal quiz focusing on listening/speaking")
        
        Task { @MainActor in
            self.errorMessage = nil
            
            do {
                let quiz = try await loadingManager.withLoadingMainActor(.quizGeneration, message: "Creating vocal practice quiz...") {
                    let request = AIQuizRequest(
                        proficiencyLevel: userProfile.proficiencyLevel,
                        topic: selectedTopic,
                        focus: .listening, // Primary focus on listening/speaking
                        questionCount: 10
                    )
                    
                    let questions = try await openAIService.generateQuiz(request: request)
                    
                    return Quiz(
                        title: "Vocal Practice: \(selectedTopic.rawValue)",
                        questions: questions,
                        estimatedDuration: questions.count * 3, // More time for vocal practice
                        createdAt: Date(),
                        topic: selectedTopic,
                        difficulty: userProfile.proficiencyLevel
                    )
                }
                
                self.availableQuizzes.append(quiz)
                self.autoGeneratedQuiz = quiz
                self.shouldAutoStartQuiz = true
                
            } catch {
                print("❌ Vocal quiz generation failed: \(error.localizedDescription)")
                self.errorMessage = "Vocal quiz generation failed: \(error.localizedDescription)"
                self.generateFallbackVocalQuiz(for: userProfile)
            }
        }
    }
    
    func generateGrammarQuiz(for userProfile: UserProfile) {
        // Focus specifically on grammar rules and structures
        let selectedTopic = userProfile.selectedTopics.randomElement() ?? .grammar
        
        guard let openAIService = openAIService else {
            print("❌ OpenAI service not available - falling back to demo quiz")
            self.errorMessage = "OpenAI service not configured. Using demo quiz."
            self.generateFallbackGrammarQuiz(for: userProfile)
            return
        }
        
        print("📚 Generating grammar-focused quiz")
        
        Task { @MainActor in
            self.errorMessage = nil
            
            do {
                let quiz = try await loadingManager.withLoadingMainActor(.quizGeneration, message: "Creating grammar mastery quiz...") {
                    let request = AIQuizRequest(
                        proficiencyLevel: userProfile.proficiencyLevel,
                        topic: selectedTopic,
                        focus: .grammar,
                        questionCount: 10
                    )
                    
                    let questions = try await openAIService.generateQuiz(request: request)
                    
                    return Quiz(
                        title: "Grammar Mastery: \(selectedTopic.rawValue)",
                        questions: questions,
                        estimatedDuration: questions.count * 2,
                        createdAt: Date(),
                        topic: selectedTopic,
                        difficulty: userProfile.proficiencyLevel
                    )
                }
                
                self.availableQuizzes.append(quiz)
                self.autoGeneratedQuiz = quiz
                self.shouldAutoStartQuiz = true
                
            } catch {
                print("❌ Grammar quiz generation failed: \(error.localizedDescription)")
                self.errorMessage = "Grammar quiz generation failed: \(error.localizedDescription)"
                self.generateFallbackGrammarQuiz(for: userProfile)
            }
        }
    }
    
    func generateSpeakingQuiz(for userProfile: UserProfile) {
        // Focus specifically on speaking and pronunciation
        let selectedTopic = userProfile.selectedTopics.randomElement() ?? .dailyConversation
        
        guard let openAIService = openAIService else {
            print("❌ OpenAI service not available - falling back to demo quiz")
            self.errorMessage = "OpenAI service not configured. Using demo quiz."
            self.generateFallbackSpeakingQuiz(for: userProfile)
            return
        }
        
        print("🗣️ Generating speaking-focused quiz")
        
        Task { @MainActor in
            self.errorMessage = nil
            
            do {
                let quiz = try await loadingManager.withLoadingMainActor(.quizGeneration, message: "Creating speaking practice quiz...") {
                    let request = AIQuizRequest(
                        proficiencyLevel: userProfile.proficiencyLevel,
                        topic: selectedTopic,
                        focus: .speaking,
                        questionCount: 10
                    )
                    
                    let questions = try await openAIService.generateQuiz(request: request)
                    
                    return Quiz(
                        title: "Speaking Practice: \(selectedTopic.rawValue)",
                        questions: questions,
                        estimatedDuration: questions.count * 3, // More time for speaking practice
                        createdAt: Date(),
                        topic: selectedTopic,
                        difficulty: userProfile.proficiencyLevel
                    )
                }
                
                self.availableQuizzes.append(quiz)
                self.autoGeneratedQuiz = quiz
                self.shouldAutoStartQuiz = true
                
            } catch {
                print("❌ Speaking quiz generation failed: \(error.localizedDescription)")
                self.errorMessage = "Speaking quiz generation failed: \(error.localizedDescription)"
                self.generateFallbackSpeakingQuiz(for: userProfile)
            }
        }
    }
    
    func generateConversationQuiz(for userProfile: UserProfile) {
        // Generate conversation-based learning quiz
        let selectedTopic = userProfile.selectedTopics.randomElement() ?? .dailyConversation
        let selectedFocus = userProfile.learningFocuses.randomElement() ?? .phrasalVerbs
        
        guard let openAIService = openAIService else {
            print("❌ OpenAI service not available - falling back to demo conversation")
            self.errorMessage = "OpenAI service not configured. Using demo conversation."
            self.generateFallbackConversationQuiz(for: userProfile)
            return
        }
        
        print("💬 Generating conversation-based quiz: \(selectedTopic.rawValue)")
        
        Task { @MainActor in
            self.errorMessage = nil
            
            do {
                let quiz = try await loadingManager.withLoadingMainActor(.quizGeneration, message: "Creating conversation quiz...") {
                    let request = AIConversationRequest(
                        proficiencyLevel: userProfile.proficiencyLevel,
                        topic: selectedTopic,
                        focus: selectedFocus,
                        scenario: nil // Let AI choose appropriate scenario
                    )
                    
                    let conversationResponse = try await openAIService.generateConversation(request: request)
                    
                    return Quiz(
                        title: conversationResponse.conversation.title,
                        questions: conversationResponse.questions,
                        estimatedDuration: conversationResponse.conversation.estimatedReadingTime + conversationResponse.questions.count * 2,
                        createdAt: Date(),
                        topic: selectedTopic,
                        difficulty: userProfile.proficiencyLevel
                    )
                }
                
                self.availableQuizzes.append(quiz)
                self.autoGeneratedQuiz = quiz
                self.shouldAutoStartQuiz = true
                
                print("✅ Generated conversation quiz: \(quiz.title)")
                
            } catch {
                print("❌ Conversation quiz generation failed: \(error.localizedDescription)")
                self.errorMessage = "Conversation quiz generation failed: \(error.localizedDescription)"
                self.generateFallbackConversationQuiz(for: userProfile)
            }
        }
    }
    
    func generateDailyChallengeQuiz(for userProfile: UserProfile) {
        // Generate a special daily challenge quiz with mixed content
        let challengeTopics = Array(userProfile.selectedTopics)
        let challengeFocuses = Array(userProfile.learningFocuses)
        
        let selectedTopic = challengeTopics.randomElement() ?? .dailyConversation
        let selectedFocus = challengeFocuses.randomElement() ?? .vocabulary
        
        guard let openAIService = openAIService else {
            print("❌ OpenAI service not available - falling back to demo quiz")
            self.errorMessage = "OpenAI service not configured. Using demo quiz."
            self.generateFallbackDailyChallengeQuiz(for: userProfile)
            return
        }
        
        print("🏆 Generating daily challenge quiz")
        
        Task { @MainActor in
            self.errorMessage = nil
            
            do {
                let quiz = try await loadingManager.withLoadingMainActor(.quizGeneration, message: "Creating daily challenge quiz...") {
                    let request = AIQuizRequest(
                        proficiencyLevel: userProfile.proficiencyLevel,
                        topic: selectedTopic,
                        focus: selectedFocus,
                        questionCount: 7 // Slightly longer for daily challenge
                    )
                    
                    let questions = try await openAIService.generateQuiz(request: request)
                    
                    return Quiz(
                        title: "Daily Challenge: \(selectedTopic.rawValue)",
                        questions: questions,
                        estimatedDuration: questions.count * 2,
                        createdAt: Date(),
                        topic: selectedTopic,
                        difficulty: userProfile.proficiencyLevel
                    )
                }
                
                self.availableQuizzes.append(quiz)
                self.autoGeneratedQuiz = quiz
                self.shouldAutoStartQuiz = true
                
            } catch {
                print("❌ Daily challenge generation failed: \(error.localizedDescription)")
                self.errorMessage = "Daily challenge generation failed: \(error.localizedDescription)"
                self.generateFallbackDailyChallengeQuiz(for: userProfile)
            }
        }
    }
    
    // MARK: - Mistake-Based Quiz Generation (NEW)
    
    func generateMistakeBasedQuiz(for userProfile: UserProfile, mistakes: [MistakeRecord]) {
        guard !mistakes.isEmpty else {
            print("📚 No mistakes available for quiz generation")
            self.errorMessage = "No mistakes available for quiz generation. Great job!"
            return
        }
        
        guard let openAIService = openAIService else {
            print("❌ OpenAI service not available - falling back to demo mistake quiz")
            self.errorMessage = "OpenAI service not configured. Using demo mistake quiz."
            self.generateFallbackMistakeQuiz(for: userProfile, mistakes: mistakes)
            return
        }
        
        print("🎯 Generating mistake-based quiz with \(mistakes.count) mistakes")
        
        Task { @MainActor in
            self.errorMessage = nil
            
            do {
                let quiz = try await loadingManager.withLoadingMainActor(.mistakeQuizGeneration, message: "Creating quiz from your mistakes...") {
                    let questions = try await openAIService.generateMistakeBasedQuiz(
                        mistakes: mistakes,
                        userProfile: userProfile
                    )
                    
                    return Quiz(
                        title: "Review Your Mistakes",
                        questions: questions,
                        estimatedDuration: questions.count * 3, // More time for reviewing mistakes
                        createdAt: Date(),
                        topic: .grammar, // Will be mixed topics from mistakes
                        difficulty: userProfile.proficiencyLevel,
                        basedOnMistakes: mistakes.map { $0.id }
                    )
                }
                
                self.availableQuizzes.append(quiz)
                self.autoGeneratedQuiz = quiz
                self.shouldAutoStartQuiz = true
                
                print("✅ Generated mistake-based quiz with \(quiz.questions.count) questions")
                
            } catch {
                print("❌ Mistake-based quiz generation failed: \(error.localizedDescription)")
                self.errorMessage = "Mistake-based quiz generation failed: \(error.localizedDescription)"
                self.generateFallbackMistakeQuiz(for: userProfile, mistakes: mistakes)
            }
        }
    }
    
    func generateQuickMistakeReview(for userProfile: UserProfile, mistakeManager: MistakeManager) {
        let pendingMistakes = mistakeManager.getMistakesForReview()
        
        guard !pendingMistakes.isEmpty else {
            print("🎉 No pending mistakes to review!")
            self.shouldShowLearningChallenge = true
            return
        }
        
        // Take up to 5 most recent mistakes for quick review
        let reviewMistakes = Array(pendingMistakes.prefix(5))
        self.generateMistakeBasedQuiz(for: userProfile, mistakes: reviewMistakes)
    }
    
    private func generateFallbackQuiz(for userProfile: UserProfile) {
        print("📋 Generating demo quiz (fallback)")
        // Simulate AI generation delay for fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let quiz = self.createPersonalizedQuiz(for: userProfile)
            self.availableQuizzes.append(quiz)
        }
    }
    
    private func generateFallbackFocusedQuiz(for userProfile: UserProfile, focus: LearningFocus) {
        print("📋 Generating focused demo quiz (fallback)")
        // Simulate AI generation delay for fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let quiz = self.createFocusedPersonalizedQuiz(for: userProfile, focus: focus)
            self.availableQuizzes.append(quiz)
        }
    }
    
    // MARK: - Fallback Methods for New Quiz Types
    private func generateFallbackRandomQuiz(for userProfile: UserProfile) {
        print("📋 Generating random demo quiz (fallback)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let randomTopic = LearningTopic.allCases.randomElement() ?? .dailyConversation
            let randomFocus = LearningFocus.allCases.randomElement() ?? .vocabulary
            let quiz = self.createSpecificQuiz(for: userProfile, topic: randomTopic, focus: randomFocus, title: "Random: \(randomTopic.rawValue)")
            self.availableQuizzes.append(quiz)
            self.autoGeneratedQuiz = quiz
            self.shouldAutoStartQuiz = true
        }
    }
    
    private func generateFallbackVocalQuiz(for userProfile: UserProfile) {
        print("📋 Generating vocal demo quiz (fallback)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let selectedTopic = userProfile.selectedTopics.randomElement() ?? .dailyConversation
            let quiz = self.createSpecificQuiz(for: userProfile, topic: selectedTopic, focus: .listening, title: "Vocal Practice: \(selectedTopic.rawValue)")
            self.availableQuizzes.append(quiz)
            self.autoGeneratedQuiz = quiz
            self.shouldAutoStartQuiz = true
        }
    }
    
    private func generateFallbackGrammarQuiz(for userProfile: UserProfile) {
        print("📋 Generating grammar demo quiz (fallback)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let quiz = self.createSpecificQuiz(for: userProfile, topic: .grammar, focus: .grammar, title: "Grammar Mastery")
            self.availableQuizzes.append(quiz)
            self.autoGeneratedQuiz = quiz
            self.shouldAutoStartQuiz = true
        }
    }
    
    private func generateFallbackSpeakingQuiz(for userProfile: UserProfile) {
        print("📋 Generating speaking demo quiz (fallback)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let selectedTopic = userProfile.selectedTopics.randomElement() ?? .dailyConversation
            let quiz = self.createSpecificQuiz(for: userProfile, topic: selectedTopic, focus: .speaking, title: "Speaking Practice: \(selectedTopic.rawValue)")
            self.availableQuizzes.append(quiz)
            self.autoGeneratedQuiz = quiz
            self.shouldAutoStartQuiz = true
        }
    }
    
    private func generateFallbackConversationQuiz(for userProfile: UserProfile) {
        print("📋 Generating conversation demo quiz (fallback)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let selectedTopic = userProfile.selectedTopics.randomElement() ?? .dailyConversation
            let selectedFocus = userProfile.learningFocuses.randomElement() ?? .phrasalVerbs
            let quiz = self.createConversationQuiz(for: userProfile, topic: selectedTopic, focus: selectedFocus)
            self.availableQuizzes.append(quiz)
            self.autoGeneratedQuiz = quiz
            self.shouldAutoStartQuiz = true
        }
    }
    
    private func generateFallbackDailyChallengeQuiz(for userProfile: UserProfile) {
        print("📋 Generating daily challenge demo quiz (fallback)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let challengeTopics = Array(userProfile.selectedTopics)
            let challengeFocuses = Array(userProfile.learningFocuses)
            
            let selectedTopic = challengeTopics.randomElement() ?? .dailyConversation
            let selectedFocus = challengeFocuses.randomElement() ?? .vocabulary
            
            let quiz = self.createSpecificQuiz(for: userProfile, topic: selectedTopic, focus: selectedFocus, title: "Daily Challenge: \(selectedTopic.rawValue)")
            self.availableQuizzes.append(quiz)
            self.autoGeneratedQuiz = quiz
            self.shouldAutoStartQuiz = true
        }
    }
    
    private func generateFallbackMistakeQuiz(for userProfile: UserProfile, mistakes: [MistakeRecord]) {
        print("📋 Generating mistake-based demo quiz (fallback)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let quiz = self.createMistakeBasedQuiz(for: userProfile, mistakes: mistakes)
            self.availableQuizzes.append(quiz)
            self.autoGeneratedQuiz = quiz
            self.shouldAutoStartQuiz = true
        }
    }
    
    private func createSpecificQuiz(for userProfile: UserProfile, topic: LearningTopic, focus: LearningFocus, title: String) -> Quiz {
        let questions = generateQuestionsFor(
            topic: topic,
            focus: focus,
            level: userProfile.proficiencyLevel
        )
        
        return Quiz(
            title: title,
            questions: questions,
            estimatedDuration: questions.count * 2,
            createdAt: Date(),
            topic: topic,
            difficulty: userProfile.proficiencyLevel
        )
    }
    
    private func createMistakeBasedQuiz(for userProfile: UserProfile, mistakes: [MistakeRecord]) -> Quiz {
        // Convert mistakes to quiz questions
        let questions = mistakes.prefix(10).map { mistake in
            QuizQuestion(
                type: mistake.questionType,
                question: mistake.question,
                correctAnswer: mistake.correctAnswer,
                options: mistake.options,
                explanation: mistake.explanation,
                difficulty: mistake.difficulty,
                topic: mistake.topic,
                focus: mistake.focus
            )
        }
        
        return Quiz(
            title: "Review Your Mistakes",
            questions: Array(questions),
            estimatedDuration: questions.count * 3,
            createdAt: Date(),
            topic: .grammar, // Mixed topics
            difficulty: userProfile.proficiencyLevel,
            basedOnMistakes: mistakes.map { $0.id }
        )
    }
    
    private func createConversationQuiz(for userProfile: UserProfile, topic: LearningTopic, focus: LearningFocus) -> Quiz {
        // Create demo conversation with questions
        let scenario = getScenarioFor(topic: topic)
        
        let conversation = Conversation(
            title: "Demo: \(scenario)",
            scenario: scenario,
            messages: createDemoMessages(for: topic, focus: focus),
            topic: topic,
            difficulty: userProfile.proficiencyLevel,
            learningFocus: focus,
            estimatedReadingTime: 3
        )
        
        let questions = createConversationQuestions(for: conversation, userProfile: userProfile)
        
        return Quiz(
            title: conversation.title,
            questions: questions,
            estimatedDuration: conversation.estimatedReadingTime + questions.count * 2,
            createdAt: Date(),
            topic: topic,
            difficulty: userProfile.proficiencyLevel
        )
    }
    
    private func getScenarioFor(topic: LearningTopic) -> String {
        switch topic {
        case .travel: return "At the Airport"
        case .business: return "Job Interview"
        case .dailyConversation: return "Meeting a Friend"
        case .academic: return "Study Group"
        case .entertainment: return "Planning Weekend"
        case .technology: return "Tech Support"
        case .grammar: return "English Lesson"
        case .general: return "Everyday Conversation"
        }
    }
    
    private func createDemoMessages(for topic: LearningTopic, focus: LearningFocus) -> [ConversationMessage] {
        switch topic {
        case .travel:
            return [
                ConversationMessage(
                    speaker: "Sarah",
                    message: "I'm really looking forward to our trip!",
                    learningElements: [
                        LearningElement(text: "looking forward to", type: .phrasalVerb, explanation: "To anticipate with pleasure")
                    ]
                ),
                ConversationMessage(
                    speaker: "Mike",
                    message: "Me too! I've been brushing up on my Spanish.",
                    learningElements: [
                        LearningElement(text: "brushing up on", type: .phrasalVerb, explanation: "To review or practice")
                    ]
                ),
                ConversationMessage(
                    speaker: "Sarah",
                    message: "Good idea! It'll come in handy at the hotel.",
                    learningElements: [
                        LearningElement(text: "come in handy", type: .idiom, explanation: "To be useful")
                    ]
                )
            ]
        case .business:
            return [
                ConversationMessage(
                    speaker: "Interviewer",
                    message: "Could you walk me through your experience?",
                    learningElements: [
                        LearningElement(text: "walk me through", type: .phrasalVerb, explanation: "To explain step by step")
                    ]
                ),
                ConversationMessage(
                    speaker: "Candidate",
                    message: "I'm eager to take on new challenges.",
                    learningElements: [
                        LearningElement(text: "take on", type: .phrasalVerb, explanation: "To accept or handle")
                    ]
                )
            ]
        default:
            return [
                ConversationMessage(
                    speaker: "Alex",
                    message: "It's been ages since we caught up!",
                    learningElements: [
                        LearningElement(text: "it's been ages", type: .expression, explanation: "It's been a long time")
                    ]
                ),
                ConversationMessage(
                    speaker: "Jordan",
                    message: "I know! I've been swamped with work.",
                    learningElements: [
                        LearningElement(text: "swamped", type: .vocabulary, explanation: "Very busy")
                    ]
                )
            ]
        }
    }
    
    private func createConversationQuestions(for conversation: Conversation, userProfile: UserProfile) -> [QuizQuestion] {
        return [
            QuizQuestion(
                type: .multipleChoice,
                question: "What does 'looking forward to' mean?",
                correctAnswer: "Anticipating with pleasure",
                options: ["Anticipating with pleasure", "Looking backwards", "Being worried", "Forgetting"],
                explanation: "'Looking forward to' means to anticipate something with pleasure.",
                difficulty: userProfile.proficiencyLevel,
                topic: conversation.topic,
                focus: conversation.learningFocus,
                conversation: conversation
            ),
            QuizQuestion(
                type: .fillInTheBlank,
                question: "Complete: 'I've been _____ up on my Spanish.'",
                correctAnswer: "brushing",
                options: ["brushing", "looking", "catching", "picking"],
                explanation: "'Brushing up on' means to review or practice something.",
                difficulty: userProfile.proficiencyLevel,
                topic: conversation.topic,
                focus: conversation.learningFocus,
                conversation: conversation
            ),
            QuizQuestion(
                type: .multipleChoice,
                question: "What does 'come in handy' mean?",
                correctAnswer: "Be useful",
                options: ["Be useful", "Come by hand", "Be difficult", "Be expensive"],
                explanation: "'Come in handy' means to be useful or helpful.",
                difficulty: userProfile.proficiencyLevel,
                topic: conversation.topic,
                focus: conversation.learningFocus,
                conversation: conversation
            ),
            QuizQuestion(
                type: .trueFalse,
                question: "The speakers are discussing work.",
                correctAnswer: "False",
                options: ["True", "False"],
                explanation: "The speakers are discussing a personal trip, not work.",
                difficulty: userProfile.proficiencyLevel,
                topic: conversation.topic,
                focus: conversation.learningFocus,
                conversation: conversation
            ),
            QuizQuestion(
                type: .multipleChoice,
                question: "Which phrasal verb was mentioned?",
                correctAnswer: "brushing up on",
                options: ["brushing up on", "looking down on", "catching up with", "picking up from"],
                explanation: "'Brushing up on' was used to describe practicing Spanish.",
                difficulty: userProfile.proficiencyLevel,
                topic: conversation.topic,
                focus: conversation.learningFocus,
                conversation: conversation
            )
        ]
    }
    
    private func createPersonalizedQuiz(for userProfile: UserProfile) -> Quiz {
        let selectedTopic = userProfile.selectedTopics.randomElement() ?? .dailyConversation
        let selectedFocus = userProfile.learningFocuses.randomElement() ?? .vocabulary
        
        let questions = generateQuestionsFor(
            topic: selectedTopic,
            focus: selectedFocus,
            level: userProfile.proficiencyLevel
        )
        
        return Quiz(
            title: "Demo: \(selectedTopic.rawValue) - \(selectedFocus.rawValue)",
            questions: questions,
            estimatedDuration: questions.count * 2, // 2 minutes per question
            createdAt: Date(),
            topic: selectedTopic,
            difficulty: userProfile.proficiencyLevel
        )
    }
    
    private func createFocusedPersonalizedQuiz(for userProfile: UserProfile, focus: LearningFocus) -> Quiz {
        let selectedTopic = userProfile.selectedTopics.randomElement() ?? .dailyConversation
        
        let questions = generateQuestionsFor(
            topic: selectedTopic,
            focus: focus,
            level: userProfile.proficiencyLevel
        )
        
        return Quiz(
            title: "\(focus.rawValue) Practice",
            questions: questions,
            estimatedDuration: questions.count * 2, // 2 minutes per question
            createdAt: Date(),
            topic: selectedTopic,
            difficulty: userProfile.proficiencyLevel
        )
    }
    
    private func generateQuestionsFor(topic: LearningTopic, focus: LearningFocus, level: ProficiencyLevel) -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        
        // Generate 10 questions per quiz
        for _ in 0..<5 {
            let questionType = QuestionType.allCases.randomElement() ?? .multipleChoice
            let question = createQuestion(type: questionType, topic: topic, focus: focus, level: level)
            questions.append(question)
        }
        
        return questions
    }
    
    private func createQuestion(type: QuestionType, topic: LearningTopic, focus: LearningFocus, level: ProficiencyLevel) -> QuizQuestion {
        // This is a simplified version - in a real app, this would use AI API
        switch (topic, focus, type) {
        case (.travel, .vocabulary, .multipleChoice):
            return QuizQuestion(
                type: type,
                question: "What do you call the place where you stay when traveling?",
                correctAnswer: "Hotel",
                options: ["Hotel", "Restaurant", "Airport", "Museum"],
                explanation: "A hotel is a commercial establishment that provides lodging for travelers.",
                difficulty: level,
                topic: topic,
                focus: focus
            )
            
        case (.business, .grammar, .fillInTheBlank):
            return QuizQuestion(
                type: type,
                question: "I _____ to attend the meeting tomorrow.",
                correctAnswer: "need",
                options: ["need", "needs", "needed", "needing"],
                explanation: "Use 'need' with 'I' in present tense.",
                difficulty: level,
                topic: topic,
                focus: focus
            )
            
        case (.dailyConversation, .phrasalVerbs, .multipleChoice):
            return QuizQuestion(
                type: type,
                question: "What does 'catch up' mean in conversation?",
                correctAnswer: "To talk and share recent news",
                options: ["To talk and share recent news", "To run faster", "To grab something", "To wake up early"],
                explanation: "'Catch up' means to talk with someone you haven't seen for a while and share recent news.",
                difficulty: level,
                topic: topic,
                focus: focus
            )
            
        default:
            // Default fallback question
            return QuizQuestion(
                type: .multipleChoice,
                question: "Which word means 'very good'?",
                correctAnswer: "Excellent",
                options: ["Excellent", "Terrible", "Average", "Poor"],
                explanation: "Excellent means of very high quality or extremely good.",
                difficulty: level,
                topic: topic,
                focus: focus
            )
        }
    }
    
    // MARK: - Quiz Session Management
    func startQuiz(_ quiz: Quiz) {
        currentQuiz = quiz
        currentQuestionIndex = 0
        userAnswers = Array(repeating: "", count: quiz.questions.count)
    }
    
    func submitAnswer(_ answer: String) {
        guard currentQuestionIndex < userAnswers.count else { return }
        userAnswers[currentQuestionIndex] = answer
    }
    
    func nextQuestion() {
        if currentQuestionIndex < (currentQuiz?.questions.count ?? 0) - 1 {
            currentQuestionIndex += 1
        }
    }
    
    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    func finishQuiz() -> QuizResult? {
        guard let quiz = currentQuiz else { return nil }
        
        var score = 0
        for (index, answer) in userAnswers.enumerated() {
            if index < quiz.questions.count && answer.lowercased() == quiz.questions[index].correctAnswer.lowercased() {
                score += 1
            }
        }
        
        let result = QuizResult(
            quizId: quiz.id,
            score: score,
            totalQuestions: quiz.questions.count,
            timeSpent: 0, // Would track actual time in real implementation
            completedAt: Date(),
            answers: userAnswers
        )
        
        quizHistory.append(result)
        saveQuizHistory()
        
        // Reset current quiz session
        currentQuiz = nil
        currentQuestionIndex = 0
        userAnswers = []
        
        return result
    }
    
    // MARK: - Auto-Flow Methods
    func completeQuizWithAutoFlow(_ result: QuizResult) {
        // Save the quiz result first
        quizHistory.append(result)
        saveQuizHistory()
        
        // Set up for learning challenge
        completedQuizResult = result
        shouldShowLearningChallenge = true
        
        // Reset current quiz session
        currentQuiz = nil
        currentQuestionIndex = 0
        userAnswers = []
        
        print("🎓 Quiz completed with auto-flow - triggering learning challenge")
    }
    
    func resetAutoFlowState() {
        shouldAutoStartQuiz = false
        autoGeneratedQuiz = nil
        shouldShowLearningChallenge = false
        completedQuizResult = nil
    }
    
    // MARK: - AI Answer Verification
    func verifyAnswer(questionIndex: Int, userAnswer: String) async -> AIVerificationResult? {
        guard let quiz = currentQuiz,
              questionIndex < quiz.questions.count,
              let openAIService = openAIService else {
            return nil
        }
        
        let question = quiz.questions[questionIndex]
        
        let verification = AIAnswerVerification(
            question: question.question,
            correctAnswer: question.correctAnswer,
            userAnswer: userAnswer,
            questionType: question.type
        )
        
        do {
            return try await openAIService.verifyAnswer(verification: verification)
        } catch {
            // Fallback to simple verification
            let isCorrect = userAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == 
                          question.correctAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            return AIVerificationResult(
                isCorrect: isCorrect,
                explanation: question.explanation,
                feedback: isCorrect ? "Correct! Well done!" : "Not quite right. Keep practicing!"
            )
        }
    }
    
    // MARK: - Data Persistence
    private func loadQuizHistory() {
        if let data = UserDefaults.standard.data(forKey: "quizHistory"),
           let history = try? JSONDecoder().decode([QuizResult].self, from: data) {
            quizHistory = history
        }
    }
    
    private func saveQuizHistory() {
        if let data = try? JSONEncoder().encode(quizHistory) {
            UserDefaults.standard.set(data, forKey: "quizHistory")
        }
    }
    
    // MARK: - Sample Data Generation
    private func generateSampleQuizzes() {
        // Generate some sample quizzes for immediate use
        let sampleQuiz1 = Quiz(
            title: "Daily Conversation - Vocabulary",
            questions: [
                QuizQuestion(
                    type: .multipleChoice,
                    question: "How do you greet someone in the morning?",
                    correctAnswer: "Good morning",
                    options: ["Good morning", "Good night", "Good afternoon", "Good evening"],
                    explanation: "Good morning is used as a greeting from dawn until noon.",
                    difficulty: .beginner,
                    topic: .dailyConversation,
                    focus: .vocabulary
                ),
                QuizQuestion(
                    type: .fillInTheBlank,
                    question: "Nice to _____ you!",
                    correctAnswer: "meet",
                    options: ["meet", "meat", "met", "meeting"],
                    explanation: "'Nice to meet you' is a common greeting when meeting someone for the first time.",
                    difficulty: .beginner,
                    topic: .dailyConversation,
                    focus: .vocabulary
                )
            ],
            estimatedDuration: 4,
            createdAt: Date(),
            topic: .dailyConversation,
            difficulty: .beginner
        )
        
        availableQuizzes = [sampleQuiz1]
    }
    
    // MARK: - Analytics
    var averageScore: Double {
        guard !quizHistory.isEmpty else { return 0 }
        let totalPercentage = quizHistory.reduce(0) { $0 + $1.percentage }
        return totalPercentage / Double(quizHistory.count)
    }
    
    func getRecentPerformance() -> [QuizResult] {
        let sortedHistory = quizHistory.sorted { $0.completedAt > $1.completedAt }
        return Array(sortedHistory.prefix(10))
    }
} 

