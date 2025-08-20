import Foundation

/// Stochastic Oscillator strategy implementation
public final class StochasticStrategy: BaseStrategy {
    public static let shared = StochasticStrategy()
    
    public var kPeriod: Int = 14
    public var dPeriod: Int = 3
    public var overboughtLevel: Double = 80.0
    public var oversoldLevel: Double = 20.0
    
    public init() {
        super.init(
            name: "Stochastic",
            description: "Momentum oscillator comparing closing price to price range"
        )
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= requiredCandles() else {
            // ✅ FALLBACK: Use price range position when insufficient data
            let recentCandles = Array(candles.suffix(min(5, candles.count)))
            let high = recentCandles.map(\.high).max() ?? 0.0
            let low = recentCandles.map(\.low).min() ?? 0.0
            let currentPrice = recentCandles.last?.close ?? 0.0
            let oscillatorPosition = (high - low) > 0 ? (currentPrice - low) / (high - low) * 100 : 50.0
            
            return StrategySignal(
                direction: oscillatorPosition > 70 ? .sell : (oscillatorPosition < 30 ? .buy : .hold),
                confidence: 0.35,
                reason: "Insufficient data - oscillator position fallback",
                strategyName: name
            )
        }
        
        let recentCandles = Array(candles.suffix(kPeriod + dPeriod))
        var kValues: [Double] = []
        
        // Calculate %K values
        for i in kPeriod..<recentCandles.count {
            let periodCandles = Array(recentCandles[(i-kPeriod)..<i])
            let highestHigh = periodCandles.map { $0.high }.max() ?? 0
            let lowestLow = periodCandles.map { $0.low }.min() ?? 0
            let currentClose = recentCandles[i].close
            
            let kValue = ((currentClose - lowestLow) / (highestHigh - lowestLow)) * 100
            kValues.append(kValue)
        }
        
        guard kValues.count >= dPeriod else {
            // ✅ FALLBACK: Use basic momentum when K values insufficient
            let momentum = candles.count >= 2 ? 
                (candles.last!.close - candles[candles.count-2].close) / candles[candles.count-2].close : 0.0
            
            return StrategySignal(
                direction: momentum > 0.01 ? .buy : (momentum < -0.01 ? .sell : .hold),
                confidence: 0.35,
                reason: "K values insufficient - momentum fallback",
                strategyName: name
            )
        }
        
        // Calculate %D (moving average of %K)
        guard let currentK = kValues.last else {
            return StrategySignal(direction: .hold, confidence: 0.33, reason: "Overbought/oversold inconclusive - neutral fallback", strategyName: name)
        }
        let currentD = kValues.suffix(dPeriod).reduce(0, +) / Double(dPeriod)
        let previousK = kValues.count > 1 ? kValues[kValues.count - 2] : currentK
        let previousD = kValues.count >= dPeriod + 1 ? 
            kValues.suffix(dPeriod + 1).dropLast().reduce(0, +) / Double(dPeriod) : currentD
        
        // Generate signals based on crossovers and levels
        if currentK < oversoldLevel && currentD < oversoldLevel && currentK > currentD && previousK <= previousD {
            // Bullish crossover in oversold territory
            let confidence = 0.7 + (0.2 * (oversoldLevel - min(currentK, currentD)) / oversoldLevel)
            return StrategySignal(
                direction: .buy,
                confidence: min(0.9, confidence),
                reason: "Stochastic bullish crossover in oversold territory",
                strategyName: name
            )
        } else if currentK > overboughtLevel && currentD > overboughtLevel && currentK < currentD && previousK >= previousD {
            // Bearish crossover in overbought territory
            let confidence = 0.7 + (0.2 * (min(currentK, currentD) - overboughtLevel) / (100 - overboughtLevel))
            return StrategySignal(
                direction: .sell,
                confidence: min(0.9, confidence),
                reason: "Stochastic bearish crossover in overbought territory",
                strategyName: name
            )
        } else if currentK < oversoldLevel && currentD < oversoldLevel {
            // In oversold territory - weak buy signal
            return StrategySignal(
                direction: .buy,
                confidence: 0.4,
                reason: "Stochastic in oversold territory",
                strategyName: name
            )
        } else if currentK > overboughtLevel && currentD > overboughtLevel {
            // In overbought territory - weak sell signal
            return StrategySignal(
                direction: .sell,
                confidence: 0.4,
                reason: "Stochastic in overbought territory",
                strategyName: name
            )
        }
        
        return StrategySignal(
            direction: .hold,
            confidence: 0.30,
            reason: "Stochastic in neutral territory",
            strategyName: name
        )
    }
    
    public override func requiredCandles() -> Int {
        return kPeriod + dPeriod + 5
    }
    
    public func updateParameter(key: String, value: Any) {
        switch key {
        case "kPeriod":
            if let intValue = value as? Int {
                kPeriod = max(5, min(50, intValue))
            }
        case "dPeriod":
            if let intValue = value as? Int {
                dPeriod = max(1, min(20, intValue))
            }
        case "overboughtLevel":
            if let doubleValue = value as? Double {
                overboughtLevel = max(70, min(95, doubleValue))
            }
        case "oversoldLevel":
            if let doubleValue = value as? Double {
                oversoldLevel = max(5, min(30, doubleValue))
            }
        default:
            break
        }
    }
}