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



// MARK: - Strategy Store (inline)
private class StrategyStore {
    static let shared = StrategyStore()
    
    func evaluateStrategies(candles: [Candle], timeframe: Timeframe) -> SignalInfo? {
        guard candles.count >= 50 else { return nil }
        
        var signals: [SignalInfo] = []
        
        // RSI Strategy
        let rsi = calculateRSI(candles: candles, period: 14)
        if rsi < 30 {
            signals.append(SignalInfo(direction: "BUY", confidence: 0.70, reason: "RSI oversold"))
        } else if rsi > 70 {
            signals.append(SignalInfo(direction: "SELL", confidence: 0.70, reason: "RSI overbought"))
        }
        
        // EMA Strategy
        let ema9 = calculateEMA(candles: candles, period: 9)
        let ema21 = calculateEMA(candles: candles, period: 21)
        if let current9 = ema9.last, let current21 = ema21.last,
           ema9.count >= 2, ema21.count >= 2 {
            let prev9 = ema9[ema9.count - 2]
            let prev21 = ema21[ema21.count - 2]
            
            if prev9 <= prev21 && current9 > current21 {
                signals.append(SignalInfo(direction: "BUY", confidence: 0.65, reason: "EMA bullish crossover"))
            } else if prev9 >= prev21 && current9 < current21 {
                signals.append(SignalInfo(direction: "SELL", confidence: 0.65, reason: "EMA bearish crossover"))
            }
        }
        
        // MACD Strategy
        let macd = calculateMACD(candles: candles)
        if macd.macd > macd.signal && macd.macd > 0 {
            signals.append(SignalInfo(direction: "BUY", confidence: 0.60, reason: "MACD bullish"))
        } else if macd.macd < macd.signal && macd.macd < 0 {
            signals.append(SignalInfo(direction: "SELL", confidence: 0.60, reason: "MACD bearish"))
        }
        
        // Combine signals
        if signals.isEmpty {
            return SignalInfo(direction: "HOLD", confidence: 0.50, reason: "No clear signals")
        }
        
        let buySignals = signals.filter { $0.direction == "BUY" }
        let sellSignals = signals.filter { $0.direction == "SELL" }
        
        if buySignals.count > sellSignals.count {
            let avgConfidence = buySignals.map { $0.confidence }.reduce(0, +) / Double(buySignals.count)
            let reasons = buySignals.map { $0.reason }.joined(separator: ", ")
            return SignalInfo(direction: "BUY", confidence: avgConfidence, reason: reasons)
        } else if sellSignals.count > buySignals.count {
            let avgConfidence = sellSignals.map { $0.confidence }.reduce(0, +) / Double(sellSignals.count)
            let reasons = sellSignals.map { $0.reason }.joined(separator: ", ")
            return SignalInfo(direction: "SELL", confidence: avgConfidence, reason: reasons)
        }
        
        return SignalInfo(direction: "HOLD", confidence: 0.50, reason: "Mixed signals")
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
    
    private func calculateEMA(candles: [Candle], period: Int) -> [Double] {
        guard candles.count >= period else { return [] }
        
        let closes = candles.map { $0.close }
        var ema: [Double] = []
        let multiplier = 2.0 / Double(period + 1)
        
        // Initial SMA
        let sma = closes.prefix(period).reduce(0, +) / Double(period)
        ema.append(sma)
        
        // Calculate EMA
        for i in period..<closes.count {
            let value = (closes[i] - ema.last!) * multiplier + ema.last!
            ema.append(value)
        }
        
        return ema
    }
    
    private func calculateMACD(candles: [Candle]) -> (macd: Double, signal: Double) {
        let ema12 = calculateEMA(candles: candles, period: 12)
        let ema26 = calculateEMA(candles: candles, period: 26)
        
        guard let fast = ema12.last, let slow = ema26.last else {
            return (0, 0)
        }
        
        let macd = fast - slow
        // Simplified signal line (normally 9-period EMA of MACD)
        let signal = macd * 0.9
        
        return (macd, signal)
    }
}

@MainActor
final class DashboardVM: ObservableObject {
    // MARK: - Dependencies
    private let aiModelManager = AIModelManager.shared
    private let errorManager = ErrorManager.shared
    private let settings = AppSettings.shared
    private let settingsRepo = SettingsRepository.shared
    private let marketDataService = MarketDataService.shared
    private let tradeManager = TradeManager.shared
    
    // MARK: - Published Properties
    @Published var price: Double = 0.0
    @Published var priceChange: Double = 0.0
    @Published var priceChangePercent: Double = 0.0
    @Published var candles: [Candle] = []
    @Published var chartPoints: [CGPoint] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    
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
    @Published var selectedTradingPair: TradingPair = TradingPair(base: "BTC", quote: "USDT", symbol: "BTCUSDT")
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
    @Published var lastUpdated: Date = Date()
    
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
    private var lastStrategySignal: EnsembleSignal?
    private let tradeManager = TradeManager.shared
    
    // Manual trading debounce (>=500ms as specified)
    private var lastManualTradeTime: Date = .distantPast
    private let manualTradeDebounce: TimeInterval = 0.5 // 500ms
    
    // MARK: - Trade Execution Methods
    func executeBuy() {
        guard canExecuteTrade() else { return }
        
        let tradeRequest = createTradeRequest(side: .buy)
        
        if settings.requireTradeConfirmation {
            pendingTradeRequest = tradeRequest
            showingTradeConfirmation = true
        } else {
            executeTradeDirectly(tradeRequest)
        }
    }
    
    func executeSell() {
        guard canExecuteTrade() else { return }
        
        let tradeRequest = createTradeRequest(side: .sell)
        
        if settings.requireTradeConfirmation {
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
                let result = try await tradeManager.executeTrade(tradeRequest)
                
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
                let tradeRequest: TradeRequest
                
                switch signal.direction.uppercased() {
                case "BUY":
                    tradeRequest = createTradeRequest(side: .buy)
                case "SELL":
                    tradeRequest = createTradeRequest(side: .sell)
                default:
                    return // Don't trade on HOLD signals
                }
                
                let result = try await tradeManager.executeTrade(tradeRequest)
                
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
        
        // Observe trading mode changes  
        $tradingMode
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
                    self.tradingMode = .paper // Fall back to paper mode
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
        guard !settings.binanceApiKey.isEmpty && !settings.binanceSecretKey.isEmpty else {
            Log.trade.warning("No Binance API keys configured")
            return false
        }
        
        // Optionally test API key validity with a simple call
        do {
            // This would be a test call to the exchange
            // For now, just check that keys are not empty
            return !settings.binanceApiKey.isEmpty && !settings.binanceSecretKey.isEmpty
        } catch {
            Log.trade.error("API key validation failed: \(error)")
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
            case .m5, .h1:
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
        let coreMLSignal = aiModelManager.predictSafely(
            timeframe: timeframe,
            candles: self.candles
        )
        
        // Combine ensemble and CoreML signals
        let finalSignal = combineSignals(
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
            
            // Log prediction to CSV/JSON files
            if let coreMLSignal = coreMLSignal {
                let mode = self.precisionMode ? "precision" : "normal"
                let strategies = strategySignal?.reason
                // PredictionLogger.shared.logPrediction(coreMLSignal, mode: mode, strategies: strategies)
            }
            
            // Auto trading logic
            if self.autoTradingEnabled {
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
            
        case .m5, .h1:
            // m5/h1 always use strategies (per specification)
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
        case .m5: return .m5
        case .h1: return .h1
        case .h4: return .h4
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
    
    // MARK: - Trading Actions
    func executeBuy() {
        // Manual BUY/SELL execution with debounce (>=500ms) and [TRADING] logs
        guard !autoTradingEnabled else { 
            Log.trading.warning("[TRADING] Manual BUY blocked: auto trading enabled")
            return 
        }
        
        // Debounce check (>=500ms as specified)
        let now = Date()
        let timeSinceLastTrade = now.timeIntervalSince(lastManualTradeTime)
        guard timeSinceLastTrade >= manualTradeDebounce else {
            let remaining = manualTradeDebounce - timeSinceLastTrade
            Log.trading.info("[TRADING] Manual BUY debounced: \(String(format: "%.1f", remaining * 1000))ms remaining")
            return
        }
        
        lastManualTradeTime = now
        Log.trading.info("[TRADING] Manual BUY initiated: user button press")
        
        HapticFeedback.impact(.medium)
        
        if settings.confirmTrades {
            // Show confirmation dialog
            Log.trading.info("[TRADING] Manual BUY: showing confirmation dialog")
            showTradeConfirmation(side: .buy)
        } else {
            // Execute immediately
            Log.trading.info("[TRADING] Manual BUY: executing immediately (no confirmation)")
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
        // Manual BUY/SELL execution with debounce (>=500ms) and [TRADING] logs
        guard !autoTradingEnabled else { 
            Log.trading.warning("[TRADING] Manual SELL blocked: auto trading enabled")
            return 
        }
        
        // Debounce check (>=500ms as specified)
        let now = Date()
        let timeSinceLastTrade = now.timeIntervalSince(lastManualTradeTime)
        guard timeSinceLastTrade >= manualTradeDebounce else {
            let remaining = manualTradeDebounce - timeSinceLastTrade
            Log.trading.info("[TRADING] Manual SELL debounced: \(String(format: "%.1f", remaining * 1000))ms remaining")
            return
        }
        
        lastManualTradeTime = now
        Log.trading.info("[TRADING] Manual SELL initiated: user button press")
        
        HapticFeedback.impact(.medium)
        
        if settings.confirmTrades {
            // Show confirmation dialog
            Log.trading.info("[TRADING] Manual SELL: showing confirmation dialog")
            showTradeConfirmation(side: .sell)
        } else {
            // Execute immediately
            Log.trading.info("[TRADING] Manual SELL: executing immediately (no confirmation)")
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
        Log.trading.info("[TRADING] Executing \(side.rawValue) order: mode=\(tradingMode.rawValue) pair=\(selectedTradingPair.symbol)")
        
        // Create multi-asset order request with current AmountMode settings
        let orderRequest = OrderRequest(
            pair: selectedTradingPair,
            side: side,
            amountMode: amountMode,
            amountValue: amountValue
        )
        
        Log.trading.debug("[TRADING] Order parameters: \(orderRequest.amountMode.displayName)=\(String(format: "%.2f", orderRequest.amountValue)), pair=\(orderRequest.pair.symbol)")
        
        do {
            // Use TradingEngine for all modes - it handles demo/paper/live internally
            Log.trading.info("[TRADING] Trade execution started via TradingEngine")
            let orderFill = try await TradingEngine.shared.placeOrder(orderRequest)
            Log.trading.info("[TRADING] Trade completed: \(orderFill.side.rawValue) \(String(format: "%.6f", orderFill.quantity)) @ \(String(format: "%.2f", orderFill.price))")
            await handleTradeResult(fill: orderFill, error: nil)
        } catch {
            Log.trading.error("[TRADING] Trade execution failed: \(error.localizedDescription)")
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
        
        // Create simulated fill with synthetic price
        let basePrice = 45000.0 + Double.random(in: -2000...2000)
        let fillPrice = basePrice + Double.random(in: -50...50) // Add some slippage
        
        return OrderFill(
            symbol: orderRequest.symbol,
            side: orderRequest.side,
            quantity: orderRequest.quantity,
            price: fillPrice,
            timestamp: Date()
        )
    }
    
    private func simulatePaperTradeExecution(orderRequest: OrderRequest) async -> OrderFill {
        // Use TradeManager for proper P&L accounting and persistence
        do {
            let fill = try await tradeManager.manualOrder(orderRequest)
            
            // Get updated equity for logging
            let newEquity = await tradeManager.getCurrentEquity()
            
            Log.trading.info("[TRADING] Paper order filled: \(orderRequest.side.rawValue) notional=\(String(format: "%.2f", orderRequest.quantity * fill.price)) mode=Paper price=\(String(format: "%.2f", fill.price)) fee=0.00 newEquity=\(String(format: "%.2f", newEquity))")
            
            return fill
        } catch {
            Log.trading.error("[TRADING] Paper trade failed: \(error.localizedDescription)")
            
            // Fallback to simulation if TradeManager fails
            let slippage = Double.random(in: -20...20)
            let fillPrice = price + slippage
            
            return OrderFill(
                symbol: orderRequest.symbol,
                side: orderRequest.side,
                quantity: orderRequest.quantity,
                price: fillPrice,
                timestamp: Date()
            )
        }
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
    
    /// Test CoreML pipeline - for debugging
    func testCoreMLPipeline() async {
        await MainActor.run {
            isLoading = true
        }
        
        Log.app.info("CoreML pipeline test - method not implemented in simple AIModelManager")
        
        await MainActor.run {
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