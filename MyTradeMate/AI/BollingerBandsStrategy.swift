import Foundation

/// Bollinger Bands strategy implementation
public final class BollingerBandsStrategy: BaseStrategy {
    public var period: Int = 20
    public var standardDeviations: Double = 2.0
    
    public init() {
        super.init(
            name: "Bollinger Bands",
            description: "Trades based on price touching or crossing Bollinger Bands"
        )
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= requiredCandles() else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for Bollinger Bands",
                strategyName: name
            )
        }
        
        let closes = candles.suffix(period).map { $0.close }
        let sma = closes.reduce(0, +) / Double(closes.count)
        
        // Calculate standard deviation
        let variance = closes.map { pow($0 - sma, 2) }.reduce(0, +) / Double(closes.count)
        let stdDev = sqrt(variance)
        
        let upperBand = sma + (standardDeviations * stdDev)
        let lowerBand = sma - (standardDeviations * stdDev)
        
        let currentPrice = candles.last!.close
        let previousPrice = candles[candles.count - 2].close
        
        // Calculate band position (0 = lower band, 1 = upper band)
        let bandPosition = (currentPrice - lowerBand) / (upperBand - lowerBand)
        
        // Generate signals
        if currentPrice <= lowerBand && previousPrice > lowerBand {
            // Price touched lower band from above - potential buy
            let confidence = min(0.9, 0.5 + (0.5 * (1.0 - bandPosition)))
            return StrategySignal(
                direction: .buy,
                confidence: confidence,
                reason: "Price touched lower Bollinger Band (oversold)",
                strategyName: name
            )
        } else if currentPrice >= upperBand && previousPrice < upperBand {
            // Price touched upper band from below - potential sell
            let confidence = min(0.9, 0.5 + (0.5 * bandPosition))
            return StrategySignal(
                direction: .sell,
                confidence: confidence,
                reason: "Price touched upper Bollinger Band (overbought)",
                strategyName: name
            )
        } else if bandPosition < 0.2 {
            // Near lower band - weak buy signal
            return StrategySignal(
                direction: .buy,
                confidence: 0.3,
                reason: "Price near lower Bollinger Band",
                strategyName: name
            )
        } else if bandPosition > 0.8 {
            // Near upper band - weak sell signal
            return StrategySignal(
                direction: .sell,
                confidence: 0.3,
                reason: "Price near upper Bollinger Band",
                strategyName: name
            )
        }
        
        return StrategySignal(
            direction: .hold,
            confidence: 0.1,
            reason: "Price within normal Bollinger Band range",
            strategyName: name
        )
    }
    
    public override func requiredCandles() -> Int {
        return period + 5
    }
    
    public func updateParameter(key: String, value: Any) {
        switch key {
        case "period":
            if let intValue = value as? Int {
                period = max(5, min(100, intValue))
            }
        case "standardDeviations":
            if let doubleValue = value as? Double {
                standardDeviations = max(0.5, min(4.0, doubleValue))
            }
        default:
            break
        }
    }
}