//
//  GlobalLoadingOverlay.swift
//  aielearn
//
//  Enhanced Global Loading Overlay with Modern Design System
//

import SwiftUI

struct GlobalLoadingOverlay: View {
    @StateObject private var loadingManager = LoadingStateManager.shared
    
    var body: some View {
        ZStack {
            // Active loading states
            if let currentLoading = loadingManager.currentPrimaryLoading {
                ModernStateOverlay(state: currentLoading)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
            }
            
            // Completed states (success/error notifications)
            VStack {
                Spacer()
                ForEach(loadingManager.completedStates) { state in
                    if state.isCompleted {
                        CompletionToast(state: state)
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .animation(DesignSystem.Animations.Loading.stateChange, value: loadingManager.currentPrimaryLoading?.id)
        .animation(DesignSystem.Animations.Loading.stateChange, value: loadingManager.completedStates.count)
    }
}

// MARK: - Completion Toast for Success/Error States

struct CompletionToast: View {
    let state: LoadingState
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            statusIcon
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(statusTitle)
                    .font(DesignSystem.Typography.Loading.statusTitle)
                    .foregroundColor(.primary)
                
                if let message = statusMessage {
                    Text(message)
                        .font(DesignSystem.Typography.Loading.statusMessage)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if case .success = state.status {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.success)
                    .font(.title2)
            }
        }
        .padding(DesignSystem.Spacing.Loading.compactPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.Loading.compact, style: .continuous)
                .fill(DesignSystem.Materials.Loading.container)
                .shadow(
                    color: DesignSystem.Shadows.Loading.floating,
                    radius: DesignSystem.Shadows.Loading.floatingRadius,
                    x: DesignSystem.Shadows.Loading.floatingOffset.width,
                    y: DesignSystem.Shadows.Loading.floatingOffset.height
                )
        )
        .onAppear {
            // Auto-dismiss after showing
            if case .success = state.status {
                LoadingStateManager.shared.triggerHapticFeedback(.success)
            } else if case .error = state.status {
                LoadingStateManager.shared.triggerHapticFeedback(.error)
            }
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch state.status {
        case .success:
            ModernLoadingIndicator.inlineRipple(
                size: 20,
                color: DesignSystem.Colors.success
            )
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DesignSystem.Colors.error)
                .font(.title3)
        case .cancelled:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(DesignSystem.Colors.secondary)
                .font(.title3)
        default:
            EmptyView()
        }
    }
    
    private var statusTitle: String {
        switch state.status {
        case .success:
            return "Success"
        case .error:
            return "Error"
        case .cancelled:
            return "Cancelled"
        default:
            return ""
        }
    }
    
    private var statusMessage: String? {
        switch state.status {
        case .success(let message):
            return message ?? "\(state.context.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) completed successfully"
        case .error(let message):
            return message
        case .cancelled:
            return "Operation was cancelled"
        default:
            return nil
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VStack {
            Text("Main Content")
                .font(.title)
            Text("This content is behind the loading overlay")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        
        GlobalLoadingOverlay()
    }
    .onAppear {
        // Demo the loading states
        let manager = LoadingStateManager.shared
        
        // Start a quiz generation
        let id = manager.startLoading(.quizGeneration, message: "Generating your personalized quiz...")
        
        // Simulate progress updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            manager.updateProgress(id, progress: 0.3, message: "Analyzing your learning patterns...")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            manager.updateProgress(id, progress: 0.7, message: "Creating questions...")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            manager.completeLoading(id, success: true, message: "Quiz ready!")
        }
    }
} 