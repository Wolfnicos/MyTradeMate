import Foundation

@MainActor
public class RSIStrategy: BaseStrategy {
    // Thread-safe singleton with proper isolation
    public static let shared: RSIStrategy = {
        let instance = RSIStrategy()
        return instance
    }()

    nonisolated public var period: Int = 14
    nonisolated public var overboughtLevel: Double = 70
    nonisolated public var oversoldLevel: Double = 30

    public init() {
        super.init(
            name: "RSI",
            description: "Relative Strength Index momentum strategy"
        )
    }

    nonisolated public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= self.period + 1 else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for RSI calculation",
                strategyName: name
            )
        }

        let validCandles = candles.filter { candle in
            candle.close > 0 && candle.close.isFinite
        }
        guard validCandles.count >= self.period else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient valid data for RSI calculation",
                strategyName: name
            )
        }

        let closes = validCandles.map { $0.close }
        let rsiValues = self.calculateRSI(prices: closes, period: self.period)

        guard !rsiValues.isEmpty, let currentRSI = rsiValues.last else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "RSI calculation failed - insufficient data",
                strategyName: name
            )
        }

        let direction: StrategySignal.Direction
        let confidence: Double
        let reason: String

        if currentRSI <= self.oversoldLevel {
            direction = .buy
            let oversoldStrength = (self.oversoldLevel - currentRSI) / self.oversoldLevel
            confidence = min(1.0, 0.6 + oversoldStrength * 0.4)
            reason = String(format: "RSI oversold at %.1f (threshold: %.1f)", currentRSI, self.oversoldLevel)
        } else if currentRSI >= self.overboughtLevel {
            direction = .sell
            let overboughtStrength = (currentRSI - self.overboughtLevel) / (100 - self.overboughtLevel)
            confidence = min(1.0, 0.6 + overboughtStrength * 0.4)
            reason = String(format: "RSI overbought at %.1f (threshold: %.1f)", currentRSI, self.overboughtLevel)
        } else {
            direction = .hold
            
            // Ultra-robust validation for currentRSI
            guard currentRSI.isFinite && !currentRSI.isNaN && currentRSI >= 0 && currentRSI <= 100 else {
                Log.ai.warning("Invalid RSI value in neutral zone: \(currentRSI)")
                confidence = 0.2
                reason = "RSI value invalid or out of range"
                return StrategySignal(direction: .hold, confidence: confidence, reason: reason, strategyName: name)
            }
            
            // Safe distance calculation with validation
            let distanceFromNeutral = abs(currentRSI - 50) / 50
            
            // Validate distance calculation result
            guard distanceFromNeutral.isFinite && !distanceFromNeutral.isNaN else {
                Log.ai.warning("Invalid distance calculation: \(distanceFromNeutral) from RSI: \(currentRSI)")
                confidence = 0.2
                reason = "RSI distance calculation failed"
                return StrategySignal(direction: .hold, confidence: confidence, reason: reason, strategyName: name)
            }
            
            // Safe confidence calculation
            let calculatedConfidence = max(0.2, 0.5 - distanceFromNeutral * 0.3)
            guard calculatedConfidence.isFinite && !calculatedConfidence.isNaN else {
                Log.ai.warning("Invalid confidence calculation: \(calculatedConfidence)")
                confidence = 0.2
                reason = "RSI confidence calculation failed"
                return StrategySignal(direction: .hold, confidence: confidence, reason: reason, strategyName: name)
            }
            
            confidence = calculatedConfidence
            
            let trend = currentRSI > 50 ? "bullish" : "bearish"
            reason = String(format: "RSI neutral at %.1f (%@ bias)", currentRSI, trend)
        }

        if rsiValues.count >= 10 {
            if let divergence = self.checkDivergence(candles: candles, rsiValues: rsiValues) {
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

    nonisolated public override func requiredCandles() -> Int {
        return self.period * 3
    }

        // MARK: - Private Methods

    nonisolated private func calculateRSI(prices: [Double], period: Int) -> [Double] {
        guard prices.count > period else {
            Log.ai.warning("RSI calculation failed: insufficient prices (\(prices.count) < \(period + 1))")
            return []
        }

        var gains: [Double] = []
        var losses: [Double] = []

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

        guard gains.count >= period else {
            Log.ai.warning("RSI calculation failed: insufficient gains data (\(gains.count) < \(period))")
            return []
        }

        var rsiValues: [Double] = []
        var avgGain = gains.prefix(period).reduce(0, +) / Double(period)
        var avgLoss = losses.prefix(period).reduce(0, +) / Double(period)

        if avgGain.isNaN || avgGain.isInfinite || avgLoss.isNaN || avgLoss.isInfinite {
            Log.ai.warning("RSI calculation failed: invalid initial averages")
            return []
        }

        let rs = avgLoss == 0 ? 100 : avgGain / avgLoss
        let rsi = 100 - (100 / (1 + rs))
        rsiValues.append(rsi)

        for i in period..<gains.count {
            avgGain = (avgGain * Double(period - 1) + gains[i]) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + losses[i]) / Double(period)

            if avgGain.isNaN || avgGain.isInfinite || avgLoss.isNaN || avgLoss.isInfinite {
                Log.ai.warning("RSI calculation warning: invalid averages at index \(i)")
                continue
            }

            let rs = avgLoss == 0 ? 100 : avgGain / avgLoss
            let rsi = 100 - (100 / (1 + rs))
            rsiValues.append(rsi)
        }

        guard !rsiValues.isEmpty else {
            Log.ai.warning("RSI calculation failed: no RSI values generated")
            return []
        }

        let validRSIValues = rsiValues.filter { $0 >= 0 && $0 <= 100 }
        if validRSIValues.count != rsiValues.count {
            Log.ai.warning("RSI calculation warning: \(rsiValues.count - validRSIValues.count) invalid RSI values filtered out")
        }

        return validRSIValues.isEmpty ? [] : validRSIValues
    }

    nonisolated private func checkDivergence(candles: [Candle], rsiValues: [Double]) -> StrategySignal? {
        guard candles.count >= 10, rsiValues.count >= 10 else { return nil }

        let recentPrices = Array(candles.suffix(10).map { $0.close })
        let recentRSI = Array(rsiValues.suffix(10))

        func findSwings(values: [Double], isHigh: Bool) -> [Int] {
            var swings: [Int] = []
            for i in 1..<values.count-1 {
                if isHigh && values[i] > values[i-1] && values[i] > values[i+1] {
                    swings.append(i)
                } else if !isHigh && values[i] < values[i-1] && values[i] < values[i+1] {
                    swings.append(i)
                }
            }
            return Array(swings.suffix(2))
        }

        let priceLows = findSwings(values: recentPrices, isHigh: false)
        let rsiLows = findSwings(values: recentRSI, isHigh: false)
        if priceLows.count >= 2 && rsiLows.count >= 2 {
            let idx1 = priceLows[priceLows.count - 2]
            let idx2 = priceLows[priceLows.count - 1]
            if idx2 > idx1 && recentPrices[idx2] < recentPrices[idx1] && recentRSI[rsiLows[rsiLows.count - 1]] > recentRSI[rsiLows[rsiLows.count - 2]] {
                return StrategySignal(
                    direction: .buy,
                    confidence: 0.8,
                    reason: "Bullish RSI divergence detected",
                    strategyName: name
                )
            }
        }

        let priceHighs = findSwings(values: recentPrices, isHigh: true)
        let rsiHighs = findSwings(values: recentRSI, isHigh: true)
        if priceHighs.count >= 2 && rsiHighs.count >= 2 {
            let idx1 = priceHighs[priceHighs.count - 2]
            let idx2 = priceHighs[priceHighs.count - 1]
            if idx2 > idx1 && recentPrices[idx2] > recentPrices[idx1] && recentRSI[rsiHighs[rsiHighs.count - 1]] < recentRSI[rsiHighs[rsiHighs.count - 2]] {
                return StrategySignal(
                    direction: .sell,
                    confidence: 0.8,
                    reason: "Bearish RSI divergence detected",
                    strategyName: name
                )
            }
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
