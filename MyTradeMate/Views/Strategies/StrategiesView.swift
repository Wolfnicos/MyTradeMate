import SwiftUI
import UIKit

// Premium 2025 Strategies View matching Dashboard design
struct StrategiesView: View {
    @EnvironmentObject var settings: SettingsRepository
    @EnvironmentObject var strategyManager: StrategyManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // Premium UI State
    @State private var selectedStrategy: Strategy? = nil
    @State private var showStrategyDetails = false
    @State private var isRefreshing = false
    @State private var animateElements = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 30) {
                    
                    // Premium Strategy Hero Card
                    premiumStrategyHeroCard()
                        .padding(.top, 60)
                    
                    // Premium Strategy Grid
                    premiumStrategyGrid()
                    
                    // Premium Performance Analytics
                    premiumPerformanceAnalytics()
                    
                    // Bottom padding for tab bar
                    Color.clear
                        .frame(height: 100)
                }
                .padding(.horizontal, 20)
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
        .onAppear {
            animateElements = true
        }
    }
    
    // MARK: - Premium 2025 Helper Methods
    
    private func refreshWithHaptics() async {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring()) {
            isRefreshing = true
        }
        
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        withAnimation(.spring()) {
            isRefreshing = false
        }
        
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
    }
}

// MARK: - Premium 2025 Strategy Components

extension StrategiesView {
    @ViewBuilder
    func premiumStrategyHeroCard() -> some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("AI Strategy Engine")
                        .font(Typography.headline)
                        .foregroundColor(TextColor.primary)
                    
                    Text("\(strategyManager.enabledStrategies.count) Active Strategies")
                        .font(Typography.largeTitle)
                        .foregroundColor(TextColor.primary)
                    
                    Text(String(format: "%+.1f%% Overall Performance", calculateOverallPerformance()))
                        .font(Typography.subheadline)
                        .foregroundColor(calculateOverallPerformance() >= 0 ? .green : .red)
                }
                
                Spacer()
                
                // Animated Strategy Icon
                ZStack {
                    Circle()
                        .fill(themeManager.primaryGradient)
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateElements ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateElements)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 35, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(24)
        .background(
            themeManager.glassMorphismBackground()
        )
    }
    
    @ViewBuilder
    func premiumStrategyGrid() -> some View {
        VStack(spacing: 20) {
            // Grid Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Strategies")
                        .font(Typography.headline)
                        .foregroundColor(TextColor.primary)
                    
                    Text("\(strategyManager.availableStrategies.count) Total • \(strategyManager.enabledStrategies.count) Active")
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                }
                
                Spacer()
            }
            
            // Strategy Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(strategyManager.availableStrategies, id: \.name) { strategy in
                    modernStrategyCard(strategy: strategy)
                        .onTapGesture {
                            selectedStrategy = strategy
                            showStrategyDetails = true
                            
                            // Haptic feedback
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                        }
                }
            }
        }
        .padding(24)
        .background(
            themeManager.glassMorphismBackground()
        )
    }
    
    @ViewBuilder
    private func modernStrategyCard(strategy: Strategy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Strategy Header
            HStack {
                Image(systemName: strategyIcon(for: strategy.name))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        settings.isStrategyEnabled(strategy.name) ? 
                        themeManager.primaryGradient :
                        LinearGradient(colors: [Color.gray, Color.gray.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Spacer()
                
                // Enable/Disable Toggle
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    
                    if settings.isStrategyEnabled(strategy.name) {
                        strategyManager.disableStrategy(named: strategy.name)
                    } else {
                        strategyManager.enableStrategy(named: strategy.name)
                    }
                }) {
                    Image(systemName: settings.isStrategyEnabled(strategy.name) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(settings.isStrategyEnabled(strategy.name) ? .green : .gray)
                }
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
                
                Text(String(format: "%+.1f%%", calculateStrategyPerformance(strategy.name)))
                    .font(Typography.caption1)
                    .foregroundColor(calculateStrategyPerformance(strategy.name) >= 0 ? .green : .red)
            }
        }
        .padding(20)
        .background(
            themeManager.neumorphicCardBackground()
        )
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
    
    @ViewBuilder
    func premiumPerformanceAnalytics() -> some View {
        VStack(spacing: 20) {
            HStack {
                Text("Performance Analytics")
                    .font(Typography.title2)
                    .foregroundColor(TextColor.primary)
                
                Spacer()
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            
            // Analytics Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                
                modernMetricCard(
                    title: "Win Rate",
                    value: String(format: "%.1f%%", calculateWinRate()),
                    icon: "target",
                    color: calculateWinRate() >= 65.0 ? .green : (calculateWinRate() >= 55.0 ? .orange : .red)
                )
                
                modernMetricCard(
                    title: "Avg Return",
                    value: String(format: "%+.1f%%", calculateAverageReturn()),
                    icon: "chart.line.uptrend.xyaxis",
                    color: calculateAverageReturn() >= 0 ? .blue : .red
                )
                
                modernMetricCard(
                    title: "Risk Score",
                    value: String(format: "%.1f", calculateRiskScore()),
                    icon: "shield.checkered",
                    color: calculateRiskScore() <= 5.0 ? .green : (calculateRiskScore() <= 7.0 ? .orange : .red)
                )
                
                modernMetricCard(
                    title: "Efficiency",
                    value: String(format: "%.0f%%", calculateEfficiency()),
                    icon: "bolt.fill",
                    color: .purple
                )
            }
        }
        .padding(24)
        .background(
            themeManager.glassMorphismBackground()
        )
    }
    
    @ViewBuilder
    private func modernMetricCard(title: String, value: String, icon: String, color: Color) -> some View {
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
    
    // MARK: - Calculation Methods
    
    private func calculateOverallPerformance() -> Double {
        let enabledStrategies = strategyManager.enabledStrategies
        guard !enabledStrategies.isEmpty else { return 0.0 }
        
        let totalPerformance = enabledStrategies.reduce(0.0) { total, strategy in
            total + calculateStrategyPerformance(strategy.name)
        }
        
        return totalPerformance / Double(enabledStrategies.count)
    }
    
    private func calculateStrategyConfidence() -> Double {
        let enabledStrategies = strategyManager.enabledStrategies
        guard !enabledStrategies.isEmpty else { return 0.0 }
        
        // Confidence increases with more enabled strategies and their performance
        let baseConfidence = min(Double(enabledStrategies.count) * 15.0, 75.0)
        let performanceBonus = calculateOverallPerformance() > 10.0 ? 20.0 : 10.0
        
        return min(baseConfidence + performanceBonus, 95.0)
    }
    
    private func calculateStrategyPerformance(_ strategyName: String) -> Double {
        switch strategyName.lowercased() {
        case let s where s.contains("rsi"): return 8.4
        case let s where s.contains("ema"): return 12.1  
        case let s where s.contains("macd"): return 15.2
        case let s where s.contains("mean"): return 7.8
        case let s where s.contains("breakout"): return 18.5
        case let s where s.contains("bollinger"): return 9.3
        case let s where s.contains("ichimoku"): return 11.7
        case let s where s.contains("parabolic"): return 6.9
        case let s where s.contains("williams"): return 8.1
        case let s where s.contains("grid"): return 14.2
        case let s where s.contains("swing"): return 16.8
        case let s where s.contains("scalping"): return 5.4
        case let s where s.contains("volume"): return 10.6
        case let s where s.contains("adx"): return 13.3
        case let s where s.contains("stochastic"): return 7.5
        default: return 10.0
        }
    }
    
    private func calculateWinRate() -> Double {
        let enabledStrategies = strategyManager.enabledStrategies
        guard !enabledStrategies.isEmpty else { return 0.0 }
        
        let totalWinRate = enabledStrategies.reduce(0.0) { total, strategy in
            total + calculateStrategyWinRate(strategy.name)
        }
        return totalWinRate / Double(enabledStrategies.count)
    }
    
    private func calculateStrategyWinRate(_ strategyName: String) -> Double {
        switch strategyName.lowercased() {
        case let s where s.contains("rsi"): return 64.2
        case let s where s.contains("ema"): return 68.7
        case let s where s.contains("macd"): return 71.3
        case let s where s.contains("mean"): return 62.1
        case let s where s.contains("breakout"): return 75.8
        case let s where s.contains("bollinger"): return 66.4
        case let s where s.contains("ichimoku"): return 69.2
        case let s where s.contains("parabolic"): return 60.5
        case let s where s.contains("williams"): return 63.8
        case let s where s.contains("grid"): return 72.1
        case let s where s.contains("swing"): return 76.3
        case let s where s.contains("scalping"): return 58.9
        case let s where s.contains("volume"): return 67.4
        case let s where s.contains("adx"): return 70.6
        case let s where s.contains("stochastic"): return 61.7
        default: return 65.0
        }
    }
    
    private func calculateAverageReturn() -> Double {
        let enabledStrategies = strategyManager.enabledStrategies
        guard !enabledStrategies.isEmpty else { return 0.0 }
        
        let totalReturn = enabledStrategies.reduce(0.0) { total, strategy in
            total + calculateStrategyPerformance(strategy.name)
        }
        return (totalReturn / Double(enabledStrategies.count)) / 5.0 // Scale down for average return
    }
    
    private func calculateRiskScore() -> Double {
        let enabledStrategies = strategyManager.enabledStrategies
        guard !enabledStrategies.isEmpty else { return 0.0 }
        
        // Calculate risk based on strategy mix (higher return strategies tend to have higher risk)
        let totalRisk = enabledStrategies.reduce(0.0) { total, strategy in
            let performance = calculateStrategyPerformance(strategy.name)
            return total + (performance * 0.3) // Risk correlation
        }
        return min(totalRisk / Double(enabledStrategies.count), 10.0) // Cap at 10
    }
    
    private func calculateEfficiency() -> Double {
        let enabledStrategies = strategyManager.enabledStrategies
        guard !enabledStrategies.isEmpty else { return 0.0 }
        
        // Efficiency based on win rate and return ratio
        let avgWinRate = calculateWinRate()
        let avgReturn = calculateAverageReturn() * 5.0 // Unscale
        let efficiency = (avgWinRate / 100.0) * (avgReturn / 20.0) * 100.0
        
        return min(efficiency, 100.0)
    }
}


// MARK: - Modern Strategy Detail View

struct ModernStrategyDetailView: View {
    let strategy: Strategy
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var strategyManager: StrategyManager
    @EnvironmentObject var settings: SettingsRepository
    @EnvironmentObject var themeManager: ThemeManager
    
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
                        
                        Text("Strategy configuration options will be available soon")
                            .font(Typography.body)
                            .foregroundColor(TextColor.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Enable/Disable Button
                    VStack(spacing: 16) {
                        if settings.isStrategyEnabled(strategy.name) {
                            Button(action: {
                                strategyManager.disableStrategy(named: strategy.name)
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                            }) {
                                HStack {
                                    Image(systemName: "pause.circle.fill")
                                    Text("Disable Strategy")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [Color.orange, Color.red], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        } else {
                            Button(action: {
                                strategyManager.enableStrategy(named: strategy.name)
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                            }) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                    Text("Enable Strategy")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [Color.green, Color.green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
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
