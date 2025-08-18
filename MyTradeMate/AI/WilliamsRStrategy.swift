import Foundation

/// Williams %R strategy implementation
public final class WilliamsRStrategy: BaseStrategy {
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
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for Williams %R",
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
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Unable to calculate Williams %R",
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
            confidence: 0.1,
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