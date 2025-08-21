import Foundation
import Combine
import SwiftUI
import CoreML
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "Dashboard")


// Strategy decision modes
enum StrategyMode: String, CaseIterable { 
    case normal, precision 
}



// MARK: - Removed duplicate StrategyStore (using LegacyStrategy.swift version)

@MainActor
final class DashboardVM: ObservableObject {
    // MARK: - Dependencies
    private let aiModelManager = AIModelManager.shared
    private let errorManager = ErrorManager.shared
    private let settings = AppSettings.shared
    private let settingsRepo = SettingsRepository.shared
    private let marketDataService = MarketDataService.shared
    private let tradeManager = TradeManager.shared
    private let metaSignalEngine = MetaSignalEngine.shared
    private let tradingEngine = TradingEngine.shared
    
    // MARK: - Published Properties
    @Published var candles: [Candle] = []
    @Published var chartPoints: [CGPoint] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    
    // Price properties
    @Published var price: Double = 0.0
    @Published var priceChange: Double = 0.0
    @Published var priceChangePercent: Double = 0.0
    @Published var lastUpdated: Date = Date()
    
    // Portfolio properties
    @Published var totalBalance: Double = 10000.0
    @Published var availableBalance: Double = 8500.0
    @Published var totalBalanceChange: Double = 250.0
    @Published var totalBalanceChangePercent: Double = 2.56
    @Published var todayPnL: Double = 125.50
    @Published var todayPnLPercent: Double = 1.28
    @Published var unrealizedPnL: Double = -45.20
    @Published var unrealizedPnLPercent: Double = -0.46
    
    // Chart data
    var chartData: [CandleData] {
        return candles.map { candle in
            CandleData(
                timestamp: candle.openTime,
                open: candle.open,
                high: candle.high,
                low: candle.low,
                close: candle.close,
                volume: candle.volume
            )
        }
    }
    @Published var errorMessage: String?
    @Published var timeframe: Timeframe = .m5
    @Published var precisionMode: Bool = false
    @Published var autoTradingEnabled: Bool = false
    
    // Multi-Asset Trading Properties
    @Published var selectedTradingPair: TradingPair = .btcUsd
    @Published var selectedExchange: Exchange = .binance
    @Published var selectedQuoteCurrency: QuoteCurrency = .USD
    @Published var amountMode: AmountMode = .percentOfEquity
    @Published var amountValue: Double = 5.0
    @Published var currentEquity: Double = 10_000.0
    
    // Trading mode is controlled by settings, not dashboard toggle
    var tradingMode: TradingMode {
        if settings.demoMode {
            return .demo
        } else if settings.paperTrading {
            return .paper
        } else {
            return .live
        }
    }
    @Published var confidence: Double = 0.0
    @Published var currentSignal: SignalInfo?
    @Published var openPositions: [TradingPosition] = []
    @Published var isConnected: Bool = false
    @Published var connectionStatus: String = "Connecting..."
    
    // Trade confirmation
    @Published var showingTradeConfirmation = false
    @Published var pendingTradeRequest: TradeRequest?
    @Published var isExecutingTrade = false
    
    // Toast notifications
    @Published var showingToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success
    
    // P&L HUD live updates with Combine binding
    @Published var currentPnLSnapshot: PnLSnapshot?
    
    // Computed property for backwards compatibility
    var isPrecisionMode: Bool {
        get { precisionMode }
        set { precisionMode = newValue }
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private var lastPredictionTime: Date = .distantPast
    private var lastThrottleLog: Date = .distantPast
    private var lastStrategySignal: DirectFusionSignal?
    
    // Manual trading debounce (>=500ms as specified)
    private var lastManualTradeTime: Date = .distantPast
    private let manualTradeDebounce: TimeInterval = 0.5 // 500ms
    
    // MARK: - Trade Execution Methods
    func executeBuy() {
        guard canExecuteTrade() else { return }
        
        let tradeRequest = createTradeRequest(side: .buy)
        
        if settings.confirmTrades {
            pendingTradeRequest = tradeRequest
            showingTradeConfirmation = true
        } else {
            executeTradeDirectly(tradeRequest)
        }
    }
    
    func executeSell() {
        guard canExecuteTrade() else { return }
        
        let tradeRequest = createTradeRequest(side: .sell)
        
        if settings.confirmTrades {
            pendingTradeRequest = tradeRequest
            showingTradeConfirmation = true
        } else {
            executeTradeDirectly(tradeRequest)
        }
    }
    
    func confirmTrade() {
        guard let tradeRequest = pendingTradeRequest else { return }
        
        showingTradeConfirmation = false
        pendingTradeRequest = nil
        
        executeTradeDirectly(tradeRequest)
    }
    
    func cancelTrade() {
        showingTradeConfirmation = false
        pendingTradeRequest = nil
    }
    
    private func canExecuteTrade() -> Bool {
        let now = Date()
        let timeSinceLastTrade = now.timeIntervalSince(lastManualTradeTime)
        
        guard timeSinceLastTrade >= manualTradeDebounce else {
            showErrorToast("Please wait before placing another trade")
            return false
        }
        
        guard !isExecutingTrade else {
            showErrorToast("Trade already in progress")
            return false
        }
        
        return true
    }
    
    private func createTradeRequest(side: TradeSide) -> TradeRequest {
        let amount = calculateTradeAmount()
        
        return TradeRequest(
            symbol: selectedTradingPair.symbol,
            side: side,
            amount: amount,
            price: price,
            type: .market,
            timeInForce: .goodTillCanceled
        )
    }
    
    private func calculateTradeAmount() -> Double {
        switch amountMode {
        case .percentOfEquity:
            return currentEquity * (amountValue / 100)
        case .fixedNotional:
            return amountValue
        case .riskPercent:
            // Risk-based calculation would involve stop-loss distance
            return currentEquity * (amountValue / 100)
        }
    }
    
    private func executeTradeDirectly(_ tradeRequest: TradeRequest) {
        isExecutingTrade = true
        lastManualTradeTime = Date()
        
        Task {
            do {
                // Convert TradeSide to OrderSide for TradingEngine
                let orderSide: OrderSide = tradeRequest.side == .buy ? .buy : .sell
                
                let result = try await tradingEngine.placeOrder(
                    symbol: tradeRequest.symbol,
                    side: orderSide,
                    amount: tradeRequest.amount,
                    amountMode: amountMode,
                    quoteCurrency: selectedQuoteCurrency
                )
                
                await MainActor.run {
                    self.isExecutingTrade = false
                    self.showSuccessToast("Order placed successfully")
                    
                    // Refresh data after successful trade
                    Task {
                        await self.loadMarketData()
                        await self.refreshPredictionAsync()
                    }
                }
                
                Log.trade.info("Manual trade executed: \(tradeRequest.side.rawValue) \(tradeRequest.amount) \(tradeRequest.symbol)")
                
            } catch {
                await MainActor.run {
                    self.isExecutingTrade = false
                    self.showErrorToast("Trade failed: \(error.localizedDescription)")
                }
                
                Log.trade.error("Manual trade failed: \(error)")
            }
        }
    }
    
    func showSuccessToast(_ message: String) {
        toastMessage = message
        toastType = .success
        showingToast = true
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showingToast = false
        }
    }
    
    func showErrorToast(_ message: String) {
        toastMessage = message
        toastType = .error
        showingToast = true
        
        // Auto-dismiss after 4 seconds for errors
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.showingToast = false
        }
    }
    
    private func handleAutoTrading(signal: SignalInfo) {
        guard autoTradingEnabled else { return }
        guard signal.confidence >= 0.7 else { return } // Only trade on high confidence signals
        
        Task {
            do {
                let side: OrderSide
                
                switch signal.direction.uppercased() {
                case "BUY":
                    side = .buy
                case "SELL":
                    side = .sell
                default:
                    return // Don't trade on HOLD signals
                }
                
                let result = try await tradingEngine.placeOrder(
                    symbol: selectedTradingPair.symbol,
                    side: side,
                    amount: calculateTradeAmount(),
                    amountMode: amountMode,
                    quoteCurrency: selectedQuoteCurrency
                )
                
                await MainActor.run {
                    self.showSuccessToast("Auto trade executed: \(signal.direction)")
                }
                
                Log.trade.info("Auto trade executed: \(signal.direction) with \(String(format: "%.1f%%", signal.confidence * 100)) confidence")
                
            } catch {
                await MainActor.run {
                    self.showErrorToast("Auto trade failed: \(error.localizedDescription)")
                }
                
                Log.trade.error("Auto trade failed: \(error)")
            }
        }
    }
    
    // MARK: - Computed Properties
    var priceString: String {
        String(format: "%.2f", price)
    }
    
    var priceChangeString: String {
        let sign = priceChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", priceChange))"
    }
    
    var priceChangePercentString: String {
        let sign = priceChangePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", priceChangePercent))%"
    }
    
    var priceChangeColor: Color {
        priceChange >= 0 ? .green : .red
    }
    
    var lastUpdatedString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
    
    // MARK: - Initialization
    init() {
        setupBindings()
        setupPerformanceOptimization()
        loadInitialData()
        startAutoRefresh()
    }
    
    private func setupPerformanceOptimization() {
        // Enable performance optimization
        PerformanceOptimizer.shared.enableOptimization(true)
        
        // Listen for optimization notifications
        NotificationCenter.default.addObserver(
            forName: .pauseNonEssentialOperations,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseNonEssentialOperations()
        }
        
        NotificationCenter.default.addObserver(
            forName: .resumeNonEssentialOperations,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeNonEssentialOperations()
        }
    }
    
    private func pauseNonEssentialOperations() {
        logger.info("Pausing non-essential operations due to memory pressure")
        
        // Pause auto-refresh timer
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        // Reduce chart update frequency
        // This would be implemented in chart components
    }
    
    private func resumeNonEssentialOperations() {
        logger.info("Resuming non-essential operations")
        
        // Restart auto-refresh timer
        startAutoRefresh()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Observe timeframe changes with debounce
        $timeframe
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] timeframe in
                Log.app.info("User set timeframe to \(timeframe.rawValue)")
                Task { @MainActor [weak self] in
                    await self?.reloadDataAndPredict()
                }
            }
            .store(in: &cancellables)
        
        // Observe precision mode changes
        $precisionMode
            .removeDuplicates()
            .sink { [weak self] precision in
                Log.ai.info("Precision mode \(precision ? "ON" : "OFF")")
                Task { @MainActor [weak self] in
                    await self?.refreshPredictionAsync()
                }
            }
            .store(in: &cancellables)
        
        // Observe trading mode changes via settings
        settings.objectWillChange
            .map { [weak self] _ in self?.tradingMode ?? .demo }
            .removeDuplicates()
            .sink { [weak self] mode in
                Log.trade.info("Trading mode: \(mode.rawValue)")
                Task { @MainActor [weak self] in
                    await self?.handleTradingModeChange(to: mode)
                }
            }
            .store(in: &cancellables)
        
        // Observe connection status
        NotificationCenter.default.publisher(for: .init("WebSocketStatusChanged"))
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                if let status = notification.object as? Bool {
                    self?.isConnected = status
                    self?.connectionStatus = status ? "Connected" : "Disconnected"
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to settings changes for multi-asset trading
        settingsRepo.$selectedTradingPair
            .removeDuplicates()
            .sink { [weak self] pair in
                self?.selectedTradingPair = pair
                Log.settings.info("[SETTINGS] Trading pair updated: \(pair.symbol)")
            }
            .store(in: &cancellables)
        
        settingsRepo.$defaultAmountMode
            .removeDuplicates()
            .sink { [weak self] mode in
                self?.amountMode = mode
            }
            .store(in: &cancellables)
        
        settingsRepo.$defaultAmountValue
            .removeDuplicates()
            .sink { [weak self] value in
                self?.amountValue = value
            }
            .store(in: &cancellables)
        
        // Update equity from TradeManager
        tradeManager.$equity
            .removeDuplicates()
            .sink { [weak self] equity in
                self?.currentEquity = equity
            }
            .store(in: &cancellables)
        
        // P&L HUD live updates with Combine binding + Health heartbeat
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePnLSnapshot()
                self?.logHealthHeartbeat()
            }
            .store(in: &cancellables)
    }
    
    private func reloadDataAndPredict() async {
        await loadMarketData()
        await refreshPredictionAsync()
    }
    
    private func handleTradingModeChange(to mode: TradingMode) async {
        Log.trade.info("Switching to \(mode.title) mode")
        
        // Validate mode requirements
        if mode.requiresAPIKeys {
            let hasValidKeys = await validateAPIKeys()
            if !hasValidKeys {
                await MainActor.run {
                    self.settings.demoMode = false
                    self.settings.paperTrading = true // Fall back to paper mode
                    self.showErrorToast("Live trading requires valid API keys. Switched to Paper mode.")
                }
                return
            }
        }
        
        if mode.allowsRealTrading {
            await MainActor.run {
                self.showSuccessToast("⚠️ Live trading enabled. Real funds at risk!")
            }
        }
        
        // Reload data with new mode
        await loadMarketData()
    }
    
    private func validateAPIKeys() async -> Bool {
        // Check if we have valid API keys for the selected exchange
        do {
            let apiKey = try await KeychainStore.shared.getAPIKey(for: .binance)
            let apiSecret = try await KeychainStore.shared.getAPISecret(for: .binance)
            
            return !apiKey.isEmpty && !apiSecret.isEmpty
        } catch {
            Log.trade.warning("No Binance API keys configured: \(error)")
            return false
        }
    }
    
    private func loadInitialData() {
        Task {
            await loadMarketData()
            await refreshPredictionAsync()
        }
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.loadMarketData()
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadMarketData() async {
        do {
            let effectiveMode = await validateTradingModeCredentials()
            
            switch effectiveMode {
            case .demo:
                generateMockData()
                Log.app.info("Loaded demo market data")
            case .paper:
                // Load real market data with paper trading
                let marketData = try await marketDataService.fetchCandles(
                    symbol: settings.defaultSymbol,
                    timeframe: timeframe
                )
                
                await MainActor.run {
                    self.candles = marketData
                    self.updatePriceInfo()
                    self.updateChartPoints()
                }
                Log.app.info("Loaded live market data: \(marketData.count) candles for Paper mode")
            case .live:
                // Load real market data for live trading (keys already validated)
                let marketData = try await marketDataService.fetchCandles(
                    symbol: settings.defaultSymbol,
                    timeframe: timeframe
                )
                
                await MainActor.run {
                    self.candles = marketData
                    self.updatePriceInfo()
                    self.updateChartPoints()
                }
                Log.app.info("Loaded live market data: \(marketData.count) candles for Live mode")
            }
        } catch {
            Log.app.error("Failed to load market data: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            // Fallback to demo data on error
            generateMockData()
        }
    }
    
    private func validateTradingModeCredentials() async -> TradingMode {
        let requestedMode = tradingMode
        
        switch requestedMode {
        case .demo:
            return .demo
        case .paper:
            // Paper mode can optionally use testnet keys but doesn't require them
            let hasTestnetKeys = await KeychainStore.shared.hasCredentials(for: .binance)
            if hasTestnetKeys && settings.useTestnet {
                Log.app.info("Paper mode using Binance testnet credentials")
            } else {
                Log.app.info("Paper mode using simulated orders (no testnet keys)")
            }
            return .paper
        case .live:
            // Live mode requires valid production API keys
            let hasLiveKeys = await KeychainStore.shared.hasCredentials(for: .binance)
            if hasLiveKeys && !settings.useTestnet {
                Log.app.info("Live mode with production Binance credentials")
                return .live
            } else {
                Log.app.warning("Live mode requested but no valid production API keys found. Falling back to Paper mode.")
                await MainActor.run {
                    // Temporarily switch to paper mode for this session
                    self.settings.paperTrading = true
                }
                return .paper
            }
        }
    }
    
    private func generateMockData() {
        // Generate mock data for demo mode
        let basePrice = 45000.0 + Double.random(in: -2000...2000)
        price = basePrice
        priceChange = Double.random(in: -500...500)
        priceChangePercent = (priceChange / basePrice) * 100
        
        // Generate mock candles
        candles = generateMockCandles(basePrice: basePrice)
        updateChartPoints()
        
        // Generate mock positions
        if openPositions.isEmpty && Bool.random() {
            // openPositions = [
            //     Position(
            //         id: UUID().uuidString,
            //         symbol: "BTCUSDT",
            //         side: "LONG",
            //         size: "0.01",
            //         entryPrice: basePrice - 100,
            //         currentPrice: basePrice,
            //         pnl: 1.0,
            //         pnlPercent: 0.1
            //     )
            // ]
        }
    }
    
    private func generateMockCandles(basePrice: Double) -> [Candle] {
        var mockCandles: [Candle] = []
        let count = 100
        
        for i in 0..<count {
            let timestamp = Date().addingTimeInterval(-Double(i * 300)) // 5-minute intervals
            let volatility = Double.random(in: 0.002...0.01) * basePrice
            let trend = sin(Double(i) * 0.1) * volatility
            
            let open = basePrice + trend + Double.random(in: -volatility...volatility)
            let close = open + Double.random(in: -volatility/2...volatility/2)
            let high = max(open, close) + Double.random(in: 0...volatility/4)
            let low = min(open, close) - Double.random(in: 0...volatility/4)
            let volume = Double.random(in: 100...1000)
            
            let candle = Candle(
                openTime: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
            mockCandles.append(candle)
        }
        
        return mockCandles.reversed()
    }
    
    private func updatePriceInfo() {
        guard let lastCandle = candles.last,
              candles.count >= 2 else { return }
        
        let previousCandle = candles[candles.count - 2]
        price = lastCandle.close
        priceChange = lastCandle.close - previousCandle.close
        priceChangePercent = (priceChange / previousCandle.close) * 100
    }
    
    private func updateChartPoints() {
        guard !candles.isEmpty else {
            chartPoints = []
            return
        }
        
        let closes = candles.suffix(100).map { $0.close }.filter { !$0.isNaN && !$0.isInfinite && $0 > 0 }
        guard closes.count >= 2,
              let maxPrice = closes.max(),
              let minPrice = closes.min(),
              maxPrice > minPrice,
              maxPrice.isFinite && minPrice.isFinite else {
            chartPoints = []
            return
        }
        
        let priceRange = maxPrice - minPrice
        guard priceRange > 0 && priceRange.isFinite else {
            chartPoints = []
            return
        }
        
        chartPoints = closes.enumerated().compactMap { index, close in
            guard close.isFinite && close >= minPrice && close <= maxPrice else { return nil }
            
            let x = CGFloat(index) / max(1, CGFloat(closes.count - 1))
            let y = CGFloat((close - minPrice) / priceRange)
            
            guard x.isFinite && y.isFinite && x >= 0 && x <= 1 && y >= 0 && y <= 1 else { return nil }
            
            return CGPoint(x: x, y: y)
        }
    }
    
    /// Update P&L snapshot with live data from TradeManager
    private func updatePnLSnapshot() {
        Task { @MainActor in
            // Get current position from TradeManager
            let currentPosition = await tradeManager.getCurrentPosition()
            
            // Get current equity from TradeManager
            let currentEquity = await tradeManager.getCurrentEquity()
            
            // Get P&L snapshot from PnLManager
            let snapshot = await PnLManager.shared.snapshot(
                price: price, 
                position: currentPosition, 
                equity: currentEquity
            )
            
            // Update published property with live P&L data
            currentPnLSnapshot = snapshot
            
            Log.pnl.debug("[PNL] Live update: equity=\(String(format: "%.2f", snapshot.equity)), realized=\(String(format: "%.2f", snapshot.realizedToday)), unrealized=\(String(format: "%.2f", snapshot.unrealized))")
        }
    }
    
    /// Production-grade health heartbeat log - validates everything is coherent
    private func logHealthHeartbeat() {
        Task { @MainActor in
            // Determine current source based on timeframe routing
            let source: String
            switch timeframe {
            case .h4:
                source = "4h Model"
            case .m1, .m5, .m15, .h1, .d1:
                source = "Strategies"
            }
            
            // Get current signal info
            let signal = currentSignal?.direction ?? "NONE"
            let conf = String(format: "%.2f", currentSignal?.confidence ?? 0.0)
            
            // Get current position and equity from TradeManager
            let currentPosition = await tradeManager.getCurrentPosition()
            let currentEquity = await tradeManager.getCurrentEquity()
            
            // Format position (positive = long, negative = short, 0 = flat)
            let positionStr: String
            if let pos = currentPosition, pos.quantity != 0 {
                let sign = pos.quantity > 0 ? "+" : ""
                positionStr = "\(sign)\(String(format: "%.6f", pos.quantity))"
            } else {
                positionStr = "0.000000"
            }
            
            // Format equity with thousands separators
            let equityStr = String(format: "$%.0f", currentEquity)
            
            // [HEALTH] heartbeat log as specified
            Log.health.info("[HEALTH] tframe=\(timeframe.rawValue) source=\(source) signal=\(signal) conf=\(conf) pos=\(positionStr) BTC equity=\(equityStr)")
        }
    }
    
    // MARK: - Public Methods
    func refreshData() {
        Task {
            await loadMarketData()
            await refreshPredictionAsync()
        }
    }
    
    // MARK: - Prediction
    func refreshPrediction() {
        guard !isRefreshing else { return }
        
        Task {
            await refreshPredictionAsync()
        }
    }
    
    private func refreshPredictionAsync() async {
        // Use intelligent inference throttling
        guard InferenceThrottler.shared.shouldAllowInference() else {
            let throttleStatus = InferenceThrottler.shared.getThrottleStatus()
            if settings.verboseAILogs {
                Log.ai.info("Inference throttled: \(throttleStatus.level.description), next in \(String(format: "%.1f", throttleStatus.nextInferenceIn))s")
            }
            return
        }
        
        await MainActor.run {
            isRefreshing = true
        }
        
        defer {
            Task { @MainActor in
                isRefreshing = false
                lastUpdated = Date()
            }
        }
        
        // Record inference for throttling
        InferenceThrottler.shared.recordInference()
        lastPredictionTime = Date()
        
        guard self.candles.count >= 50 else {
            logger.warning("Insufficient candles for prediction: \(self.candles.count)")
            return
        }
        
        let verboseLogging = AppSettings.shared.verboseAILogs
        
        // Use MetaSignalEngine to generate unified signal
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let metaSignal = await metaSignalEngine.generateMetaSignal(
                for: selectedTradingPair,
                timeframe: timeframe,
                candles: self.candles
            )
            
            let inferenceTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            if verboseLogging {
                logger.info("MetaSignal inference time: \(String(format: "%.1f", inferenceTime))ms")
                logger.info("MetaSignal: \(metaSignal.direction.rawValue) @ \(String(format: "%.1f%%", metaSignal.confidence * 100))")
            }
            
            // Convert MetaSignal to SignalInfo for UI compatibility
            let signalInfo: SignalInfo = SignalInfo(
                direction: metaSignal.direction.rawValue,
                confidence: metaSignal.confidence,
                reason: metaSignal.source,
                timestamp: metaSignal.timestamp
            )
            
            await MainActor.run {
                self.currentSignal = signalInfo
                self.confidence = metaSignal.confidence
                
                // Auto trading logic
                if self.autoTradingEnabled {
                    self.handleAutoTrading(signal: signalInfo)
                }
            }
            
        } catch {
            logger.error("MetaSignal generation failed: \(error)")
            await MainActor.run {
                self.currentSignal = nil
                self.confidence = 0.0
            }
        }
    }
    
    private func generateDemoSignal() -> SignalInfo {
        let signals = ["BUY", "SELL", "HOLD"]
        let direction = signals.randomElement() ?? "HOLD"
        let confidence = Double.random(in: 0.5...0.95)
        
        let reasons = [
            "BUY": "Strong bullish momentum detected",
            "SELL": "Bearish reversal pattern identified",
            "HOLD": "Market consolidating, wait for breakout"
        ]
        
        return SignalInfo(
            direction: direction,
            confidence: confidence,
            reason: reasons[direction] ?? "Demo signal",
            timestamp: Date()
        )
    }
    
    private func combineSignals(
        coreML: PredictionResult?,
        verboseLogging: Bool
    ) -> SignalInfo {
        // FIXED PER-TIMEFRAME ROUTING: 4h→AI, m5/h1→Strategies (always)
        
        switch timeframe {
        case .h4:
            // 4H always uses AI model
            Log.routing.info("[ROUTING] timeframe=h4 pair=\(selectedTradingPair.symbol) source=AI")
            
            if let coreML = coreML {
                Log.ai.info("[AI] classProbability \(coreML.signal) conf=\(String(format: "%.3f", coreML.confidence)) → FINAL=\(coreML.signal) conf=\(String(format: "%.2f", coreML.confidence))")
                
                let sourceLabel = "4h Model"
                let reason = "\(coreML.signal) • \(sourceLabel) • h4"
                
                return SignalInfo(
                    direction: coreML.signal,
                    confidence: coreML.confidence, // AI: 0.55-0.95
                    reason: reason,
                    timestamp: Date()
                )
            } else {
                Log.ai.warning("⚠️ 4H AI model failed, falling back to strategies")
                Log.routing.info("[ROUTING] timeframe=h4 pair=\(selectedTradingPair.symbol) source=Strategies (AI fallback)")
                return getStrategySignal(source: "4h Model (fallback)")
            }
            
        case .m1, .m5, .m15, .h1, .d1:
            // Short timeframes always use strategies (per specification)
            Log.routing.info("[ROUTING] timeframe=\(timeframe.rawValue) pair=\(selectedTradingPair.symbol) source=Strategies")
            return getStrategySignal(source: "Strategies")
        }
    }
    
    /// Get strategy-based signal using StrategyEngine
    private func getStrategySignal(source: String) -> SignalInfo {
        // Use new StrategyEngine for vote aggregation with proper [STRATEGY] logging
        if let strategyOutcome = StrategyEngine.shared.generateSignal(timeframe: timeframe, candles: candles) {
            let sourceLabel = "\(strategyOutcome.source) • \(timeframe.rawValue)"
            let reason = "\(strategyOutcome.signal) • \(sourceLabel)"
            
            // Comprehensive strategy outcome logging
            Log.ai.info("📊 Strategy result: \(strategyOutcome.signal) (conf=\(String(format: "%.2f", strategyOutcome.confidence)))")
            Log.ai.debug("🗳️ Vote breakdown: \(strategyOutcome.voteBreakdown)")
            Log.ai.debug("⚡ Active strategies: \(strategyOutcome.activeStrategies.count)/5 [\(strategyOutcome.activeStrategies.joined(separator: ", "))]")
            
            // Log strategy effectiveness if verbose logging enabled
            if settings.verboseAILogs {
                let totalVotes = strategyOutcome.voteBreakdown.values.reduce(0, +)
                let winningVotes = strategyOutcome.voteBreakdown[strategyOutcome.signal] ?? 0
                let consensus = totalVotes > 0 ? Double(winningVotes) / Double(totalVotes) : 0.0
                Log.ai.debug("📈 Consensus: \(String(format: "%.1f%%", consensus * 100)) (\(winningVotes)/\(totalVotes) votes)")
            }
            
            return SignalInfo(
                direction: strategyOutcome.signal,
                confidence: strategyOutcome.confidence, // Strategies: 0.55-0.90
                reason: reason,
                timestamp: Date()
            )
        } else {
            Log.ai.warning("⚠️ No strategy signal generated - insufficient data or no active strategies")
            Log.ai.debug("🔍 Strategy diagnostics: candles=\(candles.count), active=\(StrategyEngine.shared.activeStrategies.count), routing=\(StrategyEngine.shared.isUseStrategiesForShortTF)")
            
            return SignalInfo(
                direction: "HOLD",
                confidence: 0.55,
                reason: "No clear signal right now • \(source) • \(timeframe.rawValue)",
                timestamp: Date()
            )
        }
    }
    
    private func getSignalScore(_ signal: String) -> Double {
        switch signal.uppercased() {
        case "BUY": return 1.0
        case "SELL": return -1.0
        case "HOLD": return 0.0
        default: return 0.0
        }
    }
    
    private func directionToString(_ direction: String) -> String {
        switch direction {
        case "buy": return "BUY"
        case "sell": return "SELL"
        case "hold": return "HOLD"
        default: return "HOLD"
        }
    }
    
    private func modelKindForTimeframe(_ timeframe: Timeframe) -> ModelKind {
        switch timeframe {
        case .m1: return .m5  // Use m5 model for m1
        case .m5: return .m5
        case .m15: return .h1  // Use h1 model for m15
        case .h1: return .h1
        case .h4: return .h4
        case .d1: return .h4  // Use h4 model for d1
        }
    }
    
    /// Handle trading pair change - reload market data for new pair
    private func handlePairChange() async {
        Log.app.info("Trading pair changed to \(selectedTradingPair.symbol)")
        
        // Update settings repository
        await MainActor.run {
            settingsRepo.selectedTradingPair = selectedTradingPair
        }
        
        // Reload market data for new pair
        await loadMarketData()
        
        // Refresh prediction with new data
        await refreshPredictionAsync()
        
        Log.app.info("Market data reloaded for \(selectedTradingPair.symbol)")
    }
    
}
