import SwiftUI
import UIKit

// Modern 2025 Strategies View with immersive layouts and gesture interactions
struct StrategiesView: View {
    @EnvironmentObject var settings: SettingsRepository
    @EnvironmentObject var strategyManager: StrategyManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // Modern 2025 UI State
    @State private var selectedStrategy: Strategy? = nil
    @State private var showStrategyDetails = false
    @State private var dragOffset: CGFloat = 0
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Hero Section with Strategy Overview
                    ModernStrategyHeroSection()
                        .padding(.top, 20)
                    
                    // Immersive Strategy Grid
                    ModernStrategyGrid(
                        selectedStrategy: $selectedStrategy,
                        showStrategyDetails: $showStrategyDetails
                    )
                        .padding(.top, 30)
                    
                    // Performance Metrics with Glass Morphism
                    ModernPerformanceMetrics()
                        .padding(.top, 30)
                        .padding(.bottom, 100)
                }
            }
            .scrollIndicators(.hidden)
            .background(
                themeManager.backgroundGradient
                    .ignoresSafeArea()
            )
            .navigationTitle("AI Strategies")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            .refreshable {
                await refreshWithHaptics()
            }
            .sheet(isPresented: $showStrategyDetails) {
                if let strategy = selectedStrategy {
                    ModernStrategyDetailView(strategy: strategy)
                }
            }
        }
    }
    
    // MARK: - Modern 2025 Helper Methods
    
    private func refreshWithHaptics() async {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(themeManager.defaultAnimation) {
            isRefreshing = true
        }
        
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        withAnimation(themeManager.defaultAnimation) {
            isRefreshing = false
        }
        
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
    }
}

// MARK: - Modern 2025 Strategy Components

struct ModernStrategyHeroSection: View {
    @EnvironmentObject var strategyManager: StrategyManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Strategy Overview Card with Glass Morphism
            ZStack {
                themeManager.glassMorphismBackground()
                
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI Strategy Engine")
                                .font(Typography.largeTitle)
                                .foregroundColor(TextColor.primary)
                            
                            Text("\(strategyManager.activeStrategies.count) active strategies")
                                .font(Typography.title3)
                                .foregroundColor(TextColor.secondary)
                        }
                        
                        Spacer()
                        
                        // Animated Strategy Icon
                        ZStack {
                            Circle()
                                .fill(themeManager.primaryGradient)
                                .frame(width: 80, height: 80)
                                .scaleEffect(1.0)
                                .animation(
                                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                    value: themeManager.isDarkMode
                                )
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Strategy Performance Bar
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Overall Performance")
                                .font(Typography.headline)
                                .foregroundColor(TextColor.primary)
                            
                            Spacer()
                            
                            Text("+12.5%")
                                .font(Typography.title2)
                                .foregroundColor(.green)
                        }
                        
                        ProgressView(value: 0.75)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                }
                .padding(24)
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ModernStrategyGrid: View {
    @EnvironmentObject var strategyManager: StrategyManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settings: SettingsRepository
    @Binding var selectedStrategy: Strategy?
    @Binding var showStrategyDetails: Bool
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(strategyManager.availableStrategies, id: \.name) { strategy in
                ModernStrategyCard(
                    strategy: strategy,
                    isEnabled: settings.isStrategyEnabled(strategy.name)
                ) {
                    selectedStrategy = strategy
                    showStrategyDetails = true
                    
                    // Haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct ModernStrategyCard: View {
    let strategy: Strategy
    let isEnabled: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settings: SettingsRepository
    @EnvironmentObject var strategyManager: StrategyManager
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Strategy Header
                HStack {
                    Image(systemName: strategyIcon(for: strategy.name))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            isEnabled ? 
                            themeManager.primaryGradient :
                            LinearGradient(colors: [Color.gray, Color.gray.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    Spacer()
                    
                    // Enable/Disable Toggle with Modern Design
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        
                        if isEnabled {
                            strategyManager.disableStrategy(named: strategy.name)
                        } else {
                            strategyManager.enableStrategy(named: strategy.name)
                        }
                    }) {
                        Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(isEnabled ? .green : .gray)
                    }
                    .modifier(themeManager.modernButtonStyle())
                }
                
                // Strategy Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(strategy.name)
                        .font(Typography.headline)
                        .foregroundColor(TextColor.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(strategy.description)
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                
                // Performance Indicator
                HStack {
                    Text("Performance")
                        .font(Typography.caption2)
                        .foregroundColor(TextColor.secondary)
                    
                    Spacer()
                    
                    Text("+8.2%")
                        .font(Typography.caption1)
                        .foregroundColor(.green)
                }
            }
            .padding(20)
            .background(
                themeManager.neumorphicCardBackground()
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(themeManager.fastAnimation, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}, onPressingChanged: { pressing in
            withAnimation(themeManager.fastAnimation) {
                isPressed = pressing
            }
        })
    }
    
    private func strategyIcon(for name: String) -> String {
        switch name.lowercased() {
        case let s where s.contains("rsi"): return "chart.line.uptrend.xyaxis"
        case let s where s.contains("macd"): return "chart.bar.fill"
        case let s where s.contains("bollinger"): return "chart.line.uptrend.xyaxis.circle"
        case let s where s.contains("moving"): return "chart.line.uptrend.xyaxis"
        case let s where s.contains("breakout"): return "arrow.up.right.circle"
        case let s where s.contains("mean"): return "arrow.left.and.right.circle"
        default: return "brain.head.profile"
        }
    }
}

struct ModernPerformanceMetrics: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Performance Analytics")
                .font(Typography.title2)
                .foregroundColor(TextColor.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            // Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ModernMetricCard(
                    title: "Win Rate",
                    value: "68.5%",
                    icon: "target",
                    color: .green
                )
                
                ModernMetricCard(
                    title: "Avg Return",
                    value: "+2.4%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
                
                ModernMetricCard(
                    title: "Max Drawdown",
                    value: "-8.2%",
                    icon: "arrow.down.circle",
                    color: .red
                )
                
                ModernMetricCard(
                    title: "Sharpe Ratio",
                    value: "1.85",
                    icon: "chart.bar.fill",
                    color: .purple
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ModernMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(Typography.title2)
                .foregroundColor(TextColor.primary)
            
            Text(title)
                .font(Typography.caption1)
                .foregroundColor(TextColor.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            themeManager.neumorphicCardBackground()
        )
    }
}

struct ModernStrategyDetailView: View {
    let strategy: Strategy
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Strategy Header
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundStyle(themeManager.primaryGradient)
                        
                        Text(strategy.name)
                            .font(Typography.largeTitle)
                            .foregroundColor(TextColor.primary)
                        
                        Text(strategy.description)
                            .font(Typography.body)
                            .foregroundColor(TextColor.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Strategy Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Configuration")
                            .font(Typography.title2)
                            .foregroundColor(TextColor.primary)
                        
                        // Add configuration options here
                        Text("Configuration options will be implemented here")
                            .font(Typography.body)
                            .foregroundColor(TextColor.secondary)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Strategy Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}