//
//  DesignSystem.swift
//  aielearn
//
//  Created by AI Assistant - Enhanced for Modern Loading System
//

import SwiftUI

// MARK: - Design System Constants

struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Single accent color as specified
        static let accent = Color(hex: "FF4B4B")
        
        // Greyscale neutrals
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let tertiary = Color(.systemGray3)
        static let quaternary = Color(.systemGray4)
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        
        // Semantic colors
        static let success = Color(.systemGreen)
        static let warning = Color(.systemOrange)
        static let error = Color(.systemRed)
        
        // Card stroke color (5% black)
        static let cardStroke = Color.black.opacity(0.05)
        
        // MARK: - Loading-Specific Colors
        struct Loading {
            // Context-based loading colors
            static let quiz = Color(.systemBlue)
            static let aiProcessing = Color(.systemGreen)
            static let speech = Color(.systemPurple)
            static let validation = Color(.systemOrange)
            static let sync = Color(.systemIndigo)
            static let general = Color(.systemGray)
            
            // Loading state colors
            static let progress = accent
            static let progressBackground = accent.opacity(0.2)
            
            // Skeleton loading colors
            static let skeletonBase = Color(.systemGray5)
            static let skeletonHighlight = Color(.systemGray4).opacity(0.6)
            
            // Modern gradient collections
            static let gradientBlue = LinearGradient(
                colors: [Color(.systemBlue), Color(.systemCyan)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            static let gradientPurple = LinearGradient(
                colors: [Color(.systemPurple), Color(.systemPink)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            static let gradientGreen = LinearGradient(
                colors: [Color(.systemGreen), Color(.systemTeal)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            static let gradientOrange = LinearGradient(
                colors: [Color(.systemOrange), Color(.systemRed)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Shimmer effect gradient
            static let shimmer = LinearGradient(
                colors: [
                    .clear,
                    Color.white.opacity(0.4),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            
            // Dark mode shimmer
            static let shimmerDark = LinearGradient(
                colors: [
                    .clear,
                    Color.white.opacity(0.1),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    // MARK: - Typography
    struct Typography {
        // Section headers - Title3 / semibold
        static let sectionHeader = Font.title3.weight(.semibold)
        
        // KPI numbers - Title / bold
        static let kpiNumber = Font.title.weight(.bold)
        
        // Captions - Subheadline / regular
        static let caption = Font.subheadline.weight(.regular)
        
        // Additional common styles
        static let bodyText = Font.body.weight(.regular)
        static let buttonText = Font.body.weight(.medium)
        
        // MARK: - Loading-Specific Typography
        struct Loading {
            // Loading messages
            static let message = Font.system(size: 16, weight: .medium, design: .rounded)
            static let secondaryMessage = Font.system(size: 14, weight: .regular, design: .rounded)
            
            // Stage indicators
            static let stageTitle = Font.system(size: 14, weight: .medium, design: .rounded)
            static let stageCaption = Font.system(size: 12, weight: .regular, design: .rounded)
            
            // Progress indicators
            static let progressLabel = Font.system(size: 13, weight: .semibold, design: .monospaced)
            static let progressValue = Font.system(size: 11, weight: .medium, design: .monospaced)
            
            // Error/Success states
            static let statusTitle = Font.system(size: 16, weight: .semibold, design: .rounded)
            static let statusMessage = Font.system(size: 14, weight: .regular, design: .rounded)
        }
    }
    
    // MARK: - Spacing
    struct Spacing {
        // 4pt baseline grid
        static let baseline: CGFloat = 4
        
        // Inner padding - 20pt
        static let innerPadding: CGFloat = 20
        
        // Between sections - 32pt
        static let sectionSpacing: CGFloat = 32
        
        // Derived spacing based on baseline grid
        static let xs: CGFloat = baseline * 1    // 4pt
        static let sm: CGFloat = baseline * 2    // 8pt
        static let md: CGFloat = baseline * 3    // 12pt
        static let lg: CGFloat = baseline * 4    // 16pt
        static let xl: CGFloat = baseline * 6    // 24pt
        static let xxl: CGFloat = baseline * 8   // 32pt
        
        // MARK: - Loading-Specific Spacing
        struct Loading {
            // Loading container spacing
            static let containerPadding: CGFloat = 32
            static let compactPadding: CGFloat = 20
            
            // Animation spacing
            static let animationSpacing: CGFloat = 20
            static let stageSpacing: CGFloat = 12
            static let dotSpacing: CGFloat = 8
            
            // Progress indicators
            static let progressSpacing: CGFloat = 16
            static let progressBarHeight: CGFloat = 4
            
            // Skeleton spacing
            static let skeletonLineSpacing: CGFloat = 8
            static let skeletonBlockSpacing: CGFloat = 12
        }
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let pill: CGFloat = 999
        
        // MARK: - Loading-Specific Corner Radius
        struct Loading {
            static let container: CGFloat = 24
            static let compact: CGFloat = 16
            static let progress: CGFloat = 8
            static let skeleton: CGFloat = 8
            static let stage: CGFloat = 6
        }
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let card = Color.black.opacity(0.05)
        static let cardRadius: CGFloat = 8
        static let cardOffset = CGSize(width: 0, height: 2)
        
        // MARK: - Loading-Specific Shadows
        struct Loading {
            static let container = Color.black.opacity(0.08)
            static let containerRadius: CGFloat = 20
            static let containerOffset = CGSize(width: 0, height: 8)
            
            static let overlay = Color.black.opacity(0.15)
            static let overlayRadius: CGFloat = 25
            static let overlayOffset = CGSize(width: 0, height: 12)
            
            static let floating = Color.black.opacity(0.12)
            static let floatingRadius: CGFloat = 15
            static let floatingOffset = CGSize(width: 0, height: 6)
        }
    }
    
    // MARK: - Animation Configurations
    struct Animations {
        // Standard timing curves
        static let standard = Animation.easeInOut(duration: 0.3)
        static let quick = Animation.easeInOut(duration: 0.2)
        static let slow = Animation.easeInOut(duration: 0.5)
        
        // MARK: - Loading-Specific Animations
        struct Loading {
            // Spring animations for modern feel
            static let springFast = Animation.spring(response: 0.4, dampingFraction: 0.8)
            static let springStandard = Animation.spring(response: 0.6, dampingFraction: 0.8)
            static let springSlow = Animation.spring(response: 0.8, dampingFraction: 0.7)
            
            // Continuous animations
            static let shimmer = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
            static let ripple = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)
            static let pulse = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
            static let rotation = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
            
            // State transition animations
            static let stateChange = Animation.spring(response: 0.5, dampingFraction: 0.9)
            static let fadeInOut = Animation.easeInOut(duration: 0.4)
            static let scaleTransition = Animation.spring(response: 0.6, dampingFraction: 0.8)
            
            // Progressive animations
            static let stageTransition = Animation.spring(response: 0.6, dampingFraction: 0.8)
            static let progressUpdate = Animation.easeOut(duration: 0.3)
        }
    }
    
    // MARK: - Materials and Effects
    struct Materials {
        // Standard materials
        static let card = Material.ultraThinMaterial
        static let overlay = Material.regularMaterial
        static let background = Material.thinMaterial
        
        // MARK: - Loading-Specific Materials
        struct Loading {
            static let container = Material.regularMaterial
            static let overlay = Material.ultraThinMaterial
            static let backdrop = Material.thickMaterial
            
            // Glass-morphism effects
            static let glass = Material.ultraThinMaterial
            static let glassOverlay = Color.white.opacity(0.1)
            static let glassBorder = Color.white.opacity(0.2)
        }
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Loading Context Extension for Design System Integration
extension LoadingContext {
    var designSystemColor: Color {
        switch self {
        case .quizGeneration, .mistakeQuizGeneration:
            return DesignSystem.Colors.Loading.quiz
        case .aiVerification:
            return DesignSystem.Colors.Loading.aiProcessing
        case .speechProcessing:
            return DesignSystem.Colors.Loading.speech
        case .apiKeyValidation:
            return DesignSystem.Colors.Loading.validation
        case .dataSync:
            return DesignSystem.Colors.Loading.sync
        case .general:
            return DesignSystem.Colors.Loading.general
        }
    }
    
    var designSystemGradient: LinearGradient {
        switch self {
        case .quizGeneration, .mistakeQuizGeneration:
            return DesignSystem.Colors.Loading.gradientBlue
        case .aiVerification:
            return DesignSystem.Colors.Loading.gradientGreen
        case .speechProcessing:
            return DesignSystem.Colors.Loading.gradientPurple
        case .apiKeyValidation:
            return DesignSystem.Colors.Loading.gradientOrange
        case .dataSync:
            return DesignSystem.Colors.Loading.gradientBlue
        case .general:
            return LinearGradient(
                colors: [DesignSystem.Colors.Loading.general, DesignSystem.Colors.Loading.general.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Reusable UI Components

struct DSCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignSystem.Spacing.innerPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(DesignSystem.Materials.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .stroke(DesignSystem.Colors.cardStroke, lineWidth: 1)
                    )
            )
    }
}

struct DSButton: View {
    let title: String
    let icon: String?
    let style: Style
    let isLoading: Bool
    let action: () -> Void
    
    enum Style {
        case primary
        case secondary
        case tertiary
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return DesignSystem.Colors.accent
            case .secondary:
                return DesignSystem.Colors.accent.opacity(0.1)
            case .tertiary:
                return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary:
                return .white
            case .secondary, .tertiary:
                return DesignSystem.Colors.accent
            }
        }
    }
    
    init(_ title: String, icon: String? = nil, style: Style = .primary, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isLoading {
                    ModernLoadingIndicator.inlineSpringDots(
                        size: 16,
                        color: style.foregroundColor
                    )
                } else if let icon = icon {
                    Image(systemName: icon)
                        .symbolRenderingMode(.hierarchical)
                }
                
                if !isLoading {
                    Text(title)
                        .font(DesignSystem.Typography.buttonText)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(style.backgroundColor)
            )
        }
        .foregroundColor(style.foregroundColor)
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .animation(DesignSystem.Animations.Loading.stateChange, value: isLoading)
    }
}

struct DSSectionHeader: View {
    let title: String
    let subtitle: String?
    let isLoading: Bool
    
    init(_ title: String, subtitle: String? = nil, isLoading: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.isLoading = isLoading
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            if isLoading {
                SkeletonLoader.title()
                if subtitle != nil {
                    SkeletonLoader.text(width: 120)
                }
            } else {
                Text(title)
                    .font(DesignSystem.Typography.sectionHeader)
                    .foregroundColor(DesignSystem.Colors.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondary)
                }
            }
        }
        .animation(DesignSystem.Animations.Loading.fadeInOut, value: isLoading)
    }
}

// MARK: - Modern Loading Card Component
struct DSLoadingCard<Content: View>: View {
    let content: Content
    let isLoading: Bool
    let loadingContext: LoadingContext?
    
    init(isLoading: Bool = false, context: LoadingContext? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isLoading = isLoading
        self.loadingContext = context
    }
    
    var body: some View {
        ZStack {
            content
                .opacity(isLoading ? 0 : 1)
            
            if isLoading {
                if let context = loadingContext {
                    ModernLoadingIndicator(
                        type: context.modernAnimationType,
                        message: context.defaultMessage,
                        size: 40,
                        color: context.designSystemColor,
                        enableHaptics: false
                    )
                } else {
                    SkeletonLoader.card()
                }
            }
        }
        .padding(DesignSystem.Spacing.Loading.containerPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.Loading.container, style: .continuous)
                .fill(DesignSystem.Materials.Loading.container)
                .shadow(
                    color: DesignSystem.Shadows.Loading.container,
                    radius: DesignSystem.Shadows.Loading.containerRadius,
                    x: DesignSystem.Shadows.Loading.containerOffset.width,
                    y: DesignSystem.Shadows.Loading.containerOffset.height
                )
        )
        .animation(DesignSystem.Animations.Loading.fadeInOut, value: isLoading)
    }
}

// MARK: - Progress Indicator Component
struct DSProgressIndicator: View {
    let progress: Double
    let title: String?
    let showPercentage: Bool
    let color: Color
    
    init(progress: Double, title: String? = nil, showPercentage: Bool = true, color: Color = DesignSystem.Colors.accent) {
        self.progress = progress
        self.title = title
        self.showPercentage = showPercentage
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.Loading.progressSpacing) {
            if let title = title {
                HStack {
                    Text(title)
                        .font(DesignSystem.Typography.Loading.progressLabel)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if showPercentage {
                        Text("\(Int(progress * 100))%")
                            .font(DesignSystem.Typography.Loading.progressValue)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.Loading.progress)
                        .fill(DesignSystem.Colors.Loading.progressBackground)
                        .frame(height: DesignSystem.Spacing.Loading.progressBarHeight)
                    
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.Loading.progress)
                        .fill(color)
                        .frame(
                            width: geometry.size.width * progress,
                            height: DesignSystem.Spacing.Loading.progressBarHeight
                        )
                        .animation(DesignSystem.Animations.Loading.progressUpdate, value: progress)
                }
            }
            .frame(height: DesignSystem.Spacing.Loading.progressBarHeight)
        }
    }
}

// MARK: - Status Message Component
struct DSStatusMessage: View {
    enum MessageType {
        case loading
        case success
        case error
        case info
        
        var color: Color {
            switch self {
            case .loading:
                return DesignSystem.Colors.Loading.general
            case .success:
                return DesignSystem.Colors.success
            case .error:
                return DesignSystem.Colors.error
            case .info:
                return DesignSystem.Colors.accent
            }
        }
        
        var icon: String {
            switch self {
            case .loading:
                return "hourglass"
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "exclamationmark.triangle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
    }
    
    let type: MessageType
    let title: String
    let message: String?
    let showAnimation: Bool
    
    init(type: MessageType, title: String, message: String? = nil, showAnimation: Bool = true) {
        self.type = type
        self.title = title
        self.message = message
        self.showAnimation = showAnimation
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            if type == .loading && showAnimation {
                ModernLoadingIndicator.inlineRipple(size: 20, color: type.color)
            } else {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(type.color)
                    .symbolEffect(.bounce, value: showAnimation)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.Loading.statusTitle)
                    .foregroundColor(.primary)
                
                if let message = message {
                    Text(message)
                        .font(DesignSystem.Typography.Loading.statusMessage)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.Loading.compactPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.Loading.compact)
                .fill(type.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.Loading.compact)
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - View Extensions for Design System Integration

extension View {
    func dsLoadingCard(isLoading: Bool = false, context: LoadingContext? = nil) -> some View {
        DSLoadingCard(isLoading: isLoading, context: context) {
            self
        }
    }
    
    func dsProgressOverlay(progress: Double, title: String? = nil) -> some View {
        ZStack {
            self
            
            if progress < 1.0 {
                VStack {
                    Spacer()
                    DSProgressIndicator(progress: progress, title: title)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .fill(DesignSystem.Materials.Loading.overlay)
                        )
                        .padding()
                }
            }
        }
    }
} 