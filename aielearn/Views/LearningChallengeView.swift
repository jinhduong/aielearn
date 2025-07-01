//
//  LearningChallengeView.swift
//  aielearn
//
//  Created by AI Assistant
//

import SwiftUI

// MARK: - Header Component
struct CongratulationHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            Text("Great Job!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("You completed the quiz successfully! Here's your next learning challenge:")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Learning Challenge Card Component
struct LearningChallengeCardView: View {
    let learningTips: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Your Learning Challenge")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Daily Learning Tips")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                ForEach(learningTips.shuffled().prefix(3), id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(tip)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(challengeCardBackground)
    }
    
    private var challengeCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.blue.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Action Buttons Component
struct LearningActionButtonsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var quizManager: QuizManager
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: takeAnotherQuizAction) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Take Another Quiz")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(primaryButtonBackground)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button("Continue Learning") {
                presentationMode.wrappedValue.dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(secondaryButtonBackground)
            .foregroundColor(.blue)
        }
    }
    
    private func takeAnotherQuizAction() {
        presentationMode.wrappedValue.dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            quizManager.generateRandomQuiz(for: userProfile)
        }
    }
    
    private var primaryButtonBackground: some View {
        LinearGradient(
            colors: [.blue, .cyan],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var secondaryButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.blue, lineWidth: 2)
    }
}

// MARK: - Progress Encouragement Component
struct ProgressEncouragementView: View {
    @EnvironmentObject var userProfile: UserProfile
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Current Streak: \(userProfile.currentStreak) days")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange)
                    .frame(width: max(0, CGFloat(userProfile.currentStreak % 7) / 7.0 * 200), height: 8)
            }
            .frame(maxWidth: 200)
            
            Text("Keep going to reach your 7-day streak goal!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(progressBackground)
    }
    
    private var progressBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.orange.opacity(0.1))
    }
}

// MARK: - Main Learning Challenge View
struct LearningChallengeView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var quizManager: QuizManager
    @Environment(\.presentationMode) var presentationMode
    
    let learningTips: [String] = {
        var tips: [String] = []
        tips.append("🎯 Practice daily for 15 minutes to build consistency")
        tips.append("📚 Read English articles or books in your free time")
        tips.append("🎧 Listen to English podcasts while commuting")
        tips.append("💬 Try to think in English throughout the day")
        tips.append("📝 Keep a vocabulary journal of new words")
        tips.append("🗣️ Practice speaking with yourself in the mirror")
        tips.append("🎬 Watch English movies with subtitles")
        tips.append("🎵 Listen to English music and learn the lyrics")
        return tips
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                    
                    CongratulationHeaderView()
                    
                    LearningChallengeCardView(learningTips: learningTips)
                    
                    LearningActionButtonsView()
                    
                    ProgressEncouragementView()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Learning Challenge")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LearningChallengeView()
        .environmentObject(UserProfile())
        .environmentObject(QuizManager())
} 