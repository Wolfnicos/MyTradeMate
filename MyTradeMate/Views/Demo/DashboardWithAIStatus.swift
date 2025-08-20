import SwiftUI

/// Demo Dashboard showing AIStatusBar integration
/// Demonstrates P0-5 placement: under ModeChip, above SegmentedTimeframe
struct DashboardWithAIStatus: View {
    @StateObject private var timeframeStore = TimeframeStore.shared
    @StateObject private var tradingModeStore = TradingModeStore.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and mode chip
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Dashboard")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("Real-time trading insights")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Trading mode chip (read-only)
                            ReadOnlyModeChip()
                        }
                        
                        // AI Status Bar (new placement)
                        AIStatusBar()
                        
                        // Timeframe selector
                        TimeframeSelector()
                    }
                    .padding(.horizontal)
                    
                    // Chart section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Price Chart")
                                .font(.headline)
                            
                            Spacer()
                            
                            // Compact AI status for reference
                            CompactAIStatusBar()
                        }
                        
                        TimeframeAwareChart(height: 300)
                    }
                    .padding(.horizontal)
                    
                    // Metrics section with AI integration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI-Powered Metrics")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            AIMetricCard(
                                title: "Signal Strength",
                                value: "Strong Buy",
                                confidence: 0.73,
                                icon: "brain.head.profile"
                            )
                            
                            AIMetricCard(
                                title: "Risk Level",
                                value: "Medium",
                                confidence: 0.65,
                                icon: "shield.lefthalf.filled"
                            )
                            
                            AIMetricCard(
                                title: "Market Trend",
                                value: "Bullish",
                                confidence: 0.81,
                                icon: "arrow.up.right"
                            )
                            
                            AIMetricCard(
                                title: "Volatility",
                                value: "Low",
                                confidence: 0.58,
                                icon: "waveform.path"
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Integration status
                    IntegrationStatusView()
                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationBarHidden(true)
            .withAIStatusIntegration()
        }
    }
}

/// AI-powered metric card showing confidence levels
struct AIMetricCard: View {
    let title: String
    let value: String
    let confidence: Double
    let icon: String
    
    @StateObject private var aiStatusStore = AIStatusStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and confidence
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Spacer()
                
                // AI status indicator
                AIStatusIndicator(
                    status: aiStatusStore.status,
                    size: .small
                )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if aiStatusStore.status.state == .updating {
                    // Loading state
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 18)
                        .cornerRadius(4)
                        .shimmer()
                } else {
                    Text(value)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // Confidence bar
                HStack(spacing: 4) {
                    Text("\(Int(confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 2)
                            
                            Rectangle()
                                .fill(confidenceColor)
                                .frame(width: geometry.size.width * confidence, height: 2)
                        }
                    }
                    .frame(height: 2)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var confidenceColor: Color {
        if confidence >= 0.7 {
            return .green
        } else if confidence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

/// Integration status view for debugging
struct IntegrationStatusView: View {
    @StateObject private var aiStatusStore = AIStatusStore.shared
    @StateObject private var timeframeStore = TimeframeStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Integration Status")
                .font(.headline)
            
            VStack(spacing: 12) {
                StatusRow(
                    title: "AI Status Updates",
                    status: aiStatusStore.status.state != .paused,
                    details: "Updates within 1s after timeframe loads"
                )
                
                StatusRow(
                    title: "Timeframe Integration",
                    status: !timeframeStore.isLoading,
                    details: "AI refreshes after timeframe change"
                )
                
                StatusRow(
                    title: "Error Handling",
                    status: aiStatusStore.status.state != .error(""),
                    details: "Retry button works, telemetry logged"
                )
                
                StatusRow(
                    title: "Accessibility",
                    status: true,
                    details: "VoiceOver support with confidence levels"
                )
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
}

struct StatusRow: View {
    let title: String
    let status: Bool
    let details: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(status ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    DashboardWithAIStatus()
}