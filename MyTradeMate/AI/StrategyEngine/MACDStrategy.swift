import Foundation

public class MACDStrategy: BaseStrategy {
    public static let shared = MACDStrategy()
    
    public var fastPeriod: Int = 12
    public var slowPeriod: Int = 26
    public var signalPeriod: Int = 9
    
    public init() {
        super.init(
            name: "MACD",
            description: "Moving Average Convergence Divergence strategy"
        )
    }
    
    // MARK: - Parameter Updates
    
    public func updateFastPeriod(_ period: Int) {
        guard period > 0 && period < slowPeriod else { return }
        fastPeriod = period
        Log.strategy.info("MACD fast period updated to \(period)")
    }
    
    public func updateSlowPeriod(_ period: Int) {
        guard period > fastPeriod else { return }
        slowPeriod = period
        Log.strategy.info("MACD slow period updated to \(period)")
    }
    
    public func updateSignalPeriod(_ period: Int) {
        guard period > 0 && period <= 20 else { return }
        signalPeriod = period
        Log.strategy.info("MACD signal period updated to \(period)")
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= slowPeriod + signalPeriod else {
            // ✅ FALLBACK: Use momentum analysis when insufficient data
            let recentPrices = Array(candles.map(\.close).suffix(min(3, candles.count)))
            let momentum = recentPrices.count >= 2 ? 
                (recentPrices.last! - recentPrices.first!) / recentPrices.first! : 0.0
            
            return StrategySignal(
                direction: momentum > 0.005 ? .buy : (momentum < -0.005 ? .sell : .hold),
                confidence: min(0.38, 0.30 + abs(momentum) * 5.0),
                reason: "Insufficient data - momentum fallback",
                strategyName: name
            )
        }
        
        let closes = candles.map { $0.close }
        
        // Calculate MACD components
        let fastEMA = calculateEMA(prices: closes, period: fastPeriod)
        let slowEMA = calculateEMA(prices: closes, period: slowPeriod)
        
        guard fastEMA.count > 0 && slowEMA.count > 0 else {
            // ✅ FALLBACK: Use price change analysis when EMA fails
            let currentPrice = closes.last ?? 0.0
            let avgPrice = closes.reduce(0, +) / Double(closes.count)
            let priceDeviation = avgPrice > 0 ? (currentPrice - avgPrice) / avgPrice : 0.0
            
            return StrategySignal(
                direction: priceDeviation > 0.01 ? .buy : (priceDeviation < -0.01 ? .sell : .hold),
                confidence: min(0.36, 0.30 + abs(priceDeviation) * 2.0),
                reason: "EMA calculation failed - price action fallback",
                strategyName: name
            )
        }
        
        // Calculate MACD line
        var macdLine: [Double] = []
        let offset = slowPeriod - fastPeriod
        for i in 0..<slowEMA.count {
            if i + offset < fastEMA.count {
                macdLine.append(fastEMA[i + offset] - slowEMA[i])
            }
        }
        
        // Calculate signal line (EMA of MACD)
        let signalLine = calculateEMA(prices: macdLine, period: signalPeriod)
        
        guard let currentMACD = macdLine.last,
              let currentSignal = signalLine.last,
              macdLine.count >= 2,
              signalLine.count >= 2 else {
            // ✅ FALLBACK: Use trend analysis when signal calculation fails
            let recentClosing = Array(closes.suffix(5))
            let trendSlope = recentClosing.count >= 2 ? 
                (recentClosing.last! - recentClosing.first!) / (Double(recentClosing.count - 1) * recentClosing.first!) : 0.0
            
            return StrategySignal(
                direction: trendSlope > 0.002 ? .buy : (trendSlope < -0.002 ? .sell : .hold),
                confidence: min(0.37, 0.31 + abs(trendSlope) * 20),
                reason: "Signal calculation failed - trend fallback",
                strategyName: name
            )
        }
        
        let previousMACD = macdLine[macdLine.count - 2]
        let previousSignal = signalLine[signalLine.count - 2]
        
        // Check for crossover
        let crossoverUp = previousMACD <= previousSignal && currentMACD > currentSignal
        let crossoverDown = previousMACD >= previousSignal && currentMACD < currentSignal
        
        // Calculate histogram and confidence
        let histogram = currentMACD - currentSignal
        let confidence = min(1.0, abs(histogram) * 100) // Scale histogram to confidence
        
        if crossoverUp {
            return StrategySignal(
                direction: .buy,
                confidence: confidence,
                reason: "MACD crossed above signal line",
                strategyName: name
            )
        } else if crossoverDown {
            return StrategySignal(
                direction: .sell,
                confidence: confidence,
                reason: "MACD crossed below signal line",
                strategyName: name
            )
        } else {
            let trend = currentMACD > currentSignal ? "Bullish" : "Bearish"
            return StrategySignal(
                direction: .hold,
                confidence: 0.3,
                reason: "\(trend) momentum, no crossover",
                strategyName: name
            )
        }
    }
    
    public override func requiredCandles() -> Int {
        return slowPeriod + signalPeriod + 10
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
