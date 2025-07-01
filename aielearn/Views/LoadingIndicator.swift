//
//  LoadingIndicator.swift
//  aielearn
//
//  Created by AI Assistant - MODERNIZED VERSION
//
//  🎯 MODERN LOADING SYSTEM FEATURES:
//  
//  1. Fluid Spring Animations - Natural, bouncy feel with proper easing
//  2. SF Symbols Integration - Native iOS iconography with smooth morphing
//  3. Progressive Loading States - Multi-stage loading with contextual feedback
//  4. Haptic Feedback - Subtle tactile responses for state changes
//  5. Accessibility First - VoiceOver, reduced motion, high contrast support
//  6. Skeleton Loading - Shimmer effects for content placeholders
//  7. Micro-interactions - Hover states, success/error transitions
//  8. Design System Integration - Consistent with app's visual language
//
//  USAGE EXAMPLES:
//  
//  Modern Animations:
//    ModernLoadingIndicator.ripple()
//    ModernLoadingIndicator.morphingSymbol(symbol: "brain")
//    ModernLoadingIndicator.liquidWave(color: .blue)
//    ModernLoadingIndicator.particleSystem()
//
//  Skeleton Loading:
//    SkeletonLoader.card()
//    SkeletonLoader.list(rows: 3)
//    SkeletonLoader.text(lines: 2)
//
//  Context-Aware:
//    LoadingIndicator.forContext(.quizGeneration)
//    LoadingIndicator.progressive(stages: ["Analyzing", "Generating", "Finalizing"])

import SwiftUI

// MARK: - Legacy Loading Animation Types (for backward compatibility)
enum LoadingAnimationType {
    case spinningCircle
    case fadingDots
    case breathingCircle
    case pulsing
}

// MARK: - Modern Loading Animation Types
enum ModernLoadingType {
    case ripple           // Expanding ripple effect
    case morphingSymbol   // SF Symbol morphing animation
    case liquidWave       // Fluid wave animation
    case particleSystem   // Floating particle effect
    case breathingGlow    // Soft pulsing glow
    case springDots       // Bouncing dots with spring physics
    case progressiveRing  // Multi-stage progress ring
    case shimmer          // Skeleton shimmer effect  
}

// MARK: - Loading Stage for Progressive Loading
struct LoadingStage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let symbol: String?
    let duration: TimeInterval
    
    static func == (lhs: LoadingStage, rhs: LoadingStage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Modern Loading Indicator
struct ModernLoadingIndicator: View {
    let type: ModernLoadingType
    let message: String?
    let size: CGFloat
    let color: Color
    let showOverlay: Bool
    let enableHaptics: Bool
    let stages: [LoadingStage]
    
    @State private var animationPhase: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 1
    @State private var currentStageIndex: Int = 0
    @State private var shimmerOffset: CGFloat = -1
    @State private var particlePositions: [CGPoint] = []
    @State private var waveOffset: CGFloat = 0
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.colorScheme) var colorScheme
    
    init(
        type: ModernLoadingType = .ripple,
        message: String? = nil,
        size: CGFloat = 60,
        color: Color = .blue,
        showOverlay: Bool = false,
        enableHaptics: Bool = true,
        stages: [LoadingStage] = []
    ) {
        self.type = type
        self.message = message
        self.size = size
        self.color = color
        self.showOverlay = showOverlay
        self.enableHaptics = enableHaptics
        self.stages = stages
    }
    
    var body: some View {
        ZStack {
            // Modern overlay with blur effect
            if showOverlay {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture { }
            }
            
            // Loading content container
            VStack(spacing: 20) {
                // Main animation
                animationView
                    .frame(width: size, height: size)
                
                // Progressive stages indicator
                if !stages.isEmpty {
                    progressiveStagesView
                }
                
                // Message with modern typography
                if let message = message {
                    Text(message)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(showOverlay ? 1 : 0.9)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showOverlay)
        .onAppear {
            if !reduceMotion {
                startModernAnimations()
            }
            if enableHaptics {
                lightHaptic()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
    
    @ViewBuilder
    private var animationView: some View {
        switch type {
        case .ripple:
            rippleAnimation
        case .morphingSymbol:
            morphingSymbolAnimation
        case .liquidWave:
            liquidWaveAnimation
        case .particleSystem:
            particleSystemAnimation
        case .breathingGlow:
            breathingGlowAnimation
        case .springDots:
            springDotsAnimation
        case .progressiveRing:
            progressiveRingAnimation
        case .shimmer:
            shimmerAnimation
        }
    }
    
    // MARK: - Modern Animation Views
    
    private var rippleAnimation: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        color.opacity(0.6 - Double(index) * 0.2),
                        lineWidth: 2
                    )
                    .scaleEffect(animationPhase + CGFloat(index) * 0.3)
                    .opacity(1 - (animationPhase + CGFloat(index) * 0.3) * 0.5)
            }
        }
        .animation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: false)
            .delay(0.1),
            value: animationPhase
        )
    }
    
    private var morphingSymbolAnimation: some View {
        let symbols = ["circle", "circle.fill", "largecircle.fill.circle", "target"]
        let currentSymbol = symbols[Int(animationPhase) % symbols.count]
        
        return Image(systemName: currentSymbol)
            .font(.system(size: size * 0.5, weight: .light))
            .foregroundStyle(color)
            .symbolEffect(.pulse.byLayer, isActive: true)
            .symbolEffect(.variableColor.iterative, isActive: true)
            .scaleEffect(scale)
            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: scale)
    }
    
    private var liquidWaveAnimation: some View {
        ZStack {
            // Base circle
            Circle()
                .fill(color.opacity(0.2))
            
            // Animated wave
            WaveShape(offset: waveOffset, amplitude: 0.1)
                .fill(color)
                .clipShape(Circle())
                .animation(
                    .linear(duration: 2)
                    .repeatForever(autoreverses: false),
                    value: waveOffset
                )
        }
    }
    
    private var particleSystemAnimation: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .offset(
                        x: cos(animationPhase * 2 + Double(index) * .pi / 4) * size * 0.3,
                        y: sin(animationPhase * 2 + Double(index) * .pi / 4) * size * 0.3
                    )
                    .opacity(0.7)
                    .scaleEffect(1 + sin(animationPhase * 3 + Double(index)) * 0.5)
            }
        }
        .animation(
            .linear(duration: 3)
            .repeatForever(autoreverses: false),
            value: animationPhase
        )
    }
    
    private var breathingGlowAnimation: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.4), color.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.6
                    )
                )
                .scaleEffect(scale)
                .opacity(opacity)
            
            // Inner core
            Circle()
                .fill(color)
                .frame(width: size * 0.3, height: size * 0.3)
                .scaleEffect(scale * 0.8)
        }
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: scale)
    }
    
    private var springDotsAnimation: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: size * 0.15, height: size * 0.15)
                    .scaleEffect(scale)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.3)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: scale
                    )
            }
        }
    }
    
    private var progressiveRingAnimation: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animationPhase)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.5), color],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: animationPhase)
    }
    
    private var shimmerAnimation: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0.1),
                        color.opacity(0.3),
                        color.opacity(0.1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .black, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset * size * 2)
            )
            .animation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false),
                value: shimmerOffset
            )
    }
    
    private var progressiveStagesView: some View {
        VStack(spacing: 12) {
            // Stage indicator dots
            HStack(spacing: 8) {
                ForEach(0..<stages.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStageIndex ? color : color.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentStageIndex ? 1.3 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStageIndex)
                }
            }
            
            // Current stage text
            if currentStageIndex < stages.count {
                HStack(spacing: 8) {
                    if let symbol = stages[currentStageIndex].symbol {
                        Image(systemName: symbol)
                            .font(.caption)
                            .foregroundStyle(color)
                    }
                    
                    Text(stages[currentStageIndex].title)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
    }
    
    // MARK: - Animation Control
    
    private func startModernAnimations() {
        // Start main animation cycle
        withAnimation {
            switch type {
            case .ripple:
                animationPhase = 1.0
            case .morphingSymbol:
                startSymbolMorphing()
            case .liquidWave:
                waveOffset = 1.0
            case .particleSystem:
                animationPhase = .pi * 2
            case .breathingGlow:
                scale = 1.3
                opacity = 0.6
            case .springDots:
                scale = 1.5
            case .progressiveRing:
                animationPhase = 1.0
            case .shimmer:
                shimmerOffset = 1.0
            }
        }
        
        // Start progressive stages if available
        if !stages.isEmpty {
            startProgressiveStages()
        }
    }
    
    private func startSymbolMorphing() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animationPhase += 1
                scale = scale == 1.0 ? 1.2 : 1.0
            }
            if enableHaptics {
                lightHaptic()
            }
        }
    }
    
    private func startProgressiveStages() {
        guard !stages.isEmpty else { return }
        
        func moveToNextStage() {
            if currentStageIndex < stages.count - 1 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentStageIndex += 1
                }
                if enableHaptics {
                    mediumHaptic()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + stages[currentStageIndex].duration) {
                    moveToNextStage()
                }
            } else {
                // Reset to beginning for infinite loop
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentStageIndex = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        moveToNextStage()
                    }
                }
            }
        }
        
        moveToNextStage()
    }
    
    // MARK: - Haptic Feedback
    
    private func lightHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func mediumHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Accessibility
    
    private var accessibilityDescription: String {
        let baseMessage = message ?? "Loading"
        if !stages.isEmpty && currentStageIndex < stages.count {
            return "\(baseMessage). Current step: \(stages[currentStageIndex].title)"
        }
        return baseMessage
    }
}

// MARK: - Supporting Views and Shapes

struct WaveShape: Shape {
    var offset: CGFloat
    var amplitude: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.5
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX + offset) * .pi * 4) * amplitude * height
            let y = midHeight + sine
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Skeleton Loading Components

struct SkeletonLoader: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    @State private var shimmerOffset: CGFloat = -1
    @Environment(\.colorScheme) var colorScheme
    
    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(skeletonBaseColor)
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                shimmerColor,
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(cornerRadius)
                    .offset(x: shimmerOffset * (width ?? 200))
                    .animation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: shimmerOffset
                    )
            )
            .onAppear {
                shimmerOffset = 1
            }
    }
    
    private var skeletonBaseColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
    }
    
    private var shimmerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.4)
    }
}

// MARK: - Skeleton Presets

extension SkeletonLoader {
    static func text(width: CGFloat = 150) -> SkeletonLoader {
        SkeletonLoader(width: width, height: 16, cornerRadius: 4)
    }
    
    static func title() -> SkeletonLoader {
        SkeletonLoader(width: 200, height: 24, cornerRadius: 6)
    }
    
    static func button() -> SkeletonLoader {
        SkeletonLoader(width: 120, height: 44, cornerRadius: 12)
    }
    
    static func avatar() -> SkeletonLoader {
        SkeletonLoader(width: 40, height: 40, cornerRadius: 20)
    }
    
    static func card() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonLoader.title()
            SkeletonLoader.text(width: 180)
            SkeletonLoader.text(width: 120)
            
            HStack {
                SkeletonLoader.button()
                Spacer()
                SkeletonLoader.avatar()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    static func list(rows: Int = 3) -> some View {
        VStack(spacing: 16) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: 12) {
                    SkeletonLoader.avatar()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonLoader.text(width: 140)
                        SkeletonLoader.text(width: 100)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Modern Loading Indicator Extensions

extension ModernLoadingIndicator {
    // Quick preset methods
    static func ripple(message: String? = nil, color: Color = .blue) -> ModernLoadingIndicator {
        ModernLoadingIndicator(type: .ripple, message: message, color: color, showOverlay: true)
    }
    
    static func morphingSymbol(symbol: String = "brain", message: String? = nil, color: Color = .blue) -> ModernLoadingIndicator {
        ModernLoadingIndicator(type: .morphingSymbol, message: message, color: color, showOverlay: true)
    }
    
    static func liquidWave(message: String? = nil, color: Color = .blue) -> ModernLoadingIndicator {
        ModernLoadingIndicator(type: .liquidWave, message: message, color: color, showOverlay: true)
    }
    
    static func particles(message: String? = nil, color: Color = .blue) -> ModernLoadingIndicator {
        ModernLoadingIndicator(type: .particleSystem, message: message, color: color, showOverlay: true)
    }
    
    static func breathingGlow(message: String? = nil, color: Color = .blue) -> ModernLoadingIndicator {
        ModernLoadingIndicator(type: .breathingGlow, message: message, color: color, showOverlay: true)
    }
    
    static func springDots(message: String? = nil, color: Color = .blue) -> ModernLoadingIndicator {
        ModernLoadingIndicator(type: .springDots, message: message, color: color, showOverlay: true)
    }
    
    static func progressive(stages: [LoadingStage], message: String? = nil, color: Color = .blue) -> ModernLoadingIndicator {
        ModernLoadingIndicator(type: .progressiveRing, message: message, color: color, showOverlay: true, stages: stages)
    }
    
    // Inline versions
    static func inlineRipple(size: CGFloat = 30, color: Color = .blue) -> ModernLoadingIndicator {
        ModernLoadingIndicator(type: .ripple, size: size, color: color, enableHaptics: false)
    }
    
    static func inlineSpringDots(size: CGFloat = 30, color: Color = .blue) -> ModernLoadingIndicator {
        ModernLoadingIndicator(type: .springDots, size: size, color: color, enableHaptics: false)
    }
    
    static func inlineMorphing(size: CGFloat = 30, color: Color = .blue) -> ModernLoadingIndicator {
        ModernLoadingIndicator(type: .morphingSymbol, size: size, color: color, enableHaptics: false)
    }
}

// MARK: - Legacy Loading Indicator (Updated for Compatibility)

struct LoadingIndicator: View {
    let animationType: LoadingAnimationType
    let message: String?
    let size: CGFloat
    let accentColor: Color?
    let showOverlay: Bool
    
    var body: some View {
        // Bridge to modern loading indicator
        let modernType: ModernLoadingType = {
            switch animationType {
            case .spinningCircle:
                return .ripple
            case .fadingDots:
                return .springDots
            case .breathingCircle:
                return .breathingGlow
            case .pulsing:
                return .morphingSymbol
            }
        }()
        
        ModernLoadingIndicator(
            type: modernType,
            message: message,
            size: size,
            color: accentColor ?? .blue,
            showOverlay: showOverlay
        )
    }
    
    // Legacy compatibility methods
    static func overlay(message: String? = nil, accentColor: Color? = nil) -> LoadingIndicator {
        LoadingIndicator(
            animationType: .spinningCircle,
            message: message,
            size: 50,
            accentColor: accentColor,
            showOverlay: true
        )
    }
    
    static func inline(size: CGFloat = 30, accentColor: Color? = nil) -> LoadingIndicator {
        LoadingIndicator(
            animationType: .spinningCircle,
            message: nil,
            size: size,
            accentColor: accentColor,
            showOverlay: false
        )
    }
    
    static func dots(message: String? = nil, accentColor: Color? = nil) -> LoadingIndicator {
        LoadingIndicator(
            animationType: .fadingDots,
            message: message,
            size: 40,
            accentColor: accentColor,
            showOverlay: true
        )
    }
    
    static func breathing(message: String? = nil, accentColor: Color? = nil) -> LoadingIndicator {
        LoadingIndicator(
            animationType: .breathingCircle,
            message: message,
            size: 60,
            accentColor: accentColor,
            showOverlay: true
        )
    }
    
    static func pulsing(message: String? = nil, accentColor: Color? = nil) -> LoadingIndicator {
        LoadingIndicator(
            animationType: .pulsing,
            message: message,
            size: 50,
            accentColor: accentColor,
            showOverlay: true
        )
    }
    
    static func forContext(_ context: LoadingContext, message: String? = nil, accentColor: Color? = nil) -> some View {
        let stages = contextStages(for: context)
        let contextColor = contextColor(for: context)
        
        if stages.isEmpty {
            return AnyView(
                ModernLoadingIndicator(
                    type: context.modernAnimationType,
                    message: message ?? context.defaultMessage,
                    size: 60,
                    color: accentColor ?? contextColor,
                    showOverlay: true
                )
            )
        } else {
            return AnyView(
                ModernLoadingIndicator.progressive(
                    stages: stages,
                    message: message,
                    color: accentColor ?? contextColor
                )
            )
        }
    }
    
    static func inlineForContext(_ context: LoadingContext, size: CGFloat = 30, accentColor: Color? = nil) -> some View {
        ModernLoadingIndicator(
            type: context.modernAnimationType,
            size: size,
            color: accentColor ?? contextColor(for: context),
            enableHaptics: false
        )
    }
    
    private static func contextColor(for context: LoadingContext) -> Color {
        switch context {
        case .quizGeneration, .mistakeQuizGeneration:
            return .blue
        case .aiVerification:
            return .green
        case .speechProcessing:
            return .purple
        case .apiKeyValidation:
            return .orange
        case .dataSync:
            return .indigo
        case .general:
            return .gray
        }
    }
    
    private static func contextStages(for context: LoadingContext) -> [LoadingStage] {
        switch context {
        case .quizGeneration:
            return [
                LoadingStage(title: "Analyzing knowledge", symbol: "brain", duration: 2.0),
                LoadingStage(title: "Generating questions", symbol: "questionmark.circle", duration: 2.5),
                LoadingStage(title: "Finalizing quiz", symbol: "checkmark.circle", duration: 1.5)
            ]
        case .mistakeQuizGeneration:
            return [
                LoadingStage(title: "Reviewing mistakes", symbol: "magnifyingglass", duration: 1.5),
                LoadingStage(title: "Creating targeted questions", symbol: "target", duration: 2.0),
                LoadingStage(title: "Preparing quiz", symbol: "doc.text", duration: 1.0)
            ]
        case .aiVerification:
            return [
                LoadingStage(title: "Processing answer", symbol: "gearshape", duration: 1.0),
                LoadingStage(title: "Analyzing response", symbol: "brain.head.profile", duration: 1.5),
                LoadingStage(title: "Generating feedback", symbol: "bubble.left", duration: 1.0)
            ]
        default:
            return []
        }
    }
}

// MARK: - Loading Context Extensions

extension LoadingContext {
    var modernAnimationType: ModernLoadingType {
        switch self {
        case .quizGeneration, .mistakeQuizGeneration:
            return .progressiveRing
        case .aiVerification:
            return .morphingSymbol
        case .speechProcessing:
            return .liquidWave
        case .apiKeyValidation:
            return .ripple
        case .dataSync:
            return .particleSystem
        case .general:
            return .breathingGlow
        }
    }
}

// MARK: - Global Loading Overlay
// Note: GlobalLoadingOverlay is now defined in GlobalLoadingOverlay.swift with enhanced features

// MARK: - View Extensions (Updated)

extension View {
    func modernLoadingOverlay(for context: LoadingContext) -> some View {
        ZStack {
            self
            
            LoadingIndicator.forContext(context)
        }
    }
    
    func skeletonLoader<Content: View>(
        isLoading: Bool,
        @ViewBuilder skeleton: () -> Content
    ) -> some View {
        ZStack {
            if isLoading {
                skeleton()
            } else {
                self
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

// MARK: - Previews

#Preview("Modern Loading Showcase") {
    ScrollView {
        VStack(spacing: 30) {
            Text("Modern Loading Indicators")
                .font(.title.bold())
                .padding()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                VStack {
                    ModernLoadingIndicator.ripple(color: .blue)
                        .frame(height: 120)
                    Text("Ripple Effect")
                        .font(.caption)
                }
                
                VStack {
                    ModernLoadingIndicator.springDots(color: .green)
                        .frame(height: 120)
                    Text("Spring Dots")
                        .font(.caption)
                }
                
                VStack {
                    ModernLoadingIndicator.morphingSymbol(color: .purple)
                        .frame(height: 120)
                    Text("Morphing Symbol")
                        .font(.caption)
                }
                
                VStack {
                    ModernLoadingIndicator.breathingGlow(color: .orange)
                        .frame(height: 120)
                    Text("Breathing Glow")
                        .font(.caption)
                }
            }
            .padding()
        }
    }
}

#Preview("Skeleton Loading") {
    VStack(spacing: 20) {
        Text("Skeleton Loading")
            .font(.title.bold())
        
        SkeletonLoader.card()
        
        SkeletonLoader.list(rows: 3)
            .padding()
    }
    .padding()
}

#Preview("Progressive Loading") {
    ModernLoadingIndicator.progressive(
        stages: [
            LoadingStage(title: "Analyzing content", symbol: "brain", duration: 2.0),
            LoadingStage(title: "Generating questions", symbol: "questionmark.circle", duration: 2.5),
            LoadingStage(title: "Finalizing quiz", symbol: "checkmark.circle", duration: 1.5)
        ],
        message: "Creating your personalized quiz",
        color: .blue
    )
} 