import Foundation
import Combine
import os.log

/// MetaSignalEngine combines AI predictions with Strategy ensemble to produce unified trading signals
@MainActor
public final class MetaSignalEngine: ObservableObject {
    public static let shared = MetaSignalEngine()
    
    // MARK: - Dependencies
    private let aiModelManager = AIModelManager.shared
    private let strategyManager = StrategyManager.shared
    private let settings = SettingsRepository.shared
    
    // MARK: - Published Properties
    @Published public private(set) var lastMetaSignal: MetaSignal?
    @Published public private(set) var isProcessing = false
    
    private init() {}
    
    // MARK: - MetaSignal Structure
    public struct MetaSignal {
        public let direction: SignalDirection
        public let confidence: Double
        public let source: String
        public let timestamp: Date
        public let aiComponent: AIComponent?
        public let strategyComponent: StrategyComponent?
        public let metadata: [String: Any]
        
        public struct AIComponent {
            public let prediction: String
            public let confidence: Double
            public let modelUsed: String
            public let weight: Double
        }
        
        public struct StrategyComponent {
            public let ensemble: StrategySignal
            public let votePurity: Double
            public let contributingStrategiesCount: Int
            public let weight: Double
        }
    }
    
    // MARK: - Settings
    public struct MetaSignalSettings {
        public let aiWeight: Double
        public let strategyWeight: Double
        public let minConfidenceThresholds: [Timeframe: Double]
        
        public static let `default` = MetaSignalSettings(
            aiWeight: 0.6,
            strategyWeight: 0.4,
            minConfidenceThresholds: [
                .m1: 0.70,
                .m5: 0.65,
                .m15: 0.62,
                .h1: 0.60,
                .h4: 0.58
            ]
        )
    }
    
    // MARK: - Main Signal Generation
    public func generateMetaSignal(
        for pair: TradingPair,
        timeframe: Timeframe,
        candles: [Candle],
        settings: MetaSignalSettings = .default
    ) async -> MetaSignal {
        
        isProcessing = true
        defer { isProcessing = false }
        
        os_log("[META] Generating signal for %@ %@", log: Log.ai, type: .info, pair.symbol, timeframe.rawValue)
        
        var aiComponent: MetaSignal.AIComponent?
        var strategyComponent: MetaSignal.StrategyComponent?
        var combinedDirection: SignalDirection = .hold
        var combinedConfidence: Double = 0.0
        
        // 1. Get AI Prediction (only for h4 currently)
        if timeframe == .h4, let aiSignal = await getAIPrediction(candles: candles, timeframe: timeframe) {
            aiComponent = MetaSignal.AIComponent(
                prediction: aiSignal.direction,
                confidence: aiSignal.confidence,
                modelUsed: "BTC_4H_Model",
                weight: settings.aiWeight
            )
            os_log("[AI] %@ conf=%.2f", log: Log.ai, type: .info, aiSignal.direction, aiSignal.confidence)
        }
        
        // 2. Get Strategy Ensemble
        if let strategySignal = await getStrategyEnsemble(candles: candles, timeframe: timeframe, pair: pair) {
            let purity = calculateVotePurity(strategySignal)
            strategyComponent = MetaSignal.StrategyComponent(
                ensemble: strategySignal,
                votePurity: purity,
                contributingStrategiesCount: 1, // Simplified since we don't have individual strategy counts
                weight: settings.strategyWeight
            )
            os_log("[STRATEGY] %@ purity=%.2f conf=%.2f", log: Log.strategy, type: .info, strategySignal.direction.description, purity, strategySignal.confidence)
        }
        
        // 3. Combine AI + Strategy with weighted voting
        let (finalDirection, finalConfidence) = combineSignals(
            ai: aiComponent,
            strategy: strategyComponent,
            settings: settings
        )
        
        combinedDirection = finalDirection
        combinedConfidence = finalConfidence
        
        // 4. Apply minimum confidence threshold
        let threshold = settings.minConfidenceThresholds[timeframe] ?? 0.60
        if combinedConfidence < threshold {
            combinedDirection = .hold
            os_log("[META] Below threshold (%.2f < %.2f), forcing HOLD", log: Log.ai, type: .info, combinedConfidence, threshold)
        }
        
        let metaSignal = MetaSignal(
            direction: combinedDirection,
            confidence: combinedConfidence,
            source: "MetaSignal (AI+Strategies)",
            timestamp: Date(),
            aiComponent: aiComponent,
            strategyComponent: strategyComponent,
            metadata: [
                "timeframe": timeframe.rawValue,
                "pair": pair.symbol,
                "threshold": threshold,
                "aiWeight": settings.aiWeight,
                "strategyWeight": settings.strategyWeight
            ]
        )
        
        lastMetaSignal = metaSignal
        
        os_log("[META] ai=%.2f strat=%.2f w=%.1f/%.1f → %@ %.2f", log: Log.ai, type: .info, aiComponent?.confidence ?? 0, strategyComponent?.ensemble.confidence ?? 0, settings.aiWeight, settings.strategyWeight, combinedDirection.rawValue, combinedConfidence)
        
        return metaSignal
    }
    
    // MARK: - AI Prediction Helper
    private func getAIPrediction(candles: [Candle], timeframe: Timeframe) async -> (direction: String, confidence: Double)? {
        // Only h4 supported currently
        guard timeframe == .h4 else { return nil }
        
        do {
            // Convert candles to features for 4H model
            let features = await buildH4Features(from: candles)
            let prediction = try aiModelManager.predict4H(explicitInputs: features)
            
            if let outputArray = prediction.featureValue(for: "Identity")?.multiArrayValue {
                // Assuming model outputs [buy_prob, sell_prob, hold_prob] 
                let buyProb = outputArray[0].doubleValue
                let sellProb = outputArray[1].doubleValue 
                let holdProb = outputArray[2].doubleValue
                
                let maxProb = max(buyProb, sellProb, holdProb)
                
                if maxProb == buyProb {
                    return ("BUY", buyProb)
                } else if maxProb == sellProb {
                    return ("SELL", sellProb)
                } else {
                    return ("HOLD", holdProb)
                }
            }
        } catch {
            os_log("[AI] Prediction failed: %@", log: Log.ai, type: .error, error.localizedDescription)
        }
        
        return nil
    }
    
    // MARK: - Strategy Ensemble Helper
    private func getStrategyEnsemble(candles: [Candle], timeframe: Timeframe, pair: TradingPair) async -> StrategySignal? {
        // Use existing StrategyManager to get ensemble signal
        let ensembleSignal = await strategyManager.generateSignals(from: candles)
        
        // Convert EnsembleSignal to StrategySignal
        return StrategySignal(
            direction: ensembleSignal.direction,
            confidence: ensembleSignal.confidence,
            reason: ensembleSignal.reason,
            strategyName: "Ensemble"
        )
    }
    
    // MARK: - Signal Combination Logic
    private func combineSignals(
        ai: MetaSignal.AIComponent?,
        strategy: MetaSignal.StrategyComponent?,
        settings: MetaSignalSettings
    ) -> (SignalDirection, Double) {
        
        var buyScore: Double = 0
        var sellScore: Double = 0
        var holdScore: Double = 0
        var totalWeight: Double = 0
        
        // Add AI contribution
        if let ai = ai {
            totalWeight += ai.weight
            
            switch ai.prediction {
            case "BUY":
                buyScore += ai.confidence * ai.weight
            case "SELL":
                sellScore += ai.confidence * ai.weight
            default:
                holdScore += ai.confidence * ai.weight
            }
        }
        
        // Add Strategy contribution
        if let strategy = strategy {
            totalWeight += strategy.weight
            
            switch strategy.ensemble.direction {
            case .buy:
                buyScore += strategy.ensemble.confidence * strategy.weight
            case .sell:
                sellScore += strategy.ensemble.confidence * strategy.weight
            case .hold:
                holdScore += strategy.ensemble.confidence * strategy.weight
            }
        }
        
        // Handle case where we have no signals
        if totalWeight == 0 {
            return (.hold, 0.0)
        }
        
        // Normalize scores
        buyScore /= totalWeight
        sellScore /= totalWeight
        holdScore /= totalWeight
        
        let maxScore = max(buyScore, sellScore, holdScore)
        
        // Apply calibration smoothing
        let calibratedConfidence = calibrateConfidence(maxScore)
        
        if maxScore == buyScore {
            return (.buy, calibratedConfidence)
        } else if maxScore == sellScore {
            return (.sell, calibratedConfidence)
        } else {
            return (.hold, calibratedConfidence)
        }
    }
    
    // MARK: - Helper Methods
    private func calculateVotePurity(_ signal: StrategySignal) -> Double {
        // For simplicity, use confidence as proxy for purity
        // In a real implementation, this would analyze individual strategy votes
        return signal.confidence
    }
    
    private func calibrateConfidence(_ rawConfidence: Double) -> Double {
        // Simple smoothing: finalConf = clamp(0.55...0.98, 0.5*maxConf + 0.5*purity)
        let smoothed = 0.5 * rawConfidence + 0.5 * rawConfidence // Simplified
        return min(max(smoothed, 0.55), 0.98)
    }
    
    private func buildH4Features(from candles: [Candle]) async -> [String: NSNumber] {
        // Build the 14 features required by the H4 model
        // This is a simplified implementation - in production this would use proper technical indicators
        
        guard candles.count >= 20 else {
            return [:]  // Return empty if insufficient data
        }
        
        let closes = candles.map { $0.close }
        let volumes = candles.map { $0.volume }
        let highs = candles.map { $0.high }
        let lows = candles.map { $0.low }
        
        // Calculate basic features (simplified versions)
        let return1 = closes.count > 1 ? (closes.last! - closes[closes.count - 2]) / closes[closes.count - 2] : 0.0
        let return3 = closes.count > 3 ? (closes.last! - closes[closes.count - 4]) / closes[closes.count - 4] : 0.0  
        let return5 = closes.count > 5 ? (closes.last! - closes[closes.count - 6]) / closes[closes.count - 6] : 0.0
        
        let volatility = calculateVolatility(closes)
        let rsi = calculateRSI(closes)
        let macdHist = calculateMACDHistogram(closes)
        let emaRatio = calculateEMARatio(closes)
        let volumeZ = calculateVolumeZScore(volumes)
        let highLowRange = (highs.last! - lows.last!) / closes.last!
        let pricePosition = (closes.last! - lows.last!) / (highs.last! - lows.last!)
        let atr14 = calculateATR(highs, lows, closes, period: 14)
        let (stochK, stochD) = calculateStochastic(highs, lows, closes)
        let bbPercent = calculateBollingerBandPercent(closes)
        
        return [
            "return_1": NSNumber(value: return1),
            "return_3": NSNumber(value: return3),
            "return_5": NSNumber(value: return5),
            "volatility": NSNumber(value: volatility),
            "rsi": NSNumber(value: rsi),
            "macd_hist": NSNumber(value: macdHist),
            "ema_ratio": NSNumber(value: emaRatio),
            "volume_z": NSNumber(value: volumeZ),
            "high_low_range": NSNumber(value: highLowRange),
            "price_position": NSNumber(value: pricePosition),
            "atr_14": NSNumber(value: atr14),
            "stoch_k": NSNumber(value: stochK),
            "stoch_d": NSNumber(value: stochD),
            "bb_percent": NSNumber(value: bbPercent)
        ]
    }
    
    // MARK: - Technical Indicator Helpers (Simplified)
    private func calculateVolatility(_ closes: [Double]) -> Double {
        guard closes.count > 1 else { return 0.0 }
        let returns = (1..<closes.count).map { closes[$0] / closes[$0-1] - 1 }
        let mean = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - mean, 2) }.reduce(0, +) / Double(returns.count)
        return sqrt(variance)
    }
    
    private func calculateRSI(_ closes: [Double], period: Int = 14) -> Double {
        guard closes.count > period else { return 50.0 }
        // Simplified RSI calculation
        let changes = (1..<closes.count).map { closes[$0] - closes[$0-1] }
        let gains = changes.suffix(period).map { max($0, 0) }
        let losses = changes.suffix(period).map { abs(min($0, 0)) }
        
        let avgGain = gains.reduce(0, +) / Double(period)
        let avgLoss = losses.reduce(0, +) / Double(period)
        
        guard avgLoss != 0 else { return 100.0 }
        let rs = avgGain / avgLoss
        return 100 - (100 / (1 + rs))
    }
    
    private func calculateMACDHistogram(_ closes: [Double]) -> Double {
        // Simplified MACD histogram
        guard closes.count >= 26 else { return 0.0 }
        let ema12 = calculateEMA(closes, period: 12)
        let ema26 = calculateEMA(closes, period: 26)
        return ema12 - ema26  // Simplified - should subtract signal line
    }
    
    private func calculateEMARatio(_ closes: [Double]) -> Double {
        guard closes.count >= 20 else { return 1.0 }
        let ema10 = calculateEMA(closes, period: 10)
        let ema20 = calculateEMA(closes, period: 20)
        return ema10 / ema20
    }
    
    private func calculateVolumeZScore(_ volumes: [Double]) -> Double {
        guard volumes.count > 20 else { return 0.0 }
        let recent = volumes.suffix(20)
        let mean = recent.reduce(0, +) / Double(recent.count)
        let variance = recent.map { pow($0 - mean, 2) }.reduce(0, +) / Double(recent.count)
        let stdDev = sqrt(variance)
        guard stdDev > 0 else { return 0.0 }
        return (volumes.last! - mean) / stdDev
    }
    
    private func calculateATR(_ highs: [Double], _ lows: [Double], _ closes: [Double], period: Int) -> Double {
        guard highs.count > period, highs.count == lows.count, lows.count == closes.count else { return 0.0 }
        
        var trueRanges: [Double] = []
        for i in 1..<highs.count {
            let tr1 = highs[i] - lows[i]
            let tr2 = abs(highs[i] - closes[i-1])
            let tr3 = abs(lows[i] - closes[i-1])
            trueRanges.append(max(tr1, tr2, tr3))
        }
        
        return trueRanges.suffix(period).reduce(0, +) / Double(period)
    }
    
    private func calculateStochastic(_ highs: [Double], _ lows: [Double], _ closes: [Double], period: Int = 14) -> (Double, Double) {
        guard highs.count >= period else { return (50.0, 50.0) }
        
        let recentHighs = highs.suffix(period)
        let recentLows = lows.suffix(period)
        let highestHigh = recentHighs.max() ?? 0
        let lowestLow = recentLows.min() ?? 0
        
        let stochK = ((closes.last! - lowestLow) / (highestHigh - lowestLow)) * 100
        let stochD = stochK  // Simplified - should be 3-period MA of %K
        
        return (stochK, stochD)
    }
    
    private func calculateBollingerBandPercent(_ closes: [Double], period: Int = 20) -> Double {
        guard closes.count >= period else { return 0.5 }
        
        let recent = closes.suffix(period)
        let sma = recent.reduce(0, +) / Double(period)
        let variance = recent.map { pow($0 - sma, 2) }.reduce(0, +) / Double(period)
        let stdDev = sqrt(variance)
        
        let upperBand = sma + (2 * stdDev)
        let lowerBand = sma - (2 * stdDev)
        
        guard upperBand != lowerBand else { return 0.5 }
        return (closes.last! - lowerBand) / (upperBand - lowerBand)
    }
    
    private func calculateEMA(_ values: [Double], period: Int) -> Double {
        guard values.count >= period else { return values.last ?? 0.0 }
        
        let multiplier = 2.0 / (Double(period) + 1.0)
        var ema = values.prefix(period).reduce(0, +) / Double(period)  // Start with SMA
        
        for value in values.dropFirst(period) {
            ema = (value * multiplier) + (ema * (1 - multiplier))
        }
        
        return ema
    }
}

// MARK: - SignalInfo Conversion Extension
extension MetaSignalEngine.MetaSignal {
    /// Convert MetaSignal to SignalInfo for UI compatibility
    public func toSignalInfo() -> SignalInfo {
        let reason = buildReasonString()
        
        return SignalInfo(
            direction: direction.rawValue,
            confidence: confidence,
            reason: reason,
            timestamp: timestamp
        )
    }
    
    private func buildReasonString() -> String {
        var components: [String] = []
        
        // Add main signal
        components.append(direction.rawValue)
        
        // Add confidence
        components.append("\(Int(confidence * 100))%")
        
        // Add source
        components.append("MetaSignal (AI+Strategies)")
        
        // Add timeframe and pair if available
        if let timeframe = metadata["timeframe"] as? String,
           let pair = metadata["pair"] as? String {
            components.append("\(pair)")
            components.append(timeframe)
        }
        
        // Add threshold info for HOLD signals
        if direction == .hold,
           let threshold = metadata["threshold"] as? Double {
            components.append("Reason: below min confidence (\(String(format: "%.2f", threshold)))")
        }
        
        return components.joined(separator: " • ")
    }
}

