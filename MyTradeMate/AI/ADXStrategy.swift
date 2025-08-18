import Foundation

/// Average Directional Index (ADX) strategy implementation
public final class ADXStrategy: BaseStrategy {
    public var period: Int = 14
    public var trendThreshold: Double = 25.0
    public var strongTrendThreshold: Double = 40.0
    
    public init() {
        super.init(
            name: "ADX Trend",
            description: "Measures trend strength using Average Directional Index"
        )
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= requiredCandles() else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for ADX",
                strategyName: name
            )
        }
        
        let adxData = calculateADX(candles: candles)
        guard let currentADX = adxData.adx.last,
              let currentDIPlus = adxData.diPlus.last,
              let currentDIMinus = adxData.diMinus.last else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Unable to calculate ADX values",
                strategyName: name
            )
        }
        
        let previousDIPlus = adxData.diPlus.count > 1 ? adxData.diPlus[adxData.diPlus.count - 2] : currentDIPlus
        let previousDIMinus = adxData.diMinus.count > 1 ? adxData.diMinus[adxData.diMinus.count - 2] : currentDIMinus
        
        // Check for trend strength
        if currentADX < trendThreshold {
            return StrategySignal(
                direction: .hold,
                confidence: 0.2,
                reason: "ADX indicates weak trend (\(String(format: "%.1f", currentADX)))",
                strategyName: name
            )
        }
        
        // Strong trend with DI crossover
        if currentDIPlus > currentDIMinus && previousDIPlus <= previousDIMinus && currentADX > trendThreshold {
            let confidence = min(0.9, 0.5 + (0.4 * (currentADX - trendThreshold) / (strongTrendThreshold - trendThreshold)))
            return StrategySignal(
                direction: .buy,
                confidence: confidence,
                reason: "ADX bullish crossover with strong trend (\(String(format: "%.1f", currentADX)))",
                strategyName: name
            )
        } else if currentDIMinus > currentDIPlus && previousDIMinus <= previousDIPlus && currentADX > trendThreshold {
            let confidence = min(0.9, 0.5 + (0.4 * (currentADX - trendThreshold) / (strongTrendThreshold - trendThreshold)))
            return StrategySignal(
                direction: .sell,
                confidence: confidence,
                reason: "ADX bearish crossover with strong trend (\(String(format: "%.1f", currentADX)))",
                strategyName: name
            )
        }
        
        // Existing trend continuation
        if currentADX > strongTrendThreshold {
            if currentDIPlus > currentDIMinus {
                return StrategySignal(
                    direction: .buy,
                    confidence: 0.6,
                    reason: "ADX indicates strong uptrend (\(String(format: "%.1f", currentADX)))",
                    strategyName: name
                )
            } else {
                return StrategySignal(
                    direction: .sell,
                    confidence: 0.6,
                    reason: "ADX indicates strong downtrend (\(String(format: "%.1f", currentADX)))",
                    strategyName: name
                )
            }
        }
        
        return StrategySignal(
            direction: .hold,
            confidence: 0.3,
            reason: "ADX indicates moderate trend (\(String(format: "%.1f", currentADX)))",
            strategyName: name
        )
    }
    
    private func calculateADX(candles: [Candle]) -> (adx: [Double], diPlus: [Double], diMinus: [Double]) {
        var trueRanges: [Double] = []
        var plusDMs: [Double] = []
        var minusDMs: [Double] = []
        
        // Calculate True Range and Directional Movements
        for i in 1..<candles.count {
            let current = candles[i]
            let previous = candles[i-1]
            
            let tr1 = current.high - current.low
            let tr2 = abs(current.high - previous.close)
            let tr3 = abs(current.low - previous.close)
            let trueRange = max(tr1, max(tr2, tr3))
            trueRanges.append(trueRange)
            
            let upMove = current.high - previous.high
            let downMove = previous.low - current.low
            
            let plusDM = (upMove > downMove && upMove > 0) ? upMove : 0
            let minusDM = (downMove > upMove && downMove > 0) ? downMove : 0
            
            plusDMs.append(plusDM)
            minusDMs.append(minusDM)
        }
        
        guard trueRanges.count >= period else {
            return ([], [], [])
        }
        
        // Calculate smoothed values
        var smoothedTRs: [Double] = []
        var smoothedPlusDMs: [Double] = []
        var smoothedMinusDMs: [Double] = []
        
        // First smoothed value is simple average
        let firstTR = trueRanges.prefix(period).reduce(0, +)
        let firstPlusDM = plusDMs.prefix(period).reduce(0, +)
        let firstMinusDM = minusDMs.prefix(period).reduce(0, +)
        
        smoothedTRs.append(firstTR)
        smoothedPlusDMs.append(firstPlusDM)
        smoothedMinusDMs.append(firstMinusDM)
        
        // Subsequent values use Wilder's smoothing
        for i in period..<trueRanges.count {
            let smoothedTR = smoothedTRs.last! - (smoothedTRs.last! / Double(period)) + trueRanges[i]
            let smoothedPlusDM = smoothedPlusDMs.last! - (smoothedPlusDMs.last! / Double(period)) + plusDMs[i]
            let smoothedMinusDM = smoothedMinusDMs.last! - (smoothedMinusDMs.last! / Double(period)) + minusDMs[i]
            
            smoothedTRs.append(smoothedTR)
            smoothedPlusDMs.append(smoothedPlusDM)
            smoothedMinusDMs.append(smoothedMinusDM)
        }
        
        // Calculate DI+ and DI-
        var diPlus: [Double] = []
        var diMinus: [Double] = []
        
        for i in 0..<smoothedTRs.count {
            let diPlusValue = (smoothedPlusDMs[i] / smoothedTRs[i]) * 100
            let diMinusValue = (smoothedMinusDMs[i] / smoothedTRs[i]) * 100
            
            diPlus.append(diPlusValue)
            diMinus.append(diMinusValue)
        }
        
        // Calculate DX and ADX
        var dx: [Double] = []
        for i in 0..<diPlus.count {
            let dxValue = abs(diPlus[i] - diMinus[i]) / (diPlus[i] + diMinus[i]) * 100
            dx.append(dxValue.isNaN ? 0 : dxValue)
        }
        
        guard dx.count >= period else {
            return ([], diPlus, diMinus)
        }
        
        var adx: [Double] = []
        
        // First ADX value is simple average of DX
        let firstADX = dx.prefix(period).reduce(0, +) / Double(period)
        adx.append(firstADX)
        
        // Subsequent ADX values use Wilder's smoothing
        for i in period..<dx.count {
            let adxValue = (adx.last! * Double(period - 1) + dx[i]) / Double(period)
            adx.append(adxValue)
        }
        
        return (adx, diPlus, diMinus)
    }
    
    public override func requiredCandles() -> Int {
        return period * 3 + 10
    }
    
    public func updateParameter(key: String, value: Any) {
        switch key {
        case "period":
            if let intValue = value as? Int {
                period = max(5, min(50, intValue))
            }
        case "trendThreshold":
            if let doubleValue = value as? Double {
                trendThreshold = max(15, min(35, doubleValue))
            }
        case "strongTrendThreshold":
            if let doubleValue = value as? Double {
                strongTrendThreshold = max(30, min(60, doubleValue))
            }
        default:
            break
        }
    }
}