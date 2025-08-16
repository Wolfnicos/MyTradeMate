import SwiftUI

// MARK: - Signal Visualization View
struct SignalVisualizationView: View {
    let signal: SignalInfo?
    let isRefreshing: Bool
    let timeframe: Timeframe
    let lastUpdated: Date
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with title and refresh button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Signal")
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
            icon: "brain",
            title: "No Signal Available",
            description: "No clear trading signal right now. The AI is monitoring market conditions."
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
                    
                    // Confidence and metadata
                    HStack(spacing: 8) {
                        Text(confidenceDisplayText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("•")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text(timeframe.displayName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text(lastUpdatedString)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
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
        switch signal.direction {
        case "BUY":
            return "Bullish signal detected"
        case "SELL":
            return "Bearish signal detected"
        default:
            return "Neutral market conditions"
        }
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
        
        return "\(Int(signal.confidence * 100))% confidence"
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
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 40, height: 40)
            
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(iconColor)
        }
    }
    
    private var backgroundColor: Color {
        switch direction {
        case "BUY": return .green.opacity(0.15)
        case "SELL": return .red.opacity(0.15)
        default: return .secondary.opacity(0.15)
        }
    }
    
    private var iconColor: Color {
        switch direction {
        case "BUY": return .green
        case "SELL": return .red
        default: return .secondary
        }
    }
    
    private var iconName: String {
        switch direction {
        case "BUY": return "arrow.up"
        case "SELL": return "arrow.down"
        default: return "minus"
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
            // Strong BUY signal
            SignalVisualizationView(
                signal: SignalInfo(
                    direction: "BUY",
                    confidence: 0.85,
                    reason: "Strong bullish momentum detected with RSI oversold conditions and positive MACD crossover. Multiple technical indicators align for upward movement.",
                    timestamp: Date()
                ),
                isRefreshing: false,
                timeframe: .h1,
                lastUpdated: Date().addingTimeInterval(-120),
                onRefresh: {}
            )
            
            // Weak SELL signal
            SignalVisualizationView(
                signal: SignalInfo(
                    direction: "SELL",
                    confidence: 0.35,
                    reason: "Bearish divergence in momentum indicators",
                    timestamp: Date()
                ),
                isRefreshing: false,
                timeframe: .m5,
                lastUpdated: Date().addingTimeInterval(-30),
                onRefresh: {}
            )
            
            // Loading state
            SignalVisualizationView(
                signal: nil,
                isRefreshing: true,
                timeframe: .h4,
                lastUpdated: Date(),
                onRefresh: {}
            )
            
            // Empty state
            SignalVisualizationView(
                signal: nil,
                isRefreshing: false,
                timeframe: .h1,
                lastUpdated: Date(),
                onRefresh: {}
            )
        }
        .padding()
        .background(Color(.systemBackground))
    }
}