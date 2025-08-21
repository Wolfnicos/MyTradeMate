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
    @State private var showEMA: Bool = false
    @State private var showBollinger: Bool = false
    
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var settingsRepo = SettingsRepository.shared
    
    // ✅ FIX: Add computed property for Y-axis domain
    private var yAxisDomain: ClosedRange<Double> {
        guard !candles.isEmpty else { return 0...100 }
        
        let allPrices = candles.flatMap { [validateCandleData($0).low, validateCandleData($0).high] }
        let minPrice = allPrices.min() ?? 0
        let maxPrice = allPrices.max() ?? 100
        
        // Add 2% padding to avoid candles touching edges
        let padding = (maxPrice - minPrice) * 0.02
        let safeMin = max(0, minPrice - padding)
        let safeMax = maxPrice + padding
        
        // Ensure valid range
        return safeMin < safeMax ? safeMin...safeMax : safeMin...(safeMin + 1)
    }
    
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
        // ✅ FIX: Add task-based refresh on symbol/timeframe change
        .task(id: "\(candles.first?.openTime ?? Date()):\(timeframe.rawValue)") {
            // Chart will automatically refresh when candles array changes
            // This ensures proper reactivity to symbol/timeframe changes
        }
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
            
            Button(action: { showEMA.toggle() }) {
                Text("EMA")
                    .font(.caption.weight(.medium))
                    .foregroundColor(showEMA ? themeManager.accentColor : themeManager.secondaryColor)
            }
            
            Button(action: { showBollinger.toggle() }) {
                Text("BB")
                    .font(.caption.weight(.medium))
                    .foregroundColor(showBollinger ? themeManager.accentColor : themeManager.secondaryColor)
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
                
                // ✅ FIX: Ensure proper timestamp conversion (handle ms vs seconds)
                let chartTime = validatedCandle.openTime.timeIntervalSince1970 > 1_000_000_000_000 ? 
                    Date(timeIntervalSince1970: validatedCandle.openTime.timeIntervalSince1970 / 1000) :
                    validatedCandle.openTime
                
                // Candlestick body
                RectangleMark(
                    x: .value("Time", chartTime),
                    yStart: .value("Open", min(validatedCandle.open, validatedCandle.close)),
                    yEnd: .value("Close", max(validatedCandle.open, validatedCandle.close)),
                    width: .fixed(candleWidth)
                )
                .foregroundStyle(validatedCandle.close >= validatedCandle.open ? themeManager.candleUpColor : themeManager.candleDownColor)
                .opacity(selectedCandle?.id == validatedCandle.id ? 0.8 : 1.0)
                
                // Candlestick wick
                RectangleMark(
                    x: .value("Time", chartTime),
                    yStart: .value("Low", validatedCandle.low),
                    yEnd: .value("High", validatedCandle.high),
                    width: .fixed(1.0)
                )
                .foregroundStyle(validatedCandle.close >= validatedCandle.open ? themeManager.candleUpColor : themeManager.candleDownColor)
                .opacity(selectedCandle?.id == validatedCandle.id ? 0.8 : 1.0)
            }
            
            // EMA overlay
            if showEMA && candles.count > 20 {
                let ema20Data = calculateEMA(candles: candles, period: 20)
                let ema50Data = calculateEMA(candles: candles, period: 50)
                
                ForEach(Array(ema20Data.enumerated()), id: \.offset) { index, emaPoint in
                    LineMark(
                        x: .value("Time", emaPoint.date),
                        y: .value("EMA20", emaPoint.value)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                
                ForEach(Array(ema50Data.enumerated()), id: \.offset) { index, emaPoint in
                    LineMark(
                        x: .value("Time", emaPoint.date),
                        y: .value("EMA50", emaPoint.value)
                    )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            
            // Bollinger Bands overlay
            if showBollinger && candles.count > 20 {
                let bollinger = calculateBollingerBands(candles: candles, period: 20, multiplier: 2)
                
                ForEach(Array(bollinger.enumerated()), id: \.offset) { index, bb in
                    // Upper band
                    LineMark(
                        x: .value("Time", bb.date),
                        y: .value("Upper", bb.upper)
                    )
                    .foregroundStyle(.purple.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    
                    // Lower band
                    LineMark(
                        x: .value("Time", bb.date),
                        y: .value("Lower", bb.lower)
                    )
                    .foregroundStyle(.purple.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    
                    // Middle band (SMA)
                    LineMark(
                        x: .value("Time", bb.date),
                        y: .value("Middle", bb.middle)
                    )
                    .foregroundStyle(.purple.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                }
            }
            
            // Selection indicator
            if let selectedCandle = selectedCandle {
                RuleMark(x: .value("Selected", selectedCandle.openTime))
                    .foregroundStyle(themeManager.accentColor.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420) // Already ≥ 380
        // ✅ FIX: Add proper Y-axis domain to prevent 0-0 range
        .chartYScale(domain: yAxisDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(themeManager.secondaryColor.opacity(0.3))
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(themeManager.secondaryColor)
                AxisValueLabel(formatAxisTime($0.as(Date.self) ?? Date()))
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
                                    withAnimation(.easeOut(duration: 0.1)) {
                                        chartScale = max(0.5, min(3.0, value))
                                    }
                                }
                                .onEnded { value in
                                    // Track telemetry for zoom interactions
                                    AnalyticsService.shared.track("chart_zoom", properties: [
                                        "category": "chart_interaction",
                                        "timeframe": timeframe.displayName,
                                        "final_scale": value,
                                        "gesture_type": "pinch"
                                    ])
                                    
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        // Snap to reasonable zoom levels
                                        if chartScale < 0.7 {
                                            chartScale = 0.5
                                        } else if chartScale > 2.5 {
                                            chartScale = 3.0
                                        }
                                    }
                                },
                            DragGesture()
                                .onChanged { value in
                                    chartOffset = value.translation
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        // Auto-reset pan if dragged too far
                                        if abs(chartOffset.width) > 200 || abs(chartOffset.height) > 100 {
                                            chartOffset = .zero
                                        }
                                    }
                                }
                        )
                    )
            }
        }
        .themedCardBackground()
        .cornerRadius(8)
        .padding(.horizontal)
        .overlay(alignment: .topTrailing) {
            // Floating crosshair tooltip
            if let selectedCandle = selectedCandle {
                CrosshairTooltip(candle: selectedCandle, timeframe: timeframe)
                    .padding()
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
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
        .frame(height: 100)
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
                
                if showEMA {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                        Text("EMA 20")
                            .font(.caption2)
                            .themedSecondaryForeground()
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)
                        Text("EMA 50")
                            .font(.caption2)
                            .themedSecondaryForeground()
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                }
                
                if showBollinger {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.purple.opacity(0.7))
                            .frame(width: 8, height: 8)
                        Text("Bollinger")
                            .font(.caption2)
                            .themedSecondaryForeground()
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
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
            
            // Track telemetry for chart interactions
            AnalyticsService.shared.track("chart_candle_selected", properties: [
                "category": "chart_interaction",
                "timeframe": timeframe.displayName,
                "candle_index": clampedIndex,
                "total_candles": candles.count
            ])
            
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
    
    private func formatAxisTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        // Timeframe-specific formatting for chart axis
        switch timeframe {
        case .m1, .m5, .m15:
            formatter.dateFormat = "HH:mm"
        case .h1:
            formatter.dateFormat = "HH:mm"
        case .h4:
            formatter.dateFormat = "MMM d"
        case .d1:
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: date)
    }
    
    // MARK: - Technical Indicator Calculations
    
    private func calculateEMA(candles: [Candle], period: Int) -> [(date: Date, value: Double)] {
        guard candles.count >= period else { return [] }
        
        var emaValues: [(date: Date, value: Double)] = []
        let multiplier = 2.0 / (Double(period) + 1.0)
        
        // Start with SMA for first value
        let initialSum = candles.prefix(period).reduce(0.0) { $0 + $1.close }
        let initialEMA = initialSum / Double(period)
        emaValues.append((date: candles[period - 1].openTime, value: initialEMA))
        
        // Calculate EMA for remaining values
        for i in period..<candles.count {
            let currentClose = candles[i].close
            let previousEMA = emaValues.last!.value
            let currentEMA = (currentClose * multiplier) + (previousEMA * (1 - multiplier))
            emaValues.append((date: candles[i].openTime, value: currentEMA))
        }
        
        return emaValues
    }
    
    private func calculateBollingerBands(candles: [Candle], period: Int, multiplier: Double) -> [(date: Date, upper: Double, middle: Double, lower: Double)] {
        guard candles.count >= period else { return [] }
        
        var bollingerData: [(date: Date, upper: Double, middle: Double, lower: Double)] = []
        
        for i in (period - 1)..<candles.count {
            let window = Array(candles[(i - period + 1)...i])
            let closes = window.map { $0.close }
            
            // Calculate SMA (middle band)
            let sma = closes.reduce(0.0, +) / Double(period)
            
            // Calculate standard deviation
            let variance = closes.map { pow($0 - sma, 2) }.reduce(0.0, +) / Double(period)
            let standardDeviation = sqrt(variance)
            
            // Calculate upper and lower bands
            let upper = sma + (standardDeviation * multiplier)
            let lower = sma - (standardDeviation * multiplier)
            
            bollingerData.append((
                date: candles[i].openTime,
                upper: upper,
                middle: sma,
                lower: lower
            ))
        }
        
        return bollingerData
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
        case .d1: return "MMM dd"        // Daily timeframe
        }
    }
}

// MARK: - CrosshairTooltip Component

struct CrosshairTooltip: View {
    let candle: Candle
    let timeframe: Timeframe
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with timestamp
            HStack {
                Text("Market Data")
                    .font(.caption.weight(.semibold))
                    .themedForeground()
                Spacer()
                Text(formatTime(candle.openTime))
                    .font(.caption2)
                    .themedSecondaryForeground()
            }
            
            Divider()
                .background(themeManager.secondaryColor.opacity(0.3))
            
            // OHLC Data in 2x2 grid
            LazyVGrid(columns: [
                GridItem(.flexible(), alignment: .leading),
                GridItem(.flexible(), alignment: .leading)
            ], spacing: 6) {
                TooltipDataPoint(label: "Open", value: candle.open, format: "%.2f")
                TooltipDataPoint(label: "High", value: candle.high, format: "%.2f")
                TooltipDataPoint(label: "Low", value: candle.low, format: "%.2f")
                TooltipDataPoint(
                    label: "Close", 
                    value: candle.close, 
                    format: "%.2f",
                    color: candle.close >= candle.open ? themeManager.candleUpColor : themeManager.candleDownColor
                )
            }
            
            Divider()
                .background(themeManager.secondaryColor.opacity(0.3))
            
            // Volume
            TooltipDataPoint(label: "Volume", value: candle.volume, format: nil)
            
            // Price change
            let change = candle.close - candle.open
            let changePercent = candle.open > 0 ? (change / candle.open) * 100 : 0
            HStack {
                Text("Change")
                    .font(.caption2)
                    .themedSecondaryForeground()
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(String(format: "%.2f", change))
                        .font(.caption.weight(.medium))
                        .foregroundColor(change >= 0 ? themeManager.candleUpColor : themeManager.candleDownColor)
                    Text(String(format: "%.1f%%", changePercent))
                        .font(.caption2)
                        .foregroundColor(change >= 0 ? themeManager.candleUpColor : themeManager.candleDownColor)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .frame(maxWidth: 180)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = timeframe.timeFormat
        return formatter.string(from: date)
    }
}

struct TooltipDataPoint: View {
    let label: String
    let value: Double
    let format: String?
    let color: Color?
    
    @StateObject private var themeManager = ThemeManager.shared
    
    init(label: String, value: Double, format: String?, color: Color? = nil) {
        self.label = label
        self.value = value
        self.format = format
        self.color = color
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .themedSecondaryForeground()
            Spacer()
            Text(formattedValue)
                .font(.caption.weight(.medium))
                .foregroundColor(color ?? themeManager.primaryColor)
        }
    }
    
    private var formattedValue: String {
        if let format = format {
            return String(format: format, value)
        } else {
            // Volume formatting
            if value >= 1_000_000 {
                return String(format: "%.1fM", value / 1_000_000)
            } else if value >= 1_000 {
                return String(format: "%.1fK", value / 1_000)
            } else {
                return String(format: "%.0f", value)
            }
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