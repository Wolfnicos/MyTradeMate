import Foundation

/// Scalping strategy implementation
public final class ScalpingStrategy: BaseStrategy {
    public static let shared = ScalpingStrategy()
    public var fastEMAPeriod: Int = 5
    public var slowEMAPeriod: Int = 13
    public var rsiPeriod: Int = 7
    public var volumeMultiplier: Double = 1.5
    public var minProfitTarget: Double = 0.003 // 0.3%
    public var maxRiskPerTrade: Double = 0.002 // 0.2%
    
    public init() {
        super.init(
            name: "Scalping",
            description: "High-frequency trading strategy for quick profits"
        )
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= requiredCandles() else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for Scalping",
                strategyName: name
            )
        }
        
        guard let currentCandle = candles.last else { return StrategySignal(direction: .hold, confidence: 0.0, reason: "Insufficient data", strategyName: name) }
        guard candles.count >= 2 else {
            return StrategySignal(direction: .hold, confidence: 0.0, reason: "Insufficient data", strategyName: name)
        }
        let previousCandle = candles[candles.count - 2]
        
        // Calculate EMAs
        let fastEMA = calculateEMA(candles: candles, period: fastEMAPeriod)
        let slowEMA = calculateEMA(candles: candles, period: slowEMAPeriod)
        
        guard let currentFastEMA = fastEMA.last,
              let currentSlowEMA = slowEMA.last,
              let previousFastEMA = fastEMA.count > 1 ? fastEMA[fastEMA.count - 2] : nil,
              let previousSlowEMA = slowEMA.count > 1 ? slowEMA[slowEMA.count - 2] : nil else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Unable to calculate EMAs for scalping",
                strategyName: name
            )
        }
        
        // Calculate RSI
        let rsi = calculateRSI(candles: candles, period: rsiPeriod)
        guard let currentRSI = rsi.last else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Unable to calculate RSI for scalping",
                strategyName: name
            )
        }
        
        // Volume analysis
        let recentVolumes = candles.suffix(10).map { $0.volume }
        let averageVolume = recentVolumes.reduce(0, +) / Double(recentVolumes.count)
        let volumeRatio = currentCandle.volume / averageVolume
        
        // Price momentum
        let priceChange = (currentCandle.close - previousCandle.close) / previousCandle.close
        let isStrongMomentum = abs(priceChange) > 0.001 // 0.1% minimum move
        
        // EMA crossover detection
        let bullishCrossover = currentFastEMA > currentSlowEMA && 
                              (previousFastEMA ?? currentFastEMA) <= (previousSlowEMA ?? currentSlowEMA)
        let bearishCrossover = currentFastEMA < currentSlowEMA && 
                              (previousFastEMA ?? currentFastEMA) >= (previousSlowEMA ?? currentSlowEMA)
        
        // Scalping conditions
        var signals: [String] = []
        var confidence: Double = 0.0
        var direction: StrategySignal.Direction = .hold
        
        // Bullish scalping setup
        if bullishCrossover && currentRSI < 70 && volumeRatio >= volumeMultiplier && isStrongMomentum && priceChange > 0 {
            signals.append("EMA bullish crossover")
            signals.append("Strong volume")
            signals.append("Positive momentum")
            confidence = 0.8
            direction = .buy
            
            // Additional confirmation
            if currentRSI < 50 {
                signals.append("RSI not overbought")
                confidence += 0.1
            }
            
        // Bearish scalping setup
        } else if bearishCrossover && currentRSI > 30 && volumeRatio >= volumeMultiplier && isStrongMomentum && priceChange < 0 {
            signals.append("EMA bearish crossover")
            signals.append("Strong volume")
            signals.append("Negative momentum")
            confidence = 0.8
            direction = .sell
            
            // Additional confirmation
            if currentRSI > 50 {
                signals.append("RSI not oversold")
                confidence += 0.1
            }
        }
        
        // Quick momentum trades (no crossover required)
        else if isStrongMomentum && volumeRatio >= volumeMultiplier * 1.5 {
            if priceChange > 0.002 && currentRSI < 65 && currentCandle.close > currentFastEMA {
                signals.append("Strong bullish momentum")
                signals.append("High volume spike")
                confidence = 0.6
                direction = .buy
            } else if priceChange < -0.002 && currentRSI > 35 && currentCandle.close < currentFastEMA {
                signals.append("Strong bearish momentum")
                signals.append("High volume spike")
                confidence = 0.6
                direction = .sell
            }
        }
        
        // Risk management - avoid trades in choppy conditions
        let volatility = calculateVolatility(candles: Array(candles.suffix(20)))
        if volatility > 0.02 { // High volatility
            confidence *= 0.7
            signals.append("High volatility adjustment")
        }
        
        confidence = min(0.9, confidence)
        
        let reason = signals.isEmpty ? "No scalping opportunities" : signals.joined(separator: ", ")
        
        return StrategySignal(
            direction: direction,
            confidence: confidence,
            reason: reason,
            strategyName: name
        )
    }
    
    private func calculateEMA(candles: [Candle], period: Int) -> [Double] {
        guard candles.count >= period else { return [] }
        
        let multiplier = 2.0 / Double(period + 1)
        var ema: [Double] = []
        
        // First EMA is SMA
        let firstSMA = candles.prefix(period).map { $0.close }.reduce(0, +) / Double(period)
        ema.append(firstSMA)
        
        // Calculate subsequent EMAs
        for i in period..<candles.count {
            guard let lastEMA = ema.last else { continue }
            let newEMA = (candles[i].close * multiplier) + (lastEMA * (1 - multiplier))
            ema.append(newEMA)
        }
        
        return ema
    }
    
    private func calculateRSI(candles: [Candle], period: Int) -> [Double] {
        guard candles.count > period else { return [] }
        
        var gains: [Double] = []
        var losses: [Double] = []
        
        // Calculate price changes
        for i in 1..<candles.count {
            let change = candles[i].close - candles[i-1].close
            gains.append(max(change, 0))
            losses.append(max(-change, 0))
        }
        
        guard gains.count >= period else { return [] }
        
        var rsi: [Double] = []
        
        // Calculate first RSI
        let avgGain = gains.prefix(period).reduce(0, +) / Double(period)
        let avgLoss = losses.prefix(period).reduce(0, +) / Double(period)
        
        if avgLoss == 0 {
            rsi.append(100)
        } else {
            let rs = avgGain / avgLoss
            rsi.append(100 - (100 / (1 + rs)))
        }
        
        // Calculate subsequent RSI values using smoothed averages
        var smoothedGain = avgGain
        var smoothedLoss = avgLoss
        
        for i in period..<gains.count {
            smoothedGain = (smoothedGain * Double(period - 1) + gains[i]) / Double(period)
            smoothedLoss = (smoothedLoss * Double(period - 1) + losses[i]) / Double(period)
            
            if smoothedLoss == 0 {
                rsi.append(100)
            } else {
                let rs = smoothedGain / smoothedLoss
                rsi.append(100 - (100 / (1 + rs)))
            }
        }
        
        return rsi
    }
    
    private func calculateVolatility(candles: [Candle]) -> Double {
        guard candles.count > 1 else { return 0 }
        
        let returns = (1..<candles.count).map { i in
            (candles[i].close - candles[i-1].close) / candles[i-1].close
        }
        
        let mean = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - mean, 2) }.reduce(0, +) / Double(returns.count)
        
        return sqrt(variance)
    }
    
    public override func requiredCandles() -> Int {
        return max(slowEMAPeriod, rsiPeriod) + 20
    }
    
    public func updateParameter(key: String, value: Any) {
        switch key {
        case "fastEMAPeriod":
            if let intValue = value as? Int {
                fastEMAPeriod = max(3, min(15, intValue))
            }
        case "slowEMAPeriod":
            if let intValue = value as? Int {
                slowEMAPeriod = max(5, min(30, intValue))
            }
        case "rsiPeriod":
            if let intValue = value as? Int {
                rsiPeriod = max(5, min(20, intValue))
            }
        case "volumeMultiplier":
            if let doubleValue = value as? Double {
                volumeMultiplier = max(1.2, min(3.0, doubleValue))
            }
        case "minProfitTarget":
            if let doubleValue = value as? Double {
                minProfitTarget = max(0.001, min(0.01, doubleValue))
            }
        case "maxRiskPerTrade":
            if let doubleValue = value as? Double {
                maxRiskPerTrade = max(0.001, min(0.005, doubleValue))
            }
        default:
            break
        }
    }
}