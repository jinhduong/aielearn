//
//  OpenAIService.swift
//  aielearn
//
//  Created by AI Assistant
//

import Foundation

// MARK: - OpenAI API Models
struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let maxTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?
}

struct OpenAIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Conversation Generation Models
struct AIConversationRequest {
    let proficiencyLevel: ProficiencyLevel
    let topic: LearningTopic
    let focus: LearningFocus
    let scenario: String? // Optional specific scenario
}

struct AIConversationResponse {
    let conversation: Conversation
    let questions: [QuizQuestion]
}

// MARK: - Quiz Generation Models
struct AIQuizRequest {
    let proficiencyLevel: ProficiencyLevel
    let topic: LearningTopic
    let focus: LearningFocus
    let questionCount: Int
}

struct AIAnswerVerification {
    let question: String
    let correctAnswer: String
    let userAnswer: String
    let questionType: QuestionType
}

struct AIVerificationResult {
    let isCorrect: Bool
    let explanation: String
    let feedback: String
}

// MARK: - OpenAI Service
class OpenAIService: ObservableObject {
    let apiKey: String  // Made public for TTS usage
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Quiz Generation
    func generateQuiz(request: AIQuizRequest) async throws -> [QuizQuestion] {
        // For testing - check if API key starts with "test" or "demo"
        if apiKey.lowercased().hasPrefix("test") || apiKey.lowercased().hasPrefix("demo") {
            print("🧪 Using test mode - generating mock AI response")
            return try generateTestQuiz(request: request)
        }
        
        let prompt = createQuizGenerationPrompt(request: request)
        
        let response = try await makeOpenAIRequest(prompt: prompt, temperature: 0.7, maxTokens: 2000)
        
        guard let content = response.choices.first?.message.content else {
            throw OpenAIError.invalidResponse
        }
        
        return try parseQuizResponse(content: content, request: request)
    }
    
    // MARK: - Mistake-Based Quiz Generation (NEW)
    func generateMistakeBasedQuiz(mistakes: [MistakeRecord], userProfile: UserProfile) async throws -> [QuizQuestion] {
        // For testing - check if API key starts with "test" or "demo"
        if apiKey.lowercased().hasPrefix("test") || apiKey.lowercased().hasPrefix("demo") {
            print("🧪 Using test mode - generating mock mistake-based quiz response")
            return try generateTestMistakeQuiz(mistakes: mistakes, userProfile: userProfile)
        }
        
        let prompt = createMistakeBasedQuizPrompt(mistakes: mistakes, userProfile: userProfile)
        
        let response = try await makeOpenAIRequest(prompt: prompt, temperature: 0.8, maxTokens: 2500)
        
        guard let content = response.choices.first?.message.content else {
            throw OpenAIError.invalidResponse
        }
        
        return try parseMistakeQuizResponse(content: content, mistakes: mistakes, userProfile: userProfile)
    }
    
    private func generateTestQuiz(request: AIQuizRequest) throws -> [QuizQuestion] {
        // Simulate AI-generated content with diverse, interesting English learning questions
        let testQuestions = [
            QuizQuestion(
                type: .multipleChoice,
                question: "Which word means 'extremely tired'?",
                correctAnswer: "exhausted",
                options: ["exhausted", "excited", "excellent", "expensive"],
                explanation: "'Exhausted' means completely tired or drained of energy. It's a stronger word than 'tired'.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .fillInTheBlank,
                question: "I need to ___ up early tomorrow for my interview.",
                correctAnswer: "wake",
                options: ["wake", "get", "stand", "pick"],
                explanation: "'Wake up' is a phrasal verb meaning to stop sleeping and become alert.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .multipleChoice,
                question: "What does the idiom 'break the ice' mean?",
                correctAnswer: "start a conversation",
                options: ["start a conversation", "fix something", "be very cold", "break something"],
                explanation: "'Break the ice' means to start a conversation or make people feel more comfortable in a social situation.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .fillInTheBlank,
                question: "She ___ been working on this project all week.",
                correctAnswer: "has",
                options: ["has", "have", "had", "having"],
                explanation: "We use 'has' with third person singular (she/he/it) in present perfect tense.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .multipleChoice,
                question: "Which combination is correct?",
                correctAnswer: "make a decision",
                options: ["make a decision", "do a decision", "take a decision", "have a decision"],
                explanation: "'Make a decision' is the most common and natural collocation in English.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .trueFalse,
                question: "The word 'beautiful' can be used to describe both people and things.",
                correctAnswer: "True",
                options: ["True", "False"],
                explanation: "'Beautiful' is a versatile adjective that can describe people, objects, places, experiences, and more.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .fillInTheBlank,
                question: "This movie is really ___.",
                correctAnswer: "entertaining",
                options: ["entertaining", "entertainment", "entertained", "entertain"],
                explanation: "We use 'entertaining' (adjective) to describe something that provides amusement or enjoyment.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .multipleChoice,
                question: "What's the best way to improve your English vocabulary?",
                correctAnswer: "Read regularly and use new words in context",
                options: ["Read regularly and use new words in context", "Memorize word lists only", "Avoid difficult words", "Use only translation apps"],
                explanation: "Regular reading and using new words in context helps with retention and understanding of natural usage.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .fillInTheBlank,
                question: "I'm looking ___ to seeing you next week.",
                correctAnswer: "forward",
                options: ["forward", "ahead", "up", "down"],
                explanation: "'Look forward to' is a phrasal verb meaning to anticipate something with pleasure.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .multipleChoice,
                question: "Which sentence has the correct word order?",
                correctAnswer: "I usually drink coffee in the morning.",
                options: ["I usually drink coffee in the morning.", "I drink usually coffee in the morning.", "Usually I drink coffee in the morning.", "I drink coffee usually in the morning."],
                explanation: "Adverbs of frequency (usually) typically come before the main verb but after the verb 'to be'.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus
            )
        ]
        
        return Array(testQuestions.prefix(request.questionCount))
    }
    
    private func generateTestMistakeQuiz(mistakes: [MistakeRecord], userProfile: UserProfile) throws -> [QuizQuestion] {
        // Generate similar questions to the mistakes but with variations to test understanding
        let questions = mistakes.prefix(10).compactMap { mistake -> QuizQuestion? in
            // Create variation questions based on the mistake pattern
            switch mistake.questionType {
            case .multipleChoice:
                return QuizQuestion(
                    type: .multipleChoice,
                    question: "Review: \(mistake.question)",
                    correctAnswer: mistake.correctAnswer,
                    options: mistake.options ?? [mistake.correctAnswer, mistake.userAnswer, generateDistractor(), generateDistractor()],
                    explanation: "This is based on a mistake you made before. \(mistake.explanation)",
                    difficulty: mistake.difficulty,
                    topic: mistake.topic,
                    focus: mistake.focus
                )
            case .fillInTheBlank:
                return QuizQuestion(
                    type: .fillInTheBlank,
                    question: mistake.question, // Reuse the original question
                    correctAnswer: mistake.correctAnswer,
                    options: mistake.options,
                    explanation: "Let's review this concept: \(mistake.explanation)",
                    difficulty: mistake.difficulty,
                    topic: mistake.topic,
                    focus: mistake.focus
                )
            default:
                return QuizQuestion(
                    type: mistake.questionType,
                    question: mistake.question,
                    correctAnswer: mistake.correctAnswer,
                    options: mistake.options,
                    explanation: "Review: \(mistake.explanation)",
                    difficulty: mistake.difficulty,
                    topic: mistake.topic,
                    focus: mistake.focus
                )
            }
        }
        
        return Array(questions)
    }
    
    private func generateDistractor() -> String {
        let distractors = ["although", "however", "because", "therefore", "meanwhile", "nevertheless", "furthermore", "consequently"]
        return distractors.randomElement() ?? "other"
    }
    
    private func createMistakeBasedQuizPrompt(mistakes: [MistakeRecord], userProfile: UserProfile) -> String {
        let mistakeDescriptions = mistakes.prefix(10).map { mistake in
            """
            - Question: "\(mistake.question)"
            - Correct Answer: "\(mistake.correctAnswer)"
            - User's Wrong Answer: "\(mistake.userAnswer)"
            - Topic: \(mistake.topic.rawValue)
            - Focus: \(mistake.focus.rawValue)
            - Explanation: \(mistake.explanation)
            """
        }.joined(separator: "\n\n")
        
        return """
        Create a personalized review quiz based on the user's previous mistakes. The user is at \(userProfile.proficiencyLevel.rawValue.lowercased()) level.
        
        Previous Mistakes:
        \(mistakeDescriptions)
        
        Create questions that help the user master these concepts. Don't just repeat the exact same questions - create similar questions that test the same underlying concepts and patterns.
        
        Please return ONLY a valid JSON array with this exact format:
        [
          {
            "type": "multipleChoice",
            "question": "Question text here",
            "correctAnswer": "Correct answer",
            "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
            "explanation": "Detailed explanation connecting to their previous mistake"
          }
        ]
        
        Requirements:
        - Create \(min(mistakes.count, 10)) questions based on the mistakes above
        - Focus on the same concepts but with slight variations to ensure understanding
        - Include the user's previous wrong answers as distractors where appropriate
        - Provide explanations that reference their learning progress
        - Mix question types but match the focus areas where the user struggled
        - Make questions progressively build understanding of the concepts they missed
        - Use encouraging language that acknowledges their learning journey
        
        Return ONLY the JSON array, no other text.
        """
    }
    
    private func parseMistakeQuizResponse(content: String, mistakes: [MistakeRecord], userProfile: UserProfile) throws -> [QuizQuestion] {
        print("🔍 Parsing mistake quiz response content: \(content.prefix(200))...")
        
        // Clean the response - remove any markdown formatting
        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanContent.data(using: .utf8) else {
            print("❌ Failed to convert cleaned content to data")
            throw OpenAIError.invalidResponse
        }
        
        struct AIQuizQuestion: Codable {
            let type: String
            let question: String
            let correctAnswer: String
            let options: [String]?
            let explanation: String
        }
        
        do {
            let aiQuestions = try JSONDecoder().decode([AIQuizQuestion].self, from: data)
            print("✅ Successfully parsed \(aiQuestions.count) mistake-based questions")
            
            return aiQuestions.enumerated().map { index, aiQuestion in
                let questionType = QuestionType(rawValue: aiQuestion.type) ?? .multipleChoice
                let mistake = mistakes[safe: index] ?? mistakes.first!
                
                let questionOptions: [String]?
                if let options = aiQuestion.options {
                    questionOptions = options
                } else if questionType == .trueFalse {
                    questionOptions = ["True", "False"]
                } else {
                    questionOptions = nil
                }
                
                return QuizQuestion(
                    type: questionType,
                    question: aiQuestion.question,
                    correctAnswer: aiQuestion.correctAnswer,
                    options: questionOptions,
                    explanation: aiQuestion.explanation,
                    difficulty: mistake.difficulty,
                    topic: mistake.topic,
                    focus: mistake.focus
                )
            }
        } catch {
            print("❌ Failed to decode mistake quiz questions: \(error)")
            throw OpenAIError.invalidResponse
        }
    }
    
    // MARK: - Answer Verification
    func verifyAnswer(verification: AIAnswerVerification) async throws -> AIVerificationResult {
        let prompt = createAnswerVerificationPrompt(verification: verification)
        
        let response = try await makeOpenAIRequest(prompt: prompt, temperature: 0.3, maxTokens: 500)
        
        guard let content = response.choices.first?.message.content else {
            throw OpenAIError.invalidResponse
        }
        
        return try parseVerificationResponse(content: content)
    }
    
    // MARK: - Conversation Generation
    func generateConversation(request: AIConversationRequest) async throws -> AIConversationResponse {
        print("🤖 Generating AI conversation...")
        
        // For testing - check if API key starts with "test" or "demo"
        if apiKey.lowercased().hasPrefix("test") || apiKey.lowercased().hasPrefix("demo") {
            print("🧪 Using test mode - generating mock conversation response")
            return try generateTestConversation(request: request)
        }
        
        let prompt = createConversationPrompt(request: request)
        
        let response = try await makeOpenAIRequest(prompt: prompt, temperature: 0.7, maxTokens: 2500)
        
        guard let content = response.choices.first?.message.content else {
            throw OpenAIError.invalidResponse
        }
        
        return try parseConversationResponse(content: content, request: request)
    }
    
    // MARK: - Private Methods
    private func makeOpenAIRequest(prompt: String, temperature: Double, maxTokens: Int) async throws -> OpenAIResponse {
        print("🔑 Making OpenAI request with API key: \(apiKey.isEmpty ? "EMPTY" : "***\(apiKey.suffix(4))")")
        
        guard !apiKey.isEmpty else {
            print("❌ API key is empty!")
            throw OpenAIError.noAPIKey
        }
        
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL: \(baseURL)")
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let openAIRequest = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIMessage(role: "system", content: "You are an expert English language learning assistant that creates engaging and educational quizzes."),
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(openAIRequest)
            print("📤 Sending request to OpenAI...")
        } catch {
            print("❌ Failed to encode request: \(error)")
            throw error
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")  
            throw OpenAIError.invalidResponse
        }
        
        print("📥 OpenAI response status: \(httpResponse.statusCode)")
        
        // Log response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response data: \(responseString.prefix(500))...")
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ OpenAI API error: \(httpResponse.statusCode)")
            // Try to parse error response
            if let errorString = String(data: data, encoding: .utf8) {
                print("🔍 Error details: \(errorString)")
            }
            throw OpenAIError.apiError(httpResponse.statusCode)
        }
        
        do {
            let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            print("✅ Successfully decoded OpenAI response")
            return decoded
        } catch {
            print("❌ Failed to decode OpenAI response: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 Raw response: \(responseString)")
            }
            throw OpenAIError.invalidResponse
        }
    }
    
    private func createQuizGenerationPrompt(request: AIQuizRequest) -> String {
        return """
        Create \(request.questionCount) engaging English language learning quiz questions for a \(request.proficiencyLevel.rawValue.lowercased()) level student.
        
        English Skill Focus: \(request.focus.rawValue)
        
        IMPORTANT: Create diverse and interesting English language questions that teach practical vocabulary, grammar, and language patterns. 
        Use varied, engaging scenarios and contexts - don't limit yourself to any specific topic.
        Focus on teaching ENGLISH LANGUAGE SKILLS through interesting and diverse content.
        
        Please return ONLY a valid JSON array with this exact format:
        [
          {
            "type": "multipleChoice",
            "question": "Question text here",
            "correctAnswer": "Correct answer",
            "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
            "explanation": "Detailed explanation of why this is correct"
          }
        ]
        
        Requirements:
        - Mix question types: multipleChoice, fillInTheBlank, trueFalse
        - Focus on \(request.focus.rawValue.lowercased()) skills: grammar, vocabulary usage, sentence structure, word forms, etc.
        - Use diverse, interesting scenarios and vocabulary from different areas of life
        - Include modern, useful vocabulary that English learners encounter today
        - Questions should teach English language patterns and practical usage
        - Appropriate difficulty for \(request.proficiencyLevel.rawValue.lowercased()) level English learners
        - Use engaging, real-world contexts and situations
        - Provide educational explanations about English language rules and usage
        - For multiple choice, always provide exactly 4 options
        - For fill in the blank, put the blank as "___" in the question
        - For true/false, the correctAnswer should be "True" or "False"
        
        Examples of GOOD diverse English learning questions:
        - Grammar: "Complete the sentence: 'She ___ been working on this project all week.' (has/have/had/having)"
        - Vocabulary: "Which word means 'extremely tired'? (exhausted/excited/excellent/expensive)"  
        - Sentence structure: "What's the correct word order: 'I usually ___ coffee in the morning.' (drink/drinking/drank/drunk)"
        - Word forms: "The correct form is: 'This movie is really ___' (entertainment/entertaining/entertained/entertain)"
        - Phrasal verbs: "Fill in the blank: 'I need to ___ up early tomorrow.' (wake/get/stand/pick)"
        - Idioms: "What does 'break the ice' mean? (start a conversation/fix something/be very cold/break something)"
        - Collocations: "Which combination is correct? (make a decision/do a decision/take a decision/have a decision)"
        
        Focus on:
        - Common phrasal verbs and their meanings
        - Useful collocations and natural word combinations  
        - Practical vocabulary for daily situations
        - Grammar patterns that students often struggle with
        - Interesting idioms and expressions
        - Word formation and different word forms
        - Sentence patterns and structures
        - Pronunciation-related questions (for advanced levels)
        
        Make the content engaging and relevant to modern English usage!
        
        Return ONLY the JSON array, no other text.
        """
    }
    
    private func createAnswerVerificationPrompt(verification: AIAnswerVerification) -> String {
        return """
        Verify this English learning quiz answer:
        
        Question: \(verification.question)
        Correct Answer: \(verification.correctAnswer)
        User Answer: \(verification.userAnswer)
        Question Type: \(verification.questionType.rawValue)
        
        Please return ONLY a valid JSON object with this exact format:
        {
          "isCorrect": true/false,
          "explanation": "Detailed explanation of the correct answer",
          "feedback": "Encouraging feedback for the user"
        }
        
        Guidelines:
        - Be accurate but understanding in your evaluation
        - For language learning, consider minor spelling/grammar variations
        - Provide constructive feedback that helps learning
        - If incorrect, explain why and provide the right approach
        - Keep feedback encouraging and educational
        
        Return ONLY the JSON object, no other text.
        """
    }
    
    private func parseQuizResponse(content: String, request: AIQuizRequest) throws -> [QuizQuestion] {
        print("🔍 Parsing quiz response content: \(content.prefix(200))...")
        
        // Clean the response - remove any markdown formatting
        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🧹 Cleaned content: \(cleanContent.prefix(200))...")
        
        guard let data = cleanContent.data(using: .utf8) else {
            print("❌ Failed to convert cleaned content to data")
            throw OpenAIError.invalidResponse
        }
        
        struct AIQuizQuestion: Codable {
            let type: String
            let question: String
            let correctAnswer: String
            let options: [String]? // Made optional for questions that don't need options
            let explanation: String
        }
        
        do {
            let aiQuestions = try JSONDecoder().decode([AIQuizQuestion].self, from: data)
            print("✅ Successfully parsed \(aiQuestions.count) questions")
            
            return aiQuestions.map { aiQuestion in
                let questionType = QuestionType(rawValue: aiQuestion.type) ?? .multipleChoice
                
                // Handle optional options - provide appropriate defaults based on question type
                let questionOptions: [String]?
                if let options = aiQuestion.options {
                    questionOptions = options
                } else {
                    // For true/false questions, provide True/False options
                    if questionType == .trueFalse {
                        questionOptions = ["True", "False"]
                    } else {
                        // For fill-in-the-blank and other types, no options needed
                        questionOptions = nil
                    }
                }
                
                return QuizQuestion(
                    type: questionType,
                    question: aiQuestion.question,
                    correctAnswer: aiQuestion.correctAnswer,
                    options: questionOptions,
                    explanation: aiQuestion.explanation,
                    difficulty: request.proficiencyLevel,
                    topic: request.topic,
                    focus: request.focus
                )
            }
        } catch {
            print("❌ Failed to decode quiz questions: \(error)")
            print("🔍 Trying to decode as generic JSON...")
            
            // Try to parse as generic JSON to see the structure
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                print("📋 JSON structure: \(jsonObject)")
            }
            
            throw OpenAIError.invalidResponse
        }
    }
    
    private func parseVerificationResponse(content: String) throws -> AIVerificationResult {
        // Clean the response
        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanContent.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        struct AIVerificationResponse: Codable {
            let isCorrect: Bool
            let explanation: String
            let feedback: String
        }
        
        let response = try JSONDecoder().decode(AIVerificationResponse.self, from: data)
        
        return AIVerificationResult(
            isCorrect: response.isCorrect,
            explanation: response.explanation,
            feedback: response.feedback
        )
    }
    
    // MARK: - Conversation Generation Private Methods
    private func generateTestConversation(request: AIConversationRequest) throws -> AIConversationResponse {
        // Create a test conversation based on the request
        let scenario = request.scenario ?? getDefaultScenario(for: request.topic)
        
        let conversation = Conversation(
            title: "Conversation: \(scenario)",
            scenario: scenario,
            messages: createTestMessages(for: request),
            topic: request.topic,
            difficulty: request.proficiencyLevel,
            learningFocus: request.focus,
            estimatedReadingTime: 3
        )
        
        let questions = createTestConversationQuestions(for: conversation, request: request)
        
        return AIConversationResponse(
            conversation: conversation,
            questions: questions
        )
    }
    
    private func getDefaultScenario(for topic: LearningTopic) -> String {
        switch topic {
        case .general: return "General Conversation"
        case .travel: return "At the Airport"
        case .business: return "Job Interview"
        case .dailyConversation: return "Meeting a Friend"
        case .academic: return "Study Group Discussion"
        case .entertainment: return "Planning a Movie Night"
        case .technology: return "Tech Support Call"
        case .grammar: return "English Lesson"
        }
    }
    
    private func createTestMessages(for request: AIConversationRequest) -> [ConversationMessage] {
        switch request.topic {
        case .travel:
            return [
                ConversationMessage(
                    speaker: "Sarah",
                    message: "I'm really looking forward to our trip to Italy!",
                    learningElements: [
                        LearningElement(text: "looking forward to", type: .phrasalVerb, explanation: "To anticipate something with pleasure")
                    ]
                ),
                ConversationMessage(
                    speaker: "Mike",
                    message: "Me too! I've been brushing up on my Italian phrases.",
                    learningElements: [
                        LearningElement(text: "brushing up on", type: .phrasalVerb, explanation: "To review or practice something you learned before")
                    ]
                ),
                ConversationMessage(
                    speaker: "Sarah",
                    message: "That's smart. The language skills will definitely come in handy.",
                    learningElements: [
                        LearningElement(text: "come in handy", type: .idiom, explanation: "To be useful or helpful")
                    ]
                ),
                ConversationMessage(
                    speaker: "Mike",
                    message: "I heard the weather is supposed to be perfect. We lucked out!",
                    learningElements: [
                        LearningElement(text: "lucked out", type: .phrasalVerb, explanation: "To be fortunate or have good luck")
                    ]
                )
            ]
        case .business:
            return [
                ConversationMessage(
                    speaker: "Interviewer",
                    message: "Thank you for coming in today. Could you walk me through your experience?",
                    learningElements: [
                        LearningElement(text: "walk me through", type: .phrasalVerb, explanation: "To explain something step by step")
                    ]
                ),
                ConversationMessage(
                    speaker: "Candidate",
                    message: "Of course! I've been working in marketing for five years, and I'm eager to take on new challenges.",
                    learningElements: [
                        LearningElement(text: "take on", type: .phrasalVerb, explanation: "To accept or begin to handle something")
                    ]
                ),
                ConversationMessage(
                    speaker: "Interviewer",
                    message: "That's great. We're looking for someone who can hit the ground running.",
                    learningElements: [
                        LearningElement(text: "hit the ground running", type: .idiom, explanation: "To start working effectively immediately")
                    ]
                )
            ]
        default:
            return [
                ConversationMessage(
                    speaker: "Alex",
                    message: "Hey! How have you been? It's been ages since we caught up.",
                    learningElements: [
                        LearningElement(text: "it's been ages", type: .expression, explanation: "It's been a very long time")
                    ]
                ),
                ConversationMessage(
                    speaker: "Jordan",
                    message: "I know! I've been swamped with work lately. How about you?",
                    learningElements: [
                        LearningElement(text: "swamped", type: .vocabulary, explanation: "Extremely busy or overwhelmed")
                    ]
                )
            ]
        }
    }
    
    private func createTestConversationQuestions(for conversation: Conversation, request: AIConversationRequest) -> [QuizQuestion] {
        return [
            QuizQuestion(
                type: .multipleChoice,
                question: "What does 'looking forward to' mean in the conversation?",
                correctAnswer: "Anticipating with pleasure",
                options: ["Anticipating with pleasure", "Looking backwards", "Being worried about", "Forgetting about"],
                explanation: "'Looking forward to' means to anticipate something with pleasure or excitement.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus,
                conversation: conversation
            ),
            QuizQuestion(
                type: .multipleChoice,
                question: "What does 'come in handy' mean?",
                correctAnswer: "Be useful",
                options: ["Be useful", "Come by hand", "Be difficult", "Be expensive"],
                explanation: "'Come in handy' means to be useful or helpful in a particular situation.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus,
                conversation: conversation
            ),
            QuizQuestion(
                type: .fillInTheBlank,
                question: "Complete the phrasal verb: 'I've been _____ up on my Italian phrases.'",
                correctAnswer: "brushing",
                options: ["brushing", "looking", "catching", "picking"],
                explanation: "'Brushing up on' means to review or practice something you learned before.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus,
                conversation: conversation
            ),
            QuizQuestion(
                type: .trueFalse,
                question: "In the conversation, the speakers are planning a business meeting.",
                correctAnswer: "False",
                options: ["True", "False"],
                explanation: "The speakers are discussing a personal trip to Italy, not a business meeting.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus,
                conversation: conversation
            ),
            QuizQuestion(
                type: .multipleChoice,
                question: "What does 'lucked out' mean?",
                correctAnswer: "Had good luck",
                options: ["Had good luck", "Ran out of luck", "Locked the door", "Left quickly"],
                explanation: "'Lucked out' means to be fortunate or have good luck.",
                difficulty: request.proficiencyLevel,
                topic: request.topic,
                focus: request.focus,
                conversation: conversation
            )
        ]
    }
    
    private func createConversationPrompt(request: AIConversationRequest) -> String {
        let scenario = request.scenario ?? getDefaultScenario(for: request.topic)
        
        return """
        Create a realistic English conversation between 2 people for \(request.proficiencyLevel.rawValue.lowercased()) level English learners.
        
        Topic: \(request.topic.rawValue)
        Scenario: \(scenario)
        Learning Focus: \(request.focus.rawValue)
        
        Requirements:
        1. Create a natural conversation with 6-8 exchanges between 2 speakers
        2. Include 4-6 learning elements naturally embedded in the conversation:
           - Phrasal verbs (e.g., "look forward to", "catch up", "figure out")
           - Idioms (e.g., "break the ice", "hit the nail on the head")
           - Useful vocabulary appropriate for the topic
           - Grammar patterns relevant to the level
           - Common expressions and collocations
        
        3. Then create 5 comprehension questions about the conversation content
        
        Please return ONLY a valid JSON object with this exact format:
        {
          "conversation": {
            "title": "Conversation title",
            "scenario": "Brief scenario description",
            "messages": [
              {
                "speaker": "Speaker name",
                "message": "What they said",
                "learningElements": [
                  {
                    "text": "phrasal verb or idiom",
                    "type": "phrasalVerb|idiom|vocabulary|grammar|expression",
                    "explanation": "What it means"
                  }
                ]
              }
            ],
            "estimatedReadingTime": 3
          },
          "questions": [
            {
              "type": "multipleChoice|fillInTheBlank|trueFalse",
              "question": "Question about the conversation",
              "correctAnswer": "Correct answer",
              "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
              "explanation": "Why this is the correct answer"
            }
          ]
        }
        
        Guidelines:
        - Make the conversation feel natural and realistic
        - Speakers should have distinct personalities
        - Include learning elements organically (don't force them)
        - Questions should test understanding of the learning elements
        - Mix question types for variety
        - Keep appropriate difficulty for \(request.proficiencyLevel.rawValue.lowercased()) level
        
        Return ONLY the JSON object, no other text.
        """
    }
    
    private func parseConversationResponse(content: String, request: AIConversationRequest) throws -> AIConversationResponse {
        print("🔍 Parsing conversation response...")
        
        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanContent.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        struct AIConversationResponseData: Codable {
            let conversation: AIConversationData
            let questions: [AIQuizQuestion]
        }
        
        struct AIConversationData: Codable {
            let title: String
            let scenario: String
            let messages: [AIMessageData]
            let estimatedReadingTime: Int
        }
        
        struct AIMessageData: Codable {
            let speaker: String
            let message: String
            let learningElements: [AILearningElement]
        }
        
        struct AILearningElement: Codable {
            let text: String
            let type: String
            let explanation: String
        }
        
        struct AIQuizQuestion: Codable {
            let type: String
            let question: String
            let correctAnswer: String
            let options: [String]?
            let explanation: String
        }
        
        do {
            let aiResponse = try JSONDecoder().decode(AIConversationResponseData.self, from: data)
            
            // Convert AI response to our models
            let messages = aiResponse.conversation.messages.map { aiMessage in
                let learningElements = aiMessage.learningElements.map { aiElement in
                    LearningElement(
                        text: aiElement.text,
                        type: LearningElementType(rawValue: aiElement.type) ?? .expression,
                        explanation: aiElement.explanation
                    )
                }
                
                return ConversationMessage(
                    speaker: aiMessage.speaker,
                    message: aiMessage.message,
                    learningElements: learningElements
                )
            }
            
            let conversation = Conversation(
                title: aiResponse.conversation.title,
                scenario: aiResponse.conversation.scenario,
                messages: messages,
                topic: request.topic,
                difficulty: request.proficiencyLevel,
                learningFocus: request.focus,
                estimatedReadingTime: aiResponse.conversation.estimatedReadingTime
            )
            
            let questions = aiResponse.questions.map { aiQuestion in
                QuizQuestion(
                    type: QuestionType(rawValue: aiQuestion.type) ?? .multipleChoice,
                    question: aiQuestion.question,
                    correctAnswer: aiQuestion.correctAnswer,
                    options: aiQuestion.options,
                    explanation: aiQuestion.explanation,
                    difficulty: request.proficiencyLevel,
                    topic: request.topic,
                    focus: request.focus,
                    conversation: conversation
                )
            }
            
            return AIConversationResponse(
                conversation: conversation,
                questions: questions
            )
            
        } catch {
            print("❌ Failed to parse conversation response: \(error)")
            throw OpenAIError.invalidResponse
        }
    }
    
    // MARK: - Question Generation for Existing Articles
    func generateQuestionsForArticle(request: ArticleQuestionGenerationRequest) async throws -> [QuizQuestion] {
        // For testing - check if API key starts with "test" or "demo"
        if apiKey.lowercased().hasPrefix("test") || apiKey.lowercased().hasPrefix("demo") {
            print("🧪 Using test mode - generating mock questions for existing article")
            return try generateTestQuestionsForArticle(request: request)
        }
        
        let prompt = createArticleQuestionGenerationPrompt(request: request)
        
        let response = try await makeOpenAIRequest(prompt: prompt, temperature: 0.7, maxTokens: 2500)
        
        guard let content = response.choices.first?.message.content else {
            throw OpenAIError.invalidResponse
        }
        
        return try parseArticleQuestionResponse(content: content, request: request)
    }
    
    // MARK: - Article Generation (NEW)
    func generateArticleWithQuestions(request: ArticleGenerationRequest) async throws -> ArticleWithQuestions {
        // For testing - check if API key starts with "test" or "demo"
        if apiKey.lowercased().hasPrefix("test") || apiKey.lowercased().hasPrefix("demo") {
            print("🧪 Using test mode - generating mock article and questions")
            return try generateTestArticleWithQuestions(request: request)
        }
        
        let prompt = createArticleGenerationPrompt(request: request)
        
        let response = try await makeOpenAIRequest(prompt: prompt, temperature: 0.7, maxTokens: 3000)
        
        guard let content = response.choices.first?.message.content else {
            throw OpenAIError.invalidResponse
        }
        
        return try parseArticleResponse(content: content, request: request)
    }
    
    private func generateTestArticleWithQuestions(request: ArticleGenerationRequest) throws -> ArticleWithQuestions {
        // Generate a sample article based on the request
        let sampleArticles = [
            (
                title: "The Power of Reading: A Gateway to Knowledge",
                content: """
                Reading is one of the most powerful tools for learning and personal growth. When we read, we expand our vocabulary, improve our comprehension skills, and gain exposure to different writing styles and perspectives. The act of reading transforms our minds and opens doors to endless possibilities for intellectual development.
                
                Scientific studies have shown that regular reading can improve brain function and memory in remarkable ways. Neuroscientists have discovered that reading activates multiple regions of the brain simultaneously, creating new neural pathways and strengthening existing connections. Reading exercises our minds in ways that watching television or scrolling through social media cannot. It requires active engagement, forcing us to visualize scenes, follow complex storylines, and make connections between ideas.
                
                The cognitive benefits of reading are particularly pronounced in children and young adults. During critical developmental periods, reading helps establish strong foundation skills that support academic success throughout life. Students who read regularly demonstrate better performance in all subjects, not just language arts. This is because reading improves critical thinking skills, analytical abilities, and the capacity to synthesize information from multiple sources.
                
                Furthermore, reading exposes us to proper grammar and sentence structure naturally. As we encounter well-written texts, we internalize correct language patterns without conscious effort. This is particularly beneficial for language learners who want to improve their writing skills. The more we read, the more familiar we become with the rhythm and flow of well-constructed sentences.
                
                The benefits of reading extend far beyond language skills and cognitive development. Through books, we can travel to distant places, experience different cultures, and gain insights into human nature. Reading fiction helps develop empathy by allowing us to see the world through different characters' eyes. We learn to understand different perspectives, motivations, and experiences that broaden our worldview.
                
                Different types of reading material offer unique advantages. Fiction develops creativity and imagination, while non-fiction provides factual knowledge and practical skills. Poetry enhances appreciation for language rhythm and artistic expression. Newspapers and current events keep us informed about the world around us. Each genre contributes something valuable to our intellectual development.
                
                To maximize the benefits of reading, experts recommend reading a variety of genres and topics. This approach ensures exposure to different vocabulary sets and writing styles. Whether you prefer fiction, non-fiction, newspapers, or magazines, the key is consistency. Even fifteen minutes of daily reading can produce significant improvements over time.
                
                Creating a reading routine requires dedication but yields tremendous rewards. Many successful people attribute their achievements to extensive reading habits. They understand that reading is an investment in personal growth that pays dividends throughout life. The knowledge gained through reading becomes a foundation for making informed decisions and solving complex problems.
                
                In our digital age, reading remains as important as ever. While technology offers many distractions, those who maintain strong reading habits continue to have advantages in education, career advancement, and personal satisfaction. The ability to focus deeply on written material becomes increasingly valuable in a world filled with short attention spans and constant interruptions.
                """,
                tags: ["education", "learning", "language skills"],
                summary: "An exploration of how reading enhances learning, brain function, and personal development."
            ),
            (
                title: "Sustainable Living: Small Changes, Big Impact",
                content: """
                Climate change is one of the most pressing challenges of our time, but individuals can make a meaningful difference through sustainable living practices. Small daily choices accumulate into significant environmental impact over time. The beauty of sustainable living lies in its accessibility – anyone can participate regardless of their economic situation or living circumstances.
                
                Understanding the environmental impact of our daily choices is the first step toward sustainability. Every product we buy, every trip we take, and every decision we make has consequences for our planet. By becoming more conscious consumers, we can significantly reduce our environmental footprint while often saving money in the process.
                
                One of the easiest ways to start living sustainably is by reducing energy consumption at home. Simple actions like switching to LED light bulbs, unplugging electronics when not in use, and adjusting thermostats can reduce energy bills while helping the environment. These changes require minimal effort but produce measurable results over time. Many people are surprised to discover how much energy common household appliances consume when left plugged in.
                
                Home insulation and weatherproofing represent additional opportunities for energy savings. Sealing air leaks around windows and doors, adding insulation to attics and basements, and installing programmable thermostats can dramatically reduce heating and cooling costs. These investments typically pay for themselves within a few years through reduced utility bills.
                
                Transportation choices also play a crucial role in sustainability. Walking, cycling, or using public transportation instead of driving reduces carbon emissions significantly. When driving is necessary, carpooling or choosing fuel-efficient vehicles can minimize environmental impact. Planning errands efficiently to reduce the number of trips also helps conserve fuel and reduce emissions.
                
                For those ready to make larger changes, electric vehicles represent an excellent long-term investment. While the initial cost may be higher, electric vehicles have lower operating costs and produce zero direct emissions. As charging infrastructure continues to expand, electric vehicles become increasingly practical for everyday use.
                
                Waste reduction is another important aspect of sustainable living. The three R's – Reduce, Reuse, and Recycle – provide a framework for making environmentally conscious decisions. Before purchasing new items, consider whether you truly need them. Look for ways to repurpose existing items, and properly recycle materials when disposal is necessary. Composting organic waste creates valuable soil amendment while diverting materials from landfills.
                
                Food choices significantly impact the environment in ways many people don't realize. Eating locally grown, seasonal produce reduces transportation emissions and supports local farmers. Reducing meat consumption can also lower your carbon footprint, as livestock farming produces significant greenhouse gases. Growing your own vegetables, even in small spaces, provides fresh produce while connecting you to your food source.
                
                Water conservation deserves attention too, especially in regions facing drought conditions. Simple measures like taking shorter showers, fixing leaks promptly, and using water-efficient appliances help preserve this precious resource. Installing low-flow fixtures and collecting rainwater for garden irrigation can further reduce water consumption.
                
                Sustainable living doesn't require dramatic lifestyle changes overnight. The key is making gradual improvements that become permanent habits. Start with one or two practices and gradually incorporate more as they become routine. Every small action contributes to a larger movement toward environmental responsibility. When individuals work together toward common goals, the collective impact becomes substantial and meaningful.
                """,
                tags: ["environment", "sustainability", "lifestyle"],
                summary: "Practical tips for adopting sustainable living practices that benefit both individuals and the environment."
            )
        ]
        
        let selectedArticle = sampleArticles.randomElement()!
        
        let wordCount = selectedArticle.content.split(separator: " ").count
        let estimatedReadingTime = max(1, wordCount / 200) // 200 words per minute average
        
        let article = Article(
            title: selectedArticle.title,
            content: selectedArticle.content,
            topic: request.topic,
            difficulty: request.difficulty,
            estimatedReadingTime: estimatedReadingTime,
            wordCount: wordCount,
            tags: selectedArticle.tags,
            summary: selectedArticle.summary
        )
        
        // Generate 10 comprehension questions
        let questions = [
            QuizQuestion(
                type: .multipleChoice,
                question: "According to the article, what is the main benefit of reading mentioned?",
                correctAnswer: "It expands vocabulary and improves comprehension",
                options: ["It expands vocabulary and improves comprehension", "It's faster than watching TV", "It helps you sleep better", "It makes you more popular"],
                explanation: "The article emphasizes that reading expands vocabulary, improves comprehension, and exposes readers to different writing styles.",
                difficulty: request.difficulty,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .trueFalse,
                question: "The article states that reading exercises our minds more than watching television.",
                correctAnswer: "True",
                options: ["True", "False"],
                explanation: "The article explicitly states that reading exercises our minds in ways that watching television cannot because it requires active engagement.",
                difficulty: request.difficulty,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .fillInTheBlank,
                question: "Reading exposes us to proper ______ and sentence structure naturally.",
                correctAnswer: "grammar",
                options: ["grammar", "spelling", "pronunciation", "vocabulary"],
                explanation: "The article mentions that reading exposes us to proper grammar and sentence structure naturally.",
                difficulty: request.difficulty,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .multipleChoice,
                question: "How does reading fiction specifically help readers?",
                correctAnswer: "It helps develop empathy",
                options: ["It helps develop empathy", "It improves math skills", "It teaches history", "It builds physical strength"],
                explanation: "The article states that reading fiction helps develop empathy by allowing us to see the world through different characters' eyes.",
                difficulty: request.difficulty,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .multipleChoice,
                question: "What do experts recommend to maximize reading benefits?",
                correctAnswer: "Reading a variety of genres and topics",
                options: ["Reading a variety of genres and topics", "Reading only fiction", "Reading very fast", "Reading only newspapers"],
                explanation: "The article mentions that experts recommend reading a variety of genres and topics to ensure exposure to different vocabulary sets and writing styles.",
                difficulty: request.difficulty,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .trueFalse,
                question: "According to the article, consistency is more important than the type of material you read.",
                correctAnswer: "True",
                options: ["True", "False"],
                explanation: "The article emphasizes that whether you prefer fiction, non-fiction, newspapers, or magazines, the key is consistency.",
                difficulty: request.difficulty,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .fillInTheBlank,
                question: "Reading requires ______ engagement, forcing us to visualize scenes and follow storylines.",
                correctAnswer: "active",
                options: ["active", "passive", "minimal", "careful"],
                explanation: "The article states that reading requires active engagement, unlike passive activities like watching TV.",
                difficulty: request.difficulty,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .multipleChoice,
                question: "What advantage do people with strong reading habits have according to the article?",
                correctAnswer: "Advantages in education, career advancement, and personal satisfaction",
                options: ["Advantages in education, career advancement, and personal satisfaction", "Better physical health", "More money", "Improved social skills"],
                explanation: "The article concludes that those who maintain strong reading habits have advantages in education, career advancement, and personal satisfaction.",
                difficulty: request.difficulty,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .multipleChoice,
                question: "How do we internalize correct language patterns according to the article?",
                correctAnswer: "Without conscious effort through exposure to well-written texts",
                options: ["Without conscious effort through exposure to well-written texts", "By memorizing grammar rules", "Through intensive study", "By listening to music"],
                explanation: "The article states that we internalize correct language patterns without conscious effort as we encounter well-written texts.",
                difficulty: request.difficulty,
                topic: request.topic,
                focus: request.focus
            ),
            QuizQuestion(
                type: .trueFalse,
                question: "The article suggests that reading is less important in our digital age.",
                correctAnswer: "False",
                options: ["True", "False"],
                explanation: "The article concludes that reading remains as important as ever in our digital age, despite technological distractions.",
                difficulty: request.difficulty,
                topic: request.topic,
                focus: request.focus
            )
        ]
        
        return ArticleWithQuestions(article: article, questions: questions)
    }
    
    private func createArticleGenerationPrompt(request: ArticleGenerationRequest) -> String {
        let topicDescription = request.specificSubject ?? request.topic.rawValue
        
        return """
        Create an educational article with exactly \(request.wordCount) words (minimum 200) for English language learners at \(request.difficulty.rawValue.lowercased()) level.
        
        Requirements:
        - Topic: \(topicDescription) (related to \(request.topic.rawValue))
        - Focus: \(request.focus.rawValue)
        - Difficulty: \(request.difficulty.rawValue.lowercased()) level
        - Word count: \(request.wordCount) words (be precise)
        - Include engaging, educational content
        - Use appropriate vocabulary for the skill level
        - Create natural, flowing paragraphs
        - Include relevant examples and explanations
        
        After the article, create exactly 10 comprehension questions that test understanding of the content.
        
        Please return ONLY a valid JSON object with this exact format:
        {
          "article": {
            "title": "Article title here",
            "content": "Full article content here (\(request.wordCount) words)",
            "summary": "Brief 1-2 sentence summary",
            "tags": ["tag1", "tag2", "tag3"]
          },
          "questions": [
            {
              "type": "multipleChoice",
              "question": "Question about the article content",
              "correctAnswer": "Correct answer",
              "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
              "explanation": "Why this is correct and how it relates to the article"
            }
          ]
        }
        
        Question requirements:
        - Exactly 10 questions
        - Mix question types: multipleChoice, fillInTheBlank, trueFalse
        - Test comprehension, vocabulary, and key concepts from the article
        - Include detailed explanations for each answer
        - Questions should reference specific parts of the article
        - Difficulty appropriate for \(request.difficulty.rawValue.lowercased()) level
        
        Return ONLY the JSON object, no other text.
        """
    }
    
    private func parseArticleResponse(content: String, request: ArticleGenerationRequest) throws -> ArticleWithQuestions {
        print("🔍 Parsing article response...")
        
        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanContent.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        struct AIArticleResponse: Codable {
            let article: AIArticleData
            let questions: [AIQuizQuestion]
        }
        
        struct AIArticleData: Codable {
            let title: String
            let content: String
            let summary: String
            let tags: [String]
        }
        
        struct AIQuizQuestion: Codable {
            let type: String
            let question: String
            let correctAnswer: String
            let options: [String]?
            let explanation: String
        }
        
        do {
            let aiResponse = try JSONDecoder().decode(AIArticleResponse.self, from: data)
            
            // Calculate reading time and word count
            let wordCount = aiResponse.article.content.split(separator: " ").count
            let estimatedReadingTime = max(1, wordCount / 200) // 200 words per minute average
            
            let article = Article(
                title: aiResponse.article.title,
                content: aiResponse.article.content,
                topic: request.topic,
                difficulty: request.difficulty,
                estimatedReadingTime: estimatedReadingTime,
                wordCount: wordCount,
                tags: aiResponse.article.tags,
                summary: aiResponse.article.summary
            )
            
            let questions = aiResponse.questions.map { aiQuestion in
                let questionType = QuestionType(rawValue: aiQuestion.type) ?? .multipleChoice
                
                let questionOptions: [String]?
                if let options = aiQuestion.options {
                    questionOptions = options
                } else if questionType == .trueFalse {
                    questionOptions = ["True", "False"]
                } else {
                    questionOptions = nil
                }
                
                return QuizQuestion(
                    type: questionType,
                    question: aiQuestion.question,
                    correctAnswer: aiQuestion.correctAnswer,
                    options: questionOptions,
                    explanation: aiQuestion.explanation,
                    difficulty: request.difficulty,
                    topic: request.topic,
                    focus: request.focus
                )
            }
            
            return ArticleWithQuestions(article: article, questions: questions)
            
        } catch {
            print("❌ Failed to parse article response: \(error)")
            throw OpenAIError.invalidResponse
        }
    }
    
    // MARK: - Question Generation for Existing Articles - Helper Methods
    private func generateTestQuestionsForArticle(request: ArticleQuestionGenerationRequest) throws -> [QuizQuestion] {
        let article = request.article
        
        // Generate relevant questions based on the article content
        let questions = [
            QuizQuestion(
                type: .multipleChoice,
                question: "What is the main topic of this article?",
                correctAnswer: article.title,
                options: [article.title, "General Education", "Science Facts", "Historical Events"],
                explanation: "The main topic is reflected in the article's title and content.",
                difficulty: article.difficulty,
                topic: article.topic,
                focus: .reading
            ),
            QuizQuestion(
                type: .trueFalse,
                question: "This article is written at \(article.difficulty.rawValue.lowercased()) level.",
                correctAnswer: "True",
                options: ["True", "False"],
                explanation: "The article is specifically designed for \(article.difficulty.rawValue.lowercased()) level learners.",
                difficulty: article.difficulty,
                topic: article.topic,
                focus: .reading
            ),
            QuizQuestion(
                type: .fillInTheBlank,
                question: "The estimated reading time for this article is _____ minutes.",
                correctAnswer: "\(article.estimatedReadingTime)",
                options: ["\(article.estimatedReadingTime)", "\(article.estimatedReadingTime + 1)", "\(max(1, article.estimatedReadingTime - 1))", "\(article.estimatedReadingTime + 2)"],
                explanation: "Based on the article length and average reading speed, this article takes approximately \(article.estimatedReadingTime) minutes to read.",
                difficulty: article.difficulty,
                topic: article.topic,
                focus: .reading
            ),
            QuizQuestion(
                type: .multipleChoice,
                question: "Which learning topic category does this article belong to?",
                correctAnswer: article.topic.rawValue,
                options: [article.topic.rawValue, "Mathematics", "Science", "History"],
                explanation: "This article is categorized under \(article.topic.rawValue) based on its content and learning objectives.",
                difficulty: article.difficulty,
                topic: article.topic,
                focus: .reading
            ),
            QuizQuestion(
                type: .trueFalse,
                question: "This article contains approximately \(article.wordCount) words.",
                correctAnswer: "True",
                options: ["True", "False"],
                explanation: "The article has been designed with \(article.wordCount) words to match the appropriate reading level.",
                difficulty: article.difficulty,
                topic: article.topic,
                focus: .reading
            )
        ]
        
        // Take only the requested number of questions
        return Array(questions.prefix(request.questionCount))
    }
    
    private func createArticleQuestionGenerationPrompt(request: ArticleQuestionGenerationRequest) -> String {
        let article = request.article
        
        return """
        Based on the following article, create exactly \(request.questionCount) comprehension questions for English language learners at \(article.difficulty.rawValue.lowercased()) level.
        
        Article Title: \(article.title)
        Article Content: \(article.content)
        
        Requirements:
        - Create exactly \(request.questionCount) questions
        - Mix question types: multipleChoice, fillInTheBlank, trueFalse
        - Test comprehension, vocabulary, and key concepts from the article
        - Questions should reference specific parts of the article content
        - Difficulty appropriate for \(article.difficulty.rawValue.lowercased()) level
        - Include detailed explanations for each answer
        - Focus on understanding the main ideas and supporting details
        
        Please return ONLY a valid JSON object with this exact format:
        {
          "questions": [
            {
              "type": "multipleChoice",
              "question": "Question about the article content",
              "correctAnswer": "Correct answer",
              "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
              "explanation": "Why this is correct and how it relates to the article"
            }
          ]
        }
        
        Return ONLY the JSON object, no other text.
        """
    }
    
    private func parseArticleQuestionResponse(content: String, request: ArticleQuestionGenerationRequest) throws -> [QuizQuestion] {
        print("🔍 Parsing article question response...")
        
        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanContent.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        struct AIQuestionResponse: Codable {
            let questions: [AIQuizQuestion]
        }
        
        struct AIQuizQuestion: Codable {
            let type: String
            let question: String
            let correctAnswer: String
            let options: [String]?
            let explanation: String
        }
        
        do {
            let aiResponse = try JSONDecoder().decode(AIQuestionResponse.self, from: data)
            
            let questions = aiResponse.questions.map { aiQuestion in
                let questionType = QuestionType(rawValue: aiQuestion.type) ?? .multipleChoice
                
                let questionOptions: [String]?
                if let options = aiQuestion.options {
                    questionOptions = options
                } else if questionType == .trueFalse {
                    questionOptions = ["True", "False"]
                } else {
                    questionOptions = nil
                }
                
                return QuizQuestion(
                    type: questionType,
                    question: aiQuestion.question,
                    correctAnswer: aiQuestion.correctAnswer,
                    options: questionOptions,
                    explanation: aiQuestion.explanation,
                    difficulty: request.article.difficulty,
                    topic: request.article.topic,
                    focus: .reading
                )
            }
            
            return questions
            
        } catch {
            print("❌ Failed to parse article question response: \(error)")
            throw OpenAIError.invalidResponse
        }
    }
}

// MARK: - Errors
enum OpenAIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(Int)
    case noAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from OpenAI"
        case .apiError(let code):
            return "API Error: \(code)"
        case .noAPIKey:
            return "OpenAI API key not configured"
        }
    }
}

// MARK: - API Key Manager
class APIKeyManager: ObservableObject {
    @Published var apiKey: String = ""
    @Published var isConfigured: Bool = false
    
    private let keychain = "AIELearn_OpenAI_Key"
    
    init() {
        loadAPIKey()
    }
    
    func saveAPIKey(_ key: String) {
        apiKey = key
        isConfigured = !key.isEmpty
        
        // In a real app, you'd want to use Keychain for secure storage
        UserDefaults.standard.set(key, forKey: keychain)
    }
    
    private func loadAPIKey() {
        apiKey = UserDefaults.standard.string(forKey: keychain) ?? ""
        isConfigured = !apiKey.isEmpty
    }
    
    func clearAPIKey() {
        apiKey = ""
        isConfigured = false
        UserDefaults.standard.removeObject(forKey: keychain)
    }
}

// MARK: - Extensions
// Note: Array safe subscript extension already defined in ArticleQuizView.swift 