import SwiftUI
import Charts
import UIKit

// Temporary Spacing and CornerRadius structs for this file until DesignSystem is properly imported
private struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let sectionSpacing: CGFloat = 20
    static let cardPadding: CGFloat = 16
}

private struct CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 20
}

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
        VStack(spacing: Spacing.md) {
            if data.isEmpty {
                // Empty state for charts when no data is available with illustration
                EmptyStateView.chartNoData(
                    title: "No Chart Data",
                    description: "No price data available for the selected timeframe",
                    useIllustration: true
                )
                .frame(height: 280)
            } else {
                VStack(spacing: Spacing.sm) {
                    // Chart legend
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Price Movement")
                                .caption1MediumStyle()
                                .foregroundColor(.primary)
                            
                            Text("Shows closing price over time")
                                .caption2Style()
                        }
                        
                        Spacer()
                        
                        HStack(spacing: Spacing.sm) {
                            HStack(spacing: Spacing.xs) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                                Text("Price Line")
                                    .caption2Style()
                            }
                            
                            Text("Tap for details")
                                .caption2Style()
                                .opacity(0.7)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(CornerRadius.sm)
                    
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
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("Selected Point")
                                    .caption1MediumStyle()
                                    .foregroundColor(.primary)
                                
                                Text("Price: $\(selectedPoint.close, specifier: "%.2f")")
                                    .caption2Style()
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                                Text(selectedPoint.timestamp, style: .time)
                                    .caption2Style()
                                
                                Text(selectedPoint.timestamp, style: .date)
                                    .caption2Style()
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(CornerRadius.sm)
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
            VStack(spacing: Spacing.sectionSpacing) {
                headerSection
                priceSection
                miniChartSection
                controlsSection
                signalCardSection
                quickActionsSection
                activeOrdersSection
                positionsPreviewSection
                connectionStatusSection
            }
            .padding(Spacing.lg)
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
                        onExecutionComplete: { success in
                            if success {
                                vm.showSuccessToast("Order executed successfully")
                            } else {
                                vm.showErrorToast("Order execution failed")
                            }
                        }
                    )
                    .padding(Spacing.lg)
                }
                .animation(.easeInOut(duration: 0.3), value: vm.showingTradeConfirmation)
            }
        }
        .overlay(alignment: .top) {
            if vm.showingToast {
                ToastView(
                    type: vm.toastType,
                    title: vm.toastMessage,
                    onDismiss: {
                        vm.showingToast = false
                    }
                )
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: vm.showingToast)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("BTC/USDT")
                    .headlineStyle()
                
                Text("Binance")
                    .footnoteStyle()
            }
            
            Spacer()
            
            // Trading Mode Indicator
            tradingModeIndicator
        }
    }
    
    // MARK: - Trading Mode Indicator
    private var tradingModeIndicator: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(AppSettings.shared.demoMode ? .orange : .green)
                .frame(width: 8, height: 8)
            
            Text(AppSettings.shared.demoMode ? "DEMO" : "LIVE")
                .caption1MediumStyle()
                .foregroundColor(AppSettings.shared.demoMode ? .orange : .green)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill((AppSettings.shared.demoMode ? Color.orange : Color.green).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(AppSettings.shared.demoMode ? .orange : .green, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Price Section
    private var priceSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("$\(vm.priceString)")
                .largeTitleStyle()
            
            HStack(spacing: Spacing.md) {
                Text(vm.priceChangeString)
                    .headlineStyle()
                    .foregroundColor(vm.priceChangeColor)
                
                Text("(\(vm.priceChangePercentString))")
                    .footnoteStyle()
                    .foregroundColor(vm.priceChangeColor.opacity(0.8))
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
    }
    
    // MARK: - Mini Chart Section
    private var miniChartSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Chart section header with explanation
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Price Chart")
                        .calloutMediumStyle()
                    
                    Text("Real-time candlestick data with volume")
                        .caption1Style()
                }
                
                Spacer()
                
                if !vm.isLoading && !vm.candles.isEmpty {
                    Text("Interactive • Tap to explore")
                        .caption2Style()
                        .opacity(0.7)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            
            if vm.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading market data...")
                        .caption1Style()
                        .padding(.top, 8)
                }
                .frame(height: 280)
                .frame(maxWidth: .infinity)
            } else if !vm.candles.isEmpty {
                CandlestickChart(candles: vm.candles, timeframe: vm.timeframe)
            } else {
                EmptyStateView.chartNoData(
                    title: "No Chart Data Available",
                    description: "Check your connection or try a different symbol",
                    useIllustration: true
                )
                .frame(height: 280)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        VStack(spacing: Spacing.lg) {
            // Timeframe selector
            HStack {
                Text("Timeframe")
                    .footnoteMediumStyle()
                
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
                    .footnoteMediumStyle()
                
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
                    .footnoteMediumStyle()
                
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
        VStack(spacing: Spacing.md) {
            // Trading mode warning for demo mode
            if AppSettings.shared.demoMode {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    
                    Text("Demo Mode - No real trades will be executed")
                        .caption1Style()
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(.orange.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }
            
            // Show loading state when executing trade without confirmation
            if vm.isExecutingTrade && !vm.showingTradeConfirmation {
                LoadingStateView(message: "Submitting order...")
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(CornerRadius.lg)
            } else {
                HStack(spacing: Spacing.md) {
                    BuyButton(
                        isDisabled: vm.tradingMode == .auto || vm.isExecutingTrade,
                        isDemoMode: AppSettings.shared.demoMode,
                        action: {
                            vm.executeBuy()
                        }
                    )
                    
                    SellButton(
                        isDisabled: vm.tradingMode == .auto || vm.isExecutingTrade,
                        isDemoMode: AppSettings.shared.demoMode,
                        action: {
                            vm.executeSell()
                        }
                    )
                }
                .opacity(vm.tradingMode == .auto || vm.isExecutingTrade ? 0.5 : 1.0)
            }
        }
    }
    
    // MARK: - Active Orders Section
    private var activeOrdersSection: some View {
        ActiveOrdersView()
    }
    
    // MARK: - Positions Preview Section
    private var positionsPreviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Open Positions")
                    .calloutMediumStyle()
                
                Spacer()
                
                /* // Temporarily disabled
                NavigationLink(destination: TradesView()) {
                    Text("View All")
                        .footnoteMediumStyle()
                        .foregroundColor(Brand.blue)
                }
                */
            }
            
            if vm.openPositions.isEmpty {
                Text("No open positions")
                    .footnoteStyle()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.xl)
            } else {
                ForEach(Array(vm.openPositions.prefix(2).enumerated()), id: \.offset) { _, position in
                    PositionRow(position: position)
                }
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
    }
    
    // MARK: - Connection Status Section
    private var connectionStatusSection: some View {
        HStack(spacing: Spacing.md) {
            // Connection indicator
            HStack(spacing: Spacing.sm) {
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
                    .caption1MediumStyle()
                    .foregroundColor(vm.isConnected ? .green : .orange)
            }
            
            Spacer()
            
            // Last updated
            Text(vm.lastUpdatedString)
                .caption2Style()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
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
            VStack(alignment: .leading, spacing: Spacing.xxs) {
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
        .padding(.vertical, Spacing.xs)
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