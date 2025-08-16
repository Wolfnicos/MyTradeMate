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
    
    var body: some View {
        Group {
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
                Chart {
                    ForEach(data) { candle in
                        LineMark(
                            x: .value("Time", candle.timestamp),
                            y: .value("Price", candle.close)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
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
            }
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
        }
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
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(signalDisplayText)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(signalColor)
                        
                        /* // Temporarily disabled
                        if settings.demoMode {
                            Pill(text: "DEMO", color: Accent.yellow)
                        }
                        */
                    }
                    
                    HStack(spacing: 8) {
                        Text(confidenceDisplayText)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text(vm.timeframe.displayName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text(vm.lastUpdatedString)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    vm.refreshPrediction()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .disabled(vm.isRefreshing)
            }
            
            if let reason = vm.currentSignal?.reason {
                Text(reason)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                vm.executeBuy()
            }) {
                Text("BUY")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.green)
                    .cornerRadius(12)
            }
            .disabled(vm.tradingMode == .auto)
            
            Button(action: {
                vm.executeSell()
            }) {
                Text("SELL")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.red)
                    .cornerRadius(12)
            }
            .disabled(vm.tradingMode == .auto)
        }
        .opacity(vm.tradingMode == .auto ? 0.5 : 1.0)
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
    private var signalColor: Color {
        guard let signal = vm.currentSignal else { return .secondary }
        switch signal.direction {
        case "BUY": return .green
        case "SELL": return .red
        default: return .secondary
        }
    }
    
    private var signalDisplayText: String {
        guard let signal = vm.currentSignal else {
            return "No clear signal right now"
        }
        
        // If confidence is very low (0% or close to 0), show user-friendly text
        if signal.confidence < 0.01 {
            return "No clear signal right now"
        }
        
        return signal.direction.uppercased()
    }
    
    private var confidenceDisplayText: String {
        guard let signal = vm.currentSignal else {
            return "Monitoring market conditions"
        }
        
        // If confidence is very low (0% or close to 0), show user-friendly text
        if signal.confidence < 0.01 {
            return "Monitoring market conditions"
        }
        
        return "\(Int(signal.confidence * 100))% confidence"
    }
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