import Foundation

public class EMAStrategy: BaseStrategy {
    public static let shared = EMAStrategy()
    
    public var fastPeriod: Int = 9
    public var slowPeriod: Int = 21
    
    public init() {
        super.init(
            name: "EMA Crossover",
            description: "Exponential Moving Average crossover strategy"
        )
    }
    
    // MARK: - Parameter Updates
    
    public func updateFastPeriod(_ period: Int) {
        guard period > 0 && period < slowPeriod else { return }
        fastPeriod = period
        Log.log("EMA fast period updated to \(period)", category: .strategy)
    }
    
    public func updateSlowPeriod(_ period: Int) {
        guard period > fastPeriod else { return }
        slowPeriod = period
        Log.log("EMA slow period updated to \(period)", category: .strategy)
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= max(fastPeriod, slowPeriod) else {
            // ✅ FALLBACK: Use basic trend analysis when insufficient data
            let currentPrice = candles.last?.close ?? 0.0
            let avgPrice = candles.map(\.close).reduce(0, +) / Double(candles.count)
            let trend = currentPrice > avgPrice ? 1.0 : -1.0
            let trendStrength = avgPrice > 0 ? abs(currentPrice - avgPrice) / avgPrice : 0.0
            
            return StrategySignal(
                direction: trend > 0 ? .buy : .sell,
                confidence: min(0.40, 0.30 + trendStrength * 0.5),
                reason: "Insufficient data - basic trend fallback",
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
            // ✅ FALLBACK: Use simple moving average when EMA calculation fails
            let recentPrices = Array(closes.suffix(min(5, closes.count)))
            let avgPrice = recentPrices.reduce(0, +) / Double(recentPrices.count)
            let currentPrice = closes.last ?? 0.0
            let momentum = avgPrice > 0 ? (currentPrice - avgPrice) / avgPrice : 0.0
            
            return StrategySignal(
                direction: momentum > 0.01 ? .buy : (momentum < -0.01 ? .sell : .hold),
                confidence: min(0.38, 0.32 + abs(momentum) * 2.0),
                reason: "EMA calculation failed - SMA fallback",
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
            guard let lastEMA = ema.last else { break }
            let value = (prices[i] - lastEMA) * multiplier + lastEMA
            ema.append(value)
        }
        
        return ema
    }
}
