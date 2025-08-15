import Foundation

public class RSIStrategy: BaseStrategy {
    public var period: Int = 14
    public var oversoldThreshold: Double = 30.0
    public var overboughtThreshold: Double = 70.0
    
    public init() {
        super.init(
            name: "RSI Swing",
            description: "Relative Strength Index momentum strategy"
        )
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count > period else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for RSI",
                strategyName: name
            )
        }
        
        let rsi = calculateRSI(candles: candles, period: period)
        
        guard let currentRSI = rsi.last else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "RSI calculation error",
                strategyName: name
            )
        }
        
        // Calculate confidence based on RSI extremity
        let confidence: Double
        let direction: StrategySignal.Direction
        let reason: String
        
        if currentRSI < oversoldThreshold {
            // Oversold - potential buy signal
            confidence = (oversoldThreshold - currentRSI) / oversoldThreshold
            direction = .buy
            reason = String(format: "RSI oversold at %.1f", currentRSI)
        } else if currentRSI > overboughtThreshold {
            // Overbought - potential sell signal
            confidence = (currentRSI - overboughtThreshold) / (100 - overboughtThreshold)
            direction = .sell
            reason = String(format: "RSI overbought at %.1f", currentRSI)
        } else {
            // Neutral zone
            confidence = 0.2
            direction = .hold
            reason = String(format: "RSI neutral at %.1f", currentRSI)
        }
        
        return StrategySignal(
            direction: direction,
            confidence: min(1.0, max(0.0, confidence)),
            reason: reason,
            strategyName: name
        )
    }
    
    public override func requiredCandles() -> Int {
        return period + 10 // Extra buffer for calculation
    }
    
    private func calculateRSI(candles: [Candle], period: Int) -> [Double] {
        guard candles.count > period else { return [] }
        
        var rsiValues: [Double] = []
        let closes = candles.map { $0.close }
        
        // Calculate price changes
        var gains: [Double] = []
        var losses: [Double] = []
        
        for i in 1..<closes.count {
            let change = closes[i] - closes[i-1]
            if change > 0 {
                gains.append(change)
                losses.append(0)
            } else {
                gains.append(0)
                losses.append(abs(change))
            }
        }
        
        // Calculate initial average gain/loss
        let initialGains = gains.prefix(period)
        let initialLosses = losses.prefix(period)
        
        var avgGain = initialGains.reduce(0, +) / Double(period)
        var avgLoss = initialLosses.reduce(0, +) / Double(period)
        
        // Calculate RSI for each period
        for i in period..<gains.count {
            avgGain = (avgGain * Double(period - 1) + gains[i]) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + losses[i]) / Double(period)
            
            let rs = avgLoss == 0 ? 100 : avgGain / avgLoss
            let rsi = 100 - (100 / (1 + rs))
            rsiValues.append(rsi)
        }
        
        return rsiValues
    }
}
