//
//  QuizView.swift
//  aielearn
//
//  Created by AI Assistant
//

import SwiftUI
import Combine

struct QuizView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var quizManager: QuizManager
    @EnvironmentObject var mistakeManager: MistakeManager
    @Environment(\.presentationMode) var presentationMode
    
    let quiz: Quiz
    @State private var selectedAnswer: String = ""
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var quizCompleted = false
    @State private var finalResult: QuizResult?
    @State private var currentQuestionStartTime = Date()
    @State private var aiVerificationResult: AIVerificationResult?
    @StateObject private var loadingManager = LoadingStateManager.shared
    @State private var showingLearningChallenge = false
    @State private var mistakeBasedQuizId: UUID? // Track if this is a mistake-based quiz
    @State private var hasReadConversation = false // Track if user has read the conversation
    
    var currentQuestion: QuizQuestion? {
        guard quizManager.currentQuestionIndex < quiz.questions.count else { return nil }
        return quiz.questions[quizManager.currentQuestionIndex]
    }
    
    var isConversationQuiz: Bool {
        return quiz.questions.first?.conversation != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !quizCompleted {
                    if isConversationQuiz && !hasReadConversation {
                        // Show conversation first for conversation-based quizzes
                        ConversationReadingView(
                            conversation: quiz.questions.first!.conversation!,
                            onContinueToQuiz: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    hasReadConversation = true
                                }
                            }
                        )
                    } else if let question = currentQuestion {
                        // Normal quiz flow
                        // Quiz Header
                        QuizHeaderView(progress: Double(quizManager.currentQuestionIndex + 1) / Double(quiz.questions.count))
                        
                        // Question Content
                        ScrollView {
                            VStack(spacing: 32) {
                                QuestionCardView(
                                    question: question,
                                    selectedAnswer: $selectedAnswer,
                                    showFeedback: $showFeedback,
                                    isCorrect: $isCorrect,
                                    aiVerification: aiVerificationResult
                                )
                            }
                            .padding()
                        }
                        
                        // Quiz Controls
                        QuizControlsView(
                            selectedAnswer: $selectedAnswer,
                            showFeedback: $showFeedback,
                            isCorrect: $isCorrect,
                            quizCompleted: $quizCompleted,
                            finalResult: $finalResult,
                            aiVerificationResult: $aiVerificationResult,
                            mistakeBasedQuizId: mistakeBasedQuizId
                        )
                    }
                } else if let result = finalResult {
                    // Quiz Results
                    QuizResultView(result: result) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(isConversationQuiz && !hasReadConversation ? "Read Conversation" : quiz.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            quizManager.startQuiz(quiz)
            currentQuestionStartTime = Date()
            
            // Check if this is a mistake-based quiz
            if quiz.isMistakeBased {
                mistakeBasedQuizId = quiz.id
                print("🎯 Started mistake-based quiz with \(quiz.basedOnMistakes?.count ?? 0) mistakes")
            }
        }
        .onReceive(quizManager.$shouldShowLearningChallenge) { shouldShow in
            if shouldShow {
                showingLearningChallenge = true
                quizManager.shouldShowLearningChallenge = false
            }
        }
        .sheet(isPresented: $showingLearningChallenge) {
            if mistakeManager.pendingReviewCount > 0 {
                MistakeReviewView()
                    .environmentObject(mistakeManager)
                    .environmentObject(userProfile)
            } else {
                LearningChallengeView()
                    .environmentObject(userProfile)
                    .environmentObject(quizManager)
            }
        }
    }
}

struct QuizHeaderView: View {
    @EnvironmentObject var quizManager: QuizManager
    let progress: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * progress,
                            height: 8
                        )
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
            
            // Question Counter
            HStack {
                Text("Question \(quizManager.currentQuestionIndex + 1) of \(quizManager.currentQuiz?.questions.count ?? 0)")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct QuestionCardView: View {
    let question: QuizQuestion
    @Binding var selectedAnswer: String
    @Binding var showFeedback: Bool
    @Binding var isCorrect: Bool
    let aiVerification: AIVerificationResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Question Type Badge
            HStack {
                Label(question.type.rawValue, systemImage: question.type.icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                
                Spacer()
                
                // Difficulty Badge
                Label(question.difficulty.description, systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(question.difficulty.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(question.difficulty.color.opacity(0.1))
                    )
            }
            
            // Conversation Reference (if applicable)
            if question.conversation != nil {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.caption)
                        .foregroundColor(.mint)
                    
                    Text("Based on: \(question.conversation!.scenario)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.mint.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.mint.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Question Text with Speech
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(question.question)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                }
                
                SpeechButton(text: question.question, type: .question)
            }
            
            // Answer Options
            if question.isMultipleChoice {
                MultipleChoiceView(
                    question: question,
                    selectedAnswer: $selectedAnswer,
                    showFeedback: showFeedback
                )
            } else if question.isFillInTheBlank {
                FillInTheBlankView(
                    question: question,
                    selectedAnswer: $selectedAnswer,
                    showFeedback: showFeedback
                )
            } else if question.isTrueFalse {
                TrueFalseView(
                    question: question,
                    selectedAnswer: $selectedAnswer,
                    showFeedback: showFeedback
                )
            }
            
            // Feedback Section
            if showFeedback {
                FeedbackView(
                    question: question,
                    isCorrect: isCorrect,
                    selectedAnswer: selectedAnswer,
                    aiVerification: aiVerification
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct MultipleChoiceView: View {
    let question: QuizQuestion
    @Binding var selectedAnswer: String
    let showFeedback: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(question.safeOptions, id: \.self) { option in
                Button(action: {
                    if !showFeedback {
                        selectedAnswer = option
                    }
                }) {
                    HStack {
                        Text(option)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        if showFeedback {
                            if option == question.correctAnswer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else if option == selectedAnswer && option != question.correctAnswer {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        } else if selectedAnswer == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundColor(for: option))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(borderColor(for: option), lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(showFeedback)
            }
        }
    }
    
    private func backgroundColor(for option: String) -> Color {
        if showFeedback {
            if option == question.correctAnswer {
                return Color.green.opacity(0.1)
            } else if option == selectedAnswer && option != question.correctAnswer {
                return Color.red.opacity(0.1)
            }
        } else if selectedAnswer == option {
            return Color.blue.opacity(0.1)
        }
        return Color.gray.opacity(0.05)
    }
    
    private func borderColor(for option: String) -> Color {
        if showFeedback {
            if option == question.correctAnswer {
                return Color.green
            } else if option == selectedAnswer && option != question.correctAnswer {
                return Color.red
            }
        } else if selectedAnswer == option {
            return Color.blue
        }
        return Color.clear
    }
}

struct FillInTheBlankView: View {
    let question: QuizQuestion
    @Binding var selectedAnswer: String
    let showFeedback: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fill in the blank:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("Your answer", text: $selectedAnswer)
                .font(.body)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(showFeedback ? 
                                       (selectedAnswer.lowercased() == question.correctAnswer.lowercased() ? Color.green : Color.red) :
                                       Color.blue, lineWidth: showFeedback ? 2 : 1)
                        )
                )
                .disabled(showFeedback)
        }
    }
}

struct TrueFalseView: View {
    let question: QuizQuestion
    @Binding var selectedAnswer: String
    let showFeedback: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                if !showFeedback {
                    selectedAnswer = "True"
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("True")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedAnswer == "True" ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedAnswer == "True" ? Color.green : Color.clear, lineWidth: 2)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(showFeedback)
            
            Button(action: {
                if !showFeedback {
                    selectedAnswer = "False"
                }
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("False")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedAnswer == "False" ? Color.red.opacity(0.1) : Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedAnswer == "False" ? Color.red : Color.clear, lineWidth: 2)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(showFeedback)
        }
    }
}

struct FeedbackView: View {
    let question: QuizQuestion
    let isCorrect: Bool
    let selectedAnswer: String
    let aiVerification: AIVerificationResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.title2)
                
                Text(isCorrect ? "Correct!" : "Incorrect")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isCorrect ? .green : .red)
            }
            
            if !isCorrect {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Correct answer:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Text(question.correctAnswer)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        SpeechButton(text: question.correctAnswer, type: .answer)
                    }
                }
            }
            
            // Enhanced AI Explanation
            if let aiVerification = aiVerification {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("AI Feedback:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            SpeechButton(text: aiVerification.feedback, type: .feedback)
                        }
                        
                        Text(aiVerification.feedback)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Explanation:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            SpeechButton(text: aiVerification.explanation, type: .explanation)
                        }
                        
                        Text(aiVerification.explanation)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                }
            } else {
                // Fallback to basic explanation
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Explanation:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        SpeechButton(text: question.explanation, type: .explanation)
                    }
                    
                    Text(question.explanation)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCorrect ? Color.green.opacity(0.05) : Color.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct QuizControlsView: View {
    @EnvironmentObject var quizManager: QuizManager
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var mistakeManager: MistakeManager
    @Binding var selectedAnswer: String
    @Binding var showFeedback: Bool
    @Binding var isCorrect: Bool
    @Binding var quizCompleted: Bool
    @Binding var finalResult: QuizResult?
    @Binding var aiVerificationResult: AIVerificationResult?
    
    // NEW: Add mistake-based quiz tracking
    var mistakeBasedQuizId: UUID?
    
    @StateObject private var loadingManager = LoadingStateManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Divider()
            
            HStack(spacing: 16) {
                // Previous Button
                if quizManager.currentQuestionIndex > 0 && !showFeedback {
                    Button("Previous") {
                        quizManager.previousQuestion()
                        selectedAnswer = quizManager.userAnswers[quizManager.currentQuestionIndex]
                        showFeedback = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                Spacer()
                
                // Main Action Button
                if !showFeedback {
                    DSButton(
                        loadingManager.isLoading(.aiVerification) ? "Checking..." : "Submit",
                        style: .primary,
                        isLoading: loadingManager.isLoading(.aiVerification)
                    ) {
                        submitAnswer()
                    }
                    .disabled(selectedAnswer.isEmpty || loadingManager.isLoading(.aiVerification))
                } else {
                    if quizManager.currentQuestionIndex < (quizManager.currentQuiz?.questions.count ?? 0) - 1 {
                        Button("Next Question") {
                            nextQuestion()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("Finish Quiz") {
                            finishQuiz()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func submitAnswer() {
        guard let currentQuestion = quizManager.currentQuiz?.questions[quizManager.currentQuestionIndex] else { return }
        guard !selectedAnswer.isEmpty else { return }
        
        Task { @MainActor in
            do {
                // Simple AI verification with loading state
                let verification = try await loadingManager.withLoadingMainActor(.aiVerification, message: "Verifying answer...") {
                    return await quizManager.verifyAnswer(
                        questionIndex: quizManager.currentQuestionIndex,
                        userAnswer: selectedAnswer
                    )
                }
                
                if let verification = verification {
                    aiVerificationResult = verification
                    isCorrect = verification.isCorrect
                } else {
                    // Fallback to simple comparison
                    isCorrect = selectedAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == 
                              currentQuestion.correctAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // ENHANCED MISTAKE MANAGEMENT
                if mistakeBasedQuizId != nil {
                    // This is a mistake-based quiz - handle differently
                    handleMistakeBasedQuizAnswer(currentQuestion: currentQuestion)
                } else {
                    // Regular quiz - save mistakes as before
                    if !isCorrect {
                        mistakeManager.saveMistake(
                            question: currentQuestion.question,
                            correctAnswer: currentQuestion.correctAnswer,
                            userAnswer: selectedAnswer,
                            explanation: currentQuestion.explanation,
                            feedback: aiVerificationResult?.feedback,
                            questionType: currentQuestion.type,
                            difficulty: currentQuestion.difficulty,
                            topic: currentQuestion.topic,
                            focus: currentQuestion.focus,
                            options: currentQuestion.options
                        )
                    }
                }
                
                quizManager.submitAnswer(selectedAnswer)
                
            } catch {
                print("❌ Error during answer verification: \(error)")
                // Fallback to simple comparison if verification fails
                isCorrect = selectedAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == 
                          currentQuestion.correctAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !isCorrect {
                    mistakeManager.saveMistake(
                        question: currentQuestion.question,
                        correctAnswer: currentQuestion.correctAnswer,
                        userAnswer: selectedAnswer,
                        explanation: currentQuestion.explanation,
                        feedback: nil,
                        questionType: currentQuestion.type,
                        difficulty: currentQuestion.difficulty,
                        topic: currentQuestion.topic,
                        focus: currentQuestion.focus,
                        options: currentQuestion.options
                    )
                }
                
                quizManager.submitAnswer(selectedAnswer)
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                showFeedback = true
            }
        }
    }
    
    // NEW: Handle mistake-based quiz answers intelligently
    private func handleMistakeBasedQuizAnswer(currentQuestion: QuizQuestion) {
        // Find the corresponding mistake record
        let correspondingMistake = mistakeManager.mistakes.first { mistake in
            mistake.question == currentQuestion.question &&
            mistake.correctAnswer == currentQuestion.correctAnswer
        }
        
        if let mistake = correspondingMistake {
            if isCorrect {
                // User got it right - mark as reviewed and potentially mastered
                mistakeManager.markAsReviewed(mistake, wasCorrect: true)
                print("✅ User corrected their mistake: \(mistake.question)")
            } else {
                // User still got it wrong - mark as reviewed but not mastered
                mistakeManager.markAsReviewed(mistake, wasCorrect: false)
                print("❌ User still struggling with: \(mistake.question)")
                
                // Save a new mistake record if the answer is different
                if selectedAnswer != mistake.userAnswer {
                    mistakeManager.saveMistake(
                        question: currentQuestion.question,
                        correctAnswer: currentQuestion.correctAnswer,
                        userAnswer: selectedAnswer,
                        explanation: currentQuestion.explanation,
                        feedback: aiVerificationResult?.feedback,
                        questionType: currentQuestion.type,
                        difficulty: currentQuestion.difficulty,
                        topic: currentQuestion.topic,
                        focus: currentQuestion.focus,
                        options: currentQuestion.options
                    )
                }
            }
        }
    }
    
    private func nextQuestion() {
        quizManager.nextQuestion()
        selectedAnswer = quizManager.userAnswers[quizManager.currentQuestionIndex]
        aiVerificationResult = nil
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showFeedback = false
        }
    }
    
    private func finishQuiz() {
        guard let quiz = quizManager.currentQuiz else { return }
        
        var score = 0
        for (index, answer) in quizManager.userAnswers.enumerated() {
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
            answers: quizManager.userAnswers
        )
        
        // Use auto-flow completion method
        quizManager.completeQuizWithAutoFlow(result)
        userProfile.completeQuiz(score: result.score, totalQuestions: result.totalQuestions)
        finalResult = result
        
        withAnimation(.easeInOut(duration: 0.5)) {
            quizCompleted = true
        }
    }
}

// MARK: - Conversation Reading View
struct ConversationReadingView: View {
    let conversation: Conversation
    let onContinueToQuiz: () -> Void
    @State private var useOpenAITTS = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Read the Conversation")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Study the dialogue and learning elements, then answer quiz questions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.largeTitle)
                        .foregroundColor(.mint)
                }
                
                // Audio playback options
                VStack(spacing: 12) {
                    // TTS Option Toggle
                    VStack(spacing: 8) {
                        HStack {
                            Text("Audio Options:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Picker("TTS Options", selection: $useOpenAITTS) {
                                Text("System Voice").tag(false)
                                Text("AI Voice").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(maxWidth: 200)
                        }
                        
                        // TTS explanation
                        HStack {
                            Image(systemName: useOpenAITTS ? "brain.head.profile" : "speaker.wave.2")
                                .font(.caption)
                                .foregroundColor(useOpenAITTS ? .purple : .blue)
                                .animation(.easeInOut(duration: 0.3), value: useOpenAITTS)
                            
                            Text(useOpenAITTS ? "High-quality AI-generated voice" : "Your device's built-in voice")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .animation(.easeInOut(duration: 0.3), value: useOpenAITTS)
                            
                            Spacer()
                        }
                    }
                    
                    // Play conversation button
                    Button(action: {
                        playEntireConversation()
                    }) {
                        HStack {
                            Image(systemName: useOpenAITTS ? "waveform.badge.plus" : "waveform")
                                .font(.title2)
                                .animation(.easeInOut(duration: 0.3), value: useOpenAITTS)
                            Text("Play Entire Conversation")
                                .fontWeight(.semibold)
                            
                            if useOpenAITTS {
                                Image(systemName: "brain.head.profile")
                                    .font(.caption)
                                    .foregroundColor(.purple.opacity(0.8))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(useOpenAITTS ? .purple : .mint)
                                .animation(.easeInOut(duration: 0.3), value: useOpenAITTS)
                        )
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            // Conversation Content
            ScrollView {
                VStack(spacing: 20) {
                    ConversationView(conversation: conversation, useOpenAITTS: useOpenAITTS)
                }
                .padding()
            }
            
            // Continue Button
            VStack(spacing: 16) {
                Divider()
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    
                    Text("Ready to test your understanding?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                Button(action: onContinueToQuiz) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                        Text("Start Quiz Questions")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue)
                    )
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
    }
    
    private func playEntireConversation() {
        let fullText = conversation.messages.map { "\($0.speaker): \($0.message)" }.joined(separator: ". ")
        
        if useOpenAITTS {
            // Use OpenAI TTS with enhanced voice
            SpeechService.shared.speakWithOpenAI(fullText, voice: .nova)
        } else {
            // Use system TTS
            SpeechService.shared.speak(fullText, rate: 0.4)
        }
    }
}

// MARK: - Conversation View
struct ConversationView: View {
    let conversation: Conversation
    let useOpenAITTS: Bool
    @State private var highlightedElement: LearningElement? = nil
    
    init(conversation: Conversation, useOpenAITTS: Bool = false) {
        self.conversation = conversation
        self.useOpenAITTS = useOpenAITTS
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Conversation Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.title2)
                        .foregroundColor(.mint)
                    
                    Text(conversation.scenario)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Label("\(conversation.estimatedReadingTime) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Conversation Messages
            LazyVStack(spacing: 12) {
                ForEach(conversation.messages) { message in
                    ConversationMessageView(
                        message: message,
                        highlightedElement: $highlightedElement,
                        useOpenAITTS: useOpenAITTS
                    )
                }
            }
            
            // Learning Elements Summary
            if !conversation.messages.flatMap({ $0.learningElements }).isEmpty {
                LearningElementsSummaryView(
                    elements: conversation.messages.flatMap({ $0.learningElements }),
                    highlightedElement: $highlightedElement
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct ConversationMessageView: View {
    let message: ConversationMessage
    @Binding var highlightedElement: LearningElement?
    let useOpenAITTS: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Speaker Avatar
            Circle()
                .fill(speakerColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(message.speaker.prefix(1)))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                // Speaker Name
                Text(message.speaker)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                // Message with highlighted learning elements
                HighlightedTextView(
                    text: message.message,
                    learningElements: message.learningElements,
                    highlightedElement: $highlightedElement
                )
                
                // TTS Button
                HStack {
                    Spacer()
                    Button(action: {
                        if useOpenAITTS {
                            SpeechService.shared.speakWithOpenAI(message.message, voice: .nova)
                        } else {
                            SpeechService.shared.speak(message.message, rate: 0.5)
                        }
                    }) {
                        Image(systemName: useOpenAITTS ? "waveform.badge.plus" : "waveform")
                            .font(.title2)
                            .foregroundColor(useOpenAITTS ? .purple : .blue)
                            .animation(.easeInOut(duration: 0.3), value: useOpenAITTS)
                    }
                    .scaleEffect(0.8)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private var speakerColor: Color {
        // Generate consistent colors based on speaker name
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan]
        let index = abs(message.speaker.hashValue) % colors.count
        return colors[index]
    }
}

struct HighlightedTextView: View {
    let text: String
    let learningElements: [LearningElement]
    @Binding var highlightedElement: LearningElement?
    
    var body: some View {
        Text(attributedText)
            .font(.body)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var attributedText: AttributedString {
        var attributedString = AttributedString(text)
        
        for element in learningElements {
            if let range = attributedString.range(of: element.text) {
                attributedString[range].backgroundColor = element.type.color.opacity(0.3)
                attributedString[range].foregroundColor = element.type.color
                attributedString[range].font = .body.weight(.semibold)
            }
        }
        
        return attributedString
    }
}

struct LearningElementsSummaryView: View {
    let elements: [LearningElement]
    @Binding var highlightedElement: LearningElement?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.orange)
                Text("Learning Elements")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150))
            ], spacing: 8) {
                ForEach(elements) { element in
                    LearningElementBadge(
                        element: element,
                        isHighlighted: highlightedElement?.id == element.id
                    ) {
                        if highlightedElement?.id == element.id {
                            highlightedElement = nil
                        } else {
                            highlightedElement = element
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct LearningElementBadge: View {
    let element: LearningElement
    let isHighlighted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(element.type.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(element.type.color)
                    Spacer()
                }
                
                Text(element.text)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                
                Text(element.explanation)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(element.type.color.opacity(isHighlighted ? 0.2 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(element.type.color.opacity(isHighlighted ? 0.8 : 0.3), lineWidth: isHighlighted ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuizResultView: View {
    let result: QuizResult
    let onDismiss: () -> Void
    @EnvironmentObject var userProfile: UserProfile
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Result Icon
            Image(systemName: result.isPerfectScore ? "star.fill" : result.percentage >= 80 ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(result.isPerfectScore ? .yellow : result.percentage >= 80 ? .green : .red)
            
            // Result Text
            VStack(spacing: 16) {
                Text(resultTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("You scored \(result.score) out of \(result.totalQuestions)")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("\(Int(result.percentage))% accuracy")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            // Points Earned
            VStack(spacing: 8) {
                Text("Points Earned")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("+\(result.score * 10)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
            )
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 16) {
                Button("Continue Learning") {
                    onDismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Review Answers") {
                    // Show answer review
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding()
    }
    
    private var resultTitle: String {
        if result.isPerfectScore {
            return "Perfect Score! 🎉"
        } else if result.percentage >= 80 {
            return "Great Job! 👏"
        } else if result.percentage >= 60 {
            return "Good Effort! 👍"
        } else {
            return "Keep Practicing! 💪"
        }
    }
}

#Preview {
    QuizView(quiz: Quiz(
        title: "Sample Quiz",
        questions: [
            QuizQuestion(
                type: .multipleChoice,
                question: "What is the capital of France?",
                correctAnswer: "Paris",
                options: ["London", "Berlin", "Paris", "Madrid"],
                explanation: "Paris is the capital and largest city of France.",
                difficulty: .beginner,
                topic: .travel,
                focus: .vocabulary
            )
        ],
        estimatedDuration: 5,
        createdAt: Date(),
        topic: .travel,
        difficulty: .beginner
    ))
    .environmentObject(UserProfile())
    .environmentObject(QuizManager())
    .environmentObject(MistakeManager())
} 