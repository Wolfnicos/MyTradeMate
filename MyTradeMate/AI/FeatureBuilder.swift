import Foundation

enum FeatureError: Error, CustomStringConvertible {
    case notEnoughCandles(required: Int, have: Int)
    case nanInFeatures
    case invalidInput(String)
    
    var description: String {
        switch self {
        case .notEnoughCandles(let r, let h): 
            return "not enough candles (need \(r), have \(h))"
        case .nanInFeatures: 
            return "NaN in features after normalization"
        case .invalidInput(let msg):
            return "invalid input: \(msg)"
        }
    }
}

struct FeatureBuilder {
    /// Construiește exact 10 trăsături deterministe din ultimile N lumânări.
    static func vector10(from candles: [Candle]) throws -> [Float] {
        let need = 50
        guard candles.count >= need else { 
            throw FeatureError.notEnoughCandles(required: need, have: candles.count) 
        }
        
        guard let lastCandle = candles.last else {
            throw FeatureError.invalidInput("no candles provided")
        }

        // Extract price and volume series
        let closes = candles.map(\.close)
        let highs = candles.map(\.high)
        let lows = candles.map(\.low)
        let opens = candles.map(\.open)
        let volumes = candles.map(\.volume)
        
        // Feature 0: Close price percentage change (1 period)
        let pctChange1 = pctChange(closes, periods: 1)
        
        // Feature 1: Close price percentage change (5 periods)
        let pctChange5 = pctChange(closes, periods: 5)
        
        // Feature 2: Close price percentage change (10 periods)
        let pctChange10 = pctChange(closes, periods: 10)
        
        // Feature 3: RSI(14)
        let rsi14 = rsi(closes, periods: 14)
        
        // Feature 4: RSI(28)
        let rsi28 = rsi(closes, periods: 28)
        
        // Feature 5: EMA(9) slope
        let ema9Values = ema(closes, periods: 9)
        let slope9 = slope(ema9Values, window: 3) / Float(lastCandle.close)
        
        // Feature 6: EMA(21) slope
        let ema21Values = ema(closes, periods: 21)
        let slope21 = slope(ema21Values, window: 3) / Float(lastCandle.close)
        
        // Feature 7: ATR(14) normalized
        let atr14 = atr(highs: highs, lows: lows, closes: closes, periods: 14)
        let atrNorm = Float(atr14 / lastCandle.close)
        
        // Feature 8: Volume Z-Score(20)
        let volumeZScore = zscore(volumes.map(Float.init), lookback: 20)
        
        // Feature 9: Candle body ratio to ATR
        let bodySize = abs(lastCandle.close - lastCandle.open)
        let bodyATRRatio = Float(bodySize / max(atr14, 1e-8))
        
        let features: [Float] = [
            pctChange1, pctChange5, pctChange10,
            rsi14, rsi28,
            slope9, slope21,
            atrNorm,
            volumeZScore,
            bodyATRRatio
        ]

        // Validate no NaN or infinite values
        if features.contains(where: { $0.isNaN || !$0.isFinite }) { 
            throw FeatureError.nanInFeatures 
        }
        
        return features
    }
    
    // MARK: - Technical Indicators
    
    private static func pctChange(_ prices: [Double], periods: Int) -> Float {
        guard prices.count > periods else { return 0 }
        let current = prices[prices.count - 1]
        let previous = prices[prices.count - 1 - periods]
        guard previous != 0 else { return 0 }
        return Float((current / previous) - 1.0)
    }
    
    private static func rsi(_ prices: [Double], periods: Int) -> Float {
        guard prices.count > periods else { return 50 }
        
        var gains = 0.0
        var losses = 0.0
        
        for i in 1...periods {
            let change = prices[prices.count - i] - prices[prices.count - i - 1]
            if change >= 0 {
                gains += change
            } else {
                losses -= change
            }
        }
        
        let avgGain = gains / Double(periods)
        let avgLoss = losses / Double(periods)
        
        guard avgLoss > 0 else { return 100 }
        let rs = avgGain / avgLoss
        return Float(100.0 - 100.0 / (1.0 + rs))
    }
    
    private static func ema(_ prices: [Double], periods: Int) -> [Double] {
        guard !prices.isEmpty else { return [] }
        
        var result: [Double] = []
        let multiplier = 2.0 / (Double(periods) + 1.0)
        var ema = prices[0]
        
        for price in prices {
            ema = price * multiplier + ema * (1.0 - multiplier)
            result.append(ema)
        }
        
        return result
    }
    
    private static func slope(_ values: [Double], window: Int) -> Float {
        guard values.count >= window else { return 0 }
        let recent = Array(values.suffix(window))
        guard let first = recent.first, let last = recent.last else { return 0 }
        return Float(last - first)
    }
    
    private static func atr(highs: [Double], lows: [Double], closes: [Double], periods: Int) -> Double {
        guard highs.count == lows.count && lows.count == closes.count,
              highs.count > periods else { return 0 }
        
        var trueRanges: [Double] = []
        
        for i in 1..<highs.count {
            let high = highs[i]
            let low = lows[i]
            let prevClose = closes[i - 1]
            
            let tr = max(high - low, max(abs(high - prevClose), abs(low - prevClose)))
            trueRanges.append(tr)
        }
        
        guard trueRanges.count >= periods else { return 0 }
        let recentTR = Array(trueRanges.suffix(periods))
        return recentTR.reduce(0, +) / Double(periods)
    }
    
    static func zscore(_ values: [Float], lookback: Int) -> Float {
        guard values.count >= lookback else { return 0 }
        let recent = Array(values.suffix(lookback))
        guard let mean = recent.average, let std = recent.std, std > 0 else { return 0 }
        guard let last = recent.last else { return 0 }
        return (last - mean) / std
    }
}

// MARK: - Array Extensions

private extension Collection where Element == Float {
    var average: Float? { 
        isEmpty ? nil : reduce(0, +) / Float(count) 
    }
    
    var std: Float? {
        guard let mean = average else { return nil }
        let variance = map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Float(count)
        return sqrt(variance)
    }
}