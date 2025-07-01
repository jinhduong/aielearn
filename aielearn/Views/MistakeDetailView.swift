//
//  MistakeDetailView.swift
//  aielearn
//
//  Created by AI Assistant
//

import SwiftUI

struct MistakeDetailView: View {
    let mistake: MistakeRecord
    @EnvironmentObject var mistakeManager: MistakeManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingDeleteAlert = false
    @State private var userAnswer = ""
    @State private var isReviewMode = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Info
                    MistakeHeaderView(mistake: mistake)
                    
                    // Question Section
                    MistakeQuestionView(mistake: mistake)
                    
                    // Answer Section
                    MistakeAnswerView(mistake: mistake)
                    
                    // Explanation Section
                    MistakeExplanationView(mistake: mistake)
                    
                    // Review Section
                    if !mistake.isMastered {
                        MistakeReviewSection(
                            mistake: mistake,
                            userAnswer: $userAnswer,
                            isReviewMode: $isReviewMode
                        )
                    }
                    
                    // Progress Section
                    MistakeProgressView(mistake: mistake)
                }
                .padding()
            }
            .navigationTitle("Mistake Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if !mistake.isMastered {
                            Button("Mark as Reviewed") {
                                mistakeManager.markAsReviewed(mistake, wasCorrect: true)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                        
                        Button("Delete Mistake", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("Delete Mistake", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                mistakeManager.deleteMistake(mistake)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this mistake? This action cannot be undone.")
        }
    }
}

struct MistakeHeaderView: View {
    let mistake: MistakeRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: mistake.topic.icon)
                    .font(.title)
                    .foregroundColor(mistake.topic.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mistake.topic.rawValue.capitalized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Created \(formatDate(mistake.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if mistake.isMastered {
                    Label("Mastered", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            HStack(spacing: 8) {
                Label(mistake.difficulty.rawValue.capitalized, systemImage: "star.fill")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(mistake.difficulty.color.opacity(0.2))
                    .foregroundColor(mistake.difficulty.color)
                    .cornerRadius(8)
                
                Label(mistake.focus.rawValue.capitalized, systemImage: "target")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct MistakeQuestionView: View {
    let mistake: MistakeRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Question", systemImage: "questionmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                SpeechButton(text: mistake.question, type: .question)
            }
            
            Text(mistake.question)
                .font(.body)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            
            if let options = mistake.options, !options.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Options:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(options.indices, id: \.self) { index in
                        HStack {
                            Text("\(index + 1).")
                                .fontWeight(.medium)
                            Text(options[index])
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct MistakeAnswerView: View {
    let mistake: MistakeRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Your Answer", systemImage: "xmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(mistake.userAnswer)
                        .font(.body)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Correct Answer", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        SpeechButton(text: mistake.correctAnswer, type: .answer)
                    }
                    
                    Text(mistake.correctAnswer)
                        .font(.body)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                        )
                }
            }
        }
    }
}

struct MistakeExplanationView: View {
    let mistake: MistakeRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Explanation", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                SpeechButton(text: mistake.explanation, type: .explanation)
            }
            
            Text(mistake.explanation)
                .font(.body)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            
            if let feedback = mistake.feedback {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("AI Feedback", systemImage: "brain.head.profile")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                        
                        Spacer()
                        
                        SpeechButton(text: feedback, type: .feedback)
                    }
                    
                    Text(feedback)
                        .font(.body)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.1))
                        )
                }
            }
        }
    }
}

struct MistakeReviewSection: View {
    let mistake: MistakeRecord
    @Binding var userAnswer: String
    @Binding var isReviewMode: Bool
    @EnvironmentObject var mistakeManager: MistakeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Review", systemImage: "brain.head.profile")
                .font(.headline)
                .foregroundColor(.purple)
            
            if !isReviewMode {
                Button("Start Review") {
                    isReviewMode = true
                    userAnswer = ""
                }
                .buttonStyle(.borderedProminent)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Try answering again:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Your answer...", text: $userAnswer)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack(spacing: 12) {
                        Button("Check Answer") {
                            let isCorrect = userAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == 
                                          mistake.correctAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                            mistakeManager.markAsReviewed(mistake, wasCorrect: isCorrect)
                            isReviewMode = false
                            userAnswer = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(userAnswer.isEmpty)
                        
                        Button("Cancel") {
                            isReviewMode = false
                            userAnswer = ""
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.1))
                )
            }
        }
    }
}

struct MistakeProgressView: View {
    let mistake: MistakeRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Progress", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Review Count:")
                    Spacer()
                    Text("\(mistake.reviewCount)")
                        .fontWeight(.medium)
                }
                
                if let lastReviewed = mistake.lastReviewedAt {
                    HStack {
                        Text("Last Reviewed:")
                        Spacer()
                        Text(formatDate(lastReviewed))
                            .fontWeight(.medium)
                    }
                }
                
                HStack {
                    Text("Status:")
                    Spacer()
                    if mistake.isMastered {
                        Label("Mastered", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if mistake.needsReview {
                        Label("Needs Review", systemImage: "clock.fill")
                            .foregroundColor(.orange)
                    } else {
                        Label("Up to Date", systemImage: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            .font(.subheadline)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    MistakeDetailView(mistake: MistakeRecord(
        question: "What is the past tense of 'go'?",
        correctAnswer: "went",
        userAnswer: "goed",
        explanation: "The past tense of 'go' is 'went', which is an irregular verb form.",
        feedback: nil,
        questionType: .fillInTheBlank,
        difficulty: .intermediate,
        topic: .grammar,
        focus: .vocabulary,
        createdAt: Date(),
        options: nil
    ))
    .environmentObject(MistakeManager())
} 