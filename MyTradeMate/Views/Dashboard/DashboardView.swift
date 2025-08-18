import SwiftUI
import Charts
import UIKit

// Using Spacing and CornerRadius from DesignSystem.swift

// MARK: - Chart Data Models
// CandleData is defined in MarketDataManager.swift

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
    @StateObject private var strategyManager = StrategyManager.shared
    @StateObject private var riskManager = RiskManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionSpacing) {
                headerSection
                tradingModeBanner
                pnlHUDSection
                priceSection
                miniChartSection
                strategiesOverviewSection
                riskManagementSection
                portfolioSummarySection
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
                Text(vm.selectedTradingPair.displayName)
                    .headlineStyle()
                
                Text(vm.selectedExchange.displayName)
                    .footnoteStyle()
            }
            
            Spacer()
            
            // Currency selector - NEW
            Menu {
                Button("USD ($)") {
                    vm.selectedQuoteCurrency = .USD
                }
                
                Button("EUR (€)") {
                    vm.selectedQuoteCurrency = .EUR
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text(vm.selectedQuoteCurrency.symbol)
                        .caption1MediumStyle()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(CornerRadius.sm)
            }
            
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
            // Trading pair picker - NEW
            TradingPairPicker(selectedPair: $vm.selectedTradingPair)
            
            // Trade amount control - NEW
            TradeAmountControl(
                amountMode: $vm.amountMode,
                amountValue: $vm.amountValue,
                quoteCurrency: vm.selectedTradingPair.quote,
                currentEquity: vm.currentEquity,
                currentPrice: vm.price
            )
            
            // Timeframe selector - ENHANCED
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Timeframe")
                        .footnoteMediumStyle()
                    
                    Spacer()
                    
                    Text("Each timeframe analyzes different market patterns")
                        .caption2Style()
                        .foregroundColor(.secondary)
                }
                
                Picker("Timeframe", selection: $vm.timeframe) {
                    ForEach(Timeframe.allCases, id: \.rawValue) { tf in
                        Text(tf.displayName).tag(tf)
                    }
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
                
                Picker("Mode", selection: $vm.autoTradingEnabled) {
                    Text("Manual").tag(false)
                    Text("Auto").tag(true)
                }
                .pickerStyle(.segmented)
            }
        }
        .onChange(of: vm.timeframe) { _ in
            if AppSettings.shared.haptics {
                Haptics.playImpact(.light)
            }
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
            tradingPair: vm.selectedTradingPair,
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
                        isDisabled: vm.autoTradingEnabled || vm.isExecutingTrade,
                        isDemoMode: AppSettings.shared.demoMode,
                        action: {
                            vm.executeBuy()
                        }
                    )
                    
                    SellButton(
                        isDisabled: vm.autoTradingEnabled || vm.isExecutingTrade,
                        isDemoMode: AppSettings.shared.demoMode,
                        action: {
                            vm.executeSell()
                        }
                    )
                }
                .opacity(vm.autoTradingEnabled || vm.isExecutingTrade ? 0.5 : 1.0)
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
    
    // MARK: - P&L HUD Section
    private var pnlHUDSection: some View {
        Group {
            if let pnlSnapshot = vm.currentPnLSnapshot {
                PnLWidget(
                    snapshot: pnlSnapshot,
                    isDemoMode: vm.tradingMode == .demo
                )
            } else {
                // Loading state for P&L
                VStack(spacing: Spacing.sm) {
                    HStack {
                        Text("Portfolio")
                            .calloutMediumStyle()
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Text("Loading account data...")
                        .caption1Style()
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.cardPadding)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadius.lg)
            }
        }
    }
    
    // MARK: - Strategies Overview Section
    private var strategiesOverviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Active Strategies")
                        .calloutMediumStyle()
                    
                    Text("\(strategyManager.enabledStrategies.count) of \(strategyManager.strategies.count) enabled")
                        .caption1Style()
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                NavigationLink(destination: StrategiesView()) {
                    Text("View All")
                        .footnoteMediumStyle()
                        .foregroundColor(.blue)
                }
            }
            
            if strategyManager.strategies.isEmpty {
                EmptyStateView.strategies(
                    title: "No Strategies Loaded", 
                    description: "Configure strategies in Settings to enable AI trading signals",
                    useIllustration: true
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
            } else {
                // Strategy Grid - ENHANCED
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.sm) {
                    ForEach(Array(strategyManager.enabledStrategies.prefix(6).enumerated()), id: \.offset) { _, strategy in
                        StrategyMiniCard(
                            strategy: strategy,
                            lastSignal: strategyManager.lastSignals[strategy.name],
                            timeframe: vm.timeframe
                        )
                    }
                }
                
                // Show "View All" if more strategies exist
                if strategyManager.enabledStrategies.count > 6 {
                    HStack {
                        Text("+ \(strategyManager.enabledStrategies.count - 6) more strategies")
                            .caption1Style()
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        NavigationLink(destination: StrategiesView()) {
                            Text("View All")
                                .footnoteMediumStyle()
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, Spacing.sm)
                }
                
                // Ensemble Signal Display - ENHANCED
                if let ensembleSignal = strategyManager.ensembleSignal {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Ensemble Decision")
                                .caption1MediumStyle()
                            
                            Spacer()
                            
                            Text("Updated: \(Date(), style: .time)")
                                .caption2Style()
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            // Signal strength indicator
                            HStack(spacing: Spacing.xs) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(signalColor(for: ensembleSignal.direction))
                                    .frame(width: 4, height: 16)
                                
                                Text(ensembleSignal.direction.description.uppercased())
                                    .footnoteMediumStyle()
                                    .foregroundColor(signalColor(for: ensembleSignal.direction))
                            }
                            
                            Text("\(Int(ensembleSignal.confidence * 100))% confidence")
                                .caption2Style()
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "brain.head.profile")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text("\(ensembleSignal.contributingStrategies.count) strategies")
                                    .caption2Style()
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Strategy agreement indicator
                        if ensembleSignal.contributingStrategies.count >= 3 {
                            HStack(spacing: Spacing.xs) {
                                ForEach(0..<min(5, ensembleSignal.contributingStrategies.count), id: \.self) { _ in
                                    Circle()
                                        .fill(signalColor(for: ensembleSignal.direction))
                                        .frame(width: 6, height: 6)
                                }
                                
                                if ensembleSignal.contributingStrategies.count > 5 {
                                    Text("+\(ensembleSignal.contributingStrategies.count - 5)")
                                        .caption2Style()
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("Strong consensus")
                                    .caption2Style()
                                    .foregroundColor(signalColor(for: ensembleSignal.direction))
                            }
                        }
                    }
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(signalColor(for: ensembleSignal.direction).opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.sm)
                                    .stroke(signalColor(for: ensembleSignal.direction).opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
    }
    
    // MARK: - Risk Management Section
    private var riskManagementSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Risk Management")
                        .calloutMediumStyle()
                    
                    Text("Portfolio protection & limits")
                        .caption1Style()
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Settings") {
                    // Navigate to risk settings
                }
                .font(.footnote)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                RiskMetricCard(
                    title: "Daily Risk",
                    value: "\(Int(riskManager.currentDailyRisk * 100))%",
                    limit: "\(Int(riskManager.maxDailyRisk * 100))%",
                    isWarning: riskManager.currentDailyRisk > riskManager.maxDailyRisk * 0.8
                )
                
                RiskMetricCard(
                    title: "Position Size",
                    value: "\(Int(riskManager.currentPositionRisk * 100))%",
                    limit: "\(Int(riskManager.maxPositionRisk * 100))%",
                    isWarning: riskManager.currentPositionRisk > riskManager.maxPositionRisk * 0.8
                )
                
                RiskMetricCard(
                    title: "Portfolio Risk",
                    value: "\(Int(riskManager.currentPortfolioRisk * 100))%",
                    limit: "\(Int(riskManager.maxPortfolioRisk * 100))%",
                    isWarning: riskManager.currentPortfolioRisk > riskManager.maxPortfolioRisk * 0.8
                )
                
                RiskMetricCard(
                    title: "Open Positions",
                    value: "\(riskManager.openPositionsCount)",
                    limit: "\(riskManager.maxOpenPositions)",
                    isWarning: riskManager.openPositionsCount > Int(Double(riskManager.maxOpenPositions) * 0.8)
                )
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
    }
    
    // MARK: - Portfolio Summary Section
    private var portfolioSummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Portfolio Summary")
                        .calloutMediumStyle()
                    
                    Text("Account balance & performance")
                        .caption1Style()
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                NavigationLink(destination: TradesView()) {
                    Text("View Trades")
                        .footnoteMediumStyle()
                        .foregroundColor(.blue)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                PortfolioMetricCard(
                    title: "Total Balance",
                    value: "$\(vm.totalBalance, specifier: "%.2f")",
                    change: vm.totalBalanceChange,
                    changePercent: vm.totalBalanceChangePercent
                )
                
                PortfolioMetricCard(
                    title: "Available",
                    value: "$\(vm.availableBalance, specifier: "%.2f")",
                    change: nil,
                    changePercent: nil
                )
                
                PortfolioMetricCard(
                    title: "Today's P&L",
                    value: "$\(vm.todayPnL, specifier: "%.2f")",
                    change: vm.todayPnL,
                    changePercent: vm.todayPnLPercent
                )
                
                PortfolioMetricCard(
                    title: "Open P&L",
                    value: "$\(vm.unrealizedPnL, specifier: "%.2f")",
                    change: vm.unrealizedPnL,
                    changePercent: vm.unrealizedPnLPercent
                )
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
    }
    
    private func signalColor(for direction: StrategySignal.Direction) -> Color {
        switch direction {
        case .buy: return .green
        case .sell: return .red
        case .hold: return .secondary
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
    let position: TradingPosition
    
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
    
    // MARK: - Trading Mode Banner
    private var tradingModeBanner: some View {
        HStack(spacing: Spacing.md) {
            // Mode indicator
            Circle()
                .fill(vm.tradingMode.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.tradingMode.title.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(vm.tradingMode.color)
                
                Text(vm.tradingMode.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if vm.tradingMode == .demo {
                Text("VIRTUAL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(vm.tradingMode.backgroundColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(vm.tradingMode.color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

// MARK: - Trading Mode Extensions
extension TradingMode {
    var color: Color {
        switch self {
        case .demo: return .orange
        case .paper: return .blue
        case .live: return .green
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .demo: return .orange
        case .paper: return .blue
        case .live: return .green
        }
    }
    
    // Using description from TradingMode.swift
}

// MARK: - Strategy Mini Card
struct StrategyMiniCard: View {
    let strategy: any Strategy
    let lastSignal: StrategySignal?
    let timeframe: Timeframe
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(strategy.name)
                    .caption1MediumStyle()
                    .lineLimit(1)
                
                Spacer()
                
                HStack(spacing: Spacing.xs) {
                    // Timeframe badge
                    Text(timeframe.displayName)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color(.quaternarySystemFill))
                        .cornerRadius(3)
                    
                    Circle()
                        .fill(strategy.isEnabled ? .green : .gray)
                        .frame(width: 6, height: 6)
                }
            }
            
            if let signal = lastSignal {
                HStack {
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(signalColor(for: signal.direction))
                            .frame(width: 4, height: 4)
                        
                        Text(signal.direction.description)
                            .caption2Style()
                            .foregroundColor(signalColor(for: signal.direction))
                    }
                    
                    Spacer()
                    
                    Text("\(Int(signal.confidence * 100))%")
                        .caption2Style()
                        .foregroundColor(.secondary)
                }
                
                // Signal strength bar
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(.quaternarySystemFill))
                        .frame(height: 2)
                        .overlay(
                            HStack {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(signalColor(for: signal.direction))
                                    .frame(width: geometry.size.width * signal.confidence, height: 2)
                                
                                Spacer(minLength: 0)
                            }
                        )
                }
                .frame(height: 2)
            } else {
                Text("Analyzing...")
                    .caption2Style()
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.sm)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(CornerRadius.sm)
    }
    
    private func signalColor(for direction: StrategySignal.Direction) -> Color {
        switch direction {
        case .buy: return .green
        case .sell: return .red
        case .hold: return .secondary
        }
    }
}

// MARK: - Risk Metric Card
struct RiskMetricCard: View {
    let title: String
    let value: String
    let limit: String
    let isWarning: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .caption1Style()
                .foregroundColor(.secondary)
            
            Text(value)
                .footnoteMediumStyle()
                .foregroundColor(isWarning ? .orange : .primary)
            
            Text("Limit: \(limit)")
                .caption2Style()
                .foregroundColor(.secondary)
        }
        .padding(Spacing.sm)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(isWarning ? .orange.opacity(0.5) : .clear, lineWidth: 1)
        )
    }
}

// MARK: - Portfolio Metric Card
struct PortfolioMetricCard: View {
    let title: String
    let value: String
    let change: Double?
    let changePercent: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .caption1Style()
                .foregroundColor(.secondary)
            
            Text(value)
                .footnoteMediumStyle()
                .foregroundColor(.primary)
            
            if let change = change, let changePercent = changePercent {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                        .foregroundColor(change >= 0 ? .green : .red)
                    
                    Text("\(changePercent, specifier: "%.2f")%")
                        .caption2Style()
                        .foregroundColor(change >= 0 ? .green : .red)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Extensions
// Using description from StrategySignal.Direction in Strategy.swift

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DashboardView()
                // .environmentObject(AppSettings.shared) // Temporarily disabled
        }
    }
}