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
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for Stochastic",
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
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient K values for Stochastic",
                strategyName: name
            )
        }
        
        // Calculate %D (moving average of %K)
        guard let currentK = kValues.last else {
            return StrategySignal(direction: .hold, confidence: 0.0, reason: "Insufficient Stochastic data", strategyName: name)
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
            confidence: 0.1,
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