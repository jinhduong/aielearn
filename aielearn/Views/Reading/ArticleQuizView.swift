//
//  ArticleQuizView.swift
//  aielearn
//
//  Created by AI Assistant
//

import SwiftUI

struct ArticleQuizView: View {
    let article: Article
    let questions: [QuizQuestion]
    @EnvironmentObject var articleManager: ArticleManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: [String] = []
    @State private var userAnswers: [String] = []
    @State private var showingResults = false
    @State private var quizStartTime = Date()
    @State private var selectedAnswer: String = ""
    
    var currentQuestion: QuizQuestion? {
        questions.indices.contains(currentQuestionIndex) ? questions[currentQuestionIndex] : nil
    }
    
    var isLastQuestion: Bool {
        currentQuestionIndex >= questions.count - 1
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if questions.isEmpty {
                    // Modern loading state for quiz questions
                    VStack(spacing: 20) {
                        ModernLoadingIndicator.morphingSymbol(
                            message: "Loading quiz questions...",
                            color: DesignSystem.Colors.Loading.quiz
                        )
                        
                        DSStatusMessage(
                            type: .loading,
                            title: "Preparing Quiz",
                            message: "Please wait while we prepare your quiz questions."
                        )
                    }
                    .padding()
                } else if showingResults {
                    ArticleQuizResultsView(
                        article: article,
                        questions: questions,
                        userAnswers: userAnswers,
                        onDismiss: {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                    .environmentObject(articleManager)
                } else {
                    questionView
                }
            }
        }
        .onAppear {
            setupQuiz()
        }
        .onChange(of: questions.count) { _ in
            // Retry setup when questions become available
            if !questions.isEmpty && userAnswers.isEmpty {
                setupQuiz()
            }
        }
    }
    
    private var questionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress indicator
                QuizProgressView(
                    currentQuestion: currentQuestionIndex + 1,
                    totalQuestions: questions.count,
                    article: article
                )
                
                // Question content
                if let question = currentQuestion {
                    QuestionCard(
                        question: question,
                        selectedAnswer: $selectedAnswer,
                        onAnswerSelected: { answer in
                            selectedAnswer = answer
                        }
                    )
                }
                
                // Navigation buttons
                NavigationButtons()
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle("Comprehension Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
        )
    }
    
    private func setupQuiz() {
        guard !questions.isEmpty else {
            // Don't setup quiz if no questions available yet
            return
        }
        
        userAnswers = Array(repeating: "", count: questions.count)
        selectedAnswers = Array(repeating: "", count: questions.count)
        quizStartTime = Date()
        currentQuestionIndex = 0
        selectedAnswer = ""
    }
    
    private func nextQuestion() {
        // Save current answer
        if currentQuestionIndex < userAnswers.count {
            userAnswers[currentQuestionIndex] = selectedAnswer
        }
        
        if isLastQuestion {
            // Show results
            showingResults = true
        } else {
            // Move to next question
            currentQuestionIndex += 1
            selectedAnswer = userAnswers[currentQuestionIndex] 
        }
    }
    
    private func previousQuestion() {
        guard currentQuestionIndex > 0 else { return }
        
        // Save current answer
        userAnswers[currentQuestionIndex] = selectedAnswer
        
        // Move to previous question
        currentQuestionIndex -= 1
        selectedAnswer = userAnswers[currentQuestionIndex]
    }
}

struct QuizProgressView: View {
    let currentQuestion: Int
    let totalQuestions: Int
    let article: Article
    
    var progress: Double {
        Double(currentQuestion) / Double(totalQuestions)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quiz: \(article.title)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    
                    Text("Question \(currentQuestion) of \(totalQuestions)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                
                Capsule()
                    .fill(Color.blue)
                    .frame(width: (UIScreen.main.bounds.width - 40) * progress, height: 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct QuestionCard: View {
    let question: QuizQuestion
    @Binding var selectedAnswer: String
    let onAnswerSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(question.question)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
            
            if question.type == .multipleChoice || question.type == .trueFalse {
                MultipleChoiceOptions(
                    question: question,
                    selectedAnswer: $selectedAnswer,
                    onAnswerSelected: onAnswerSelected
                )
            } else if question.type == .fillInTheBlank {
                FillInTheBlankField(
                    question: question,
                    selectedAnswer: $selectedAnswer,
                    onAnswerSelected: onAnswerSelected
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

struct MultipleChoiceOptions: View {
    let question: QuizQuestion
    @Binding var selectedAnswer: String
    let onAnswerSelected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(question.safeOptions, id: \.self) { option in
                OptionButton(
                    text: option,
                    isSelected: selectedAnswer == option,
                    onTap: {
                        selectedAnswer = option
                        onAnswerSelected(option)
                    }
                )
            }
        }
    }
}

struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(text)
                    .multilineTextAlignment(.leading)
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FillInTheBlankField: View {
    let question: QuizQuestion
    @Binding var selectedAnswer: String
    let onAnswerSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Your answer", text: $selectedAnswer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: selectedAnswer) { newValue in
                    onAnswerSelected(newValue)
                }
            
            if !question.safeOptions.isEmpty {
                Text("Suggested answers:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                FlexibleView(
                    data: question.safeOptions,
                    spacing: 8,
                    alignment: .leading
                ) { option in
                    Button(option) {
                        selectedAnswer = option
                        onAnswerSelected(option)
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct NavigationButtons: View {
    @EnvironmentObject var articleManager: ArticleManager
    @State private var selectedAnswer: String = ""
    let currentQuestionIndex: Int = 0
    let isLastQuestion: Bool = false
    let nextQuestion: () -> Void = {}
    let previousQuestion: () -> Void = {}
    
    var body: some View {
        HStack(spacing: 16) {
            if currentQuestionIndex > 0 {
                Button("Previous") {
                    previousQuestion()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            Spacer()
            
            Button(isLastQuestion ? "Finish Quiz" : "Next") {
                nextQuestion()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selectedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

struct ArticleQuizResultsView: View {
    let article: Article
    let questions: [QuizQuestion]
    let userAnswers: [String]
    let onDismiss: () -> Void
    @EnvironmentObject var articleManager: ArticleManager
    
    @State private var score = 0
    @State private var showingCelebration = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Results header
                ResultsHeader(
                    article: article,
                    score: score,
                    totalQuestions: questions.count
                )
                
                // Detailed results
                ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                    QuestionResultCard(
                        question: question,
                        userAnswer: userAnswers[safe: index] ?? "",
                        isCorrect: isAnswerCorrect(question: question, userAnswer: userAnswers[safe: index] ?? "")
                    )
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("Continue Learning") {
                        recordResults()
                        onDismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Review Article") {
                        onDismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle("Quiz Results")
        .navigationBarItems(trailing: Button("Done") {
            recordResults()
            onDismiss()
        })
        .onAppear {
            calculateScore()
        }
    }
    
    private func calculateScore() {
        score = zip(questions, userAnswers).reduce(0) { total, pair in
            let (question, userAnswer) = pair
            return total + (isAnswerCorrect(question: question, userAnswer: userAnswer) ? 1 : 0)
        }
        
        if score == questions.count {
            showingCelebration = true
        }
    }
    
    private func isAnswerCorrect(question: QuizQuestion, userAnswer: String) -> Bool {
        return userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == 
               question.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private func recordResults() {
        let quizResult = QuizResult(
            quizId: UUID(), // This would be the article-based quiz ID
            score: score,
            totalQuestions: questions.count,
            timeSpent: 300, // Simplified - would track actual time
            completedAt: Date(),
            answers: userAnswers
        )
        
        articleManager.recordArticleQuizResult(articleId: article.id, quizResult: quizResult)
    }
}

struct ResultsHeader: View {
    let article: Article
    let score: Int
    let totalQuestions: Int
    
    var percentage: Double {
        Double(score) / Double(totalQuestions) * 100
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("🎉 Quiz Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Article: \(article.title)")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("\(score)/\(totalQuestions)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(scoreColor)
                
                Text(String(format: "%.0f%% Comprehension", percentage))
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Text(congratulationMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    private var scoreColor: Color {
        switch percentage {
        case 90...100: return .green
        case 70..<90: return .blue
        case 50..<70: return .orange
        default: return .red
        }
    }
    
    private var congratulationMessage: String {
        switch percentage {
        case 90...100: return "Excellent comprehension! You've mastered this article."
        case 70..<90: return "Great job! You understood most of the key concepts."
        case 50..<70: return "Good effort! Consider reviewing the article for better understanding."
        default: return "Keep practicing! Reading comprehension improves with time."
        }
    }
}

struct QuestionResultCard: View {
    let question: QuizQuestion
    let userAnswer: String
    let isCorrect: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
                
                Text(question.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Your answer:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(userAnswer)
                        .font(.caption)
                        .foregroundColor(isCorrect ? .green : .red)
                }
                
                if !isCorrect {
                    HStack {
                        Text("Correct answer:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(question.correctAnswer)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Text(question.explanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Helper Views
struct FlexibleView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(Array(data), id: \.self, content: content)
        }
    }
}

// MARK: - Extensions
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ArticleQuizView(
        article: Article(
            title: "Sample Article",
            content: "Sample content",
            topic: .general,
            difficulty: .intermediate,
            estimatedReadingTime: 3,
            wordCount: 250,
            tags: ["sample"],
            summary: "A sample article"
        ),
        questions: [
            QuizQuestion(
                type: .multipleChoice,
                question: "What is the main topic?",
                correctAnswer: "Reading",
                options: ["Reading", "Writing", "Speaking", "Listening"],
                explanation: "The article focuses on reading skills.",
                difficulty: .intermediate,
                topic: .general,
                focus: .reading
            )
        ]
    )
    .environmentObject(ArticleManager())
} 