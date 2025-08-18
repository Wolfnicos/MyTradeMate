import SwiftUI

struct StrategyConfigurationView: View {
    @StateObject private var strategyManager = StrategyManager.shared
    @StateObject private var riskManager = RiskManager.shared
    @State private var selectedStrategy: (any Strategy)?
    @State private var showingParameterSheet = false
    
    var body: some View {
        NavigationView {
            List {
                // Strategy Guide Section
                Section {
                    StrategyGuideView()
                } header: {
                    Text("Strategy Guide")
                }
                
                // Active Strategies Section
                Section("Active Strategies") {
                    ForEach(strategyManager.activeStrategies, id: \.name) { strategy in
                        StrategyConfigRowView(
                            strategy: strategy,
                            isActive: true,
                            onToggle: { strategyManager.disableStrategy(named: strategy.name) },
                            onConfigure: {
                                selectedStrategy = strategy
                                showingParameterSheet = true
                            }
                        )
                    }
                    
                    if strategyManager.activeStrategies.isEmpty {
                        Text("No active strategies")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                // Available Strategies Section
                Section("Available Strategies") {
                    ForEach(strategyManager.strategies.filter { !$0.isEnabled }, id: \.name) { strategy in
                        StrategyConfigRowView(
                            strategy: strategy,
                            isActive: false,
                            onToggle: { strategyManager.enableStrategy(named: strategy.name) },
                            onConfigure: {
                                selectedStrategy = strategy
                                showingParameterSheet = true
                            }
                        )
                    }
                }
                
                // Risk Management Section
                Section("Risk Management") {
                    NavigationLink("Risk Parameters") {
                        RiskParametersView()
                    }
                    
                    NavigationLink("Position Sizing") {
                        PositionSizingView()
                    }
                }
                
                // Strategy Performance Section
                Section("Performance") {
                    NavigationLink("Strategy Analytics") {
                        StrategyAnalyticsView()
                    }
                    
                    NavigationLink("Backtest Results") {
                        BacktestResultsView()
                    }
                }
            }
            .navigationTitle("Strategy Configuration")
            .onAppear {
                // Force refresh of strategies
                strategyManager.objectWillChange.send()
            }
            .sheet(isPresented: $showingParameterSheet) {
                if let strategy = selectedStrategy {
                    StrategyParametersSheet(strategy: strategy)
                }
            }
        }
    }
}

struct StrategyConfigRowView: View {
    let strategy: any Strategy
    let isActive: Bool
    let onToggle: () -> Void
    let onConfigure: () -> Void
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(strategy.name)
                        .font(.headline)
                    
                    Text(strategy.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text("Weight: \(String(format: "%.1f", strategy.weight))")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        
                        if isActive {
                            Text("ACTIVE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button(action: { showingDetails.toggle() }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: onConfigure) {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: onToggle) {
                        Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                            .foregroundColor(isActive ? .orange : .green)
                    }
                }
            }
            
            if showingDetails {
                StrategyDetailView(strategy: strategy)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .slide))
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.3), value: showingDetails)
    }
}

struct StrategyDetailView: View {
    let strategy: any Strategy
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("What it does:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(getStrategyDetails(for: strategy).whatItDoes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Best used when:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(getStrategyDetails(for: strategy).bestUsedWhen)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Good for:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(getStrategyDetails(for: strategy).goodFor)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Timeframe", systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(getStrategyDetails(for: strategy).timeframe)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Risk Level", systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(getStrategyDetails(for: strategy).riskLevel)
                    .font(.caption2)
                    .foregroundColor(getRiskColor(for: getStrategyDetails(for: strategy).riskLevel))
            }
            
            // Performance indicators
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Win Rate")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(getStrategyPerformance(for: strategy).winRate)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg Return")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(getStrategyPerformance(for: strategy).avgReturn)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Max Drawdown")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(getStrategyPerformance(for: strategy).maxDrawdown)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func getRiskColor(for riskLevel: String) -> Color {
        switch riskLevel.lowercased() {
        case "low": return .green
        case "medium": return .orange
        case "high": return .red
        default: return .secondary
        }
    }
}

struct StrategyDetails {
    let whatItDoes: String
    let bestUsedWhen: String
    let goodFor: String
    let timeframe: String
    let riskLevel: String
}

struct StrategyPerformance {
    let winRate: String
    let avgReturn: String
    let maxDrawdown: String
}

func getStrategyDetails(for strategy: any Strategy) -> StrategyDetails {
    switch strategy.name {
    case "RSI":
        return StrategyDetails(
            whatItDoes: "Measures momentum by comparing recent gains to losses. Identifies overbought (>70) and oversold (<30) conditions to signal potential reversals.",
            bestUsedWhen: "Markets are ranging or showing clear overbought/oversold conditions. Works best in sideways markets with regular bounces.",
            goodFor: "Swing trading, reversal trading, and identifying entry/exit points in ranging markets. Great for catching pullbacks in trends.",
            timeframe: "15m - 4h",
            riskLevel: "Low"
        )
        
    case "EMA":
        return StrategyDetails(
            whatItDoes: "Uses exponential moving averages to identify trend direction. Generates signals when fast EMA crosses above/below slow EMA.",
            bestUsedWhen: "Strong trending markets with clear directional movement. Avoid during choppy, sideways markets.",
            goodFor: "Trend following, momentum trading, and catching major market moves. Excellent for riding strong trends.",
            timeframe: "1h - 1d",
            riskLevel: "Medium"
        )
        
    case "MACD":
        return StrategyDetails(
            whatItDoes: "Combines trend-following and momentum indicators. Uses MACD line crossovers and histogram to identify trend changes and momentum shifts.",
            bestUsedWhen: "Markets transitioning between trends or showing momentum changes. Works well in both trending and ranging conditions.",
            goodFor: "Trend reversal detection, momentum confirmation, and timing entries/exits. Great for confirming other signals.",
            timeframe: "30m - 4h",
            riskLevel: "Medium"
        )
        
    case "Mean Reversion":
        return StrategyDetails(
            whatItDoes: "Assumes prices will return to their average over time. Buys when price is below average and sells when above average.",
            bestUsedWhen: "Stable, ranging markets with regular price oscillations around a mean. Avoid during strong trending periods.",
            goodFor: "Range trading, scalping in stable markets, and profiting from price normalization. Works well in low volatility environments.",
            timeframe: "5m - 1h",
            riskLevel: "Medium"
        )
        
    case "Breakout":
        return StrategyDetails(
            whatItDoes: "Identifies when price breaks through key support/resistance levels with volume confirmation. Trades in the direction of the breakout.",
            bestUsedWhen: "Markets are consolidating near key levels or showing signs of volatility expansion. Best during news events or market catalysts.",
            goodFor: "Capturing large moves, trading news events, and profiting from volatility expansion. Excellent for momentum trading.",
            timeframe: "15m - 1h",
            riskLevel: "High"
        )
        
    case "Bollinger Bands":
        return StrategyDetails(
            whatItDoes: "Uses standard deviation bands around a moving average. Trades mean reversion when price touches bands and breakouts when bands expand.",
            bestUsedWhen: "Markets showing volatility contractions followed by expansions. Works in both trending and ranging conditions.",
            goodFor: "Volatility trading, mean reversion in ranging markets, and breakout trading when volatility expands.",
            timeframe: "30m - 4h",
            riskLevel: "Medium"
        )
        
    case "Stochastic":
        return StrategyDetails(
            whatItDoes: "Compares closing price to price range over time. Identifies overbought (>80) and oversold (<20) conditions for reversal signals.",
            bestUsedWhen: "Ranging markets with clear support/resistance levels. Most effective when combined with trend analysis.",
            goodFor: "Timing entries in ranging markets, identifying reversal points, and confirming other oscillator signals.",
            timeframe: "15m - 2h",
            riskLevel: "Low"
        )
        
    case "Williams %R":
        return StrategyDetails(
            whatItDoes: "Momentum oscillator that measures overbought/oversold levels. Similar to Stochastic but more sensitive to recent price action.",
            bestUsedWhen: "Fast-moving markets where quick reversal signals are needed. Works best in volatile, ranging conditions.",
            goodFor: "Short-term trading, scalping, and quick reversal plays. Excellent for active traders seeking fast signals.",
            timeframe: "5m - 1h",
            riskLevel: "Medium"
        )
        
    case "ADX":
        return StrategyDetails(
            whatItDoes: "Measures trend strength without indicating direction. Values >25 indicate strong trends, <20 suggest weak/ranging markets.",
            bestUsedWhen: "Confirming trend strength before entering trades. Use with directional indicators for complete picture.",
            goodFor: "Trend confirmation, avoiding false breakouts, and determining when to use trend-following vs mean-reversion strategies.",
            timeframe: "1h - 1d",
            riskLevel: "Low"
        )
        
    case "Ichimoku":
        return StrategyDetails(
            whatItDoes: "Comprehensive system using multiple timeframes to identify trend, support/resistance, and momentum. Provides complete market picture.",
            bestUsedWhen: "All market conditions, but especially effective in trending markets. Cloud provides dynamic support/resistance.",
            goodFor: "Complete market analysis, trend identification, and multi-timeframe trading. Excellent for position trading.",
            timeframe: "4h - 1d",
            riskLevel: "Medium"
        )
        
    case "Parabolic SAR":
        return StrategyDetails(
            whatItDoes: "Trend-following indicator that provides stop-loss levels. Dots below price indicate uptrend, above indicate downtrend.",
            bestUsedWhen: "Strong trending markets with minimal consolidation. Avoid during sideways, choppy market conditions.",
            goodFor: "Trend following, trailing stops, and staying in trends longer. Great for capturing extended moves.",
            timeframe: "1h - 1d",
            riskLevel: "Medium"
        )
        
    case "Volume":
        return StrategyDetails(
            whatItDoes: "Analyzes volume patterns to confirm price movements. High volume confirms moves, low volume suggests weak moves.",
            bestUsedWhen: "Confirming breakouts, trend changes, or significant price movements. Always use with price action.",
            goodFor: "Confirming signals from other strategies, validating breakouts, and identifying institutional activity.",
            timeframe: "15m - 4h",
            riskLevel: "Low"
        )
        
    case "Scalping":
        return StrategyDetails(
            whatItDoes: "High-frequency strategy targeting small, quick profits. Uses fast EMAs and volume to identify short-term momentum.",
            bestUsedWhen: "High liquidity markets with tight spreads. Best during active trading sessions with good volatility.",
            goodFor: "Quick profits, active trading, and capitalizing on small price movements. Requires constant monitoring.",
            timeframe: "1m - 15m",
            riskLevel: "High"
        )
        
    case "Swing Trading":
        return StrategyDetails(
            whatItDoes: "Captures multi-day price swings using trend analysis and momentum indicators. Holds positions for days to weeks.",
            bestUsedWhen: "Markets showing clear swing patterns with regular highs and lows. Works in both trending and ranging markets.",
            goodFor: "Part-time trading, capturing larger moves, and reduced transaction costs. Perfect for busy professionals.",
            timeframe: "4h - 1d",
            riskLevel: "Medium"
        )
        
    case "Grid Trading":
        return StrategyDetails(
            whatItDoes: "Places buy/sell orders at regular intervals above and below current price. Profits from price oscillations within a range.",
            bestUsedWhen: "Ranging, sideways markets with regular price oscillations. Avoid during strong trending periods.",
            goodFor: "Automated trading, ranging markets, and generating consistent small profits. Works well in stable pairs.",
            timeframe: "1h - 4h",
            riskLevel: "High"
        )
        
    default:
        return StrategyDetails(
            whatItDoes: "Custom trading strategy with specific parameters and logic.",
            bestUsedWhen: "Market conditions align with strategy parameters.",
            goodFor: "Specific trading scenarios based on strategy design.",
            timeframe: "Variable",
            riskLevel: "Medium"
        )
    }
}

func getStrategyPerformance(for strategy: any Strategy) -> StrategyPerformance {
    // These would typically come from backtesting data or live performance tracking
    // For now, providing realistic estimates based on strategy characteristics
    switch strategy.name {
    case "RSI":
        return StrategyPerformance(winRate: "68%", avgReturn: "1.2%", maxDrawdown: "-8%")
    case "EMA":
        return StrategyPerformance(winRate: "62%", avgReturn: "2.1%", maxDrawdown: "-12%")
    case "MACD":
        return StrategyPerformance(winRate: "65%", avgReturn: "1.8%", maxDrawdown: "-10%")
    case "Mean Reversion":
        return StrategyPerformance(winRate: "72%", avgReturn: "0.9%", maxDrawdown: "-6%")
    case "Breakout":
        return StrategyPerformance(winRate: "45%", avgReturn: "3.2%", maxDrawdown: "-18%")
    case "Bollinger Bands":
        return StrategyPerformance(winRate: "70%", avgReturn: "1.5%", maxDrawdown: "-9%")
    case "Stochastic":
        return StrategyPerformance(winRate: "66%", avgReturn: "1.3%", maxDrawdown: "-7%")
    case "Williams %R":
        return StrategyPerformance(winRate: "58%", avgReturn: "1.7%", maxDrawdown: "-11%")
    case "ADX":
        return StrategyPerformance(winRate: "71%", avgReturn: "1.1%", maxDrawdown: "-5%")
    case "Ichimoku":
        return StrategyPerformance(winRate: "64%", avgReturn: "2.3%", maxDrawdown: "-13%")
    case "Parabolic SAR":
        return StrategyPerformance(winRate: "59%", avgReturn: "2.0%", maxDrawdown: "-14%")
    case "Volume":
        return StrategyPerformance(winRate: "73%", avgReturn: "0.8%", maxDrawdown: "-4%")
    case "Scalping":
        return StrategyPerformance(winRate: "52%", avgReturn: "0.3%", maxDrawdown: "-3%")
    case "Swing Trading":
        return StrategyPerformance(winRate: "61%", avgReturn: "2.8%", maxDrawdown: "-16%")
    case "Grid Trading":
        return StrategyPerformance(winRate: "78%", avgReturn: "1.0%", maxDrawdown: "-22%")
    default:
        return StrategyPerformance(winRate: "N/A", avgReturn: "N/A", maxDrawdown: "N/A")
    }
}

#Preview {
    StrategyConfigurationView()
}

// Placeholder views for navigation
struct RiskParametersView: View {
    var body: some View {
        Text("Risk Parameters Configuration")
            .navigationTitle("Risk Parameters")
    }
}

struct PositionSizingView: View {
    var body: some View {
        Text("Position Sizing Configuration")
            .navigationTitle("Position Sizing")
    }
}

struct StrategyAnalyticsView: View {
    var body: some View {
        Text("Strategy Analytics")
            .navigationTitle("Analytics")
    }
}

struct BacktestResultsView: View {
    var body: some View {
        Text("Backtest Results")
            .navigationTitle("Backtest Results")
    }
}

struct StrategyParametersSheet: View {
    let strategy: any Strategy
    @Environment(\.dismiss) private var dismiss
    @StateObject private var strategyManager = StrategyManager.shared
    
    @State private var weight: Double
    @State private var parameters: [String: Any] = [:]
    
    init(strategy: any Strategy) {
        self.strategy = strategy
        self._weight = State(initialValue: strategy.weight)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("General Settings") {
                    VStack(alignment: .leading) {
                        Text("Strategy Weight")
                        Slider(value: $weight, in: 0.1...2.0, step: 0.1)
                        Text("\(String(format: "%.1f", weight))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Strategy Parameters") {
                    Text("Strategy-specific parameters will be available in a future update")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(strategy.description)
                            .font(.body)
                        
                        Text("Required Candles")
                            .font(.headline)
                        Text("\(strategy.requiredCandles())")
                            .font(.body)
                    }
                }
            }
            .navigationTitle(strategy.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveParameters()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveParameters() {
        strategyManager.updateStrategyWeight(named: strategy.name, weight: weight)
        
        // Save strategy-specific parameters
        for (key, value) in parameters {
            strategyManager.updateStrategyParameter(
                strategyName: strategy.name,
                parameter: key,
                value: value
            )
        }
    }
}

struct StrategyGuideView: View {
    @State private var showingFullGuide = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Quick Strategy Tips")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { showingFullGuide.toggle() }) {
                    Text(showingFullGuide ? "Less" : "More")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                StrategyTipRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Trending Markets",
                    description: "Use EMA, MACD, Parabolic SAR, Ichimoku",
                    color: .green
                )
                
                StrategyTipRow(
                    icon: "arrow.left.and.right",
                    title: "Ranging Markets",
                    description: "Use RSI, Bollinger Bands, Stochastic, Mean Reversion",
                    color: .blue
                )
                
                StrategyTipRow(
                    icon: "bolt.fill",
                    title: "High Volatility",
                    description: "Use Breakout, Volume, Scalping strategies",
                    color: .orange
                )
                
                if showingFullGuide {
                    Divider()
                        .padding(.vertical, 4)
                    
                    StrategyTipRow(
                        icon: "clock",
                        title: "Short-term (1m-15m)",
                        description: "Scalping, Williams %R, Volume analysis",
                        color: .red
                    )
                    
                    StrategyTipRow(
                        icon: "calendar",
                        title: "Long-term (4h-1d)",
                        description: "Swing Trading, Ichimoku, ADX, Parabolic SAR",
                        color: .purple
                    )
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    Text("Recommended Combinations:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.top, 4)
                    
                    StrategyTipRow(
                        icon: "1.circle.fill",
                        title: "Conservative Portfolio",
                        description: "RSI + Bollinger Bands + ADX (trend confirmation)",
                        color: .green
                    )
                    
                    StrategyTipRow(
                        icon: "2.circle.fill",
                        title: "Aggressive Growth",
                        description: "EMA + MACD + Breakout + Volume",
                        color: .orange
                    )
                    
                    StrategyTipRow(
                        icon: "3.circle.fill",
                        title: "Balanced Approach",
                        description: "Ichimoku + Stochastic + Swing Trading",
                        color: .blue
                    )
                    
                    StrategyTipRow(
                        icon: "shield.fill",
                        title: "Risk Management",
                        description: "Never risk more than 2% per trade, use stop losses",
                        color: .gray
                    )
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: showingFullGuide)
    }
}

struct StrategyTipRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}