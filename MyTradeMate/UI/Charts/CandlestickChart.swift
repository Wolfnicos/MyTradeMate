import SwiftUI
import Charts

/// Enhanced candlestick chart with volume and interactive features
struct CandlestickChart: View {
    let candles: [Candle]
    let timeframe: Timeframe
    @State private var selectedCandle: Candle?
    @State private var showVolume: Bool = true
    @State private var chartScale: CGFloat = 1.0
    @State private var chartOffset: CGSize = .zero
    
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            if candles.isEmpty {
                emptyStateView
            } else {
                chartHeaderView
                mainChartView
                if showVolume {
                    volumeChartView
                }
                chartControlsView
                
                // Chart legend to clarify meanings
                chartLegendView
            }
        }
        .themedBackground()
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(themeManager.secondaryColor)
            
            Text("No Chart Data")
                .font(.title2)
                .fontWeight(.medium)
                .themedForeground()
            
            Text("Market data is loading or unavailable")
                .font(.caption)
                .themedSecondaryForeground()
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Chart Header
    
    private var chartHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Price Chart")
                    .font(.headline)
                    .themedForeground()
                
                if let selectedCandle = selectedCandle {
                    candleInfoView(selectedCandle)
                } else if let lastCandle = candles.last {
                    candleInfoView(lastCandle)
                }
            }
            
            Spacer()
            
            chartOptionsView
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func candleInfoView(_ candle: Candle) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Enhanced header with tooltip explanation
            HStack {
                Text("OHLC Data")
                    .font(.caption)
                    .fontWeight(.medium)
                    .themedSecondaryForeground()
                
                Spacer()
                
                Text("Tap candles for details")
                    .font(.caption2)
                    .themedSecondaryForeground()
                    .opacity(0.7)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Open: \(candle.open, specifier: "%.2f")")
                        .font(.caption)
                        .themedSecondaryForeground()
                    Text("High: \(candle.high, specifier: "%.2f")")
                        .font(.caption)
                        .themedSecondaryForeground()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Low: \(candle.low, specifier: "%.2f")")
                        .font(.caption)
                        .themedSecondaryForeground()
                    Text("Close: \(candle.close, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(candle.close >= candle.open ? themeManager.candleUpColor : themeManager.candleDownColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Volume: \(formatVolume(candle.volume))")
                        .font(.caption)
                        .themedSecondaryForeground()
                    Text(formatTime(candle.openTime))
                        .font(.caption)
                        .themedSecondaryForeground()
                }
            }
        }
    }
    
    private var chartOptionsView: some View {
        HStack(spacing: 12) {
            Button(action: { showVolume.toggle() }) {
                Image(systemName: showVolume ? "chart.bar.fill" : "chart.bar")
                    .font(.system(size: 16))
                    .foregroundColor(showVolume ? themeManager.accentColor : themeManager.secondaryColor)
            }
            
            Button(action: resetZoom) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.secondaryColor)
            }
        }
    }
    
    // MARK: - Main Chart
    
    private var mainChartView: some View {
        Chart {
            ForEach(Array(candles.enumerated()), id: \.offset) { index, candle in
                // Validate candle data before rendering
                let validatedCandle = validateCandleData(candle)
                
                // Candlestick body
                RectangleMark(
                    x: .value("Time", validatedCandle.openTime),
                    yStart: .value("Open", min(validatedCandle.open, validatedCandle.close)),
                    yEnd: .value("Close", max(validatedCandle.open, validatedCandle.close)),
                    width: .fixed(candleWidth)
                )
                .foregroundStyle(validatedCandle.close >= validatedCandle.open ? themeManager.candleUpColor : themeManager.candleDownColor)
                .opacity(selectedCandle?.id == validatedCandle.id ? 0.8 : 1.0)
                
                // Candlestick wick
                RectangleMark(
                    x: .value("Time", validatedCandle.openTime),
                    yStart: .value("Low", validatedCandle.low),
                    yEnd: .value("High", validatedCandle.high),
                    width: .fixed(1.0)
                )
                .foregroundStyle(validatedCandle.close >= validatedCandle.open ? themeManager.candleUpColor : themeManager.candleDownColor)
                .opacity(selectedCandle?.id == validatedCandle.id ? 0.8 : 1.0)
            }
            
            // Selection indicator
            if let selectedCandle = selectedCandle {
                RuleMark(x: .value("Selected", selectedCandle.openTime))
                    .foregroundStyle(themeManager.accentColor.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(themeManager.secondaryColor.opacity(0.3))
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(themeManager.secondaryColor)
                AxisValueLabel(format: .dateTime.hour().minute())
                    .foregroundStyle(themeManager.secondaryColor)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 6)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(themeManager.secondaryColor.opacity(0.3))
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(themeManager.secondaryColor)
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text("$\(price, specifier: "%.2f")")
                            .font(.caption2)
                            .foregroundStyle(themeManager.secondaryColor)
                    }
                }
            }
        }
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleChartTap(at: location, in: geometry, chartProxy: chartProxy)
                    }
                    .scaleEffect(chartScale)
                    .offset(chartOffset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    chartScale = max(0.5, min(3.0, value))
                                },
                            DragGesture()
                                .onChanged { value in
                                    chartOffset = value.translation
                                }
                        )
                    )
            }
        }
        .themedCardBackground()
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // MARK: - Volume Chart
    
    private var volumeChartView: some View {
        Chart {
            ForEach(candles, id: \.id) { candle in
                // Validate candle data before rendering
                let validatedCandle = validateCandleData(candle)
                
                BarMark(
                    x: .value("Time", validatedCandle.openTime),
                    y: .value("Volume", validatedCandle.volume),
                    width: .fixed(candleWidth * 0.8)
                )
                .foregroundStyle(
                    validatedCandle.close >= validatedCandle.open ? 
                    themeManager.candleUpColor.opacity(0.6) : 
                    themeManager.candleDownColor.opacity(0.6)
                )
                .opacity(selectedCandle?.id == validatedCandle.id ? 1.0 : 0.7)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(themeManager.secondaryColor.opacity(0.2))
                AxisValueLabel {
                    if let volume = value.as(Double.self) {
                        Text(formatVolume(volume))
                            .font(.caption2)
                            .foregroundStyle(themeManager.secondaryColor)
                    }
                }
            }
        }
        .themedCardBackground()
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 4)
    }
    
    // MARK: - Chart Controls
    
    private var chartControlsView: some View {
        HStack {
            Text("Timeframe: \(timeframe.displayName)")
                .font(.caption)
                .themedSecondaryForeground()
            
            Spacer()
            
            if !candles.isEmpty {
                Text("\(candles.count) candles")
                    .font(.caption)
                    .themedSecondaryForeground()
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Chart Legend
    
    private var chartLegendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chart Legend")
                .font(.caption)
                .fontWeight(.medium)
                .themedSecondaryForeground()
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(themeManager.candleUpColor)
                        .frame(width: 8, height: 8)
                    Text("Bullish Candle")
                        .font(.caption2)
                        .themedSecondaryForeground()
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(themeManager.candleDownColor)
                        .frame(width: 8, height: 8)
                    Text("Bearish Candle")
                        .font(.caption2)
                        .themedSecondaryForeground()
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 8, height: 8)
                    Text("Volume")
                        .font(.caption2)
                        .themedSecondaryForeground()
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 10))
                        .themedSecondaryForeground()
                    Text("Price Range")
                        .font(.caption2)
                        .themedSecondaryForeground()
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Helper Methods
    
    /// Validates candle data to prevent chart rendering errors
    private func validateCandleData(_ candle: Candle) -> Candle {
        // Define safe default values
        let safeDefault = 50000.0 // Safe fallback price
        let safeVolumeDefault = 100.0 // Safe fallback volume
        
        // Validate and sanitize each price component
        let safeOpen = candle.open.isNaN || candle.open.isInfinite || candle.open <= 0 ? safeDefault : candle.open
        let safeHigh = candle.high.isNaN || candle.high.isInfinite || candle.high <= 0 ? safeDefault : candle.high
        let safeLow = candle.low.isNaN || candle.low.isInfinite || candle.low <= 0 ? safeDefault : candle.low
        let safeClose = candle.close.isNaN || candle.close.isInfinite || candle.close <= 0 ? safeDefault : candle.close
        let safeVolume = candle.volume.isNaN || candle.volume.isInfinite || candle.volume < 0 ? safeVolumeDefault : candle.volume
        
        // Ensure high >= low logic for proper candlestick rendering
        let validatedHigh = max(safeHigh, safeLow, safeOpen, safeClose)
        let validatedLow = min(safeLow, safeHigh, safeOpen, safeClose)
        
        return Candle(
            openTime: candle.openTime,
            open: safeOpen,
            high: validatedHigh,
            low: validatedLow,
            close: safeClose,
            volume: safeVolume
        )
    }
    
    private var candleWidth: CGFloat {
        let baseWidth: CGFloat = 8
        let scaledWidth = baseWidth / chartScale
        return max(2, min(20, scaledWidth))
    }
    
    private func handleChartTap(at location: CGPoint, in geometry: GeometryProxy, chartProxy: ChartProxy) {
        // Find the closest candle to the tap location
        let frame = geometry.frame(in: .local)
        let relativeX = location.x / frame.width
        
        if !candles.isEmpty {
            let index = Int(relativeX * CGFloat(candles.count))
            let clampedIndex = max(0, min(candles.count - 1, index))
            selectedCandle = candles[clampedIndex]
            
            // Haptic feedback
            if AppSettings.shared.haptics {
                Haptics.playSelection()
            }
        }
    }
    
    private func resetZoom() {
        withAnimation(.easeInOut(duration: 0.3)) {
            chartScale = 1.0
            chartOffset = .zero
        }
        selectedCandle = nil
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.1fK", volume / 1_000)
        } else {
            return String(format: "%.0f", volume)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = timeframe.timeFormat
        return formatter.string(from: date)
    }
}

// MARK: - Timeframe Extension

extension Timeframe {
    var timeFormat: String {
        switch self {
        case .m1: return "HH:mm:ss"      // More precision for 1-minute
        case .m5: return "HH:mm"
        case .m15: return "HH:mm"        // 15-minute timeframe
        case .h1: return "HH:mm"
        case .h4: return "MMM dd HH:mm"
        }
    }
}

// MARK: - Preview

#Preview {
    CandlestickChart(
        candles: [
            Candle(openTime: Date(), open: 100, high: 110, low: 95, close: 105, volume: 1000),
            Candle(openTime: Date().addingTimeInterval(300), open: 105, high: 115, low: 100, close: 110, volume: 1200),
            Candle(openTime: Date().addingTimeInterval(600), open: 110, high: 120, low: 105, close: 115, volume: 800)
        ],
        timeframe: .m5
    )
    .padding()
}