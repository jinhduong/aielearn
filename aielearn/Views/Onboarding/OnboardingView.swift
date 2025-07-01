//
//  OnboardingView.swift
//  aielearn
//
//  Created by AI Assistant
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userProfile: UserProfile
    @State private var currentStep = 0
    private let totalSteps = 4
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Bar
                ProgressBar(current: currentStep, total: totalSteps)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Onboarding Content
                TabView(selection: $currentStep) {
                    WelcomeStep()
                        .tag(0)
                    
                    ProficiencyStep()
                        .tag(1)
                    
                    TopicsStep()
                        .tag(2)
                    
                    FocusStep()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Navigation Buttons
                OnboardingNavigationButtons(
                    currentStep: $currentStep,
                    totalSteps: totalSteps,
                    canProceed: canProceedToNextStep()
                )
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func canProceedToNextStep() -> Bool {
        switch currentStep {
        case 0: return true // Welcome step
        case 1: return true // Proficiency is set by default
        case 2: return !userProfile.selectedTopics.isEmpty
        case 3: return !userProfile.learningFocuses.isEmpty
        default: return false
        }
    }
}

struct ProgressBar: View {
    let current: Int
    let total: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Step \(current + 1) of \(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int((Double(current + 1) / Double(total)) * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
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
                        .frame(width: geometry.size.width * (Double(current + 1) / Double(total)), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: current)
                }
            }
            .frame(height: 8)
        }
    }
}

struct OnboardingNavigationButtons: View {
    @EnvironmentObject var userProfile: UserProfile
    @Binding var currentStep: Int
    let totalSteps: Int
    let canProceed: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            Spacer()
            
            Button(currentStep == totalSteps - 1 ? "Get Started!" : "Continue") {
                if currentStep == totalSteps - 1 {
                    // Complete onboarding
                    userProfile.isOnboardingCompleted = true
                    userProfile.saveUserData()
                } else {
                    withAnimation {
                        currentStep += 1
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canProceed)
        }
    }
}

// MARK: - Onboarding Steps

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon/Logo
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 16) {
                Text("Welcome to AIELearn!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Your personalized AI English learning companion. Let's set up your profile to create the perfect learning experience just for you.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct ProficiencyStep: View {
    @EnvironmentObject var userProfile: UserProfile
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What's your English level?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("This helps us create content that's just right for you.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ForEach(ProficiencyLevel.allCases, id: \.self) { level in
                    ProficiencyCard(
                        level: level,
                        isSelected: userProfile.proficiencyLevel == level
                    ) {
                        userProfile.proficiencyLevel = level
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct ProficiencyCard: View {
    let level: ProficiencyLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.description)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(levelDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var levelDescription: String {
        switch level {
        case .beginner:
            return "Just starting out or know basic words and phrases"
        case .intermediate:
            return "Can have conversations and understand most content"
        case .advanced:
            return "Fluent speaker looking to perfect skills"
        }
    }
}

struct TopicsStep: View {
    @EnvironmentObject var userProfile: UserProfile
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What interests you?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Choose topics you'd like to learn about. You can select multiple options.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(LearningTopic.allCases, id: \.self) { topic in
                    TopicCard(
                        topic: topic,
                        isSelected: userProfile.selectedTopics.contains(topic)
                    ) {
                        if userProfile.selectedTopics.contains(topic) {
                            userProfile.selectedTopics.remove(topic)
                        } else {
                            userProfile.selectedTopics.insert(topic)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct TopicCard: View {
    let topic: LearningTopic
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: topic.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(topic.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FocusStep: View {
    @EnvironmentObject var userProfile: UserProfile
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What would you like to improve?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Select the skills you want to focus on during your learning journey.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(LearningFocus.allCases, id: \.self) { focus in
                    FocusCard(
                        focus: focus,
                        isSelected: userProfile.learningFocuses.contains(focus)
                    ) {
                        if userProfile.learningFocuses.contains(focus) {
                            userProfile.learningFocuses.remove(focus)
                        } else {
                            userProfile.learningFocuses.insert(focus)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct FocusCard: View {
    let focus: LearningFocus
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: focus.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(focus.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(minWidth: 120)
            .background(
                LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.blue)
            .padding()
            .frame(minWidth: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserProfile())
} 