//
//  MistakeListView.swift
//  aielearn
//
//  Created by AI Assistant
//

import SwiftUI

struct MistakeListView: View {
    let mistakes: [MistakeRecord]
    let emptyMessage: String
    let onMistakeSelected: (MistakeRecord) -> Void
    
    var body: some View {
        Group {
            if mistakes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text(emptyMessage)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(mistakes) { mistake in
                            MistakeRowView(mistake: mistake) {
                                onMistakeSelected(mistake)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
        }
    }
}

struct MistakeRowView: View {
    let mistake: MistakeRecord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Topic Icon
                Image(systemName: mistake.topic.icon)
                    .font(.title2)
                    .foregroundColor(mistake.topic.color)
                    .frame(width: 30, height: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Question Preview
                    Text(mistake.question)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Correct Answer with Speech
                    HStack(spacing: 8) {
                        Text("Correct: \(mistake.correctAnswer)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        SpeechButton(text: mistake.correctAnswer, type: .answer)
                            .onTapGesture {
                                // Prevent row selection when tapping speech button
                            }
                    }
                    
                    // Your Answer
                    Text("Your answer: \(mistake.userAnswer)")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .lineLimit(1)
                    
                    // Metadata
                    HStack(spacing: 8) {
                        Text(mistake.difficulty.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(mistake.difficulty.color.opacity(0.2))
                            .foregroundColor(mistake.difficulty.color)
                            .cornerRadius(8)
                        
                        Text(mistake.focus.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        if mistake.needsReview && !mistake.isMastered {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        if mistake.isMastered {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MistakeListView(
        mistakes: [],
        emptyMessage: "No mistakes to review!"
    ) { _ in }
} 