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
        Log.log("MACD fast period updated to \(period)", category: .strategy)
    }
    
    public func updateSlowPeriod(_ period: Int) {
        guard period > fastPeriod else { return }
        slowPeriod = period
        Log.log("MACD slow period updated to \(period)", category: .strategy)
    }
    
    public func updateSignalPeriod(_ period: Int) {
        guard period > 0 && period <= 20 else { return }
        signalPeriod = period
        Log.log("MACD signal period updated to \(period)", category: .strategy)
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= slowPeriod + signalPeriod else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for MACD",
                strategyName: name
            )
        }
        
        let closes = candles.map { $0.close }
        
        // Calculate MACD components
        let fastEMA = calculateEMA(prices: closes, period: fastPeriod)
        let slowEMA = calculateEMA(prices: closes, period: slowPeriod)
        
        guard fastEMA.count > 0 && slowEMA.count > 0 else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "EMA calculation error",
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
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Signal calculation error",
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
