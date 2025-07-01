//
//  aielearnApp.swift
//  aielearn
//
//  Created by Dinh Duong on 29/6/25.
//

import SwiftUI

@main
struct aielearnApp: App {
    @StateObject private var userProfile = UserProfile()
    @StateObject private var apiKeyManager = APIKeyManager()
    @StateObject private var quizManager = QuizManager()
    @StateObject private var mistakeManager = MistakeManager()
    @StateObject private var articleManager = ArticleManager()
    
    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .environmentObject(userProfile)
                .environmentObject(apiKeyManager)
                .environmentObject(quizManager)
                .environmentObject(mistakeManager)
                .environmentObject(articleManager)
        }
    }
}
