import Foundation
import Combine
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "SignalManager")



// MARK: - Signal Manager
@MainActor
final class SignalManager: ObservableObject {
    // MARK: - Injected Dependencies
    @Injected private var aiModelManager: AIModelManagerProtocol
    @Injected private var strategyManager: StrategyManagerProtocol
    @Injected private var settings: AppSettingsProtocol
    @Injected private var errorManager: ErrorManagerProtocol
    
    // MARK: - Published Properties
    @Published var currentSignal: SignalInfo?
    @Published var confidence: Double = 0.0
    @Published var isRefreshing = false
    
    // MARK: - Private Properties
    private var lastPredictionTime: Date = .distantPast
    private var lastThrottleLog: Date = .distantPast
    private let predictionThrottleInterval: TimeInterval = 0.5
    
    // MARK: - Public Methods
    func refreshPrediction(candles: [Candle], timeframe: Timeframe) {
        guard !isRefreshing else { return }
        
        Task {
            await refreshPredictionAsync(candles: candles, timeframe: timeframe)
        }
    }
    
    func generateDemoSignal() -> SignalInfo {
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
            reason: reasons[direction] ?? "Demo signal"
        )
    }
    
    // MARK: - Private Methods
    private func refreshPredictionAsync(candles: [Candle], timeframe: Timeframe) async {
        // Throttle predictions
        let timeSinceLastPrediction = Date().timeIntervalSince(lastPredictionTime)
        guard timeSinceLastPrediction >= predictionThrottleInterval else {
            // Only log throttling when verbose logging is enabled and at most once per second
            let now = Date()
            if settings.verboseAILogs && now.timeIntervalSince(lastThrottleLog) >= 1.0 {
                Log.ai.info("Throttling prediction, last was \(String(format: "%.1f", timeSinceLastPrediction))s ago")
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
            }
        }
        
        lastPredictionTime = Date()
        
        guard candles.count >= 50 else {
            logger.warning("Insufficient candles for prediction: \(candles.count)")
            return
        }
        
        let verboseLogging = settings.verboseAILogs
        
        if settings.demoMode {
            // Demo mode - generate synthetic signal
            let demoSignal = generateDemoSignal()
            await MainActor.run {
                self.currentSignal = demoSignal
                self.confidence = demoSignal.confidence
            }
            
            if verboseLogging {
                logger.info("Demo signal: \(demoSignal.direction) @ \(String(format: "%.1f%%", demoSignal.confidence * 100))")
            }
        } else {
            // Live mode - use AI and strategy signals
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Get CoreML prediction
            let coreMLSignal = await aiModelManager.predictSafely(
                timeframe: timeframe,
                candles: candles,
                mode: .manual
            )
            
            // Get strategy signals
            let strategySignals = await strategyManager.generateSignals(for: candles)
            
            // Combine signals
            let finalSignal = combineSignals(
                coreML: coreMLSignal,
                strategySignals: strategySignals,
                candles: candles,
                timeframe: timeframe,
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
            }
        }
    }
    
    private func combineSignals(
        coreML: PredictionResult?,
        strategySignals: [StrategySignal],
        candles: [Candle],
        timeframe: Timeframe,
        verboseLogging: Bool
    ) -> SignalInfo {
        // If no CoreML signal, use strategy signals only
        guard let coreML = coreML else {
            return combineStrategySignals(strategySignals, candles: candles, timeframe: timeframe)
        }
        
        // Weight: 60% CoreML, 40% strategies
        let coreMLWeight = 0.6
        let strategyWeight = 0.4
        
        // Convert to scores
        var buyScore = 0.0
        var sellScore = 0.0
        var holdScore = 0.0
        
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
        
        // Add strategy scores
        if !strategySignals.isEmpty {
            let avgStrategyConfidence = strategySignals.map { $0.confidence }.reduce(0, +) / Double(strategySignals.count)
            let dominantDirection = findDominantDirection(in: strategySignals)
            
            switch dominantDirection {
            case .buy:
                buyScore += avgStrategyConfidence * strategyWeight
            case .sell:
                sellScore += avgStrategyConfidence * strategyWeight
            case .hold:
                holdScore += avgStrategyConfidence * strategyWeight
            }
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
        
        var reason = "CoreML \(coreML.modelName)"
        if !strategySignals.isEmpty {
            let strategyNames = strategySignals.map { $0.strategyId }.joined(separator: ", ")
            reason += " + Strategies: \(strategyNames)"
        }
        
        if verboseLogging {
            logger.info("Combined scores - Buy: \(String(format: "%.2f", buyScore)), Sell: \(String(format: "%.2f", sellScore)), Hold: \(String(format: "%.2f", holdScore))")
        }
        
        return SignalInfo(
            direction: direction,
            confidence: confidence,
            reason: reason
        )
    }
    
    private func combineStrategySignals(_ signals: [StrategySignal], candles: [Candle], timeframe: Timeframe) -> SignalInfo {
        guard !signals.isEmpty else {
            return SignalInfo(direction: "HOLD", confidence: 0.0, reason: "No signals available")
        }
        
        let dominantDirection = findDominantDirection(in: signals)
        let avgConfidence = signals.map { $0.confidence }.reduce(0, +) / Double(signals.count)
        let strategyNames = signals.map { $0.strategyId }.joined(separator: ", ")
        
        return SignalInfo(
            direction: dominantDirection.rawValue,
            confidence: avgConfidence,
            reason: "Strategies: \(strategyNames)"
        )
    }
    
    private func findDominantDirection(in signals: [StrategySignal]) -> SignalDirection {
        let directionCounts = signals.reduce(into: [SignalDirection: Int]()) { counts, signal in
            counts[signal.direction, default: 0] += 1
        }
        
        return directionCounts.max(by: { $0.value < $1.value })?.key ?? .hold
    }
}

// MARK: - Strategy Store (Legacy Support)
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