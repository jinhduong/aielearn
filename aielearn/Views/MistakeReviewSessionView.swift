//
//  MistakeReviewSessionView.swift
//  aielearn
//
//  Created by AI Assistant
//

import SwiftUI

struct MistakeReviewSessionView: View {
    let mistakes: [MistakeRecord]
    @EnvironmentObject var mistakeManager: MistakeManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentIndex = 0
    @State private var userAnswer = ""
    @State private var showingResult = false
    @State private var isCorrect = false
    @State private var sessionComplete = false
    @State private var correctCount = 0
    
    private var currentMistake: MistakeRecord? {
        guard currentIndex < mistakes.count else { return nil }
        return mistakes[currentIndex]
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if sessionComplete {
                    VStack(spacing: 20) {
                        Text("Session Complete!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Score: \(correctCount)/\(mistakes.count)")
                            .font(.title2)
                        
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if let mistake = currentMistake {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Question \(currentIndex + 1) of \(mistakes.count)")
                            .font(.headline)
                        
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading) {
                                Text(mistake.question)
                                    .font(.title3)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            
                            SpeechButton(text: mistake.question, type: .question)
                        }
                        
                        if showingResult {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(isCorrect ? "Correct!" : "Incorrect")
                                        .font(.headline)
                                        .foregroundColor(isCorrect ? .green : .red)
                                    Spacer()
                                }
                                
                                if !isCorrect {
                                    Text("Your answer: \(userAnswer)")
                                        .foregroundColor(.red)
                                }
                                
                                HStack(spacing: 8) {
                                    Text("Correct answer: \(mistake.correctAnswer)")
                                        .foregroundColor(.green)
                                    
                                    Spacer()
                                    
                                    SpeechButton(text: mistake.correctAnswer, type: .answer)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Explanation:")
                                            .font(.body)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        SpeechButton(text: mistake.explanation, type: .explanation)
                                    }
                                    
                                    Text(mistake.explanation)
                                        .font(.body)
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                                
                                Button("Next") {
                                    nextQuestion()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Your answer:")
                                    .font(.headline)
                                
                                TextField("Type your answer...", text: $userAnswer)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button("Submit") {
                                    submitAnswer()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(userAnswer.isEmpty)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    Text("No mistakes to review")
                        .font(.title2)
                }
            }
            .navigationTitle("Review Session")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Exit") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func submitAnswer() {
        guard let mistake = currentMistake else { return }
        
        isCorrect = userAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                   mistake.correctAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isCorrect {
            correctCount += 1
        }
        
        mistakeManager.markAsReviewed(mistake, wasCorrect: isCorrect)
        showingResult = true
    }
    
    private func nextQuestion() {
        currentIndex += 1
        
        if currentIndex >= mistakes.count {
            sessionComplete = true
        } else {
            userAnswer = ""
            showingResult = false
        }
    }
}

#Preview {
    MistakeReviewSessionView(mistakes: [])
        .environmentObject(MistakeManager())
} 