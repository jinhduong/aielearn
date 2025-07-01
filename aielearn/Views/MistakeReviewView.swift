//
//  MistakeReviewView.swift
//  aielearn
//
//  Created by AI Assistant
//

import SwiftUI

struct MistakeReviewView: View {
    @EnvironmentObject var mistakeManager: MistakeManager
    @EnvironmentObject var userProfile: UserProfile
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTab = 0
    @State private var showingReviewSession = false
    @State private var reviewMistakes: [MistakeRecord] = []
    @State private var selectedMistake: MistakeRecord?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Stats
                MistakeStatsView()
                
                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    Text("Pending Review").tag(0)
                    Text("All Mistakes").tag(1)
                    Text("Mastered").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search mistakes...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Content
                TabView(selection: $selectedTab) {
                    // Pending Review
                    MistakeListView(
                        mistakes: filteredPendingMistakes,
                        emptyMessage: "No mistakes need review right now! Great job! 🎉",
                        onMistakeSelected: { mistake in
                            selectedMistake = mistake
                        }
                    )
                    .tag(0)
                    
                    // All Mistakes
                    MistakeListView(
                        mistakes: filteredAllMistakes,
                        emptyMessage: "No mistakes saved yet. Keep learning! 📚",
                        onMistakeSelected: { mistake in
                            selectedMistake = mistake
                        }
                    )
                    .tag(1)
                    
                    // Mastered
                    MistakeListView(
                        mistakes: filteredMasteredMistakes,
                        emptyMessage: "No mastered mistakes yet. Keep reviewing! 💪",
                        onMistakeSelected: { mistake in
                            selectedMistake = mistake
                        }
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Review Mistakes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Start Review Session") {
                            startReviewSession()
                        }
                        .disabled(mistakeManager.pendingReviewCount == 0)
                        
                        Button("Clear Mastered") {
                            mistakeManager.clearAllMasteredMistakes()
                        }
                        .disabled(mistakeManager.masteredCount == 0)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingReviewSession) {
            MistakeReviewSessionView(mistakes: reviewMistakes)
        }
        .sheet(item: $selectedMistake) { mistake in
            MistakeDetailView(mistake: mistake)
        }
    }
    
    private var filteredPendingMistakes: [MistakeRecord] {
        let pending = mistakeManager.getMistakesForReview()
        return searchText.isEmpty ? pending : pending.filter { 
            $0.question.localizedCaseInsensitiveContains(searchText) ||
            $0.correctAnswer.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredAllMistakes: [MistakeRecord] {
        let all = mistakeManager.mistakes.filter { !$0.isMastered }
        return searchText.isEmpty ? all : all.filter { 
            $0.question.localizedCaseInsensitiveContains(searchText) ||
            $0.correctAnswer.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredMasteredMistakes: [MistakeRecord] {
        let mastered = mistakeManager.mistakes.filter { $0.isMastered }
        return searchText.isEmpty ? mastered : mastered.filter { 
            $0.question.localizedCaseInsensitiveContains(searchText) ||
            $0.correctAnswer.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func startReviewSession() {
        reviewMistakes = mistakeManager.getMistakesForReview()
        showingReviewSession = true
    }
}

struct MistakeStatsView: View {
    @EnvironmentObject var mistakeManager: MistakeManager
    
    var body: some View {
        HStack(spacing: 16) {
            MistakeStatCard(
                icon: "clock",
                title: "Pending Review",
                value: "\(mistakeManager.pendingReviewCount)",
                color: .orange
            )
            
            MistakeStatCard(
                icon: "doc.text",
                title: "Total Mistakes",
                value: "\(mistakeManager.totalMistakeCount)",
                color: .blue
            )
            
            MistakeStatCard(
                icon: "checkmark.circle",
                title: "Mastered",
                value: "\(mistakeManager.masteredCount)",
                color: .green
            )
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct MistakeStatCard: View {
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    MistakeReviewView()
        .environmentObject(MistakeManager())
        .environmentObject(UserProfile())
} 
