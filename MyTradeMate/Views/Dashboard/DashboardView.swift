import SwiftUI
import Charts
import UIKit

// MARK: - Chart Data Models
struct CandleData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

// MARK: - Simple Line Chart (simplified for now)
struct CandleChartView: View {
    let data: [CandleData]
    @State private var selectedPoint: CandleData?
    
    var body: some View {
        VStack(spacing: 12) {
            if data.isEmpty {
                // Empty state for charts when no data is available
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("No Chart Data")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("No price data available for the selected timeframe")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No Chart Data. No price data available for the selected timeframe")
            } else {
                VStack(spacing: 8) {
                    // Chart legend
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Price Movement")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Shows closing price over time")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                                Text("Price Line")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Tap for details")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .opacity(0.7)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    Chart {
                        ForEach(data) { candle in
                            LineMark(
                                x: .value("Time", candle.timestamp),
                                y: .value("Price", candle.close)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)
                        }
                        
                        // Selection indicator
                        if let selectedPoint = selectedPoint {
                            RuleMark(x: .value("Selected", selectedPoint.timestamp))
                                .foregroundStyle(.blue.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        }
                    }
                    .frame(height: 280)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.hour().minute())
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing, values: .automatic(desiredCount: 6)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let price = value.as(Double.self) {
                                    Text("$\(price, specifier: "%.0f")")
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
                        }
                    }
                    
                    // Selected point info
                    if let selectedPoint = selectedPoint {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Selected Point")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("Price: $\(selectedPoint.close, specifier: "%.2f")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(selectedPoint.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text(selectedPoint.timestamp, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(6)
                    }
                }
            }
        }
    }
    
    private func handleChartTap(at location: CGPoint, in geometry: GeometryProxy, chartProxy: ChartProxy) {
        let frame = geometry.frame(in: .local)
        let relativeX = location.x / frame.width
        
        if !data.isEmpty {
            let index = Int(relativeX * CGFloat(data.count))
            let clampedIndex = max(0, min(data.count - 1, index))
            selectedPoint = data[clampedIndex]
        }
    }
}

struct DashboardView: View {
    @StateObject private var vm = DashboardVM()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                priceSection
                miniChartSection
                controlsSection
                signalCardSection
                quickActionsSection
                positionsPreviewSection
                connectionStatusSection
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationTitle("Dashboard")
        .onAppear {
            vm.refreshData()
        }
        .overlay {
            if vm.showingTradeConfirmation, let tradeRequest = vm.pendingTradeRequest {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            vm.cancelTrade()
                        }
                    
                    TradeConfirmationDialog(
                        trade: tradeRequest,
                        onConfirm: {
                            vm.confirmTrade()
                        },
                        onCancel: {
                            vm.cancelTrade()
                        },
                        isExecuting: vm.isExecutingTrade
                    )
                    .padding()
                }
                .animation(.easeInOut(duration: 0.3), value: vm.showingTradeConfirmation)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("BTC/USDT")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Binance")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Trading Mode Indicator
            tradingModeIndicator
        }
    }
    
    // MARK: - Trading Mode Indicator
    private var tradingModeIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(AppSettings.shared.demoMode ? .orange : .green)
                .frame(width: 8, height: 8)
            
            Text(AppSettings.shared.demoMode ? "DEMO" : "LIVE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppSettings.shared.demoMode ? .orange : .green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((AppSettings.shared.demoMode ? Color.orange : Color.green).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppSettings.shared.demoMode ? .orange : .green, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Price Section
    private var priceSection: some View {
        VStack(spacing: 8) {
            Text("$\(vm.priceString)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Text(vm.priceChangeString)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(vm.priceChangeColor)
                
                Text("(\(vm.priceChangePercentString))")
                    .font(.system(size: 14))
                    .foregroundColor(vm.priceChangeColor.opacity(0.8))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Mini Chart Section
    private var miniChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart section header with explanation
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Price Chart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Real-time candlestick data with volume")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !vm.isLoading && !vm.candles.isEmpty {
                    Text("Interactive • Tap to explore")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            if vm.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading market data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(height: 280)
                .frame(maxWidth: .infinity)
            } else if !vm.candles.isEmpty {
                CandlestickChart(candles: vm.candles, timeframe: vm.timeframe)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No chart data available")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Check your connection or try a different symbol")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 280)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        VStack(spacing: 16) {
            // Timeframe selector
            HStack {
                Text("Timeframe")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("Timeframe", selection: $vm.timeframe) {
                    Text("5m").tag(Timeframe.m5)
                    Text("1h").tag(Timeframe.h1)
                    Text("4h").tag(Timeframe.h4)
                }
                .pickerStyle(.segmented)
            }
            
            // Mode selector
            HStack {
                Text("Mode")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("Mode", selection: $vm.isPrecisionMode) {
                    Text("Normal").tag(false)
                    Text("Precision").tag(true)
                }
                .pickerStyle(.segmented)
            }
            
            // Auto/Manual switch
            HStack {
                Text("Trading Mode")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("Trading", selection: $vm.tradingMode) {
                    Text("Manual").tag(TradingMode.manual)
                    Text("Auto").tag(TradingMode.auto)
                }
                .pickerStyle(.segmented)
            }
        }
        .onChange(of: vm.timeframe) { _ in
            vm.refreshData()
        }
        .onChange(of: vm.tradingMode) { _ in
            if AppSettings.shared.haptics {
                Haptics.playImpact(.medium)
            }
        }
    }
    
    // MARK: - Signal Card Section
    private var signalCardSection: some View {
        SignalVisualizationView(
            signal: vm.currentSignal,
            isRefreshing: vm.isRefreshing,
            timeframe: vm.timeframe,
            lastUpdated: vm.lastUpdated,
            onRefresh: {
                vm.refreshPrediction()
            }
        )
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            // Trading mode warning for demo mode
            if AppSettings.shared.demoMode {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    
                    Text("Demo Mode - No real trades will be executed")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Show loading state when executing trade without confirmation
            if vm.isExecutingTrade && !vm.showingTradeConfirmation {
                LoadingStateView(message: "Submitting order...")
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            } else {
                HStack(spacing: 12) {
                    Button(action: {
                        vm.executeBuy()
                    }) {
                        VStack(spacing: 4) {
                            Text("BUY")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            if AppSettings.shared.demoMode {
                                Text("DEMO")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.green)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppSettings.shared.demoMode ? .orange.opacity(0.5) : .clear, lineWidth: 2)
                        )
                    }
                    .disabled(vm.tradingMode == .auto || vm.isExecutingTrade)
                    
                    Button(action: {
                        vm.executeSell()
                    }) {
                        VStack(spacing: 4) {
                            Text("SELL")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            if AppSettings.shared.demoMode {
                                Text("DEMO")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.red)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppSettings.shared.demoMode ? .orange.opacity(0.5) : .clear, lineWidth: 2)
                        )
                    }
                    .disabled(vm.tradingMode == .auto || vm.isExecutingTrade)
                }
                .opacity(vm.tradingMode == .auto || vm.isExecutingTrade ? 0.5 : 1.0)
            }
        }
    }
    
    // MARK: - Positions Preview Section
    private var positionsPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Open Positions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                /* // Temporarily disabled
                NavigationLink(destination: TradesView()) {
                    Text("View All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Brand.blue)
                }
                */
            }
            
            if vm.openPositions.isEmpty {
                Text("No open positions")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(vm.openPositions.prefix(2).enumerated()), id: \.offset) { _, position in
                    PositionRow(position: position)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Connection Status Section
    private var connectionStatusSection: some View {
        HStack(spacing: 12) {
            // Connection indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(vm.isConnected ? .green : .red)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(vm.isConnected ? .green.opacity(0.3) : .red.opacity(0.3), lineWidth: 8)
                            .scaleEffect(vm.isConnected ? 2 : 1.5)
                            .opacity(vm.isConnected ? 0 : 0.5)
                            .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: vm.isConnected)
                    )
                
                Text(connectionStatusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(vm.isConnected ? .green : .orange)
            }
            
            Spacer()
            
            // Last updated
            Text(vm.lastUpdatedString)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(vm.isConnected ? .green.opacity(0.3) : .orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var connectionStatusText: String {
        if vm.isConnected {
            return "Connected to Binance"
        } else {
            return "Connecting..."
        }
    }
    
    // MARK: - Helpers
}

// MARK: - Sparkline Chart
struct SparklineChart: View {
    let points: [CGPoint]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard points.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                
                path.move(to: CGPoint(
                    x: points[0].x * width,
                    y: (1 - points[0].y) * height
                ))
                
                for point in points.dropFirst() {
                    path.addLine(to: CGPoint(
                        x: point.x * width,
                        y: (1 - point.y) * height
                    ))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [.blue, .blue.opacity(0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
        }
    }
}

// MARK: - Position Row
struct PositionRow: View {
    let position: Position
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                // Text(String(position.symbol))
                //     .font(.system(size: 14, weight: .medium))
                //     .foregroundColor(.primary)
                
                // Text("\(String(position.side)) • \(String(position.size))")
                //     .font(.system(size: 12))
                //     .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Text(String(position.pnlString))
            //     .font(.system(size: 14, weight: .semibold))
            //     .foregroundColor(position.pnl >= 0 ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DashboardView()
                // .environmentObject(AppSettings.shared) // Temporarily disabled
        }
    }
}