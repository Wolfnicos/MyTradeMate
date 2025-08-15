import Foundation

public class EMAStrategy: BaseStrategy {
    public var fastPeriod: Int = 9
    public var slowPeriod: Int = 21
    
    public init() {
        super.init(
            name: "EMA Crossover",
            description: "Exponential Moving Average crossover strategy"
        )
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= max(fastPeriod, slowPeriod) else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data",
                strategyName: name
            )
        }
        
        let closes = candles.map { $0.close }
        let fastEMA = calculateEMA(prices: closes, period: fastPeriod)
        let slowEMA = calculateEMA(prices: closes, period: slowPeriod)
        
        guard let currentFast = fastEMA.last,
              let currentSlow = slowEMA.last,
              fastEMA.count >= 2,
              slowEMA.count >= 2 else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "EMA calculation error",
                strategyName: name
            )
        }
        
        let previousFast = fastEMA[fastEMA.count - 2]
        let previousSlow = slowEMA[slowEMA.count - 2]
        
        // Check for crossover
        let crossoverUp = previousFast <= previousSlow && currentFast > currentSlow
        let crossoverDown = previousFast >= previousSlow && currentFast < currentSlow
        
        // Calculate confidence based on crossover strength
        let crossoverStrength = abs(currentFast - currentSlow) / currentSlow
        let confidence = min(1.0, crossoverStrength * 10) // Scale to 0-1
        
        if crossoverUp {
            return StrategySignal(
                direction: .buy,
                confidence: confidence,
                reason: "Fast EMA crossed above slow EMA",
                strategyName: name
            )
        } else if crossoverDown {
            return StrategySignal(
                direction: .sell,
                confidence: confidence,
                reason: "Fast EMA crossed below slow EMA",
                strategyName: name
            )
        } else {
            let trend = currentFast > currentSlow ? "Bullish" : "Bearish"
            return StrategySignal(
                direction: .hold,
                confidence: 0.3,
                reason: "\(trend) trend, no crossover",
                strategyName: name
            )
        }
    }
    
    public override func requiredCandles() -> Int {
        return max(fastPeriod, slowPeriod) * 2
    }
    
    private func calculateEMA(prices: [Double], period: Int) -> [Double] {
        guard prices.count >= period else { return [] }
        
        var ema: [Double] = []
        let multiplier = 2.0 / Double(period + 1)
        
        // Calculate initial SMA
        let sma = prices.prefix(period).reduce(0, +) / Double(period)
        ema.append(sma)
        
        // Calculate EMA for remaining prices
        for i in period..<prices.count {
            let value = (prices[i] - ema.last!) * multiplier + ema.last!
            ema.append(value)
        }
        
        return ema
    }
}
