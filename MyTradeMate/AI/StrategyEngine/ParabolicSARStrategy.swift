import Foundation

/// Parabolic SAR strategy implementation
public final class ParabolicSARStrategy: BaseStrategy {
    public static let shared = ParabolicSARStrategy()
    public var accelerationFactor: Double = 0.02
    public var maxAcceleration: Double = 0.20
    
    public init() {
        super.init(
            name: "Parabolic SAR",
            description: "Trend-following indicator using stop and reverse points"
        )
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= requiredCandles() else {
            // ✅ FALLBACK: Use basic trend analysis when insufficient data
            let currentPrice = candles.last?.close ?? 0.0
            let avgPrice = candles.count > 1 ? candles.map(\.close).reduce(0, +) / Double(candles.count) : currentPrice
            let trend = currentPrice > avgPrice ? 1.0 : -1.0
            
            return StrategySignal(
                direction: trend > 0 ? .buy : .sell,
                confidence: 0.35,
                reason: "Insufficient data - basic trend fallback",
                strategyName: name
            )
        }
        
        let sarData = calculateParabolicSAR(candles: candles)
        
        guard sarData.count >= 2 else {
            // ✅ FALLBACK: Use momentum when SAR calculation fails
            let recentPrices = Array(candles.map(\.close).suffix(min(5, candles.count)))
            let momentum = recentPrices.count >= 2 ? 
                (recentPrices.last! - recentPrices.first!) / recentPrices.first! : 0.0
            
            return StrategySignal(
                direction: momentum > 0.01 ? .buy : (momentum < -0.01 ? .sell : .hold),
                confidence: 0.35,
                reason: "SAR calculation unavailable - trend fallback",
                strategyName: name
            )
        }
        
        guard let currentCandle = candles.last else { 
            return StrategySignal(direction: .hold, confidence: 0.33, reason: "No current price - neutral fallback", strategyName: name)
        }
        guard candles.count >= 2 else {
            return StrategySignal(direction: .hold, confidence: 0.33, reason: "Single candle - neutral fallback", strategyName: name)
        }
        let previousCandle = candles[candles.count - 2]
        guard let currentSAR = sarData.last else {
            // ✅ FALLBACK: Use price action when SAR data missing
            let priceAction = currentCandle.close > currentCandle.open ? 1.0 : -1.0
            return StrategySignal(
                direction: priceAction > 0 ? .buy : .sell, 
                confidence: 0.34, 
                reason: "Insufficient SAR data - price action fallback", 
                strategyName: name
            )
        }
        let previousSAR = sarData[sarData.count - 2]
        
        // Determine trend direction
        let currentTrendUp = currentCandle.close > currentSAR
        let previousTrendUp = previousCandle.close > previousSAR
        
        // Check for trend reversal
        if currentTrendUp && !previousTrendUp {
            // Bullish reversal - price crossed above SAR
            let confidence = calculateConfidence(candle: currentCandle, sar: currentSAR, isUptrend: true)
            return StrategySignal(
                direction: .buy,
                confidence: confidence,
                reason: "Parabolic SAR bullish reversal",
                strategyName: name
            )
        } else if !currentTrendUp && previousTrendUp {
            // Bearish reversal - price crossed below SAR
            let confidence = calculateConfidence(candle: currentCandle, sar: currentSAR, isUptrend: false)
            return StrategySignal(
                direction: .sell,
                confidence: confidence,
                reason: "Parabolic SAR bearish reversal",
                strategyName: name
            )
        }
        
        // Trend continuation signals
        if currentTrendUp {
            let distance = (currentCandle.close - currentSAR) / currentCandle.close
            if distance > 0.02 { // Strong uptrend
                return StrategySignal(
                    direction: .buy,
                    confidence: 0.6,
                    reason: "Parabolic SAR strong uptrend continuation",
                    strategyName: name
                )
            } else {
                return StrategySignal(
                    direction: .buy,
                    confidence: 0.3,
                    reason: "Parabolic SAR uptrend continuation",
                    strategyName: name
                )
            }
        } else {
            let distance = (currentSAR - currentCandle.close) / currentCandle.close
            if distance > 0.02 { // Strong downtrend
                return StrategySignal(
                    direction: .sell,
                    confidence: 0.6,
                    reason: "Parabolic SAR strong downtrend continuation",
                    strategyName: name
                )
            } else {
                return StrategySignal(
                    direction: .sell,
                    confidence: 0.3,
                    reason: "Parabolic SAR downtrend continuation",
                    strategyName: name
                )
            }
        }
    }
    
    private func calculateParabolicSAR(candles: [Candle]) -> [Double] {
        guard candles.count >= 2 else { return [] }
        
        var sarValues: [Double] = []
        guard let firstCandle = candles.first,
              let secondCandle = candles.dropFirst().first else { return [] }
        
        var isUptrend = secondCandle.close > firstCandle.close
        var extremePoint = isUptrend ? secondCandle.high : secondCandle.low
        var acceleration = accelerationFactor
        var sar = firstCandle.close
        
        sarValues.append(sar)
        
        for i in 1..<candles.count {
            let currentCandle = candles[i]
            
            // Calculate new SAR
            sar = sar + acceleration * (extremePoint - sar)
            
            // Check for trend reversal
            let reversal = isUptrend ? (currentCandle.low <= sar) : (currentCandle.high >= sar)
            
            if reversal {
                // Trend reversal
                isUptrend = !isUptrend
                sar = extremePoint
                extremePoint = isUptrend ? currentCandle.high : currentCandle.low
                acceleration = accelerationFactor
            } else {
                // Trend continuation
                if isUptrend {
                    if currentCandle.high > extremePoint {
                        extremePoint = currentCandle.high
                        acceleration = min(acceleration + accelerationFactor, maxAcceleration)
                    }
                    // Ensure SAR doesn't go above previous two lows
                    if i >= 2 {
                        sar = min(sar, min(candles[i-1].low, candles[i-2].low))
                    } else if i >= 1 {
                        sar = min(sar, candles[i-1].low)
                    }
                } else {
                    if currentCandle.low < extremePoint {
                        extremePoint = currentCandle.low
                        acceleration = min(acceleration + accelerationFactor, maxAcceleration)
                    }
                    // Ensure SAR doesn't go below previous two highs
                    if i >= 2 {
                        sar = max(sar, max(candles[i-1].high, candles[i-2].high))
                    } else if i >= 1 {
                        sar = max(sar, candles[i-1].high)
                    }
                }
            }
            
            sarValues.append(sar)
        }
        
        return sarValues
    }
    
    private func calculateConfidence(candle: Candle, sar: Double, isUptrend: Bool) -> Double {
        let distance = abs(candle.close - sar) / candle.close
        let baseConfidence: Double = 0.7
        
        // Increase confidence based on distance from SAR
        let distanceBonus = min(0.2, distance * 10) // Max 0.2 bonus
        
        // Volume consideration (if available)
        let volumeBonus: Double = 0.0 // Could be enhanced with volume data
        
        return min(0.9, baseConfidence + distanceBonus + volumeBonus)
    }
    
    public override func requiredCandles() -> Int {
        return 20
    }
    
    public func updateParameter(key: String, value: Any) {
        switch key {
        case "accelerationFactor":
            if let doubleValue = value as? Double {
                accelerationFactor = max(0.01, min(0.1, doubleValue))
            }
        case "maxAcceleration":
            if let doubleValue = value as? Double {
                maxAcceleration = max(0.1, min(0.5, doubleValue))
            }
        default:
            break
        }
    }
}