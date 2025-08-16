import Foundation
import Combine
import SwiftUI
import CoreML
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "Dashboard")


// Using the canonical TradingMode from Models/TradingMode.swift

enum Mode: String, CaseIterable { 
    case normal, precision 
}



// MARK: - Strategy Store (inline)
private class StrategyStore {
    static let shared = StrategyStore()
    
    func evaluateStrategies(candles: [Candle], timeframe: Timeframe) -> SignalInfo? {
        guard candles.count >= 20 else { return nil }
        
        // Simple RSI strategy
        let rsi = calculateRSI(candles: candles, period: 14)
        if rsi < 30 {
            return SignalInfo(direction: "BUY", confidence: 65, reason: "RSI oversold")
        } else if rsi > 70 {
            return SignalInfo(direction: "SELL", confidence: 65, reason: "RSI overbought")
        }
        
        return SignalInfo(direction: "HOLD", confidence: 50, reason: "No clear signal")
    }
    
    private func calculateRSI(candles: [Candle], period: Int) -> Double {
        guard candles.count >= period else { return 50.0 }
        
        var gains: [Double] = []
        var losses: [Double] = []
        
        for i in 1..<min(candles.count, period + 1) {
            let change = candles[i].close - candles[i-1].close
            if change > 0 {
                gains.append(change)
                losses.append(0)
            } else {
                gains.append(0)
                losses.append(-change)
            }
        }
        
        let avgGain = gains.reduce(0, +) / Double(gains.count)
        let avgLoss = losses.reduce(0, +) / Double(losses.count)
        
        guard avgLoss > 0 else { return 50.0 }
        let rs = avgGain / avgLoss
        return 100 - (100 / (1 + rs))
    }
}

@MainActor
final class DashboardVM: ObservableObject {
    // MARK: - Injected Dependencies
    @Injected private var marketDataService: MarketDataServiceProtocol
    @Injected private var aiModelManager: AIModelManagerProtocol
    @Injected private var errorManager: ErrorManagerProtocol
    @Injected private var settings: AppSettingsProtocol
    @Injected private var strategyManager: StrategyManagerProtocol
    
    // MARK: - Published Properties
    @Published var price: Double = 0.0
    @Published var priceChange: Double = 0.0
    @Published var priceChangePercent: Double = 0.0
    @Published var candles: [Candle] = []
    @Published var chartPoints: [CGPoint] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    
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
    @Published var tradingMode: TradingMode = .manual
    @Published var confidence: Double = 0.0
    @Published var currentSignal: SignalInfo?
    @Published var openPositions: [Position] = []
    @Published var isConnected: Bool = false
    @Published var connectionStatus: String = "Connecting..."
    @Published var lastUpdated: Date = Date()
    
    // Trade confirmation
    @Published var showingTradeConfirmation = false
    @Published var pendingTradeRequest: TradeRequest?
    @Published var isExecutingTrade = false
    
    // Toast notifications
    @Published var showingToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success
    
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
        
        // Observe trading mode changes  
        $tradingMode
            .removeDuplicates()
            .sink { [weak self] mode in
                Log.trade.info("Trading mode \(mode.rawValue)")
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
    }
    
    private func reloadDataAndPredict() async {
        await loadMarketData()
        await refreshPredictionAsync()
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
            if settings.demoMode {
                generateMockData()
                Log.app.info("Loaded demo market data")
            } else if settings.liveMarketData {
                // Load real market data
                let marketData = try await marketDataService.fetchCandles(
                    symbol: settings.defaultSymbol,
                    timeframe: timeframe
                )
                
                await MainActor.run {
                    self.candles = marketData
                    self.updatePriceInfo()
                    self.updateChartPoints()
                }
                Log.app.info("Loaded live market data: \(marketData.count) candles")
            } else {
                // Fallback to demo data
                generateMockData()
                Log.app.info("Fallback to demo data")
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
        
        let closes = candles.suffix(100).map { $0.close }
        guard let maxPrice = closes.max(),
              let minPrice = closes.min(),
              maxPrice > minPrice else {
            chartPoints = []
            return
        }
        
        let priceRange = maxPrice - minPrice
        chartPoints = closes.enumerated().map { index, close in
            CGPoint(
                x: CGFloat(index) / CGFloat(closes.count - 1),
                y: CGFloat((close - minPrice) / priceRange)
            )
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
        
        // let verboseLogging = AppSettings.shared.verboseAILogs
        let verboseLogging = false
        
        // if AppSettings.shared.demoMode {
        //     // Demo mode - generate synthetic signal
        //     let demoSignal = generateDemoSignal()
        //     await MainActor.run {
        //         self.currentSignal = demoSignal
        //     }
        //     
        //     if verboseLogging {
        //         logger.info("Demo signal: \(demoSignal.direction) @ \(String(format: "%.1f%%", demoSignal.confidence * 100))")
        //     }
        // } else {
        // Live mode - use ensemble strategy engine
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Get ensemble decision
        // let ensembleDecision = ensembleDecider.decide(
        //     candles: candles,
        //     verboseLogging: verboseLogging
        // )
        
        // Try to get CoreML prediction
        let coreMLSignal = await aiModelManager.predictSafely(
            timeframe: timeframe,
            candles: self.candles,
            mode: .manual
        )
        
        // Combine ensemble and CoreML signals
        let finalSignal = combineSignals(
            // ensemble: ensembleDecision,
            coreML: coreMLSignal,
            verboseLogging: verboseLogging
        )
        
        let inferenceTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        if verboseLogging {
            logger.info("Inference time: \(String(format: "%.1f", inferenceTime))ms")
            logger.info("Final signal: \(finalSignal.direction) @ \(String(format: "%.1f%%", finalSignal.confidence * 100))")
        }
        
        await MainActor.run {
            self.currentSignal = finalSignal
            self.confidence = finalSignal.confidence
            
            // Auto trading logic
            if self.tradingMode == .auto && settings.autoTrading {
                self.handleAutoTrading(signal: finalSignal)
            }
        }
        // }
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
        // ensemble: EnsembleDecision,
        coreML: PredictionResult?,
        verboseLogging: Bool
    ) -> SignalInfo {
        // If no CoreML signal, use ensemble only
        guard let coreML = coreML else {
            return SignalInfo(
                direction: directionToString("hold"), // Default to HOLD if no CoreML signal
                confidence: 0.0, // No confidence if no CoreML signal
                reason: "No CoreML signal available.",
                timestamp: Date()
            )
        }
        
        // Weight: 60% ensemble, 40% CoreML
        let ensembleWeight = 0.6
        let coreMLWeight = 0.4
        
        // Convert to scores
        var buyScore = 0.0
        var sellScore = 0.0
        var holdScore = 0.0
        
        // Add ensemble scores
        // switch ensemble.direction {
        // case .buy:
        //     buyScore += ensemble.confidence * ensembleWeight
        // case .sell:
        //     sellScore += ensemble.confidence * ensembleWeight
        // case .hold:
        //     holdScore += ensemble.confidence * ensembleWeight
        // }
        
        // Add CoreML scores
        switch coreML.signal {
        case "BUY":
            buyScore += coreML.confidence * coreMLWeight
        case "SELL":
            sellScore += coreML.confidence * coreMLWeight
        case "HOLD":
            holdScore += coreML.confidence * coreMLWeight
        default:
            holdScore += coreML.confidence * coreMLWeight
        }
        
        // Determine final direction
        let maxScore = max(buyScore, sellScore, holdScore)
        let direction: String
        let confidence: Double
        
        if maxScore == buyScore && buyScore > 0.4 {
            direction = "BUY"
            confidence = buyScore
        } else if maxScore == sellScore && sellScore > 0.4 {
            direction = "SELL"
            confidence = sellScore
        } else {
            direction = "HOLD"
            confidence = holdScore
        }
        
        var reason = "CoreML \(coreML.modelName)" // No ensemble reasoning in this simplified example
        
        // If AI returns HOLD and strategies are enabled, check for secondary suggestions
        if direction == "HOLD" {
            if let strategySignal = StrategyStore.shared.evaluateStrategies(candles: self.candles, timeframe: self.timeframe) {
                reason = "AI: HOLD, Strategy: \(strategySignal)"
                Log.ai.info("Strategy override: \(strategySignal)")
            }
        }
        
        if verboseLogging {
            logger.info("Combined scores - Buy: \(String(format: "%.2f", buyScore)), Sell: \(String(format: "%.2f", sellScore)), Hold: \(String(format: "%.2f", holdScore))")
        }
        
        return SignalInfo(
            direction: direction,
            confidence: confidence,
            reason: reason,
            timestamp: Date()
        )
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
        case .m5: return .m5
        case .h1: return .h1
        case .h4: return .h4
        }
    }
    
    // MARK: - Trading Actions
    func executeBuy() {
        guard !settings.autoTrading else { 
            logger.warning("Manual trading disabled in auto mode")
            return 
        }
        
        HapticFeedback.impact(.medium)
        
        if settings.confirmTrades {
            // Show confirmation dialog
            logger.info("Buy order confirmation required")
            showTradeConfirmation(side: .buy)
        } else {
            // Execute immediately
            logger.info("Executing buy order immediately")
            isExecutingTrade = true
            Task {
                await performTradeExecution(side: .buy)
                await MainActor.run {
                    self.isExecutingTrade = false
                }
            }
        }
    }
    
    func executeSell() {
        guard !settings.autoTrading else { 
            logger.warning("Manual trading disabled in auto mode")
            return 
        }
        
        HapticFeedback.impact(.medium)
        
        if settings.confirmTrades {
            // Show confirmation dialog
            logger.info("Sell order confirmation required")
            showTradeConfirmation(side: .sell)
        } else {
            // Execute immediately
            logger.info("Executing sell order immediately")
            isExecutingTrade = true
            Task {
                await performTradeExecution(side: .sell)
                await MainActor.run {
                    self.isExecutingTrade = false
                }
            }
        }
    }
    
    private func showTradeConfirmation(side: OrderSide) {
        logger.info("Showing trade confirmation for \(side.rawValue) order")
        
        // Calculate trade size
        let tradeSize = calculateTradeSize()
        
        // Create trade request
        let tradeRequest = TradeRequest(
            symbol: settings.defaultSymbol,
            side: side,
            amount: tradeSize,
            price: price,
            mode: tradingMode,
            isDemo: settings.demoMode
        )
        
        // Show confirmation dialog
        pendingTradeRequest = tradeRequest
        showingTradeConfirmation = true
    }
    
    func confirmTrade() {
        guard let tradeRequest = pendingTradeRequest else { return }
        
        logger.info("Trade confirmed by user: \(tradeRequest.side.rawValue)")
        
        // Start executing trade (show loading state)
        isExecutingTrade = true
        
        // Execute the trade
        Task {
            await performTradeExecution(side: tradeRequest.side)
            
            // Hide confirmation dialog and stop loading after execution
            await MainActor.run {
                self.showingTradeConfirmation = false
                self.pendingTradeRequest = nil
                self.isExecutingTrade = false
            }
        }
    }
    
    func cancelTrade() {
        logger.info("Trade cancelled by user")
        
        // Hide confirmation dialog
        showingTradeConfirmation = false
        pendingTradeRequest = nil
        isExecutingTrade = false
    }
    
    private func performTradeExecution(side: OrderSide) async {
        logger.info("Performing trade execution: \(side.rawValue)")
        
        // Determine trade size based on risk management
        let tradeSize = calculateTradeSize()
        
        // Create order request
        let symbol = Symbol(settings.defaultSymbol, exchange: .binance)
        let orderRequest = OrderRequest(
            symbol: symbol,
            side: side,
            quantity: tradeSize
        )
        
        do {
            if settings.demoMode {
                // Demo mode - simulate trade
                let simulatedFill = await simulateTradeExecution(orderRequest: orderRequest)
                await handleTradeResult(fill: simulatedFill, error: nil)
            } else {
                // Live/Paper mode - use exchange client
                let exchangeClient = getExchangeClient()
                let orderFill = try await exchangeClient.placeMarketOrder(orderRequest)
                await handleTradeResult(fill: orderFill, error: nil)
            }
        } catch {
            logger.error("Trade execution failed: \(error.localizedDescription)")
            await handleTradeResult(fill: nil, error: error)
        }
    }
    
    private func calculateTradeSize() -> Double {
        // Simple position sizing - 1% of account balance
        let accountBalance = 10000.0 // This would come from account info
        let riskPercent = 0.01 // 1%
        let riskAmount = accountBalance * riskPercent
        
        // Calculate position size based on current price
        let positionSize = riskAmount / price
        
        // Minimum and maximum position sizes
        let minSize = 0.001
        let maxSize = 0.1
        
        return max(minSize, min(maxSize, positionSize))
    }
    
    private func getExchangeClient() -> ExchangeClient {
        // This would return the appropriate exchange client
        // For now, return a paper trading client
        return PaperExchangeClient()
    }
    
    private func simulateTradeExecution(orderRequest: OrderRequest) async -> OrderFill {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Create simulated fill
        let fillPrice = price + Double.random(in: -10...10) // Add some slippage
        
        return OrderFill(
            symbol: orderRequest.symbol,
            side: orderRequest.side,
            quantity: orderRequest.quantity,
            price: fillPrice,
            timestamp: Date()
        )
    }
    
    private func handleTradeResult(fill: OrderFill?, error: Error?) async {
        await MainActor.run {
            if let fill = fill {
                // Trade successful
                logger.info("Trade executed: \(fill.side.rawValue) \(fill.quantity) at \(fill.price)")
                
                // Update positions
                updatePositions(with: fill)
                
                // Show success feedback
                HapticFeedback.success()
                
                // Show success toast
                showTradeSuccessToast(fill: fill)
                
                // Update last trade time for auto trading cooldown
                lastAutoTradeTime = Date()
                
            } else if let error = error {
                // Trade failed
                logger.error("Trade failed: \(error.localizedDescription)")
                errorManager.handle(error, context: "Trade Execution")
                
                // Show error feedback
                HapticFeedback.error()
                
                // Show error toast
                showTradeErrorToast(error: error)
            }
        }
    }
    
    private func updatePositions(with fill: OrderFill) {
        // Update position tracking
        // This would integrate with the position management system
        logger.info("Updating positions with fill: \(fill.side.rawValue) \(fill.quantity)")
        
        // For now, just log the position update
        // In a full implementation, this would:
        // 1. Update the position in the position manager
        // 2. Calculate new P&L
        // 3. Update the UI
        // 4. Store the trade in the trade history
    }
    
    // MARK: - Auto Trading
    private var lastAutoTradeTime: Date = .distantPast
    private let autoTradeCooldown: TimeInterval = 60.0 // 60 seconds
    
    private func handleAutoTrading(signal: SignalInfo) {
        // Cooldown check
        let timeSinceLastTrade = Date().timeIntervalSince(lastAutoTradeTime)
        guard timeSinceLastTrade >= autoTradeCooldown else {
            Log.ai.info("Auto trading on cooldown: \(String(format: "%.1f", timeSinceLastTrade))s / \(autoTradeCooldown)s")
            return
        }
        
        // Only act on strong signals
        guard signal.confidence > 0.7 else {
            Log.ai.info("Auto trading: Signal confidence too low (\(String(format: "%.1f", signal.confidence)))")
            return
        }
        
        // Paper trading simulation
        if settings.confirmTrades { // Using confirmTrades as paper trading toggle
            simulatePaperTrade(signal: signal)
        } else {
            Log.ai.info("❌ Live trading disabled for safety")
        }
    }
    
    private func simulatePaperTrade(signal: SignalInfo) {
        lastAutoTradeTime = Date()
        
        let orderType = signal.direction
        let confidence = String(format: "%.1f%%", signal.confidence * 100)
        
        Log.ai.info("📝 Paper Trade Simulated: \(orderType) @ \(price) (confidence: \(confidence))")
        Log.ai.info("↳ Reason: \(signal.reason)")
        
        // This would integrate with PaperExchangeClient in a full implementation
        // For now, just log the simulated trade
    }
    
    // MARK: - Public Methods
    func refreshData() {
        Task {
            isLoading = true
            await loadMarketData()
            await refreshPredictionAsync()
            isLoading = false
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Toast Methods
    
    private func showTradeSuccessToast(fill: OrderFill) {
        let symbol = fill.symbol.display
        let side = fill.side.rawValue.capitalized
        let amount = formatAmount(fill.quantity)
        
        toastMessage = "\(side) order for \(amount) \(symbol) submitted successfully"
        toastType = .success
        showingToast = true
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showingToast = false
        }
    }
    
    private func showTradeErrorToast(error: Error) {
        toastMessage = "Order failed: \(error.localizedDescription)"
        toastType = .error
        showingToast = true
        
        // Auto-dismiss after 5 seconds for errors
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.showingToast = false
        }
    }
    
    // MARK: - Public Toast Methods
    
    func showSuccessToast(_ message: String) {
        toastMessage = message
        toastType = .success
        showingToast = true
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showingToast = false
        }
    }
    
    func showErrorToast(_ message: String) {
        toastMessage = message
        toastType = .error
        showingToast = true
        
        // Auto-dismiss after 5 seconds for errors
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.showingToast = false
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount >= 1.0 {
            return String(format: "%.4f", amount)
        } else if amount >= 0.001 {
            return String(format: "%.6f", amount)
        } else {
            return String(format: "%.8f", amount)
        }
    }
}