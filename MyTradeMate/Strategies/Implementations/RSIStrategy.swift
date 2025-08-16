import Foundation

public class RSIStrategy: BaseStrategy {
    public static let shared = RSIStrategy()
    
    public var period: Int = 14
    public var overboughtLevel: Double = 70
    public var oversoldLevel: Double = 30
    
    public init() {
        super.init(
            name: "RSI",
            description: "Relative Strength Index momentum strategy"
        )
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= period + 1 else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for RSI calculation",
                strategyName: name
            )
        }
        
        let closes = candles.map { $0.close }
        let rsiValues = calculateRSI(prices: closes, period: period)
        
        guard let currentRSI = rsiValues.last else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "RSI calculation failed",
                strategyName: name
            )
        }
        
        // Determine signal based on RSI levels
        let direction: StrategySignal.Direction
        let confidence: Double
        let reason: String
        
        if currentRSI <= oversoldLevel {
            // Oversold condition - potential buy signal
            direction = .buy
            let oversoldStrength = (oversoldLevel - currentRSI) / oversoldLevel
            confidence = min(1.0, 0.6 + oversoldStrength * 0.4)
            reason = String(format: "RSI oversold at %.1f (threshold: %.1f)", currentRSI, oversoldLevel)
            
        } else if currentRSI >= overboughtLevel {
            // Overbought condition - potential sell signal
            direction = .sell
            let overboughtStrength = (currentRSI - overboughtLevel) / (100 - overboughtLevel)
            confidence = min(1.0, 0.6 + overboughtStrength * 0.4)
            reason = String(format: "RSI overbought at %.1f (threshold: %.1f)", currentRSI, overboughtLevel)
            
        } else {
            // Neutral zone
            direction = .hold
            
            // Calculate distance from neutral (50)
            let distanceFromNeutral = abs(currentRSI - 50) / 50
            confidence = 0.2 + distanceFromNeutral * 0.3
            
            let trend = currentRSI > 50 ? "bullish" : "bearish"
            reason = String(format: "RSI neutral at %.1f (%s bias)", currentRSI, trend)
        }
        
        // Check for divergence if we have enough data
        if rsiValues.count >= 10 {
            let divergenceSignal = checkDivergence(candles: candles, rsiValues: rsiValues)
            if let divergence = divergenceSignal {
                return divergence
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
        return period * 3 // Need extra data for reliable RSI calculation
    }
    
    // MARK: - Private Methods
    
    private func calculateRSI(prices: [Double], period: Int) -> [Double] {
        guard prices.count > period else { return [] }
        
        var gains: [Double] = []
        var losses: [Double] = []
        
        // Calculate price changes
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            if change > 0 {
                gains.append(change)
                losses.append(0)
            } else {
                gains.append(0)
                losses.append(-change)
            }
        }
        
        guard gains.count >= period else { return [] }
        
        var rsiValues: [Double] = []
        
        // Calculate initial average gain and loss
        var avgGain = gains.prefix(period).reduce(0, +) / Double(period)
        var avgLoss = losses.prefix(period).reduce(0, +) / Double(period)
        
        // Calculate first RSI value
        let rs = avgLoss == 0 ? 100 : avgGain / avgLoss
        let rsi = 100 - (100 / (1 + rs))
        rsiValues.append(rsi)
        
        // Calculate subsequent RSI values using smoothed averages
        for i in period..<gains.count {
            avgGain = (avgGain * Double(period - 1) + gains[i]) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + losses[i]) / Double(period)
            
            let rs = avgLoss == 0 ? 100 : avgGain / avgLoss
            let rsi = 100 - (100 / (1 + rs))
            rsiValues.append(rsi)
        }
        
        return rsiValues
    }
    
    private func checkDivergence(candles: [Candle], rsiValues: [Double]) -> StrategySignal? {
        guard candles.count >= 10, rsiValues.count >= 10 else { return nil }
        
        let recentCandles = Array(candles.suffix(10))
        let recentRSI = Array(rsiValues.suffix(10))
        
        // Find recent highs and lows
        let priceHigh = recentCandles.map { $0.high }.max() ?? 0
        let priceLow = recentCandles.map { $0.low }.min() ?? 0
        let rsiHigh = recentRSI.max() ?? 0
        let rsiLow = recentRSI.min() ?? 0
        
        let currentPrice = recentCandles.last?.close ?? 0
        let currentRSI = recentRSI.last ?? 0
        
        // Check for bullish divergence (price makes lower low, RSI makes higher low)
        if currentPrice < priceLow * 1.02 && currentRSI > rsiLow * 1.05 {
            return StrategySignal(
                direction: .buy,
                confidence: 0.75,
                reason: "Bullish RSI divergence detected",
                strategyName: name
            )
        }
        
        // Check for bearish divergence (price makes higher high, RSI makes lower high)
        if currentPrice > priceHigh * 0.98 && currentRSI < rsiHigh * 0.95 {
            return StrategySignal(
                direction: .sell,
                confidence: 0.75,
                reason: "Bearish RSI divergence detected",
                strategyName: name
            )
        }
        
        return nil
    }
}

// MARK: - Parameter Configuration

extension RSIStrategy {
    public func updatePeriod(_ newPeriod: Int) {
        guard newPeriod >= 2 && newPeriod <= 50 else { return }
        period = newPeriod
        Log.verbose("RSI period updated to \(newPeriod)", category: .ai)
    }
    
    public func updateOverboughtLevel(_ level: Double) {
        guard level >= 50 && level <= 95 else { return }
        overboughtLevel = level
        Log.verbose("RSI overbought level updated to \(level)", category: .ai)
    }
    
    public func updateOversoldLevel(_ level: Double) {
        guard level >= 5 && level <= 50 else { return }
        oversoldLevel = level
        Log.verbose("RSI oversold level updated to \(level)", category: .ai)
    }
    
    public var parameters: [String: Any] {
        return [
            "period": period,
            "overboughtLevel": overboughtLevel,
            "oversoldLevel": oversoldLevel
        ]
    }
    
    public func updateParameter(key: String, value: Any) {
        switch key {
        case "period":
            if let intValue = value as? Int {
                updatePeriod(intValue)
            }
        case "overboughtLevel":
            if let doubleValue = value as? Double {
                updateOverboughtLevel(doubleValue)
            }
        case "oversoldLevel":
            if let doubleValue = value as? Double {
                updateOversoldLevel(doubleValue)
            }
        default:
            Log.warning("Unknown RSI parameter: \(key)", category: .ai)
        }
    }
}