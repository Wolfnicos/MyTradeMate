import SwiftUI

/// An enhanced empty state view with custom illustrations and animations
struct IllustratedEmptyStateView: View {
    let illustration: EmptyStateIllustration
    let title: String
    let description: String
    let actionButton: (() -> Void)?
    let actionButtonTitle: String?
    
    init(
        illustration: EmptyStateIllustration,
        title: String,
        description: String,
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil
    ) {
        self.illustration = illustration
        self.title = title
        self.description = description
        self.actionButton = actionButton
        self.actionButtonTitle = actionButtonTitle
    }
    
    private var spacing: CGFloat {
        switch DeviceClass.current {
        case .compact:
            return 12
        case .regular:
            return 16
        case .large:
            return 24
        case .extraLarge:
            return 32
        }
    }
    
    private var titleFont: Font {
        switch DeviceClass.current {
        case .compact:
            return .title3.weight(.semibold)
        case .regular:
            return .title2.weight(.semibold)
        case .large:
            return .title2.weight(.semibold)
        case .extraLarge:
            return .title.weight(.semibold)
        }
    }
    
    private var descriptionFont: Font {
        switch DeviceClass.current {
        case .compact:
            return .callout
        case .regular:
            return .body
        case .large:
            return .body
        case .extraLarge:
            return .title3
        }
    }
    
    private var buttonControlSize: ControlSize {
        switch DeviceClass.current {
        case .compact:
            return .regular
        case .regular:
            return .large
        case .large:
            return .large
        case .extraLarge:
            return .extraLarge
        }
    }
    
    var body: some View {
        VStack(spacing: spacing) {
            // Illustration with optimized animations
            illustration.view
            
            VStack(spacing: ImageOptimizer.shared.optimalSpacing(baseSpacing: 12)) {
                Text(title)
                    .font(titleFont)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(descriptionFont)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
            }
            
            if let action = actionButton, let buttonTitle = actionButtonTitle {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(buttonControlSize)
            }
        }
        .optimalPadding(spacing)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}

/// Enum defining different empty state illustrations
enum EmptyStateIllustration {
    case chartNoData
    case pnlNoData
    case tradesNoData
    case strategiesNoData
    case aiSignalNoData
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .chartNoData:
            ChartEmptyIllustration()
        case .pnlNoData:
            PnLEmptyIllustration()
        case .tradesNoData:
            TradesEmptyIllustration()
        case .strategiesNoData:
            StrategiesEmptyIllustration()
        case .aiSignalNoData:
            AISignalEmptyIllustration()
        }
    }
}

// MARK: - Individual Illustrations

struct ChartEmptyIllustration: View {
    @State private var animateChart = false
    @State private var animateBackground = false
    @State private var animateGlow = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var illustrationSize: CGSize {
        switch DeviceClass.current {
        case .compact:
            return CGSize(width: 80, height: 80)
        case .regular:
            return CGSize(width: 100, height: 100)
        case .large:
            return CGSize(width: 120, height: 120)
        case .extraLarge:
            return CGSize(width: 160, height: 160)
        }
    }
    
    private var chartBarOpacity: Double {
        colorScheme == .dark ? 0.9 : 0.7
    }
    
    private var axisLineOpacity: Double {
        colorScheme == .dark ? 0.5 : 0.3
    }
    
    var body: some View {
        ZStack {
            // Background circle with subtle pulsing animation
            Circle()
                .fill(Color.emptyStateBackgroundBlue)
                .frame(width: illustrationSize.width, height: illustrationSize.height)
                .scaleEffect(animateBackground ? 1.02 : 1.0)
                .opacity(animateBackground ? 0.8 : 1.0)
                .overlay(
                    Circle()
                        .stroke(Color.emptyStateBlue.opacity(0.1), lineWidth: 1)
                        .scaleEffect(animateGlow ? 1.05 : 1.0)
                        .opacity(animateGlow ? 0.3 : 0.1)
                )
            
            // Chart lines with enhanced subtle animations
            VStack(spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(0..<6, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.emptyStateBlue.opacity(chartBarOpacity))
                            .frame(width: 3, height: chartBarHeight(for: index))
                            .scaleEffect(y: animateChart ? 1.0 + sin(Double(index) * 0.5) * 0.1 : 0.9)
                            .opacity(animateChart ? 1.0 : 0.6)
                            .animation(
                                .easeInOut(duration: ImageOptimizer.shared.optimalAnimationDuration(3.0))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: animateChart
                            )
                    }
                }
                
                // X-axis line with subtle fade animation
                Rectangle()
                    .fill(Color.emptyStateNeutral.opacity(axisLineOpacity))
                    .frame(width: 30, height: 1)
                    .opacity(animateChart ? 0.8 : 0.4)
                    .animation(
                        .easeInOut(duration: ImageOptimizer.shared.optimalAnimationDuration(2.0))
                        .repeatForever(autoreverses: true),
                        value: animateChart
                    )
            }
        }
        .onAppear {
            if ImageOptimizer.shared.shouldEnableAnimations {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animateChart = true
                }
                
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                    animateBackground = true
                }
                
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(1.0)) {
                    animateGlow = true
                }
            }
        }
        .onDisappear {
            animateChart = false
            animateBackground = false
            animateGlow = false
        }
    }
    
    private func chartBarHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [12, 18, 8, 22, 15, 10]
        return heights[index % heights.count]
    }
}

struct PnLEmptyIllustration: View {
    @State private var animateCoins = false
    @State private var animateRotation = false
    @State private var animateScale = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var illustrationSize: CGSize {
        switch DeviceClass.current {
        case .compact:
            return CGSize(width: 80, height: 80)
        case .regular:
            return CGSize(width: 100, height: 100)
        case .large:
            return CGSize(width: 120, height: 120)
        case .extraLarge:
            return CGSize(width: 160, height: 160)
        }
    }
    
    private var offsetMultiplier: CGFloat {
        switch DeviceClass.current {
        case .compact:
            return 16
        case .regular:
            return 20
        case .large:
            return 24
        case .extraLarge:
            return 32
        }
    }
    
    private var coinOpacity: (active: Double, inactive: Double) {
        colorScheme == .dark ? (0.9, 0.5) : (0.8, 0.4)
    }
    
    var body: some View {
        ZStack {
            // Background circle with subtle breathing animation
            Circle()
                .fill(Color.emptyStateBackgroundGreen)
                .frame(width: illustrationSize.width, height: illustrationSize.height)
                .scaleEffect(animateScale ? 1.03 : 1.0)
                .overlay(
                    Circle()
                        .stroke(Color.emptyStateGreen.opacity(0.1), lineWidth: 1)
                        .scaleEffect(animateScale ? 1.06 : 1.0)
                        .opacity(animateScale ? 0.2 : 0.1)
                )
            
            // Floating coins with enhanced subtle animations
            ForEach(0..<3, id: \.self) { index in
                Image.adaptiveEmptyStateSymbol("dollarsign.circle.fill")
                    .foregroundColor(.emptyStateGreen)
                    .scaleEffect(animateCoins ? 1.0 + sin(Double(index) * 0.8) * 0.05 : 0.95)
                    .rotationEffect(.degrees(animateRotation ? Double(index * 5) : 0))
                    .offset(
                        x: CGFloat(index - 1) * offsetMultiplier * (animateCoins ? 1.1 : 0.9),
                        y: animateCoins ? -offsetMultiplier/2 + sin(Double(index) * 1.2) * 3 : offsetMultiplier/2
                    )
                    .opacity(animateCoins ? coinOpacity.active : coinOpacity.inactive)
                    .animation(
                        .easeInOut(duration: ImageOptimizer.shared.optimalAnimationDuration(2.5))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.4),
                        value: animateCoins
                    )
                    .animation(
                        .linear(duration: ImageOptimizer.shared.optimalAnimationDuration(8.0))
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.5),
                        value: animateRotation
                    )
            }
        }
        .onAppear {
            if ImageOptimizer.shared.shouldEnableAnimations {
                withAnimation(.easeInOut(duration: 0.6)) {
                    animateCoins = true
                }
                
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true).delay(0.5)) {
                    animateScale = true
                }
                
                withAnimation(.linear(duration: 12.0).repeatForever(autoreverses: false).delay(1.0)) {
                    animateRotation = true
                }
            }
        }
        .onDisappear {
            animateCoins = false
            animateScale = false
            animateRotation = false
        }
    }
}

struct TradesEmptyIllustration: View {
    @State private var animateList = false
    @State private var animateShimmer = false
    @State private var animateBackground = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var illustrationSize: CGSize {
        switch DeviceClass.current {
        case .compact:
            return CGSize(width: 80, height: 80)
        case .regular:
            return CGSize(width: 100, height: 100)
        case .large:
            return CGSize(width: 120, height: 120)
        case .extraLarge:
            return CGSize(width: 160, height: 160)
        }
    }
    
    private var listItemOpacity: (dot: Double, bar: Double, active: Double, inactive: Double) {
        colorScheme == .dark ? (0.8, 0.6, 1.0, 0.6) : (0.6, 0.4, 1.0, 0.5)
    }
    
    var body: some View {
        ZStack {
            // Background circle with subtle pulsing
            Circle()
                .fill(Color.emptyStateBackgroundOrange)
                .frame(width: illustrationSize.width, height: illustrationSize.height)
                .scaleEffect(animateBackground ? 1.02 : 1.0)
                .overlay(
                    Circle()
                        .stroke(Color.emptyStateOrange.opacity(0.1), lineWidth: 1)
                        .scaleEffect(animateBackground ? 1.04 : 1.0)
                        .opacity(animateBackground ? 0.3 : 0.1)
                )
            
            // List items with enhanced subtle animations and shimmer effect
            VStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(Color.emptyStateOrange.opacity(listItemOpacity.dot))
                            .frame(width: 6, height: 6)
                            .scaleEffect(animateList ? 1.0 + sin(Double(index) * 0.7) * 0.1 : 0.8)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.emptyStateOrange.opacity(listItemOpacity.bar))
                            .frame(width: 30, height: 4)
                            .overlay(
                                // Subtle shimmer effect
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.clear,
                                                Color.emptyStateOrange.opacity(0.3),
                                                Color.clear
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .offset(x: animateShimmer ? 40 : -40)
                                    .animation(
                                        .easeInOut(duration: ImageOptimizer.shared.optimalAnimationDuration(2.0))
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(index) * 0.3),
                                        value: animateShimmer
                                    )
                            )
                            .clipped()
                        
                        Spacer()
                    }
                    .scaleEffect(animateList ? 1.0 : 0.8)
                    .opacity(animateList ? listItemOpacity.active : listItemOpacity.inactive)
                    .offset(x: animateList ? 0 : -10)
                    .animation(
                        .easeOut(duration: ImageOptimizer.shared.optimalAnimationDuration(0.8))
                        .delay(Double(index) * 0.15),
                        value: animateList
                    )
                }
            }
            .frame(width: 50)
        }
        .onAppear {
            if ImageOptimizer.shared.shouldEnableAnimations {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateList = true
                }
                
                withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(0.8)) {
                    animateBackground = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    animateShimmer = true
                }
            }
        }
        .onDisappear {
            animateList = false
            animateShimmer = false
            animateBackground = false
        }
    }
}

struct StrategiesEmptyIllustration: View {
    @State private var animateBrain = false
    @State private var animateThinking = false
    @State private var animateConnections = false
    @State private var animateGlow = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var illustrationSize: CGSize {
        switch DeviceClass.current {
        case .compact:
            return CGSize(width: 80, height: 80)
        case .regular:
            return CGSize(width: 100, height: 100)
        case .large:
            return CGSize(width: 120, height: 120)
        case .extraLarge:
            return CGSize(width: 160, height: 160)
        }
    }
    
    private var neuralDotOpacity: Double {
        colorScheme == .dark ? 0.8 : 0.6
    }
    
    var body: some View {
        ZStack {
            // Background circle with subtle glow animation
            Circle()
                .fill(Color.emptyStateBackgroundPurple)
                .frame(width: illustrationSize.width, height: illustrationSize.height)
                .overlay(
                    Circle()
                        .stroke(Color.emptyStatePurple.opacity(0.1), lineWidth: 1)
                        .scaleEffect(animateGlow ? 1.05 : 1.0)
                        .opacity(animateGlow ? 0.4 : 0.1)
                )
            
            // Brain with enhanced thinking animation
            VStack(spacing: 8) {
                Image.adaptiveEmptyStateSymbol("brain.head.profile")
                    .foregroundColor(.emptyStatePurple)
                    .scaleEffect(animateBrain ? 1.05 : 0.95)
                    .rotationEffect(.degrees(animateThinking ? 2 : -2))
                    .opacity(animateBrain ? 1.0 : 0.7)
                    .animation(
                        .easeInOut(duration: ImageOptimizer.shared.optimalAnimationDuration(2.5))
                        .repeatForever(autoreverses: true),
                        value: animateBrain
                    )
                    .animation(
                        .easeInOut(duration: ImageOptimizer.shared.optimalAnimationDuration(4.0))
                        .repeatForever(autoreverses: true)
                        .delay(0.5),
                        value: animateThinking
                    )
                
                // Enhanced neural connection dots with wave-like animation
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(Color.emptyStatePurple.opacity(neuralDotOpacity))
                            .frame(width: 3, height: 3)
                            .scaleEffect(animateConnections ? 1.2 + sin(Double(index) * 0.8) * 0.3 : 0.5)
                            .opacity(animateConnections ? 0.9 : 0.3)
                            .offset(y: animateConnections ? sin(Double(index) * 0.6) * 2 : 0)
                            .animation(
                                .easeInOut(duration: ImageOptimizer.shared.optimalAnimationDuration(1.5))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                                value: animateConnections
                            )
                    }
                }
                
                // Additional thinking dots above the brain
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.emptyStatePurple.opacity(0.4))
                            .frame(width: CGFloat(2 + index), height: CGFloat(2 + index))
                            .offset(
                                x: CGFloat(index - 1) * 8,
                                y: animateThinking ? -CGFloat(index * 4 + 8) : -4
                            )
                            .opacity(animateThinking ? 0.8 : 0.2)
                            .animation(
                                .easeInOut(duration: ImageOptimizer.shared.optimalAnimationDuration(2.0))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.3),
                                value: animateThinking
                            )
                    }
                }
                .offset(y: -20)
            }
        }
        .onAppear {
            if ImageOptimizer.shared.shouldEnableAnimations {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateBrain = true
                }
                
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.5)) {
                    animateGlow = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateConnections = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    animateThinking = true
                }
            }
        }
        .onDisappear {
            animateBrain = false
            animateThinking = false
            animateConnections = false
            animateGlow = false
        }
    }
}

struct AISignalEmptyIllustration: View {
    @State private var animateSignal = false
    @State private var animateRadar = false
    @State private var animateCenter = false
    @State private var animatePulse = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var illustrationSize: CGSize {
        switch DeviceClass.current {
        case .compact:
            return CGSize(width: 80, height: 80)
        case .regular:
            return CGSize(width: 100, height: 100)
        case .large:
            return CGSize(width: 120, height: 120)
        case .extraLarge:
            return CGSize(width: 160, height: 160)
        }
    }
    
    private var signalWaveOpacity: (active: Double, inactive: Double) {
        colorScheme == .dark ? (0.3, 0.7) : (0.2, 0.6)
    }
    
    private var signalStrokeOpacity: Double {
        colorScheme == .dark ? 0.4 : 0.3
    }
    
    var body: some View {
        ZStack {
            // Background circle with subtle pulse
            Circle()
                .fill(Color.emptyStateBackgroundCyan)
                .frame(width: illustrationSize.width, height: illustrationSize.height)
                .scaleEffect(animatePulse ? 1.02 : 1.0)
                .overlay(
                    Circle()
                        .stroke(Color.emptyStateCyan.opacity(0.1), lineWidth: 1)
                        .scaleEffect(animatePulse ? 1.04 : 1.0)
                        .opacity(animatePulse ? 0.3 : 0.1)
                )
            
            // Enhanced signal waves with radar-like sweep
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color.emptyStateCyan.opacity(signalStrokeOpacity), lineWidth: 2)
                    .frame(width: CGFloat(40 + index * 20), height: CGFloat(40 + index * 20))
                    .scaleEffect(animateSignal ? 1.1 + sin(Double(index) * 0.5) * 0.1 : 0.8)
                    .opacity(animateSignal ? signalWaveOpacity.active + sin(Double(index) * 0.8) * 0.2 : signalWaveOpacity.inactive)
                    .rotationEffect(.degrees(animateRadar ? 360 : 0))
                    .animation(
                        .easeInOut(duration: ImageOptimizer.shared.optimalAnimationDuration(2.5))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.4),
                        value: animateSignal
                    )
                    .animation(
                        .linear(duration: ImageOptimizer.shared.optimalAnimationDuration(6.0))
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.2),
                        value: animateRadar
                    )
            }
            
            // Scanning line effect
            if ImageOptimizer.shared.shouldEnableAnimations {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 30, y: 0))
                }
                .stroke(Color.emptyStateCyan.opacity(0.6), lineWidth: 1.5)
                .rotationEffect(.degrees(animateRadar ? 360 : 0))
                .animation(
                    .linear(duration: ImageOptimizer.shared.optimalAnimationDuration(4.0))
                    .repeatForever(autoreverses: false),
                    value: animateRadar
                )
            }
            
            // Center icon with subtle breathing animation
            Image.adaptiveEmptyStateSymbol("antenna.radiowaves.left.and.right")
                .foregroundColor(.emptyStateCyan)
                .scaleEffect(animateCenter ? 1.05 : 0.95)
                .opacity(animateCenter ? 1.0 : 0.8)
                .animation(
                    .easeInOut(duration: ImageOptimizer.shared.optimalAnimationDuration(2.0))
                    .repeatForever(autoreverses: true),
                    value: animateCenter
                )
        }
        .onAppear {
            if ImageOptimizer.shared.shouldEnableAnimations {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateSignal = true
                }
                
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.3)) {
                    animatePulse = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animateCenter = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    animateRadar = true
                }
            }
        }
        .onDisappear {
            animateSignal = false
            animateRadar = false
            animateCenter = false
            animatePulse = false
        }
    }
}

// MARK: - Convenience Initializers

extension IllustratedEmptyStateView {
    /// Empty state for charts when no data is available
    static func chartNoData(
        title: String = "No Chart Data",
        description: String = "Market data is loading or temporarily unavailable. Check your connection and try again.",
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil
    ) -> IllustratedEmptyStateView {
        IllustratedEmptyStateView(
            illustration: .chartNoData,
            title: title,
            description: description,
            actionButton: actionButton,
            actionButtonTitle: actionButtonTitle
        )
    }
    
    /// Empty state for P&L charts when no trading data exists
    static func pnlNoData(
        title: String = "No Trading Data",
        description: String = "Start trading to see your performance metrics and profit & loss charts here.",
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil
    ) -> IllustratedEmptyStateView {
        IllustratedEmptyStateView(
            illustration: .pnlNoData,
            title: title,
            description: description,
            actionButton: actionButton,
            actionButtonTitle: actionButtonTitle
        )
    }
    
    /// Empty state for trade history
    static func tradesNoData(
        title: String = "No Trades Yet",
        description: String = "Your trading history will appear here once you start placing orders.",
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil
    ) -> IllustratedEmptyStateView {
        IllustratedEmptyStateView(
            illustration: .tradesNoData,
            title: title,
            description: description,
            actionButton: actionButton,
            actionButtonTitle: actionButtonTitle
        )
    }
    
    /// Empty state for strategies list
    static func strategiesNoData(
        title: String = "No Strategies Available",
        description: String = "AI trading strategies will appear here when they're loaded and ready to use.",
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil
    ) -> IllustratedEmptyStateView {
        IllustratedEmptyStateView(
            illustration: .strategiesNoData,
            title: title,
            description: description,
            actionButton: actionButton,
            actionButtonTitle: actionButtonTitle
        )
    }
    
    /// Empty state for AI signals
    static func aiSignalNoData(
        title: String = "No Signal Available",
        description: String = "The AI is analyzing market conditions. No clear trading signal at the moment.",
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil
    ) -> IllustratedEmptyStateView {
        IllustratedEmptyStateView(
            illustration: .aiSignalNoData,
            title: title,
            description: description,
            actionButton: actionButton,
            actionButtonTitle: actionButtonTitle
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 32) {
            IllustratedEmptyStateView.chartNoData()
                .frame(height: 250)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            
            IllustratedEmptyStateView.pnlNoData(
                actionButton: { print("Get started tapped") },
                actionButtonTitle: "Start Trading"
            )
            .frame(height: 250)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            IllustratedEmptyStateView.tradesNoData()
                .frame(height: 250)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            
            IllustratedEmptyStateView.strategiesNoData()
                .frame(height: 250)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            
            IllustratedEmptyStateView.aiSignalNoData()
                .frame(height: 250)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
        .padding()
    }
}