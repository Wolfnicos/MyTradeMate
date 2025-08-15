import Foundation
import Combine
import SwiftUI
import CoreML
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "Dashboard")

// MARK: - Logging Helper
private enum Log {
    static func ai(_ msg: @autoclosure () -> String) {
        print("[AI] \(msg())")
    }
}

// Using the canonical TradingMode from Models/TradingMode.swift

enum Mode: String, CaseIterable { 
    case normal, precision 
}

// MARK: - Signal Info
struct SignalInfo {
    let direction: String  // "BUY", "SELL", "HOLD"
    let confidence: Double // 0-100
    let reason: String
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
    @Published var isPrecisionMode: Bool = false
    @Published var currentSignal: SignalInfo?
    @Published var openPositions: [Position] = []
    @Published var isConnected: Bool = false
    @Published var connectionStatus: String = "Connecting..."
    @Published var lastUpdated: Date = Date()
    @Published var tradingMode: TradingMode = .manual
    
    // MARK: - Private Properties
    private let aiModelManager = AIModelManager.shared
    // private let ensembleDecider = EnsembleDecider()
    private let marketDataService = MarketDataService.shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private var lastPredictionTime: Date = .distantPast
    private var lastThrottleLog: Date = .distantPast
    
    // MARK: - Signal Info
    struct SignalInfo {
        let direction: String // "BUY", "SELL", "HOLD"
        let confidence: Double
        let reason: String
        let timestamp: Date
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
        loadInitialData()
        startAutoRefresh()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Observe timeframe changes with debounce
        $timeframe
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.refreshPredictionAsync()
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
            // In demo mode, generate mock data
            // if AppSettings.shared.demoMode {
            //     generateMockData()
            // } else {
            //     // Load real market data
            //     let marketData = try await marketDataService.fetchCandles(
            //         symbol: "BTCUSDT",
            //         timeframe: timeframe
            //     )
            //     
            //     await MainActor.run {
            //         self.candles = marketData
            //         self.updatePriceInfo()
            //         self.updateChartPoints()
            //     }
            // }
            
            // Generate mock data for now
            generateMockData()
        } catch {
            logger.error("Failed to load market data: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
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
        // Throttle predictions
        let timeSinceLastPrediction = Date().timeIntervalSince(lastPredictionTime)
        guard timeSinceLastPrediction >= 0.5 else {
            // Only log throttling when verbose logging is enabled and at most once per second
            let now = Date()
            if AppSettings.shared.verboseAILogs && now.timeIntervalSince(lastThrottleLog) >= 1.0 {
                Log.ai("Throttling prediction, last was \(String(format: "%.1f", timeSinceLastPrediction))s ago")
                lastThrottleLog = now
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
            
            // Auto trading logic
            if self.tradingMode == .auto && AppSettings.shared.confirmTrades {
                self.handleAutoTrading(signal: finalSignal)
            }
        }
        // }
    }
    
    private func generateDemoSignal() -> SignalInfo {
        let signals = ["BUY", "SELL", "HOLD"]
        let direction = signals.randomElement()!
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
        case .buy:
            buyScore += coreML.confidence * coreMLWeight
        case .sell:
            sellScore += coreML.confidence * coreMLWeight
        case .hold:
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
        
        var reason = "CoreML \(coreML.modelUsed)" // No ensemble reasoning in this simplified example
        
        // If AI returns HOLD and strategies are enabled, check for secondary suggestions
        if direction == "HOLD" {
            if let strategySignal = StrategyStore.shared.evaluateStrategies(candles: self.candles, timeframe: self.timeframe) {
                reason = "AI: HOLD, Strategy: \(strategySignal)"
                Log.ai("Strategy override: \(strategySignal)")
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
        // guard !AppSettings.shared.autoTrading else { return }
        
        // Haptics.impact(.medium)
        
        // if AppSettings.shared.confirmTrades {
        //     // Show confirmation dialog
        //     logger.info("Buy order confirmation required")
        // } else {
        //     // Execute immediately
        //     logger.info("Executing buy order")
        //     // TODO: Implement trade execution
        // }
        
        logger.info("Executing buy order")
    }
    
    func executeSell() {
        // guard !AppSettings.shared.autoTrading else { return }
        
        // Haptics.impact(.medium)
        
        // if AppSettings.shared.confirmTrades {
        //     // Show confirmation dialog
        //     logger.info("Sell order confirmation required")
        // } else {
        //     // Execute immediately
        //     logger.info("Executing sell order")
        //     // TODO: Implement trade execution
        // }
        
        logger.info("Executing sell order")
    }
    
    // MARK: - Auto Trading
    private var lastAutoTradeTime: Date = .distantPast
    private let autoTradeCooldown: TimeInterval = 60.0 // 60 seconds
    
    private func handleAutoTrading(signal: SignalInfo) {
        // Cooldown check
        let timeSinceLastTrade = Date().timeIntervalSince(lastAutoTradeTime)
        guard timeSinceLastTrade >= autoTradeCooldown else {
            Log.ai("Auto trading on cooldown: \(String(format: "%.1f", timeSinceLastTrade))s / \(autoTradeCooldown)s")
            return
        }
        
        // Only act on strong signals
        guard signal.confidence > 0.7 else {
            Log.ai("Auto trading: Signal confidence too low (\(String(format: "%.1f", signal.confidence)))")
            return
        }
        
        // Paper trading simulation
        if AppSettings.shared.confirmTrades { // Using confirmTrades as paper trading toggle
            simulatePaperTrade(signal: signal)
        } else {
            Log.ai("❌ Live trading disabled for safety")
        }
    }
    
    private func simulatePaperTrade(signal: SignalInfo) {
        lastAutoTradeTime = Date()
        
        let orderType = signal.direction
        let confidence = String(format: "%.1f%%", signal.confidence * 100)
        
        Log.ai("📝 Paper Trade Simulated: \(orderType) @ \(price) (confidence: \(confidence))")
        Log.ai("↳ Reason: \(signal.reason)")
        
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
}