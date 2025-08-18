import Foundation

/// Volume-based trading strategy
public final class VolumeStrategy: BaseStrategy {
    public var volumePeriod: Int = 20
    public var volumeThreshold: Double = 1.5 // Multiple of average volume
    public var priceChangeThreshold: Double = 0.02 // 2% price change
    
    public init() {
        super.init(
            name: "Volume Breakout",
            description: "Trades based on volume spikes and price movements"
        )
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= requiredCandles() else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for Volume strategy",
                strategyName: name
            )
        }
        
        let currentCandle = candles.last!
        let previousCandle = candles[candles.count - 2]
        
        // Calculate average volume
        let recentVolumes = candles.suffix(volumePeriod).map { $0.volume }
        let averageVolume = recentVolumes.reduce(0, +) / Double(recentVolumes.count)
        
        // Check for volume spike
        let volumeRatio = currentCandle.volume / averageVolume
        let isVolumeSpike = volumeRatio >= volumeThreshold
        
        // Calculate price change
        let priceChange = (currentCandle.close - previousCandle.close) / previousCandle.close
        let significantPriceMove = abs(priceChange) >= priceChangeThreshold
        
        // Check for breakout patterns
        let isBreakingUp = currentCandle.close > currentCandle.open && 
                          currentCandle.close > previousCandle.high
        let isBreakingDown = currentCandle.close < currentCandle.open && 
                            currentCandle.close < previousCandle.low
        
        // Volume-Price Analysis
        if isVolumeSpike && significantPriceMove {
            if priceChange > 0 && isBreakingUp {
                let confidence = calculateConfidence(
                    volumeRatio: volumeRatio,
                    priceChange: abs(priceChange),
                    isBreakout: true
                )
                return StrategySignal(
                    direction: .buy,
                    confidence: confidence,
                    reason: "Volume spike with bullish breakout (\(String(format: "%.1fx", volumeRatio)) volume)",
                    strategyName: name
                )
            } else if priceChange < 0 && isBreakingDown {
                let confidence = calculateConfidence(
                    volumeRatio: volumeRatio,
                    priceChange: abs(priceChange),
                    isBreakout: true
                )
                return StrategySignal(
                    direction: .sell,
                    confidence: confidence,
                    reason: "Volume spike with bearish breakdown (\(String(format: "%.1fx", volumeRatio)) volume)",
                    strategyName: name
                )
            }
        }
        
        // Volume confirmation of existing trends
        if isVolumeSpike {
            if priceChange > priceChangeThreshold / 2 {
                return StrategySignal(
                    direction: .buy,
                    confidence: 0.5,
                    reason: "High volume supporting upward price movement",
                    strategyName: name
                )
            } else if priceChange < -priceChangeThreshold / 2 {
                return StrategySignal(
                    direction: .sell,
                    confidence: 0.5,
                    reason: "High volume supporting downward price movement",
                    strategyName: name
                )
            }
        }
        
        // Volume divergence analysis
        let volumeDivergence = analyzeVolumeDivergence(candles: Array(candles.suffix(10)))
        if let divergence = volumeDivergence {
            return divergence
        }
        
        // Low volume - potential reversal warning
        if volumeRatio < 0.5 && significantPriceMove {
            return StrategySignal(
                direction: .hold,
                confidence: 0.3,
                reason: "Significant price move on low volume - potential false signal",
                strategyName: name
            )
        }
        
        return StrategySignal(
            direction: .hold,
            confidence: 0.1,
            reason: "No significant volume patterns detected",
            strategyName: name
        )
    }
    
    private func calculateConfidence(volumeRatio: Double, priceChange: Double, isBreakout: Bool) -> Double {
        var confidence: Double = 0.5
        
        // Volume factor
        let volumeFactor = min(0.3, (volumeRatio - volumeThreshold) * 0.1)
        confidence += volumeFactor
        
        // Price change factor
        let priceChangeFactor = min(0.2, priceChange * 5)
        confidence += priceChangeFactor
        
        // Breakout bonus
        if isBreakout {
            confidence += 0.1
        }
        
        return min(0.9, confidence)
    }
    
    private func analyzeVolumeDivergence(candles: [Candle]) -> StrategySignal? {
        guard candles.count >= 5 else { return nil }
        
        let recentCandles = Array(candles.suffix(5))
        let prices = recentCandles.map { $0.close }
        let volumes = recentCandles.map { $0.volume }
        
        // Check for price trend
        let priceSlope = (prices.last! - prices.first!) / Double(prices.count - 1)
        let volumeSlope = (volumes.last! - volumes.first!) / Double(volumes.count - 1)
        
        // Bullish divergence: price declining but volume increasing
        if priceSlope < -0.01 && volumeSlope > 0 {
            return StrategySignal(
                direction: .buy,
                confidence: 0.4,
                reason: "Bullish volume divergence detected",
                strategyName: name
            )
        }
        
        // Bearish divergence: price rising but volume declining
        if priceSlope > 0.01 && volumeSlope < 0 {
            return StrategySignal(
                direction: .sell,
                confidence: 0.4,
                reason: "Bearish volume divergence detected",
                strategyName: name
            )
        }
        
        return nil
    }
    
    public override func requiredCandles() -> Int {
        return volumePeriod + 10
    }
    
    public func updateParameter(key: String, value: Any) {
        switch key {
        case "volumePeriod":
            if let intValue = value as? Int {
                volumePeriod = max(5, min(50, intValue))
            }
        case "volumeThreshold":
            if let doubleValue = value as? Double {
                volumeThreshold = max(1.2, min(3.0, doubleValue))
            }
        case "priceChangeThreshold":
            if let doubleValue = value as? Double {
                priceChangeThreshold = max(0.005, min(0.05, doubleValue))
            }
        default:
            break
        }
    }
}