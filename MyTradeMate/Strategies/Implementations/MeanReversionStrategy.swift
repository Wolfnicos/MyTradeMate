import Foundation

public class MeanReversionStrategy: BaseStrategy {
    public static let shared = MeanReversionStrategy()
    
    public var period: Int = 20
    public var standardDeviations: Double = 2.0
    
    public init() {
        super.init(
            name: "Mean Reversion",
            description: "Bollinger Bands mean reversion strategy"
        )
    }
    
    // MARK: - Parameter Updates
    
    public func updatePeriod(_ period: Int) {
        guard period >= 10 && period <= 50 else { return }
        self.period = period
        Log.log("Mean Reversion period updated to \(period)", category: .strategy)
    }
    
    public func updateStandardDeviations(_ deviations: Double) {
        guard deviations >= 1.0 && deviations <= 3.0 else { return }
        self.standardDeviations = deviations
        Log.log("Mean Reversion standard deviations updated to \(deviations)", category: .strategy)
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= period else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for Bollinger Bands",
                strategyName: name
            )
        }
        
        let closes = candles.map { $0.close }
        guard let currentPrice = closes.last else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "No current price data",
                strategyName: name
            )
        }
        
        // Calculate Bollinger Bands
        let recentCloses = Array(closes.suffix(period))
        let sma = recentCloses.reduce(0, +) / Double(period)
        
        // Calculate standard deviation
        let variance = recentCloses.map { pow($0 - sma, 2) }.reduce(0, +) / Double(period)
        let stdDev = sqrt(variance)
        
        let upperBand = sma + (stdDev * standardDeviations)
        let lowerBand = sma - (stdDev * standardDeviations)
        
        // Calculate position within bands (0 = lower, 1 = upper)
        let bandWidth = upperBand - lowerBand
        let position = bandWidth > 0 ? (currentPrice - lowerBand) / bandWidth : 0.5
        
        // Generate signal based on band position
        let direction: StrategySignal.Direction
        let confidence: Double
        let reason: String
        
        if currentPrice <= lowerBand {
            // Price at or below lower band - oversold
            direction = .buy
            confidence = min(1.0, (lowerBand - currentPrice) / stdDev + 0.5)
            reason = String(format: "Price at lower band (%.2f)", currentPrice)
        } else if currentPrice >= upperBand {
            // Price at or above upper band - overbought
            direction = .sell
            confidence = min(1.0, (currentPrice - upperBand) / stdDev + 0.5)
            reason = String(format: "Price at upper band (%.2f)", currentPrice)
        } else {
            // Price within bands
            direction = .hold
            confidence = 0.3
            let percentInBand = position * 100
            reason = String(format: "Price within bands (%.1f%% position)", percentInBand)
        }
        
        return StrategySignal(
            direction: direction,
            confidence: confidence,
            reason: reason,
            strategyName: name
        )
    }
    
    public override func requiredCandles() -> Int {
        return period + 10
    }
}
