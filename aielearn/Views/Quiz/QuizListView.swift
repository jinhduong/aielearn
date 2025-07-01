//
//  QuizListView.swift
//  aielearn
//
//  Created by AI Assistant
//

import SwiftUI

struct QuizListView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var quizManager: QuizManager
    @State private var selectedQuiz: Quiz?
    @State private var showingQuizSheet = false
    @State private var selectedFilter: QuizFilter = .all
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Section
                FilterBarView(selectedFilter: $selectedFilter)
                
                // Quiz List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if filteredQuizzes.isEmpty {
                            EmptyQuizListView()
                        } else {
                            ForEach(filteredQuizzes) { quiz in
                                QuizCardView(quiz: quiz) {
                                    selectedQuiz = quiz
                                    showingQuizSheet = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Quizzes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        quizManager.generateQuiz(for: userProfile)
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingQuizSheet) {
                if let quiz = selectedQuiz {
                    QuizView(quiz: quiz)
                        .environmentObject(userProfile)
                        .environmentObject(quizManager)
                }
            }
        }
    }
    
    private var filteredQuizzes: [Quiz] {
        switch selectedFilter {
        case .all:
            return quizManager.availableQuizzes
        case .completed:
            let completedQuizIds = Set(quizManager.quizHistory.map { $0.quizId })
            return quizManager.availableQuizzes.filter { completedQuizIds.contains($0.id) }
        case .new:
            let completedQuizIds = Set(quizManager.quizHistory.map { $0.quizId })
            return quizManager.availableQuizzes.filter { !completedQuizIds.contains($0.id) }
        case .byTopic(let topic):
            return quizManager.availableQuizzes.filter { $0.topic == topic }
        }
    }
}

enum QuizFilter: Hashable {
    case all
    case completed
    case new
    case byTopic(LearningTopic)
    
    var title: String {
        switch self {
        case .all: return "All"
        case .completed: return "Completed"
        case .new: return "New"
        case .byTopic(let topic): return topic.rawValue
        }
    }
}

struct FilterBarView: View {
    @Binding var selectedFilter: QuizFilter
    @EnvironmentObject var userProfile: UserProfile
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: QuizFilter.all.title,
                    isSelected: selectedFilter == .all
                ) {
                    selectedFilter = .all
                }
                
                FilterChip(
                    title: QuizFilter.new.title,
                    isSelected: selectedFilter == .new
                ) {
                    selectedFilter = .new
                }
                
                FilterChip(
                    title: QuizFilter.completed.title,
                    isSelected: selectedFilter == .completed
                ) {
                    selectedFilter = .completed
                }
                
                ForEach(Array(userProfile.selectedTopics), id: \.self) { topic in
                    FilterChip(
                        title: topic.rawValue,
                        isSelected: selectedFilter == .byTopic(topic)
                    ) {
                        selectedFilter = .byTopic(topic)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuizCardView: View {
    let quiz: Quiz
    let action: () -> Void
    @EnvironmentObject var quizManager: QuizManager
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quiz.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)
                        
                        Text("\(quiz.questions.count) questions • \(quiz.estimatedDuration) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        DifficultyBadge(level: quiz.difficulty)
                        
                        if isCompleted {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("Completed")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                // Topic and Focus
                HStack {
                    TopicChip(topic: quiz.topic)
                    
                    if let lastResult = lastResult {
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("Last Score:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(lastResult.percentage))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(lastResult.percentage >= 80 ? .green : lastResult.percentage >= 60 ? .orange : .red)
                        }
                    }
                }
                
                // Action Button
                HStack {
                    Spacer()
                    
                    Text(isCompleted ? "Retake Quiz" : "Start Quiz")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var isCompleted: Bool {
        quizManager.quizHistory.contains { $0.quizId == quiz.id }
    }
    
    private var lastResult: QuizResult? {
        quizManager.quizHistory
            .filter { $0.quizId == quiz.id }
            .sorted { $0.completedAt > $1.completedAt }
            .first
    }
}

struct DifficultyBadge: View {
    let level: ProficiencyLevel
    
    var body: some View {
        Text(level.description)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(level.color.opacity(0.1))
            )
            .foregroundColor(level.color)
    }
}

struct TopicChip: View {
    let topic: LearningTopic
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: topic.icon)
                .font(.caption)
            
            Text(topic.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
        .foregroundColor(.blue)
    }
}

struct EmptyQuizListView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var quizManager: QuizManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("No Quizzes Available")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Generate your first AI-powered quiz based on your learning preferences!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                quizManager.generateQuiz(for: userProfile)
            }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                    Text("Generate Quiz")
                        .fontWeight(.semibold)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

#Preview {
    QuizListView()
        .environmentObject(UserProfile())
        .environmentObject(QuizManager())
} 