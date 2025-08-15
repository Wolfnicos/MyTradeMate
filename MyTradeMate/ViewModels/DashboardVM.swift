import Foundation
import Combine
import SwiftUI

@MainActor
final class DashboardVM: ObservableObject {
    @Published var exchange: Exchange = .binance
    @Published var symbol: Symbol = Symbol("BTCUSDT", exchange: .binance)
    @Published var price: Double = 0
    @Published var priceUp: Bool = true
    @Published var lastSignal: Signal?
    @Published var lastAIDecision: SignalDecision?
    @Published var lastPrediction: PredictionResult?
    @Published var timeframe: Timeframe = .m5
    @Published var aiMode: AIModelManager.Mode = .normal
    @Published var autoTrading: Bool = false
    @Published var pnl: PnLSnapshot = .init(equity: 10_000, realizedToday: 0, unrealized: 0, ts: .init())
    @Published var signalFlashColor: Color? = nil
    
    private var prev: Double = 0
    private var mockCandles: [Candle] = []
    private let aiManager = AIModelManager.shared
    private let paperTrading = PaperTradingModule.shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?
    
    // AppSettings reference - will be injected via environment
    private weak var appSettings: AppSettings?
    
    // Demo isolation properties
    var isDemoAI: Bool { appSettings?.isDemoAI ?? false }
    var isDemoPnL: Bool { appSettings?.isDemoPnL ?? false }
    var shouldShowAIDebug: Bool { appSettings?.shouldShowAIDebug ?? false }
    
    func configure(with appSettings: AppSettings) {
        self.appSettings = appSettings
        setupTimeframeObserver()
        setupDemoModeObserver()
    }
    
    private func setupTimeframeObserver() {
        // Debounced timeframe switching with auto prediction
        $timeframe
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] tf in
                if let self = self, let appSettings = self.appSettings {
                    if appSettings.shouldShowAIDebug {
                        print("🖥️ timeframe=\(tf.rawValue)")
                    }
                    Task { 
                        await self.refreshPrediction(reason: "timeframe_changed")
                        if appSettings.shouldShowAIDebug {
                            print("✅ Prediction refreshed for timeframe: \(tf.rawValue)")
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupDemoModeObserver() {
        // Observe demo mode changes for isolation
        appSettings?.demoModePublisher
            .removeDuplicates()
            .sink { [weak self] isDemo in
                guard let self = self else { return }
                if !isDemo {
                    // Clear demo-specific data when exiting demo mode
                    self.clearDemoData()
                }
                if let appSettings = self.appSettings, appSettings.shouldShowAIDebug {
                    print("🧪 Demo Mode: \(isDemo ? "ON" : "OFF")")
                }
            }
            .store(in: &cancellables)
    }
    
    private func clearDemoData() {
        // Clear any demo-specific prediction data
        if let prediction = lastPrediction, prediction.modelUsed == "Demo" {
            lastPrediction = nil
            lastSignal = nil
            lastAIDecision = nil
            if shouldShowAIDebug {
                print("🧹 Cleared demo prediction data")
            }
        }
    }
    
    func onAppear() {
        // Generate some mock candle data for AI predictions
        generateMockCandles()
        
        // Observe demo mode changes to reset PnL when toggled off
        aiManager.$pnlDemoMode
            .removeDuplicates()
            .sink { [weak self] isDemo in
                guard let self = self else { return }
                if !isDemo {
                    // Reset to real PnL data when demo mode is turned off
                    Task { await self.resetToRealPnL() }
                }
            }
            .store(in: &cancellables)
        
        Task { await MarketDataService.shared.subscribe { [weak self] tick in
            Task { @MainActor in
                guard let self, tick.symbol == self.symbol else { return }
                self.priceUp = tick.price >= self.prev
                self.prev = tick.price
                self.price = tick.price
                
                // Update mock candles with latest price
                self.updateMockCandles(with: tick.price)
                
                // Update PnL (use demo mode if enabled)
                if self.aiManager.pnlDemoMode {
                    self.updateDemoPnL()
                } else {
                    let pos = await TradeManager.shared.position
                    let eq = await TradeManager.shared.equity
                    await PnLManager.shared.resetIfNeeded()
                    let snap = await PnLManager.shared.snapshot(price: tick.price, position: pos, equity: eq)
                    await MainActor.run { self.pnl = snap }
                }
            }
        }}
        Task { await MarketDataService.shared.start(symbol: symbol) }
    }
    
    func changeExchange(_ ex: Exchange) {
        exchange = ex
        symbol = Symbol(symbol.raw, exchange: ex)
        Task {
            await MarketDataService.shared.stop()
            await TradeManager.shared.setExchange(ex)
            await MarketDataService.shared.start(symbol: symbol)
        }
    }
    
    func generateSignal() {
        Task {
            await refreshSignal(reason: "manual_trigger")
        }
    }
    
    func refreshPrediction(reason: String) async {
        // Cancel any previous refresh task
        refreshTask?.cancel()
        
        refreshTask = Task {
            let prediction: PredictionResult?
            
            if shouldShowAIDebug {
                print("🔄 Refreshing AI signal for \(timeframe.rawValue) (reason: \(reason))")
            }
            
            // Demo isolation: use isDemoAI instead of checking aiManager directly
            if isDemoAI {
                prediction = aiManager.generateSyntheticPrediction(for: timeframe)
                if shouldShowAIDebug {
                    print("🎭 Using Demo prediction for \(timeframe.rawValue)")
                }
            } else {
                // Use enhanced prediction with candles
                prediction = await aiManager.predictWithCandles(for: timeframe, candles: mockCandles)
                if shouldShowAIDebug {
                    print("🧠 Using Live model prediction for \(timeframe.rawValue)")
                }
            }
            
            guard let prediction = prediction else {
                print("❌ No prediction generated")
                return
            }
            
            await MainActor.run {
                self.lastPrediction = prediction
                self.flashSignalUI(for: prediction.signal)
                
                // Update legacy signal for compatibility
                self.lastSignal = Signal(
                    symbol: symbol,
                    timeframe: timeframe,
                    type: SignalType(rawValue: prediction.signal.rawValue),
                    confidence: prediction.confidence,
                    modelName: prediction.modelUsed,
                    timestamp: prediction.timestamp
                )
                
                // Update AI decision for compatibility
                self.lastAIDecision = SignalDecision(
                    signal: prediction.signal,
                    confidence: prediction.confidence,
                    reasoning: prediction.reasoning,
                    timestamp: prediction.timestamp
                )
            }
            
            // Auto trading if enabled and not in demo mode
            if autoTrading && !isDemoAI {
                await executeAutoTrade(prediction: prediction)
            }
        }
    }
    
    // Legacy method for compatibility
    func refreshSignal(reason: String) async {
        await refreshPrediction(reason: reason)
    }
    
    private func extractFeatures(from candles: [Candle], for timeframe: Timeframe) -> [Double] {
        guard !candles.isEmpty else { 
            return timeframe == .h4 ? Array(repeating: 45000.0, count: 5) : Array(repeating: 0.45, count: 10)
        }
        
        let recentCandle = candles.last!
        
        // For 4H model, use OHLCV directly
        if timeframe == .h4 {
            return [
                recentCandle.open,
                recentCandle.high,
                recentCandle.low,
                recentCandle.close,
                recentCandle.volume
            ]
        }
        
        // For NN models (5m, 1h), use 10 normalized features
        let close = recentCandle.close
        let open = recentCandle.open
        let high = recentCandle.high
        let low = recentCandle.low
        let volume = recentCandle.volume
        
        return [
            close / 100000.0,  // Normalized close
            open / 100000.0,   // Normalized open
            high / 100000.0,   // Normalized high
            low / 100000.0,    // Normalized low
            volume / 10000.0,  // Normalized volume
            (close - open) / open,  // Price change ratio
            (high - low) / open,    // Range ratio
            volume / (candles.count > 1 ? candles[candles.count-2].volume : volume), // Volume ratio
            Double.random(in: 0...1), // Random feature 9
            Double.random(in: 0...1)  // Random feature 10
        ]
    }
    
    private func flashSignalUI(for signal: MyTradeMate.SignalType) {
        let flashColor: Color
        switch signal {
        case .buy: 
            flashColor = .green
            Haptics.success()
        case .sell: 
            flashColor = .red
            Haptics.warning()
        case .hold: 
            flashColor = .gray
            Haptics.playSelection()
        }
        
        signalFlashColor = flashColor
        
        // Clear flash after delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                self.signalFlashColor = nil
            }
        }
    }
    
    private func executeAutoTrade(prediction: PredictionResult) async {
        guard prediction.signal != .hold else { return }
        
        print("🤖 Auto trading: Executing \(prediction.signal.rawValue) signal")
        
        // Use the integrated auto trading from AIModelManager
        let equity = await TradeManager.shared.equity
        await aiManager.executeAutoTrade(
            signal: prediction,
            symbol: symbol,
            currentPrice: price,
            equity: equity
        )
        
        // Update PnL in demo mode
        if aiManager.pnlDemoMode {
            await MainActor.run {
                let impact = Double.random(in: -50...100) * prediction.confidence
                self.pnl = PnLSnapshot(
                    equity: self.pnl.equity + impact,
                    realizedToday: self.pnl.realizedToday + impact,
                    unrealized: self.pnl.unrealized,
                    ts: Date()
                )
            }
        }
    }
    
    func buy(_ qty: Double = 0.01) {
        Task {
            if await ThemeManager.shared.isHapticsEnabled {
                Haptics.buyFeedback()
            }
            let req = OrderRequest(symbol: symbol, side: .buy, quantity: qty, limitPrice: nil, stopLoss: nil, takeProfit: nil)
            _ = try? await TradeManager.shared.manualOrder(req)
        }
    }
    
    func sell(_ qty: Double = 0.01) {
        Task {
            if await ThemeManager.shared.isHapticsEnabled {
                Haptics.sellFeedback()
            }
            let req = OrderRequest(symbol: symbol, side: .sell, quantity: qty, limitPrice: nil, stopLoss: nil, takeProfit: nil)
            _ = try? await TradeManager.shared.manualOrder(req)
        }
    }
    
    // MARK: - Mock Data & Demo Functions
    
    private func generateMockCandles() {
        mockCandles.removeAll()
        let basePrice = 45000.0
        let now = Date()
        
        // Generate 200 mock candles with realistic OHLCV data
        for i in 0..<200 {
            let openTime = now.addingTimeInterval(TimeInterval(-i * 300)) // 5min intervals
            let volatility = Double.random(in: 0.995...1.005)
            let open = basePrice * volatility
            let close = open * Double.random(in: 0.998...1.002)
            let high = max(open, close) * Double.random(in: 1.0...1.001)
            let low = min(open, close) * Double.random(in: 0.999...1.0)
            let volume = Double.random(in: 50...500)
            
            let candle = Candle(
                openTime: openTime,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
            mockCandles.append(candle)
        }
        
        // Sort by time (oldest first)
        mockCandles.sort { $0.openTime < $1.openTime }
    }
    
    private func updateMockCandles(with currentPrice: Double) {
        // Update the latest candle with current price
        if !mockCandles.isEmpty {
            let lastIndex = mockCandles.count - 1
            let lastCandle = mockCandles[lastIndex]
            
            let updatedCandle = Candle(
                openTime: lastCandle.openTime,
                open: lastCandle.open,
                high: max(lastCandle.high, currentPrice),
                low: min(lastCandle.low, currentPrice),
                close: currentPrice,
                volume: lastCandle.volume + Double.random(in: 1...10)
            )
            
            mockCandles[lastIndex] = updatedCandle
        }
    }
    
    private func updateDemoPnL() {
        // Generate realistic but random PnL movements
        let baseEquity = 10000.0
        let variation = Double.random(in: -200...500)
        let realizedToday = Double.random(in: -100...300)
        let unrealized = Double.random(in: -50...150)
        
        pnl = PnLSnapshot(
            equity: baseEquity + variation,
            realizedToday: realizedToday,
            unrealized: unrealized,
            ts: Date()
        )
    }
    
    private func updateDemoPnLWithSignal(_ prediction: PredictionResult) {
        // Update PnL based on AI signal strength and market conditions
        let baseImpact = Double.random(in: -100...200)
        let signalMultiplier: Double
        
        switch prediction.signal {
        case .buy: signalMultiplier = 1.2
        case .sell: signalMultiplier = 0.8  
        case .hold: signalMultiplier = 0.9
        }
        
        let confidenceMultiplier = prediction.confidence
        let finalImpact = baseImpact * signalMultiplier * confidenceMultiplier
        
        pnl = PnLSnapshot(
            equity: pnl.equity + finalImpact,
            realizedToday: pnl.realizedToday + finalImpact,
            unrealized: Double.random(in: -25...50),
            ts: Date()
        )
        
        if aiManager.aiDebugMode {
            print("💰 Demo PnL updated: \(prediction.signal.rawValue) signal, impact: \(String(format: "%.2f", finalImpact))")
        }
    }
    
    private func resetToRealPnL() async {
        // Reset to real PnL data when exiting demo mode
        let pos = await TradeManager.shared.position
        let eq = await TradeManager.shared.equity
        await PnLManager.shared.resetIfNeeded()
        let snap = await PnLManager.shared.snapshot(price: price, position: pos, equity: eq)
        await MainActor.run { 
            self.pnl = snap
            if aiManager.aiDebugMode {
                print("🔄 Reset to real PnL data: equity=\(eq), realized=\(snap.realizedToday)")
            }
        }
    }
}