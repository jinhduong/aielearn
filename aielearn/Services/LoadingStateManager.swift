//
//  LoadingStateManager.swift
//  aielearn
//
//  Created by AI Assistant - Enhanced with Modern Loading States
//

import Foundation
import SwiftUI
import Combine

// MARK: - Loading State Types
enum LoadingContext: String, CaseIterable {
    case quizGeneration = "quiz_generation"
    case mistakeQuizGeneration = "mistake_quiz_generation"
    case aiVerification = "ai_verification"
    case speechProcessing = "speech_processing"
    case apiKeyValidation = "api_key_validation"
    case dataSync = "data_sync"
    case general = "general"
    
    var defaultMessage: String {
        switch self {
        case .quizGeneration:
            return "Generating your personalized quiz..."
        case .mistakeQuizGeneration:
            return "Creating quiz from your mistakes..."
        case .aiVerification:
            return "Verifying your answer..."
        case .speechProcessing:
            return "Processing speech..."
        case .apiKeyValidation:
            return "Validating API key..."
        case .dataSync:
            return "Syncing data..."
        case .general:
            return "Loading..."
        }
    }
    
    var animationType: LoadingAnimationType {
        switch self {
        case .quizGeneration, .mistakeQuizGeneration:
            return .fadingDots
        case .aiVerification:
            return .pulsing
        case .speechProcessing:
            return .breathingCircle
        case .apiKeyValidation, .dataSync:
            return .spinningCircle
        case .general:
            return .spinningCircle
        }
    }
}

// MARK: - Modern Loading State Status
enum LoadingStatus: Equatable {
    case loading
    case progress(Double) // 0.0 to 1.0
    case success(String?) // Optional success message
    case error(String) // Error message
    case cancelled
    
    var isActive: Bool {
        switch self {
        case .loading, .progress:
            return true
        case .success, .error, .cancelled:
            return false
        }
    }
    
    var isCompleted: Bool {
        switch self {
        case .success, .error, .cancelled:
            return true
        case .loading, .progress:
            return false
        }
    }
}

// MARK: - Loading State Model
struct LoadingState: Identifiable {
    let id = UUID()
    let context: LoadingContext
    var message: String?
    var status: LoadingStatus
    let startTime: Date
    var lastUpdated: Date
    let canCancel: Bool
    let onCancel: (() -> Void)?
    let autoHideOnSuccess: Bool
    let successDuration: TimeInterval
    
    init(
        context: LoadingContext,
        message: String? = nil,
        status: LoadingStatus = .loading,
        canCancel: Bool = false,
        onCancel: (() -> Void)? = nil,
        autoHideOnSuccess: Bool = true,
        successDuration: TimeInterval = 2.0
    ) {
        self.context = context
        self.message = message ?? context.defaultMessage
        self.status = status
        self.startTime = Date()
        self.lastUpdated = Date()
        self.canCancel = canCancel
        self.onCancel = onCancel
        self.autoHideOnSuccess = autoHideOnSuccess
        self.successDuration = successDuration
    }
    
    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        status.isActive
    }
    
    var isCompleted: Bool {
        status.isCompleted
    }
    
    mutating func updateStatus(_ newStatus: LoadingStatus, message: String? = nil) {
        self.status = newStatus
        if let message = message {
            self.message = message
        }
        self.lastUpdated = Date()
    }
}

// MARK: - Loading Progress
struct LoadingProgress {
    let current: Int
    let total: Int
    let currentTask: String?
    
    var percentage: Double {
        guard total > 0 else { return 0.0 }
        return Double(current) / Double(total)
    }
    
    var isComplete: Bool {
        current >= total
    }
}

// MARK: - Loading State Manager
@MainActor
class LoadingStateManager: ObservableObject {
    static let shared = LoadingStateManager()
    
    @Published private(set) var activeLoadingStates: [LoadingState] = []
    @Published private(set) var currentPrimaryLoading: LoadingState?
    @Published private(set) var completedStates: [LoadingState] = []
    
    private var loadingStateSubscription: AnyCancellable?
    private var autoHideTimers: [UUID: Timer] = [:]
    
    private init() {
        setupPrimaryLoadingSubscription()
    }
    
    private func setupPrimaryLoadingSubscription() {
        loadingStateSubscription = $activeLoadingStates
            .map { states in
                // Priority: active states first, then by context priority, then by duration
                let activeStates = states.filter { $0.isActive }
                return activeStates.sorted { state1, state2 in
                    let priority1 = self.contextPriority(state1.context)
                    let priority2 = self.contextPriority(state2.context)
                    
                    if priority1 != priority2 {
                        return priority1 > priority2
                    }
                    return state1.duration > state2.duration
                }.first
            }
            .assign(to: \.currentPrimaryLoading, on: self)
    }
    
    // MARK: - Public Interface
    
    /// Start a loading operation with modern state support
    @discardableResult
    func startLoading(
        _ context: LoadingContext,
        message: String? = nil,
        canCancel: Bool = false,
        autoHideOnSuccess: Bool = true,
        successDuration: TimeInterval = 2.0,
        onCancel: (() -> Void)? = nil
    ) -> UUID {
        let loadingState = LoadingState(
            context: context,
            message: message,
            canCancel: canCancel,
            onCancel: onCancel,
            autoHideOnSuccess: autoHideOnSuccess,
            successDuration: successDuration
        )
        
        // Remove any existing states for this context
        stopLoading(context: context)
        
        activeLoadingStates.append(loadingState)
        triggerHapticFeedback(.light)
        print("🔄 Started loading: \(context.rawValue) - \(loadingState.message ?? "No message")")
        
        return loadingState.id
    }
    
    /// Update loading progress
    func updateProgress(_ id: UUID, progress: Double, message: String? = nil) {
        guard let index = activeLoadingStates.firstIndex(where: { $0.id == id }) else { return }
        
        let clampedProgress = max(0.0, min(1.0, progress))
        activeLoadingStates[index].updateStatus(.progress(clampedProgress), message: message)
        
        // Auto-complete when progress reaches 1.0
        if clampedProgress >= 1.0 {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                completeLoading(id, success: true)
            }
        }
        
        print("📊 Progress updated for \(activeLoadingStates[index].context.rawValue): \(Int(clampedProgress * 100))%")
    }
    
    /// Complete loading with success or error
    func completeLoading(_ id: UUID, success: Bool, message: String? = nil) {
        guard let index = activeLoadingStates.firstIndex(where: { $0.id == id }) else { return }
        
        let context = activeLoadingStates[index].context
        let newStatus: LoadingStatus = success ? .success(message) : .error(message ?? "An error occurred")
        
        activeLoadingStates[index].updateStatus(newStatus, message: message)
        
        // Trigger appropriate haptic feedback
        triggerHapticFeedback(success ? .success : .error)
        
        print(success ? "✅ Completed successfully: \(context.rawValue)" : "❌ Failed: \(context.rawValue)")
        
        // Move to completed states and set up auto-hide if needed
        let completedState = activeLoadingStates[index]
        completedStates.append(completedState)
        
        if success && completedState.autoHideOnSuccess {
            setupAutoHide(for: id, duration: completedState.successDuration)
        } else if !success {
            // Auto-hide errors after a longer duration
            setupAutoHide(for: id, duration: 4.0)
        }
    }
    
    /// Cancel loading operation
    func cancelLoading(_ id: UUID) {
        guard let index = activeLoadingStates.firstIndex(where: { $0.id == id }) else { return }
        
        let state = activeLoadingStates[index]
        
        // Execute cancel callback if provided
        state.onCancel?()
        
        // Update status to cancelled
        activeLoadingStates[index].updateStatus(.cancelled, message: "Cancelled")
        
        // Move to completed states
        completedStates.append(activeLoadingStates[index])
        activeLoadingStates.remove(at: index)
        
        triggerHapticFeedback(.warning)
        print("🚫 Cancelled loading: \(state.context.rawValue)")
        
        // Auto-hide cancelled states
        setupAutoHide(for: id, duration: 1.5)
    }
    
    /// Stop a loading operation by ID
    func stopLoading(_ id: UUID) {
        if let index = activeLoadingStates.firstIndex(where: { $0.id == id }) {
            let context = activeLoadingStates[index].context
            activeLoadingStates.remove(at: index)
            print("⏹️ Stopped loading: \(context.rawValue)")
        }
        
        // Cancel auto-hide timer if exists
        autoHideTimers[id]?.invalidate()
        autoHideTimers.removeValue(forKey: id)
    }
    
    /// Stop all loading operations for a specific context
    func stopLoading(context: LoadingContext) {
        let statesToRemove = activeLoadingStates.filter { $0.context == context }
        activeLoadingStates.removeAll { $0.context == context }
        
        // Cancel timers for removed states
        for state in statesToRemove {
            autoHideTimers[state.id]?.invalidate()
            autoHideTimers.removeValue(forKey: state.id)
        }
        
        if !statesToRemove.isEmpty {
            print("⏹️ Stopped all loading for context: \(context.rawValue)")
        }
    }
    
    /// Stop all loading operations
    func stopAllLoading() {
        let count = activeLoadingStates.count
        activeLoadingStates.removeAll()
        
        // Cancel all timers
        autoHideTimers.values.forEach { $0.invalidate() }
        autoHideTimers.removeAll()
        
        if count > 0 {
            print("🛑 Stopped all loading operations (\(count) active)")
        }
    }
    
    /// Check if a specific context is loading
    func isLoading(_ context: LoadingContext) -> Bool {
        return activeLoadingStates.contains { $0.context == context && $0.isActive }
    }
    
    /// Check if any loading is active
    var isAnyLoading: Bool {
        return activeLoadingStates.contains { $0.isActive }
    }
    
    /// Get loading state for a specific context
    func getLoadingState(for context: LoadingContext) -> LoadingState? {
        return activeLoadingStates.first { $0.context == context }
    }
    
    /// Get progress for a specific context
    func getProgress(for context: LoadingContext) -> Double? {
        guard let state = getLoadingState(for: context),
              case .progress(let progress) = state.status else {
            return nil
        }
        return progress
    }
    
    // MARK: - Convenience Methods with Modern State Support
    
    /// Execute an async operation with automatic loading management and progress tracking
    func withLoading<T>(
        _ context: LoadingContext,
        message: String? = nil,
        canCancel: Bool = false,
        progressTracking: Bool = false,
        operation: @escaping (_ updateProgress: @escaping (Double, String?) -> Void) async throws -> T
    ) async throws -> T {
        let loadingId = startLoading(context, message: message, canCancel: canCancel)
        
        let updateProgress: (Double, String?) -> Void = { [weak self] progress, progressMessage in
            Task { @MainActor in
                self?.updateProgress(loadingId, progress: progress, message: progressMessage)
            }
        }
        
        do {
            let result = try await operation(updateProgress)
            completeLoading(loadingId, success: true)
            return result
        } catch {
            completeLoading(loadingId, success: false, message: error.localizedDescription)
            throw error
        }
    }
    
    /// Execute an async operation with automatic loading management (MainActor)
    @MainActor
    func withLoadingMainActor<T>(
        _ context: LoadingContext,
        message: String? = nil,
        canCancel: Bool = false,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        let loadingId = startLoading(context, message: message, canCancel: canCancel)
        
        do {
            let result = try await operation()
            completeLoading(loadingId, success: true)
            return result
        } catch {
            completeLoading(loadingId, success: false, message: error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Private Helpers
    
    private func contextPriority(_ context: LoadingContext) -> Int {
        switch context {
        case .quizGeneration, .mistakeQuizGeneration: return 100
        case .aiVerification: return 90
        case .speechProcessing: return 80
        case .apiKeyValidation: return 70
        case .dataSync: return 60
        case .general: return 50
        }
    }
    
    private func setupAutoHide(for id: UUID, duration: TimeInterval) {
        // Cancel existing timer if any
        autoHideTimers[id]?.invalidate()
        
        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.hideCompletedState(id)
            }
        }
        
        autoHideTimers[id] = timer
    }
    
    private func hideCompletedState(_ id: UUID) {
        completedStates.removeAll { $0.id == id }
        autoHideTimers.removeValue(forKey: id)
    }
    
    public func triggerHapticFeedback(_ type: HapticFeedbackType) {
        switch type {
        case .light:
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        case .medium:
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        case .success:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        case .error:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        case .warning:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        }
    }
}

// MARK: - Haptic Feedback Types
public enum HapticFeedbackType {
    case light
    case medium
    case success
    case error
    case warning
}

// MARK: - SwiftUI Environment
extension EnvironmentValues {
    var loadingStateManager: LoadingStateManager {
        get { self[LoadingStateManagerKey.self] }
        set { self[LoadingStateManagerKey.self] = newValue }
    }
}

private struct LoadingStateManagerKey: EnvironmentKey {
    static let defaultValue = LoadingStateManager.shared
}

// MARK: - View Extensions for Modern Loading States

extension View {
    /// Add progress indicator overlay
    func progressOverlay(for context: LoadingContext, title: String? = nil) -> some View {
        ProgressOverlay(context: context, title: title) {
            self
        }
    }
}

// MARK: - Modern Loading Overlay Component

struct ModernLoadingOverlay<Content: View>: View {
    let context: LoadingContext
    let content: Content
    @StateObject private var loadingManager = LoadingStateManager.shared
    
    init(context: LoadingContext, @ViewBuilder content: () -> Content) {
        self.context = context
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
            
            if let state = loadingManager.getLoadingState(for: context) {
                ModernStateOverlay(state: state)
            }
        }
    }
}

// MARK: - Modern State Overlay

struct ModernStateOverlay: View {
    let state: LoadingState
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Backdrop
            Rectangle()
                .fill(DesignSystem.Materials.Loading.backdrop)
                .ignoresSafeArea()
            
            // State content
            VStack(spacing: DesignSystem.Spacing.Loading.animationSpacing) {
                stateIndicator
                
                if let message = state.message {
                    Text(message)
                        .font(DesignSystem.Typography.Loading.message)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
                
                // Cancel button if allowed
                if state.canCancel && state.isActive {
                    Button("Cancel") {
                        LoadingStateManager.shared.cancelLoading(state.id)
                    }
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.accent)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(DesignSystem.Materials.Loading.container)
                            .shadow(radius: 4)
                    )
                }
            }
            .padding(DesignSystem.Spacing.Loading.containerPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.Loading.container, style: .continuous)
                    .fill(DesignSystem.Materials.Loading.container)
                    .shadow(
                        color: DesignSystem.Shadows.Loading.overlay,
                        radius: DesignSystem.Shadows.Loading.overlayRadius,
                        x: DesignSystem.Shadows.Loading.overlayOffset.width,
                        y: DesignSystem.Shadows.Loading.overlayOffset.height
                    )
            )
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        ))
        .animation(DesignSystem.Animations.Loading.stateChange, value: state.status)
    }
    
    @ViewBuilder
    private var stateIndicator: some View {
        switch state.status {
        case .loading:
            ModernLoadingIndicator(
                type: state.context.modernAnimationType,
                size: 60,
                color: state.context.designSystemColor
            )
            
        case .progress(let progress):
            VStack(spacing: 16) {
                ModernLoadingIndicator(
                    type: .progressiveRing,
                    size: 60,
                    color: state.context.designSystemColor
                )
                
                DSProgressIndicator(
                    progress: progress,
                    title: "Progress",
                    color: state.context.designSystemColor
                )
                .frame(width: 200)
            }
            
        case .success(let successMessage):
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DesignSystem.Colors.success)
                    .symbolEffect(.bounce, value: true)
                
                if let successMessage = successMessage {
                    Text(successMessage)
                        .font(DesignSystem.Typography.Loading.statusMessage)
                        .foregroundStyle(.secondary)
                }
            }
            
        case .error(let errorMessage):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DesignSystem.Colors.error)
                    .symbolEffect(.bounce, value: true)
                
                Text(errorMessage)
                    .font(DesignSystem.Typography.Loading.statusMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
        case .cancelled:
            VStack(spacing: 16) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DesignSystem.Colors.secondary)
                    .symbolEffect(.bounce, value: true)
                
                Text("Cancelled")
                    .font(DesignSystem.Typography.Loading.statusMessage)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Progress Overlay Component

struct ProgressOverlay<Content: View>: View {
    let context: LoadingContext
    let title: String?
    let content: Content
    @StateObject private var loadingManager = LoadingStateManager.shared
    
    init(context: LoadingContext, title: String?, @ViewBuilder content: () -> Content) {
        self.context = context
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
            
            if let progress = loadingManager.getProgress(for: context) {
                VStack {
                    Spacer()
                    DSProgressIndicator(
                        progress: progress,
                        title: title,
                        color: context.designSystemColor
                    )
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(DesignSystem.Materials.Loading.overlay)
                    )
                    .padding()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
} 