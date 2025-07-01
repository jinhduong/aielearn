//
//  AppNavigationView.swift
//  aielearn
//
//  Created by AI Assistant
//

import SwiftUI

struct AppNavigationView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var apiKeyManager: APIKeyManager
    @EnvironmentObject var quizManager: QuizManager
    @EnvironmentObject var mistakeManager: MistakeManager
    @EnvironmentObject var articleManager: ArticleManager
    
    var body: some View {
        ZStack {
            Group {
                if !apiKeyManager.isConfigured {
                    APIKeySetupView()
                } else if !userProfile.isOnboardingCompleted {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            }
            .animation(.easeInOut(duration: 0.5), value: userProfile.isOnboardingCompleted)
            .animation(.easeInOut(duration: 0.5), value: apiKeyManager.isConfigured)
            
            // ENHANCED: Global Loading Overlay
            GlobalLoadingOverlay()
        }
        .onAppear {
            setupOpenAIService()
        }
        .onChange(of: apiKeyManager.apiKey) {
            setupOpenAIService()
        }
    }
    
    private func setupOpenAIService() {
        if !apiKeyManager.apiKey.isEmpty {
            print("🔑 Setting up OpenAI service with API key: \(apiKeyManager.apiKey.prefix(10))...")
            let openAIService = OpenAIService(apiKey: apiKeyManager.apiKey)
            quizManager.setOpenAIService(openAIService)
            articleManager.setOpenAIService(openAIService)
            SpeechService.shared.setOpenAIService(openAIService)
            print("✅ OpenAI service configured successfully")
        } else {
            print("❌ No API key available - OpenAI service not configured")
            quizManager.setOpenAIService(nil)
            articleManager.setOpenAIService(nil)
            SpeechService.shared.setOpenAIService(nil)
        }
        
        // Ensure voice preference is applied
        SpeechService.shared.updateFromUserProfile()
    }
}

struct MainTabView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var quizManager: QuizManager
    @EnvironmentObject var mistakeManager: MistakeManager
    @EnvironmentObject var articleManager: ArticleManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .environmentObject(userProfile)
                .environmentObject(quizManager)
                .environmentObject(mistakeManager)
                .environmentObject(articleManager)
            
            QuizListView()
                .tabItem {
                    Image(systemName: "questionmark.circle.fill")
                    Text("Quizzes")
                }
                .environmentObject(userProfile)
                .environmentObject(quizManager)
                .environmentObject(mistakeManager)
                .environmentObject(articleManager)
            
            ArticleListView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Reading")
                }
                .environmentObject(userProfile)
                .environmentObject(articleManager)
            
            ProgressView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Progress")
                }
                .environmentObject(userProfile)
                .environmentObject(quizManager)
                .environmentObject(mistakeManager)
                .environmentObject(articleManager)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .environmentObject(userProfile)
                .environmentObject(quizManager)
                .environmentObject(mistakeManager)
                .environmentObject(articleManager)
        }
        .accentColor(.blue)
    }
}

#Preview {
    AppNavigationView()
        .environmentObject(UserProfile())
        .environmentObject(APIKeyManager())
        .environmentObject(QuizManager())
        .environmentObject(MistakeManager())
        .environmentObject(ArticleManager())
} 