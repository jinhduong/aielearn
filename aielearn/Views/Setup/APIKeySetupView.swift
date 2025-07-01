//
//  APIKeySetupView.swift
//  aielearn
//
//  Created by AI Assistant
//

import SwiftUI

struct APIKeySetupView: View {
    @EnvironmentObject var apiKeyManager: APIKeyManager
    @State private var apiKey: String = ""
    @State private var showingHelp = false
    @State private var isTestingKey = false
    @State private var testResult: TestResult?
    @StateObject private var loadingManager = LoadingStateManager.shared
    
    enum TestResult {
        case success
        case failure(String)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "key.horizontal")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(spacing: 8) {
                            Text("OpenAI API Setup")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Enter your OpenAI API key to unlock AI-powered quiz generation and smart answer verification.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // API Key Input
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("API Key")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button("Need Help?") {
                                showingHelp = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            SecureField("sk-...", text: $apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(.body, design: .monospaced))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            Text("Your API key is stored securely on your device")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Test Result
                    if let result = testResult {
                        TestResultView(result: result)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        DSButton(
                            "Validate & Continue",
                            icon: "checkmark.circle.fill",
                            style: .primary,
                            isLoading: loadingManager.isLoading(.apiKeyValidation)
                        ) {
                            validateAndContinue()
                        }
                        .disabled(apiKey.isEmpty || loadingManager.isLoading(.apiKeyValidation))
                        
                        Button("Skip (Use Demo Mode)") {
                            skipSetup()
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingHelp) {
            APIKeyHelpView()
        }
        .onAppear {
            apiKey = apiKeyManager.apiKey
        }
    }
    
    private func testAPIKey() {
        guard !apiKey.isEmpty else { return }
        
        isTestingKey = true
        testResult = nil
        
        Task {
            do {
                let service = OpenAIService(apiKey: apiKey)
                let testRequest = AIQuizRequest(
                    proficiencyLevel: .beginner,
                    topic: .dailyConversation,
                    focus: .vocabulary,
                    questionCount: 1
                )
                
                _ = try await service.generateQuiz(request: testRequest)
                
                await MainActor.run {
                    testResult = .success
                    isTestingKey = false
                }
            } catch {
                await MainActor.run {
                    testResult = .failure(error.localizedDescription)
                    isTestingKey = false
                }
            }
        }
    }
    
    private func saveAPIKey() {
        apiKeyManager.saveAPIKey(apiKey)
    }
    
    private func skipSetup() {
        // Save "demo" key to activate test mode
        apiKeyManager.saveAPIKey("demo-mode")
    }
    
    private func validateAndContinue() {
        testAPIKey()
    }
}

struct TestResultView: View {
    let result: APIKeySetupView.TestResult
    
    var body: some View {
        HStack {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isSuccess ? .green : .red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isSuccess ? "API Key Valid!" : "Test Failed")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSuccess ? .green : .red)
                
                if case .failure(let error) = result {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSuccess ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSuccess ? Color.green : Color.red, lineWidth: 1)
                )
        )
    }
    
    private var isSuccess: Bool {
        if case .success = result {
            return true
        }
        return false
    }
}

struct APIKeyHelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How to Get Your OpenAI API Key")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HelpStep(
                                number: "1",
                                title: "Visit OpenAI Platform",
                                description: "Go to platform.openai.com and sign up or log in to your account."
                            )
                            
                            HelpStep(
                                number: "2",
                                title: "Navigate to API Keys",
                                description: "Click on your profile in the top right, then select 'View API keys' from the dropdown menu."
                            )
                            
                            HelpStep(
                                number: "3",
                                title: "Create New Key",
                                description: "Click 'Create new secret key' and give it a name like 'AIELearn App'."
                            )
                            
                            HelpStep(
                                number: "4",
                                title: "Copy Your Key",
                                description: "Copy the generated key (starts with 'sk-') and paste it into the app. Keep it secure!"
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Important Notes")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InfoPoint(
                                icon: "lock.fill",
                                text: "Your API key is stored securely on your device only"
                            )
                            
                            InfoPoint(
                                icon: "dollarsign.circle",
                                text: "OpenAI charges per API call. Quiz generation costs ~$0.01-0.02 per quiz"
                            )
                            
                            InfoPoint(
                                icon: "wifi.slash",
                                text: "AI features require internet connection"
                            )
                            
                            InfoPoint(
                                icon: "exclamationmark.triangle",
                                text: "Never share your API key with others"
                            )
                        }
                    }
                    
                    Button(action: {
                        if let url = URL(string: "https://platform.openai.com/api-keys") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "link")
                            Text("Open OpenAI Platform")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("API Key Help")
            .navigationBarTitleDisplayMode(.inline)
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

struct HelpStep: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(Color.blue)
                .frame(width: 24, height: 24)
                .overlay(
                    Text(number)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct InfoPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    APIKeySetupView()
        .environmentObject(APIKeyManager())
} 