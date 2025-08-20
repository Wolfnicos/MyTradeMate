import Foundation

/// Williams %R strategy implementation
public final class WilliamsRStrategy: BaseStrategy {
    public static let shared = WilliamsRStrategy()
    public var period: Int = 14
    public var overboughtLevel: Double = -20.0
    public var oversoldLevel: Double = -80.0
    
    public init() {
        super.init(
            name: "Williams %R",
            description: "Momentum oscillator measuring overbought/oversold levels"
        )
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= requiredCandles() else {
            // ✅ FALLBACK: Use price range analysis when insufficient data
            let recentPrices = candles.map(\.close)
            let currentPrice = recentPrices.last ?? 0.0
            let avgPrice = recentPrices.reduce(0, +) / Double(recentPrices.count)
            let oscillatorBias = currentPrice > avgPrice ? 1.0 : -1.0
            
            return StrategySignal(
                direction: oscillatorBias > 0 ? .buy : .sell,
                confidence: 0.35,
                reason: "Insufficient data - oscillator bias fallback",
                strategyName: name
            )
        }
        
        let recentCandles = Array(candles.suffix(period + 1))
        var williamsRValues: [Double] = []
        
        // Calculate Williams %R values
        for i in period..<recentCandles.count {
            let periodCandles = Array(recentCandles[(i-period)..<i])
            let highestHigh = periodCandles.map { $0.high }.max() ?? 0
            let lowestLow = periodCandles.map { $0.low }.min() ?? 0
            let currentClose = recentCandles[i].close
            
            let williamsR = ((highestHigh - currentClose) / (highestHigh - lowestLow)) * -100
            williamsRValues.append(williamsR)
        }
        
        guard let currentWR = williamsRValues.last else {
            // ✅ FALLBACK: Use high-low range when Williams %R calculation fails
            let recentCandles = Array(candles.suffix(min(5, candles.count)))
            let highPrice = recentCandles.map(\.high).max() ?? 0.0
            let lowPrice = recentCandles.map(\.low).min() ?? 0.0
            let currentPrice = recentCandles.last?.close ?? 0.0
            let rangePosition = (highPrice - lowPrice) > 0 ? (currentPrice - lowPrice) / (highPrice - lowPrice) : 0.5
            
            return StrategySignal(
                direction: rangePosition > 0.7 ? .sell : (rangePosition < 0.3 ? .buy : .hold),
                confidence: 0.35,
                reason: "Oscillator range inconclusive - bias fallback",
                strategyName: name
            )
        }
        
        let previousWR = williamsRValues.count > 1 ? williamsRValues[williamsRValues.count - 2] : currentWR
        
        // Generate signals
        if currentWR < oversoldLevel && previousWR >= oversoldLevel {
            // Entering oversold territory - potential buy setup
            let confidence = 0.6 + (0.3 * (oversoldLevel - currentWR) / (oversoldLevel - (-100)))
            return StrategySignal(
                direction: .buy,
                confidence: min(0.9, confidence),
                reason: "Williams %R entering oversold territory",
                strategyName: name
            )
        } else if currentWR > overboughtLevel && previousWR <= overboughtLevel {
            // Entering overbought territory - potential sell setup
            let confidence = 0.6 + (0.3 * (currentWR - overboughtLevel) / (0 - overboughtLevel))
            return StrategySignal(
                direction: .sell,
                confidence: min(0.9, confidence),
                reason: "Williams %R entering overbought territory",
                strategyName: name
            )
        } else if currentWR > oversoldLevel && previousWR <= oversoldLevel {
            // Exiting oversold territory - buy signal
            return StrategySignal(
                direction: .buy,
                confidence: 0.7,
                reason: "Williams %R exiting oversold territory",
                strategyName: name
            )
        } else if currentWR < overboughtLevel && previousWR >= overboughtLevel {
            // Exiting overbought territory - sell signal
            return StrategySignal(
                direction: .sell,
                confidence: 0.7,
                reason: "Williams %R exiting overbought territory",
                strategyName: name
            )
        } else if currentWR < oversoldLevel {
            // In oversold territory - weak buy signal
            return StrategySignal(
                direction: .buy,
                confidence: 0.3,
                reason: "Williams %R in oversold territory",
                strategyName: name
            )
        } else if currentWR > overboughtLevel {
            // In overbought territory - weak sell signal
            return StrategySignal(
                direction: .sell,
                confidence: 0.3,
                reason: "Williams %R in overbought territory",
                strategyName: name
            )
        }
        
        return StrategySignal(
            direction: .hold,
            confidence: 0.30,
            reason: "Williams %R in neutral range",
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
                period = max(5, min(50, intValue))
            }
        case "overboughtLevel":
            if let doubleValue = value as? Double {
                overboughtLevel = max(-50, min(-10, doubleValue))
            }
        case "oversoldLevel":
            if let doubleValue = value as? Double {
                oversoldLevel = max(-95, min(-50, doubleValue))
            }
        default:
            break
        }
    }
}