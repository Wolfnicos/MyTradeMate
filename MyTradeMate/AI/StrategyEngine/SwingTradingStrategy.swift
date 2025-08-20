import Foundation

/// Swing Trading strategy implementation
public final class SwingTradingStrategy: BaseStrategy {
    public static let shared = SwingTradingStrategy()
    public var sma20Period: Int = 20
    public var sma50Period: Int = 50
    public var rsiPeriod: Int = 14
    public var macdFastPeriod: Int = 12
    public var macdSlowPeriod: Int = 26
    public var macdSignalPeriod: Int = 9
    public var supportResistancePeriod: Int = 50
    
    public init() {
        super.init(
            name: "Swing Trading",
            description: "Medium-term strategy for capturing price swings"
        )
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= requiredCandles() else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for Swing Trading",
                strategyName: name
            )
        }
        
        // Calculate indicators
        let sma20 = calculateSMA(candles: candles, period: sma20Period)
        let sma50 = calculateSMA(candles: candles, period: sma50Period)
        let rsi = calculateRSI(candles: candles, period: rsiPeriod)
        let macd = calculateMACD(candles: candles)
        let supportResistance = findSupportResistance(candles: candles)
        
        guard let currentSMA20 = sma20.last,
              let currentSMA50 = sma50.last,
              let currentRSI = rsi.last,
              let currentMACD = macd.macd.last,
              let currentSignal = macd.signal.last else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Unable to calculate swing trading indicators",
                strategyName: name
            )
        }
        
        guard let currentPrice = candles.last?.close,
              candles.count >= 2 else { 
            return StrategySignal(direction: .hold, confidence: 0.0, reason: "Insufficient data", strategyName: name) 
        }
        let previousPrice = candles[candles.count - 2].close
        
        var signals: [String] = []
        var confidence: Double = 0.0
        var direction: StrategySignal.Direction = .hold
        
        // Trend analysis
        let isUptrend = currentSMA20 > currentSMA50
        let trendStrength = abs(currentSMA20 - currentSMA50) / currentSMA50
        
        // MACD analysis
        let macdBullish = currentMACD > currentSignal
        let macdCrossover = checkMACDCrossover(macd: macd)
        
        // Support/Resistance analysis
        let nearSupport = isNearLevel(price: currentPrice, level: supportResistance.support, tolerance: 0.01)
        let nearResistance = isNearLevel(price: currentPrice, level: supportResistance.resistance, tolerance: 0.01)
        
        // Bullish swing setup
        if isUptrend && currentRSI < 70 && currentPrice > currentSMA20 {
            signals.append("Uptrend confirmed")
            confidence += 0.3
            direction = .buy
            
            // Additional bullish signals
            if macdBullish {
                signals.append("MACD bullish")
                confidence += 0.2
            }
            
            if macdCrossover == .bullish {
                signals.append("MACD bullish crossover")
                confidence += 0.3
            }
            
            if nearSupport {
                signals.append("Near support level")
                confidence += 0.2
            }
            
            if currentRSI < 50 {
                signals.append("RSI not overbought")
                confidence += 0.1
            }
            
            if trendStrength > 0.02 {
                signals.append("Strong trend")
                confidence += 0.1
            }
        }
        
        // Bearish swing setup
        else if !isUptrend && currentRSI > 30 && currentPrice < currentSMA20 {
            signals.append("Downtrend confirmed")
            confidence += 0.3
            direction = .sell
            
            // Additional bearish signals
            if !macdBullish {
                signals.append("MACD bearish")
                confidence += 0.2
            }
            
            if macdCrossover == .bearish {
                signals.append("MACD bearish crossover")
                confidence += 0.3
            }
            
            if nearResistance {
                signals.append("Near resistance level")
                confidence += 0.2
            }
            
            if currentRSI > 50 {
                signals.append("RSI not oversold")
                confidence += 0.1
            }
            
            if trendStrength > 0.02 {
                signals.append("Strong trend")
                confidence += 0.1
            }
        }
        
        // Reversal patterns
        else if nearSupport && currentRSI < 35 && macdCrossover == .bullish {
            signals.append("Potential bullish reversal")
            signals.append("Oversold at support")
            confidence = 0.7
            direction = .buy
        }
        
        else if nearResistance && currentRSI > 65 && macdCrossover == .bearish {
            signals.append("Potential bearish reversal")
            signals.append("Overbought at resistance")
            confidence = 0.7
            direction = .sell
        }
        
        // Momentum continuation
        else if isUptrend && currentPrice > previousPrice && currentRSI > 50 && currentRSI < 70 {
            signals.append("Bullish momentum continuation")
            confidence = 0.4
            direction = .buy
        }
        
        else if !isUptrend && currentPrice < previousPrice && currentRSI < 50 && currentRSI > 30 {
            signals.append("Bearish momentum continuation")
            confidence = 0.4
            direction = .sell
        }
        
        confidence = min(0.9, confidence)
        
        let reason = signals.isEmpty ? "No swing trading opportunities" : signals.joined(separator: ", ")
        
        return StrategySignal(
            direction: direction,
            confidence: confidence,
            reason: reason,
            strategyName: name
        )
    }
    
    private func calculateSMA(candles: [Candle], period: Int) -> [Double] {
        guard candles.count >= period else { return [] }
        
        var sma: [Double] = []
        
        for i in (period - 1)..<candles.count {
            let sum = candles[(i - period + 1)...i].map { $0.close }.reduce(0, +)
            sma.append(sum / Double(period))
        }
        
        return sma
    }
    
    private func calculateRSI(candles: [Candle], period: Int) -> [Double] {
        guard candles.count > period else { return [] }
        
        var gains: [Double] = []
        var losses: [Double] = []
        
        for i in 1..<candles.count {
            let change = candles[i].close - candles[i-1].close
            gains.append(max(change, 0))
            losses.append(max(-change, 0))
        }
        
        guard gains.count >= period else { return [] }
        
        var rsi: [Double] = []
        var avgGain = gains.prefix(period).reduce(0, +) / Double(period)
        var avgLoss = losses.prefix(period).reduce(0, +) / Double(period)
        
        if avgLoss == 0 {
            rsi.append(100)
        } else {
            let rs = avgGain / avgLoss
            rsi.append(100 - (100 / (1 + rs)))
        }
        
        for i in period..<gains.count {
            avgGain = (avgGain * Double(period - 1) + gains[i]) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + losses[i]) / Double(period)
            
            if avgLoss == 0 {
                rsi.append(100)
            } else {
                let rs = avgGain / avgLoss
                rsi.append(100 - (100 / (1 + rs)))
            }
        }
        
        return rsi
    }
    
    private func calculateMACD(candles: [Candle]) -> (macd: [Double], signal: [Double], histogram: [Double]) {
        let fastEMA = calculateEMA(candles: candles, period: macdFastPeriod)
        let slowEMA = calculateEMA(candles: candles, period: macdSlowPeriod)
        
        guard fastEMA.count == slowEMA.count && !fastEMA.isEmpty else {
            return ([], [], [])
        }
        
        let macd = zip(fastEMA, slowEMA).map { $0 - $1 }
        let signal = calculateEMAFromValues(values: macd, period: macdSignalPeriod)
        
        let histogram = zip(macd.suffix(signal.count), signal).map { $0 - $1 }
        
        return (macd, signal, histogram)
    }
    
    private func calculateEMA(candles: [Candle], period: Int) -> [Double] {
        guard candles.count >= period else { return [] }
        
        let multiplier = 2.0 / Double(period + 1)
        var ema: [Double] = []
        
        let firstSMA = candles.prefix(period).map { $0.close }.reduce(0, +) / Double(period)
        ema.append(firstSMA)
        
        for i in period..<candles.count {
            guard let lastEMA = ema.last else { continue }
            let newEMA = (candles[i].close * multiplier) + (lastEMA * (1 - multiplier))
            ema.append(newEMA)
        }
        
        return ema
    }
    
    private func calculateEMAFromValues(values: [Double], period: Int) -> [Double] {
        guard values.count >= period else { return [] }
        
        let multiplier = 2.0 / Double(period + 1)
        var ema: [Double] = []
        
        let firstSMA = values.prefix(period).reduce(0, +) / Double(period)
        ema.append(firstSMA)
        
        for i in period..<values.count {
            guard let lastEMA = ema.last else { continue }
            let newEMA = (values[i] * multiplier) + (lastEMA * (1 - multiplier))
            ema.append(newEMA)
        }
        
        return ema
    }
    
    private func findSupportResistance(candles: [Candle]) -> (support: Double, resistance: Double) {
        let recentCandles = Array(candles.suffix(supportResistancePeriod))
        let highs = recentCandles.map { $0.high }
        let lows = recentCandles.map { $0.low }
        
        let resistance = highs.max() ?? 0
        let support = lows.min() ?? 0
        
        return (support, resistance)
    }
    
    private func isNearLevel(price: Double, level: Double, tolerance: Double) -> Bool {
        let distance = abs(price - level) / level
        return distance <= tolerance
    }
    
    private enum MACDCrossover {
        case bullish, bearish, none
    }
    
    private func checkMACDCrossover(macd: (macd: [Double], signal: [Double], histogram: [Double])) -> MACDCrossover {
        guard macd.macd.count >= 2 && macd.signal.count >= 2 else { return .none }
        
        guard let currentMACD = macd.macd.last,
              let currentSignal = macd.signal.last else {
            return .none
        }
        let previousMACD = macd.macd[macd.macd.count - 2]
        let previousSignal = macd.signal[macd.signal.count - 2]
        
        if currentMACD > currentSignal && previousMACD <= previousSignal {
            return .bullish
        } else if currentMACD < currentSignal && previousMACD >= previousSignal {
            return .bearish
        }
        
        return .none
    }
    
    public override func requiredCandles() -> Int {
        return max(sma50Period, supportResistancePeriod) + 20
    }
    
    public func updateParameter(key: String, value: Any) {
        switch key {
        case "sma20Period":
            if let intValue = value as? Int {
                sma20Period = max(10, min(30, intValue))
            }
        case "sma50Period":
            if let intValue = value as? Int {
                sma50Period = max(30, min(100, intValue))
            }
        case "rsiPeriod":
            if let intValue = value as? Int {
                rsiPeriod = max(10, min(25, intValue))
            }
        case "supportResistancePeriod":
            if let intValue = value as? Int {
                supportResistancePeriod = max(30, min(100, intValue))
            }
        default:
            break
        }
    }
}