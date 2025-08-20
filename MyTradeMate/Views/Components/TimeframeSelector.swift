import SwiftUI

/// Timeframe selector that integrates with TimeframeStore
/// Provides loading states, error handling, and haptic feedback
struct TimeframeSelector: View {
    @StateObject private var timeframeStore = TimeframeStore.shared
    let timeframes: [Timeframe]
    let isCompact: Bool
    
    init(
        timeframes: [Timeframe] = Timeframe.allCases,
        isCompact: Bool = false
    ) {
        self.timeframes = timeframes
        self.isCompact = isCompact
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Timeframe selector with loading state
            SegmentedTimeframeWithLoading(
                selection: Binding(
                    get: { timeframeStore.selectedTimeframe },
                    set: { newTimeframe in
                        Task {
                            await timeframeStore.changeTimeframe(to: newTimeframe)
                        }
                    }
                ),
                isLoading: timeframeStore.isLoading,
                timeframes: timeframes
            )
            
            // Error message
            if let error = timeframeStore.loadingError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Retry button
                    Button("Retry") {
                        Task {
                            await timeframeStore.refreshCurrentTimeframe()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Last updated info (compact only)
            if !isCompact, let lastUpdated = timeframeStore.lastUpdated {
                HStack {
                    Text("Updated \(timeAgoString(from: lastUpdated))")
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                    
                    Spacer()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: timeframeStore.isLoading)
        .animation(.easeInOut(duration: 0.3), value: timeframeStore.loadingError != nil)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 10 {
            return "just now"
        } else if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        }
    }
}

/// Compact timeframe selector for use in toolbars
struct CompactTimeframeSelector: View {
    @StateObject private var timeframeStore = TimeframeStore.shared
    
    var body: some View {
        TimeframeSelector(isCompact: true)
    }
}

/// Simple timeframe display (read-only)
struct TimeframeDisplay: View {
    @StateObject private var timeframeStore = TimeframeStore.shared
    
    var body: some View {
        HStack(spacing: 4) {
            if timeframeStore.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
            }
            
            Text(timeframeStore.selectedTimeframe.displayName)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
            
            if timeframeStore.loadingError != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(6)
    }
}

#Preview("Timeframe Selectors") {
    VStack(spacing: 32) {
        VStack(alignment: .leading, spacing: 16) {
            Text("Full Timeframe Selector")
                .font(.headline)
            
            TimeframeSelector()
        }
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Compact Timeframe Selector")
                .font(.headline)
            
            CompactTimeframeSelector()
        }
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Timeframe Display")
                .font(.headline)
            
            HStack {
                TimeframeDisplay()
                Spacer()
            }
        }
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Limited Timeframes")
                .font(.headline)
            
            TimeframeSelector(
                timeframes: [.m5, .m15, .h1, .h4]
            )
        }
    }
    .padding()
}