import SwiftUI

// MARK: - Signal Visualization View
struct SignalVisualizationView: View {
    let signal: SignalInfo?
    let isRefreshing: Bool
    let timeframe: Timeframe
    let tradingPair: TradingPair
    let lastUpdated: Date
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with title and refresh button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trading Signal")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Real-time market analysis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .disabled(isRefreshing)
            }
            
            if isRefreshing {
                LoadingStateView(message: "Analyzing market...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else if let signal = signal {
                SignalContentView(
                    signal: signal,
                    timeframe: timeframe,
                    lastUpdated: lastUpdated
                )
            } else {
                emptySignalView
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Empty Signal View
    private var emptySignalView: EmptyStateView {
        EmptyStateView(
            icon: "antenna.radiowaves.left.and.right",
            title: "No Signal Available",
            description: "No clear trading signal right now. The AI is monitoring market conditions.",
            useIllustration: true
        )
    }
}

// MARK: - Signal Content View
struct SignalContentView: View {
    let signal: SignalInfo
    let timeframe: Timeframe
    let lastUpdated: Date
    
    var body: some View {
        VStack(spacing: 16) {
            // Main signal display
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // Signal direction with visual indicator
                    HStack(spacing: 12) {
                        SignalDirectionIndicator(direction: signal.direction)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(signalDisplayText)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(signalColor)
                            
                            Text(signalSubtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Confidence and metadata with source labels
                    HStack(spacing: 8) {
                        Text(confidenceDisplayText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        if let sourceLabel = extractSourceLabel() {
                            Text("•")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Text(sourceLabel)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        
                        Text("•")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text(timeframe.displayName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        if !isVeryLowConfidence {
                            Text("•")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Text(lastUpdatedString)
                                .font(.system(size: 14))
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }
                }
                
                Spacer()
                
                // Confidence gauge
                ConfidenceGaugeView(confidence: signal.confidence)
            }
            
            // Confidence bar
            ConfidenceBarView(confidence: signal.confidence, direction: signal.direction)
            
            // Signal reasoning
            if !signal.reason.isEmpty {
                SignalReasoningView(reason: signal.reason)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var signalDisplayText: String {
        // If confidence is very low (0% or close to 0), show user-friendly text
        if signal.confidence < 0.01 {
            return "No clear signal"
        }
        
        return signal.direction.uppercased()
    }
    
    private var signalSubtitle: String {
        // Deterministic subtitle format as specified: confidence: XX% • {Strategies|4h Model} • {5m|1h|4h} • BTC/USD
        let confidence = Int(signal.confidence * 100)
        let source: String
        
        switch timeframe {
        case .h4:
            source = "4h Model"
        case .m1, .m5, .m15, .h1:
            source = "Strategies"
        }
        
        return "confidence: \(confidence)% • \(source) • \(timeframe.rawValue) • BTC/USDT"
    }
    
    private var signalColor: Color {
        switch signal.direction {
        case "BUY": return .green
        case "SELL": return .red
        default: return .secondary
        }
    }
    
    private var confidenceDisplayText: String {
        // If confidence is very low (0% or close to 0), show user-friendly text
        if signal.confidence < 0.01 {
            return "Monitoring conditions"
        }
        
        return "confidence: \(Int(signal.confidence * 100))%"
    }
    
    private var isVeryLowConfidence: Bool {
        return signal.confidence < 0.01
    }
    
    /// Extract source label from signal reason (e.g., "4h Model", "Strategies")
    private func extractSourceLabel() -> String? {
        let reason = signal.reason
        
        // Look for source patterns in the reason text
        if reason.contains("4h Model") {
            return "4h Model"
        } else if reason.contains("Strategies") {
            return "Strategies"
        } else if reason.contains("Model") {
            return "AI Model"
        } else if reason.contains("Strategy") {
            return "Strategy"
        }
        
        // Fallback: try to extract text between "•" separators
        let components = reason.components(separatedBy: " • ")
        if components.count >= 2 {
            let secondComponent = components[1].trimmingCharacters(in: .whitespaces)
            if !secondComponent.isEmpty && !secondComponent.contains("confidence") {
                return secondComponent
            }
        }
        
        return nil
    }
    
    private var lastUpdatedString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
}

// MARK: - Signal Direction Indicator
struct SignalDirectionIndicator: View {
    let direction: String
    
    var body: some View {
        // Color-coded badge with text as specified
        Text(direction.uppercased())
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(badgeColor)
            .cornerRadius(8)
    }
    
    /// Color-coded badges: BUY (green), SELL (red), HOLD (gray/blue)
    private var badgeColor: Color {
        switch direction {
        case "BUY": return .green
        case "SELL": return .red
        default: return .blue  // HOLD gets blue instead of gray for better visibility
        }
    }
}

// MARK: - Confidence Gauge View
struct ConfidenceGaugeView: View {
    let confidence: Double
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: confidence)
                    .stroke(confidenceColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: confidence)
                
                Text("\(Int(confidence * 100))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(confidenceColor)
            }
            
            Text("Confidence")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var confidenceColor: Color {
        if confidence >= 0.7 {
            return .green
        } else if confidence >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Confidence Bar View
struct ConfidenceBarView: View {
    let confidence: Double
    let direction: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Signal Strength")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(strengthLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(strengthColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // Confidence bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * confidence, height: 8)
                        .animation(.easeInOut(duration: 0.8), value: confidence)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var strengthLabel: String {
        if confidence >= 0.8 {
            return "Very Strong"
        } else if confidence >= 0.6 {
            return "Strong"
        } else if confidence >= 0.4 {
            return "Moderate"
        } else if confidence >= 0.2 {
            return "Weak"
        } else {
            return "Very Weak"
        }
    }
    
    private var strengthColor: Color {
        if confidence >= 0.7 {
            return .green
        } else if confidence >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var gradientColors: [Color] {
        switch direction {
        case "BUY":
            return [.green.opacity(0.6), .green]
        case "SELL":
            return [.red.opacity(0.6), .red]
        default:
            return [.secondary.opacity(0.6), .secondary]
        }
    }
}

// MARK: - Signal Reasoning View
struct SignalReasoningView: View {
    let reason: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text("Analysis")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
            }
            
            if isExpanded {
                Text(reason)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text(reason)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 20)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Preview
struct SignalVisualizationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Strong BUY signal from AI
            SignalVisualizationView(
                signal: SignalInfo(
                    direction: "BUY",
                    confidence: 0.85,
                    reason: "BUY • 4h Model • 4h",
                    timestamp: Date()
                ),
                isRefreshing: false,
                timeframe: .h4,
                tradingPair: TradingPair.btcUsd,
                lastUpdated: Date().addingTimeInterval(-120),
                onRefresh: {}
            )
            
            // Moderate SELL signal from Strategies
            SignalVisualizationView(
                signal: SignalInfo(
                    direction: "SELL",
                    confidence: 0.67,
                    reason: "SELL • Strategies • 5m",
                    timestamp: Date()
                ),
                isRefreshing: false,
                timeframe: .m5,
                tradingPair: TradingPair.ethUsd,
                lastUpdated: Date().addingTimeInterval(-30),
                onRefresh: {}
            )
            
            // Loading state
            SignalVisualizationView(
                signal: nil,
                isRefreshing: true,
                timeframe: .h4,
                tradingPair: TradingPair.btcUsd,
                lastUpdated: Date(),
                onRefresh: {}
            )
            
            // Empty state
            SignalVisualizationView(
                signal: nil,
                isRefreshing: false,
                timeframe: .h1,
                tradingPair: TradingPair.btcUsd,
                lastUpdated: Date(),
                onRefresh: {}
            )
        }
        .padding()
        .background(Color(.systemBackground))
    }
}