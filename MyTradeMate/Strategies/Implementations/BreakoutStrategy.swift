import Foundation

public class BreakoutStrategy: BaseStrategy {
    public static let shared = BreakoutStrategy()
    
    public var atrPeriod: Int = 14
    public var multiplier: Double = 1.5
    
    public init() {
        super.init(
            name: "ATR Breakout",
            description: "Average True Range breakout strategy"
        )
    }
    
    // MARK: - Parameter Updates
    
    public func updateATRPeriod(_ period: Int) {
        guard period >= 5 && period <= 30 else { return }
        self.atrPeriod = period
        Log.log("ATR Breakout period updated to \(period)", category: .strategy)
    }
    
    public func updateMultiplier(_ multiplier: Double) {
        guard multiplier >= 0.5 && multiplier <= 3.0 else { return }
        self.multiplier = multiplier
        Log.log("ATR Breakout multiplier updated to \(multiplier)", category: .strategy)
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count > atrPeriod else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for ATR",
                strategyName: name
            )
        }
        
        // Calculate ATR
        let atr = calculateATR(candles: candles, period: atrPeriod)
        
        guard let currentATR = atr.last else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "ATR calculation error",
                strategyName: name
            )
        }
        
        guard let currentCandle = candles.last,
              candles.count >= 2 else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient candle data",
                strategyName: name
            )
        }
        let previousCandle = candles[candles.count - 2]
        
        // Calculate recent high/low
        let recentCandles = Array(candles.suffix(atrPeriod))
        let recentHigh = recentCandles.map { $0.high }.max() ?? currentCandle.high
        let recentLow = recentCandles.map { $0.low }.min() ?? currentCandle.low
        
        // Define breakout levels
        let upperBreakout = recentHigh + (currentATR * multiplier)
        let lowerBreakout = recentLow - (currentATR * multiplier)
        
        // Check for breakouts
        let direction: StrategySignal.Direction
        let confidence: Double
        let reason: String
        
        if currentCandle.close > upperBreakout {
            // Upward breakout
            direction = .buy
            let breakoutStrength = (currentCandle.close - upperBreakout) / currentATR
            confidence = min(1.0, 0.5 + breakoutStrength * 0.3)
            reason = String(format: "Upward breakout above %.2f", upperBreakout)
        } else if currentCandle.close < lowerBreakout {
            // Downward breakout
            direction = .sell
            let breakoutStrength = (lowerBreakout - currentCandle.close) / currentATR
            confidence = min(1.0, 0.5 + breakoutStrength * 0.3)
            reason = String(format: "Downward breakout below %.2f", lowerBreakout)
        } else {
            // No breakout - check volatility
            let volatilityRatio = currentATR / currentCandle.close
            if volatilityRatio > 0.02 { // High volatility
                direction = .hold
                confidence = 0.4
                reason = String(format: "High volatility (ATR: %.2f), waiting for breakout", currentATR)
            } else {
                direction = .hold
                confidence = 0.2
                reason = String(format: "Consolidating (ATR: %.2f)", currentATR)
            }
        }
        
        return StrategySignal(
            direction: direction,
            confidence: confidence,
            reason: reason,
            strategyName: name
        )
    }
    
    public override func requiredCandles() -> Int {
        return atrPeriod * 2
    }
    
    private func calculateATR(candles: [Candle], period: Int) -> [Double] {
        guard candles.count > period else { return [] }
        
        var trueRanges: [Double] = []
        
        // Calculate True Range for each candle
        for i in 1..<candles.count {
            let current = candles[i]
            let previous = candles[i-1]
            
            let tr1 = current.high - current.low
            let tr2 = abs(current.high - previous.close)
            let tr3 = abs(current.low - previous.close)
            
            let trueRange = max(tr1, tr2, tr3)
            trueRanges.append(trueRange)
        }
        
        guard trueRanges.count >= period else { return [] }
        
        var atrValues: [Double] = []
        
        // Calculate initial ATR (SMA of first period TRs)
        let initialATR = trueRanges.prefix(period).reduce(0, +) / Double(period)
        atrValues.append(initialATR)
        
        // Calculate subsequent ATRs using EMA method
        for i in period..<trueRanges.count {
            guard let lastATR = atrValues.last else { break }
            let atr = (lastATR * Double(period - 1) + trueRanges[i]) / Double(period)
            atrValues.append(atr)
        }
        
        return atrValues
    }
}
