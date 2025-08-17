import Foundation
import Combine
import SwiftUI
import CoreML
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "Dashboard")

enum Mode: String, CaseIterable {
    case normal, precision
}

    // MARK: - Signal Info (publicat deja mai jos și folosit în VM)
struct SignalInfo {
    let direction: String  // "BUY", "SELL", "HOLD"
    let confidence: Double // 0...1
    let reason: String
    let timestamp: Date
}

@MainActor
final class DashboardVM: ObservableObject {
        // MARK: - Dependencies
    private let marketDataService = MarketDataService.shared
    private let aiModelManager = AIModelManager.shared
    private let settings = AppSettings.shared

        // MARK: - Published
    @Published var price: Double = 0.0
    @Published var priceChange: Double = 0.0
    @Published var priceChangePercent: Double = 0.0
    @Published var candles: [Candle] = []
    @Published var chartPoints: [CGPoint] = []
    @Published var isLoading = false
    @Published var isRefreshing = false

        // Chart data
    var chartData: [CandleData] {
        candles.map {
            CandleData(timestamp: $0.openTime,
                       open: $0.open, high: $0.high,
                       low: $0.low, close: $0.close,
                       volume: $0.volume)
        }
    }

    @Published var errorMessage: String?
    @Published var timeframe: Timeframe = .m5
    @Published var precisionMode: Bool = false
    @Published var tradingMode: TradingMode = .manual
    @Published var confidence: Double = 0.0
    @Published var currentSignal: SignalInfo?
    @Published var currentPredictionResult: PredictionResult?
    @Published var allModelPredictions: [PredictionResult] = []
    @Published var openPositions: [Position] = []
    @Published var isConnected: Bool = false
    @Published var connectionStatus: String = "Connecting..."
    @Published var lastUpdated: Date = Date()

        // Back-compat
    var isPrecisionMode: Bool {
        get { precisionMode }
        set { precisionMode = newValue }
    }

        // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private var lastPredictionTime: Date = .distantPast
    private var lastThrottleLog: Date = .distantPast

        // MARK: - Computed strings
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
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: lastUpdated, relativeTo: Date())
    }

        // MARK: - Lifecycle
    init() {
        setupBindings()
        loadInitialData()
        startAutoRefresh()
    }
    deinit {
        refreshTimer?.invalidate()
    }

        // MARK: - Setup
    private func setupBindings() {
            // timeframe
        $timeframe
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] tf in
                Log.app.info("User set timeframe to \(tf.rawValue)")
                Task { @MainActor [weak self] in
                    await self?.reloadDataAndPredict()
                }
            }
            .store(in: &cancellables)

            // precision
        $precisionMode
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.refreshPredictionAsync()
                }
            }
            .store(in: &cancellables)

            // trading mode (just logs)
        $tradingMode
            .removeDuplicates()
            .sink { mode in
                Log.trade.info("Trading mode \(mode.rawValue)")
            }
            .store(in: &cancellables)

            // connection status
        NotificationCenter.default.publisher(for: .init("WebSocketStatusChanged"))
            .receive(on: RunLoop.main)
            .sink { [weak self] n in
                if let status = n.object as? Bool {
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
    private func reloadDataAndPredict() async {
        await loadMarketData()
        await refreshPredictionAsync()
    }

        // MARK: - Data
    private func loadMarketData() async {
        do {
            if settings.demoMode {
                generateMockData()
                Log.app.info("Loaded demo market data")
            } else if settings.liveMarketData {
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
                generateMockData()
                Log.app.info("Fallback to demo data")
            }
        } catch {
            Log.app.error("Failed to load market data: \(error.localizedDescription)")
            await MainActor.run { self.errorMessage = error.localizedDescription }
            generateMockData()
        }
    }

    private func generateMockData() {
        let basePrice = 45000.0 + Double.random(in: -2000...2000)
        price = basePrice
        priceChange = Double.random(in: -500...500)
        priceChangePercent = (priceChange / basePrice) * 100
        candles = generateMockCandles(basePrice: basePrice)
        updateChartPoints()
    }

    private func generateMockCandles(basePrice: Double) -> [Candle] {
        var mock: [Candle] = []
        let count = 100
        for i in 0..<count {
            let ts = Date().addingTimeInterval(-Double(i * 300))
            let vol = Double.random(in: 0.002...0.01) * basePrice
            let trend = sin(Double(i) * 0.1) * vol
            let open = basePrice + trend + Double.random(in: -vol...vol)
            let close = open + Double.random(in: -vol/2...vol/2)
            let high = max(open, close) + Double.random(in: 0...vol/4)
            let low  = min(open, close) - Double.random(in: 0...vol/4)
            let volume = Double.random(in: 100...1000)
            mock.append(Candle(openTime: ts, open: open, high: high, low: low, close: close, volume: volume))
        }
        return mock.reversed()
    }

    private func updatePriceInfo() {
        guard candles.count >= 2 else { return }
        let last = candles.last!
        let prev = candles[candles.count - 2]
        price = last.close
        priceChange = last.close - prev.close
        priceChangePercent = (priceChange / prev.close) * 100
    }

    private func updateChartPoints() {
        guard !candles.isEmpty else { chartPoints = []; return }
        let closes = candles.suffix(100).map { $0.close }
        guard let maxP = closes.max(), let minP = closes.min(), maxP > minP else {
            chartPoints = []; return
        }
        let range = maxP - minP
        chartPoints = closes.enumerated().map { (idx, c) in
            CGPoint(x: CGFloat(idx) / CGFloat(closes.count - 1),
                    y: CGFloat((c - minP) / range))
        }
    }

        // MARK: - Prediction
    func refreshPrediction() {
        guard !isRefreshing else { return }
        Task { await refreshPredictionAsync() }
    }

    private func refreshPredictionAsync() async {
            // throttle
        let dt = Date().timeIntervalSince(lastPredictionTime)
        guard dt >= 0.5 else {
            let now = Date()
            if AppSettings.shared.aiVerbose && now.timeIntervalSince(lastThrottleLog) >= 1.0 {
                Log.ai.info("Throttling prediction, last was \(String(format: "%.1f", dt))s ago")
                lastThrottleLog = now
            }
            return
        }

        await MainActor.run { isRefreshing = true }
        defer {
            Task { @MainActor in
                isRefreshing = false
                lastUpdated = Date()
            }
        }
        lastPredictionTime = Date()

        guard candles.count >= 50 else {
            logger.warning("Insufficient candles for prediction: \(self.candles.count)")
            return
        }

        let verboseLogging = false
        let start = CFAbsoluteTimeGetCurrent()

            // Legacy fallback: use CoreML-only
        let allPredictions = await getAllModelPredictions()

            // pick current TF
        let coreMLSignal = allPredictions.first(where: { p in
            (timeframe == .m5 && p.modelName.contains("5m")) ||
            (timeframe == .h1 && p.modelName.contains("1h")) ||
            (timeframe == .h4 && (p.modelName.contains("4h") || p.modelName.contains("4H")))
        }) ?? allPredictions.first ?? PredictionResult(signal: "HOLD", confidence: 0.0, modelName: "Unknown", timestamp: Date())

        let finalSignal = combineSignals(coreML: coreMLSignal, verboseLogging: verboseLogging)
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

        if verboseLogging {
            logger.info("Inference time: \(String(format: "%.1f", elapsed))ms")
            logger.info("Final signal: \(finalSignal.direction) @ \(String(format: "%.1f%%", finalSignal.confidence * 100))")
        }

        await MainActor.run {
            self.currentSignal = finalSignal
            self.currentPredictionResult = coreMLSignal
            self.allModelPredictions = allPredictions
            self.confidence = finalSignal.confidence
            if self.tradingMode == .auto && settings.autoTrading, let sig = self.currentSignal {
                self.handleAutoTrading(signal: sig)
            }
        }
    }

        /// Construiește predicții pentru m5/h1 (dense) + h4 (explicit) folosind AIModelManager actual.
    private func getAllModelPredictions() async -> [PredictionResult] {
        var predictions: [PredictionResult] = []

            // Dense features (10) – simple, dar conforme (managerul pad-ează/trunchiază)
        let dense = buildDenseFeatures(from: candles)

        if let p = aiModelManager.predictSafely(kind: .m5, denseFeatures: dense) {
            predictions.append(p)
        }
        if let p = aiModelManager.predictSafely(kind: .h1, denseFeatures: dense) {
            predictions.append(p)
        }

            // 4h explicit (12 features). Încercăm dacă putem construi minimul necesar
        if let explicit = build4HExplicitInputs(from: candles),
           let out = try? aiModelManager.predict4H(explicitInputs: explicit) {

                // 1) classProbability (BUY/SELL/HOLD sau 0/1 etc.)
            if let anyDict = out.featureValue(for: "classProbability")?.dictionaryValue {
                var buy = 0.0, sell = 0.0, hold = 0.0
                for (k, v) in anyDict {
                    if let s = k as? String {
                        if s.uppercased() == "BUY"  { buy  = v.doubleValue }
                        if s.uppercased() == "SELL" { sell = v.doubleValue }
                        if s.uppercased() == "HOLD" { hold = v.doubleValue }
                    } else if let i = k as? Int {
                            // fallback convenție văzută în loguri
                        if i == 0 { sell = v.doubleValue }
                        if i == 1 { hold = v.doubleValue }
                    }
                }
                let maxVal = max(buy, sell, hold)
                let dir = (maxVal == buy) ? "BUY" : ((maxVal == sell) ? "SELL" : "HOLD")
                predictions.append(PredictionResult(signal: dir, confidence: maxVal, model: .h4, timestamp: Date()))
            }
                // 2) prediction string (fallback)
            else if let pred = out.featureValue(for: "prediction")?.stringValue {
                let dir = pred.uppercased()
                let conf = 1.0 // dacă nu avem probabilități, punem 1.0 nominal
                predictions.append(PredictionResult(signal: dir, confidence: conf, model: .h4, timestamp: Date()))
            }
        }

        return predictions
    }

        // MARK: - Feature builders (simple & safe)
        /// Construcție 10 features pentru modelele dense (m5/h1). Valorile sunt simple, dar valide.
    private func buildDenseFeatures(from candles: [Candle]) -> [Float] {
            // Luăm ultimele 6 închideri pt derivate simple
        guard let last = candles.last else { return Array(repeating: 0, count: 10) }
        let closes = candles.suffix(6).map { $0.close }
        let v: (Double, Double, Double) = {
            if closes.count >= 6 {
                let r1  = (closes.last! - closes[closes.count-2]) / max(closes[closes.count-2], 1)
                let r3  = (closes.last! - closes[closes.count-4]) / max(closes[closes.count-4], 1)
                let r5  = (closes.last! - closes.first!)        / max(closes.first!, 1)
                return (r1, r3, r5)
            } else { return (0,0,0) }
        }()

            // semnal medie mobilă  (foarte simplu: close > medie ultimelor 10)
        let last10 = candles.suffix(10).map { $0.close }
        let ma = last10.isEmpty ? 0 : last10.reduce(0,+) / Double(last10.count)
        let maSignal: Double = (last.close > ma) ? 1.0 : 0.0

            // RSI simplificat pe 14 (aproximare grosieră)
        let rsi = simpleRSI(values: candles.map{$0.close}, period: 14)

            // volume ratio (ultimul volum / medie 20)
        let vols = candles.suffix(20).map { $0.volume }
        let vAvg = vols.isEmpty ? 1.0 : vols.reduce(0,+)/Double(vols.count)
        let volumeRatio = vAvg == 0 ? 0 : (candles.last!.volume / vAvg)

            // poziție preț în range 50
        let closes50 = candles.suffix(50).map { $0.close }
        let min50 = closes50.min() ?? last.close
        let max50 = closes50.max() ?? last.close
        let pricePos = (max50 > min50) ? (last.close - min50) / (max50 - min50) : 0.5

            // volatilitate simplă (std dev / medie pe 20)
        let volCloses = candles.suffix(20).map { $0.close }
        let mean = volCloses.isEmpty ? last.close : volCloses.reduce(0,+)/Double(volCloses.count)
        let variance = volCloses.isEmpty ? 0 : volCloses.map { pow($0 - mean, 2) }.reduce(0,+) / Double(volCloses.count)
        let std = sqrt(variance)
        let volatility = (mean != 0) ? (std / mean) : 0

            // booleene rsi
        let rsiOverbought = (rsi > 70) ? 1.0 : 0.0
        let rsiOversold   = (rsi < 30) ? 1.0 : 0.0

            // 10 features
        let vec: [Float] = [
            Float(v.0), Float(v.1), Float(v.2),
            Float(maSignal),
            Float(rsi),
            Float(rsiOversold),
            Float(rsiOverbought),
            Float(volumeRatio),
            Float(pricePos),
            Float(volatility)
        ]
        return vec
    }

    private func simpleRSI(values: [Double], period: Int) -> Double {
        guard values.count > period else { return 50.0 }
        var gains = 0.0
        var losses = 0.0
        for i in (values.count - period)..<values.count-1 {
            let diff = values[i+1] - values[i]
            if diff >= 0 { gains += diff } else { losses -= diff }
        }
        guard (gains + losses) > 0 else { return 50.0 }
        let rs = (gains / Double(period)) / max((losses / Double(period)), 1e-8)
        return 100.0 - (100.0 / (1.0 + rs))
    }

        /// Construiește 12 features explicite pentru modelul 4h.
    private func build4HExplicitInputs(from candles: [Candle]) -> [String: NSNumber]? {
        guard let last = candles.last else { return nil }

        let closes50 = candles.suffix(50).map { $0.close }
        let min50 = closes50.min() ?? last.close
        let max50 = closes50.max() ?? last.close
        let pricePos = (max50 > min50) ? (last.close - min50) / (max50 - min50) : 0.5

            // returns pe 1/3/5 pași (fallback dacă n-avem suficiente)
        func ret(_ n: Int) -> Double {
            guard candles.count > n else { return 0 }
            let prev = candles[candles.count - 1 - n]
            return (last.close - prev.close) / max(prev.close, 1)
        }

            // volatilitate 20
        let volCloses = candles.suffix(20).map { $0.close }
        let mean = volCloses.isEmpty ? last.close : volCloses.reduce(0,+)/Double(volCloses.count)
        let variance = volCloses.isEmpty ? 0 : volCloses.map { pow($0 - mean, 2) }.reduce(0,+) / Double(volCloses.count)
        let std = sqrt(variance)
        let volatility = (mean != 0) ? (std / mean) : 0

            // volume ratio 20
        let vols = candles.suffix(20).map { $0.volume }
        let vAvg = vols.isEmpty ? 1.0 : vols.reduce(0,+)/Double(vols.count)
        let volumeRatio = vAvg == 0 ? 0 : (last.volume / vAvg)

        let rsi = simpleRSI(values: candles.map{$0.close}, period: 14)

            // Cheile așa cum apar în logurile tale
        let dict: [String: NSNumber] = [
            "close": NSNumber(value: last.close),
            "high": NSNumber(value: last.high),
            "low": NSNumber(value: last.low),
            "open": NSNumber(value: last.open),
            "price_position": NSNumber(value: pricePos),
            "return_1": NSNumber(value: ret(1)),
            "return_3": NSNumber(value: ret(3)),
            "return_5": NSNumber(value: ret(5)),
            "rsi": NSNumber(value: rsi),
            "volatility": NSNumber(value: volatility),
            "volume": NSNumber(value: last.volume),
            "volume_ratio": NSNumber(value: volumeRatio)
        ]
        return dict
    }

    private func combineSignals(coreML: PredictionResult?, verboseLogging: Bool) -> SignalInfo {
        guard let coreML = coreML else {
            return SignalInfo(direction: "HOLD", confidence: 0.0, reason: "No CoreML signal available.", timestamp: Date())
        }
        if verboseLogging {
            logger.info("CoreML Raw Signal: \(coreML.signal) @ \(String(format: "%.1f%%", coreML.confidence * 100))")
        }
        let reason = "CoreML \(coreML.modelName)"
        return SignalInfo(direction: coreML.signal, confidence: coreML.confidence, reason: reason, timestamp: Date())
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
        if settings.confirmTrades {
            logger.info("Buy order confirmation required")
        } else {
            logger.info("Executing buy order")
        }
        logger.info("Executing buy order")
    }

    func executeSell() {
        guard !settings.autoTrading else {
            logger.warning("Manual trading disabled in auto mode")
            return
        }
        if settings.confirmTrades {
            logger.info("Sell order confirmation required")
        } else {
            logger.info("Executing sell order")
        }
        logger.info("Executing sell order")
    }

        // MARK: - Auto Trading
    private var lastAutoTradeTime: Date = .distantPast
    private let autoTradeCooldown: TimeInterval = 60.0

    private func handleAutoTrading(signal: SignalInfo) {
        let dt = Date().timeIntervalSince(lastAutoTradeTime)
        guard dt >= autoTradeCooldown else {
            Log.ai.info("Auto trading on cooldown: \(String(format: "%.1f", dt))s / \(autoTradeCooldown)s")
            return
        }
        guard signal.confidence > 0.7 else {
            Log.ai.info("Auto trading: Signal confidence too low (\(String(format: "%.1f", signal.confidence)))")
            return
        }
        if settings.confirmTrades {
            simulatePaperTrade(signal: signal)
        } else {
            Log.ai.info("❌ Live trading disabled for safety")
        }
    }

    private func simulatePaperTrade(signal: SignalInfo) {
        lastAutoTradeTime = Date()
        let orderType = signal.direction
        let confStr = String(format: "%.1f%%", signal.confidence * 100)
        Log.ai.info("📝 Paper Trade Simulated: \(orderType) @ \(price) (confidence: \(confStr))")
        Log.ai.info("↳ Reason: \(signal.reason)")
    }

        // MARK: - Public
    func refreshData() {
        Task {
            isLoading = true
            await loadMarketData()
            await refreshPredictionAsync()
            isLoading = false
        }
    }
}
