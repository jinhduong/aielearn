//
//  ProfileView.swift
//  aielearn
//
//  Created by AI Assistant
//

import SwiftUI
import AVFoundation

struct ProfileView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var quizManager: QuizManager
    @EnvironmentObject var mistakeManager: MistakeManager
    @State private var showingMistakeReview = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderView()
                    
                    // Quick Stats
                    QuickStatsView()
                    
                    // Review & Practice
                    ReviewPracticeView(showingMistakeReview: $showingMistakeReview)
                    
                    // Learning Preferences
                    LearningPreferencesView()
                    
                    // App Info
                    AppVersionView()
                }
                .padding()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingMistakeReview) {
                MistakeReviewView()
                    .environmentObject(mistakeManager)
                    .environmentObject(userProfile)
            }
        }
    }
}

struct ProfileHeaderView: View {
    @EnvironmentObject var userProfile: UserProfile
    @State private var showingProficiencyEdit = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                )
            
            VStack(spacing: 8) {
                Text("English Learner")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Level Badge (now tappable)
                Button(action: {
                    showingProficiencyEdit = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(userProfile.proficiencyLevel.description)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(userProfile.proficiencyLevel.color.opacity(0.1))
                    )
                    .foregroundColor(userProfile.proficiencyLevel.color)
                    .overlay(
                        Capsule()
                            .stroke(userProfile.proficiencyLevel.color.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("Tap to edit level")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .sheet(isPresented: $showingProficiencyEdit) {
            ProficiencyEditView()
                .environmentObject(userProfile)
        }
    }
}

struct QuickStatsView: View {
    @EnvironmentObject var userProfile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                QuickStatCard(
                    icon: "brain.head.profile",
                    title: "Points",
                    value: "\(userProfile.totalPoints)",
                    color: .blue
                )
                
                QuickStatCard(
                    icon: "flame.fill",
                    title: "Streak",
                    value: "\(userProfile.currentStreak)",
                    color: .orange
                )
                
                QuickStatCard(
                    icon: "trophy.fill",
                    title: "Badges",
                    value: "\(userProfile.badges.count)",
                    color: .purple
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

struct QuickStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct LearningPreferencesView: View {
    @EnvironmentObject var userProfile: UserProfile
    @State private var showingProficiencyEdit = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Learning Preferences")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                EditablePreferenceRow(
                    icon: "star.fill",
                    title: "Proficiency Level",
                    value: userProfile.proficiencyLevel.description,
                    color: userProfile.proficiencyLevel.color
                ) {
                    showingProficiencyEdit = true
                }
                
                PreferenceRow(
                    icon: "book.pages",
                    title: "Interested Topics",
                    value: "\(userProfile.selectedTopics.count) selected",
                    color: .blue
                )
                
                PreferenceRow(
                    icon: "target",
                    title: "Learning Focus",
                    value: "\(userProfile.learningFocuses.count) selected",
                    color: .green
                )
                
                // Voice Selection
                VoiceSelectionRow()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .sheet(isPresented: $showingProficiencyEdit) {
            ProficiencyEditView()
                .environmentObject(userProfile)
        }
    }
}

struct PreferenceRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct EditablePreferenceRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(value)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReviewPracticeView: View {
    @EnvironmentObject var mistakeManager: MistakeManager
    @Binding var showingMistakeReview: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review & Practice")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Button(action: {
                    showingMistakeReview = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Review Mistakes")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            if mistakeManager.pendingReviewCount > 0 {
                                Text("\(mistakeManager.pendingReviewCount) mistakes need review")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                Text("All caught up!")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                        
                        if mistakeManager.pendingReviewCount > 0 {
                            Text("\(mistakeManager.pendingReviewCount)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.orange)
                                )
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("\(mistakeManager.totalMistakeCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 4) {
                        Text("\(mistakeManager.pendingReviewCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("Pending")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 4) {
                        Text("\(mistakeManager.masteredCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("Mastered")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
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

struct AppVersionView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("AIELearn")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Made with ❤️ for English learners")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct ProficiencyEditView: View {
    @EnvironmentObject var userProfile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLevel: ProficiencyLevel
    
    init() {
        // Initialize with current proficiency level
        _selectedLevel = State(initialValue: .beginner)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("Update Your Level")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Choose your current English proficiency level. This helps us create personalized quizzes for you.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 16) {
                        ForEach(ProficiencyLevel.allCases, id: \.self) { level in
                            ProficiencyEditCard(
                                level: level,
                                isSelected: selectedLevel == level
                            ) {
                                selectedLevel = level
                            }
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Proficiency Level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        userProfile.proficiencyLevel = selectedLevel
                        userProfile.saveUserData()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            selectedLevel = userProfile.proficiencyLevel
        }
    }
}

struct ProficiencyEditCard: View {
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
                        .foregroundColor(.primary)
                    
                    Text(levelDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(level.color)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? level.color.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? level.color : Color.clear, lineWidth: 2)
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

struct VoiceSelectionRow: View {
    @EnvironmentObject var userProfile: UserProfile
    @State private var showingVoiceSelection = false
    @State private var availableVoices: [VoiceOption] = []
    @State private var selectedVoice: VoiceOption?
    
    var body: some View {
        EditablePreferenceRow(
            icon: "waveform",
            title: "Voice Selection",
            value: selectedVoice?.name ?? "Loading...",
            color: .purple
        ) {
            showingVoiceSelection = true
        }
        .onAppear {
            loadVoices()
        }
        .sheet(isPresented: $showingVoiceSelection) {
            VoiceSelectionSheet(
                availableVoices: availableVoices,
                selectedVoice: $selectedVoice,
                onVoiceSelected: { voice in
                    userProfile.setSelectedVoice(voice.identifier)
                    selectedVoice = voice
                }
            )
        }
    }
    
    private func loadVoices() {
        availableVoices = userProfile.getHighQualityVoices()
        
        // Find currently selected voice
        let currentIdentifier = userProfile.selectedVoiceIdentifier
        selectedVoice = availableVoices.first { $0.identifier == currentIdentifier }
    }
}

struct VoiceSelectionSheet: View {
    let availableVoices: [VoiceOption]
    @Binding var selectedVoice: VoiceOption?
    let onVoiceSelected: (VoiceOption) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var testingVoice: VoiceOption?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Choose your preferred voice for text-to-speech. Only high-quality voices (Q2 and Q3) are shown.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
                
                Section("Available Voices") {
                    ForEach(availableVoices, id: \.identifier) { voice in
                        VoiceOptionRow(
                            voice: voice,
                            isSelected: selectedVoice?.identifier == voice.identifier,
                            isTesting: testingVoice?.identifier == voice.identifier,
                            onSelect: {
                                selectedVoice = voice
                                onVoiceSelected(voice)
                            },
                            onTest: {
                                testVoice(voice)
                            }
                        )
                    }
                }
            }
            .navigationTitle("Voice Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func testVoice(_ voice: VoiceOption) {
        testingVoice = voice
        
        // Create a test voice and speak
        if let avVoice = AVSpeechSynthesisVoice(identifier: voice.identifier) {
            SpeechService.shared.setVoice(avVoice)
            SpeechService.shared.speak("Hello! This is how I sound. I will help you learn English with clear pronunciation.")
        }
        
        // Clear testing state after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            testingVoice = nil
        }
    }
}

struct VoiceOptionRow: View {
    let voice: VoiceOption
    let isSelected: Bool
    let isTesting: Bool
    let onSelect: () -> Void
    let onTest: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(voice.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(voice.qualityDisplayName)
                    .font(.caption)
                    .foregroundColor(voice.quality == .enhanced ? .purple : .blue)
            }
            
            Spacer()
            
            // Test button
            Button(action: onTest) {
                if isTesting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                } else {
                    Image(systemName: "play.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isTesting)
            
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserProfile())
        .environmentObject(QuizManager())
        .environmentObject(MistakeManager())
} 