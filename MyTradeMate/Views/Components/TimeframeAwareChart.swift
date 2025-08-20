import SwiftUI
import Charts

/// Chart component that integrates with TimeframeStore for loading states
/// Shows skeleton loading during timeframe changes and data refresh
struct TimeframeAwareChart: View {
    @StateObject private var timeframeStore = TimeframeStore.shared
    let height: CGFloat
    let showHeader: Bool
    
    init(height: CGFloat = 300, showHeader: Bool = true) {
        self.height = height
        self.showHeader = showHeader
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Chart Header
            if showHeader {
                ChartHeader()
            }
            
            // Chart Content with Loading State
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .frame(height: height)
                
                if timeframeStore.isLoading {
                    // Skeleton loading state
                    ChartSkeleton(height: height)
                } else if !timeframeStore.currentCandles.isEmpty {
                    // Actual chart
                    CandlestickChartView(data: candlePoints)
                        .frame(height: height)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    // Empty state
                    ChartEmptyState()
                        .frame(height: height)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: timeframeStore.isLoading)
            .animation(.easeInOut(duration: 0.4), value: timeframeStore.currentCandles.count)
        }
    }
    
    // Convert candles to chart format
    private var candlePoints: [CandlePoint] {
        timeframeStore.currentCandles.map { candle in
            CandlePoint(
                time: candle.openTime,
                open: candle.open,
                high: candle.high,
                low: candle.low,
                close: candle.close
            )
        }
    }
}

/// Chart header with price and change information
struct ChartHeader: View {
    @StateObject private var timeframeStore = TimeframeStore.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("BTC/USDT")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    TimeframeDisplay()
                }
                
                if timeframeStore.isLoading {
                    // Loading skeleton
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 24)
                        .cornerRadius(6)
                        .shimmer()
                } else {
                    Text("$\(String(format: "%.2f", timeframeStore.currentPrice))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if timeframeStore.isLoading {
                    // Loading skeleton for price change
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 18)
                        .cornerRadius(4)
                        .shimmer()
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: timeframeStore.priceChangePercent >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                        
                        Text(timeframeStore.priceChangeString)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(timeframeStore.priceChangePercent >= 0 ? .green : .red)
                }
                
                Text("24h")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Empty state for chart when no data is available
struct ChartEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Chart Data")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Market data is currently unavailable")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Retry") {
                Task {
                    await TimeframeStore.shared.refreshCurrentTimeframe()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

/// Compact chart variant for smaller spaces
struct CompactTimeframeAwareChart: View {
    @StateObject private var timeframeStore = TimeframeStore.shared
    let height: CGFloat
    
    init(height: CGFloat = 200) {
        self.height = height
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Compact header
            HStack {
                HStack(spacing: 4) {
                    Text("BTC/USDT")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TimeframeDisplay()
                }
                
                Spacer()
                
                if !timeframeStore.isLoading {
                    Text("$\(String(format: "%.0f", timeframeStore.currentPrice))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                }
            }
            
            // Compact chart
            ZStack {
                if timeframeStore.isLoading {
                    ChartSkeleton(height: height)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if !timeframeStore.currentCandles.isEmpty {
                    CandlestickChartView(data: candlePoints)
                        .frame(height: height)
                        .transition(.opacity)
                } else {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .frame(height: height)
                        .overlay(
                            Text("No Data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: timeframeStore.isLoading)
        }
    }
    
    private var candlePoints: [CandlePoint] {
        timeframeStore.currentCandles.map { candle in
            CandlePoint(
                time: candle.openTime,
                open: candle.open,
                high: candle.high,
                low: candle.low,
                close: candle.close
            )
        }
    }
}

#Preview("Timeframe-Aware Charts") {
    ScrollView {
        VStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Full Chart with Header")
                    .font(.headline)
                
                TimeframeAwareChart()
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Chart without Header")
                    .font(.headline)
                
                TimeframeAwareChart(showHeader: false)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Compact Chart")
                    .font(.headline)
                
                CompactTimeframeAwareChart()
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Custom Height Chart")
                    .font(.headline)
                
                TimeframeAwareChart(height: 400)
            }
        }
        .padding()
    }
}