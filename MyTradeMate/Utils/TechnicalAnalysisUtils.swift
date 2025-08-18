import Foundation

/// Utility functions for technical analysis calculations
public struct TechnicalAnalysisUtils {
    
    // MARK: - Moving Averages
    
    /// Calculate Simple Moving Average
    public static func calculateSMA(values: [Double], period: Int) -> [Double] {
        guard values.count >= period else { return [] }
        
        var sma: [Double] = []
        
        for i in (period - 1)..<values.count {
            let sum = values[(i - period + 1)...i].reduce(0, +)
            sma.append(sum / Double(period))
        }
        
        return sma
    }
    
    /// Calculate Exponential Moving Average
    public static func calculateEMA(values: [Double], period: Int) -> [Double] {
        guard values.count >= period else { return [] }
        
        let multiplier = 2.0 / Double(period + 1)
        var ema: [Double] = []
        
        // First EMA is SMA
        let firstSMA = values.prefix(period).reduce(0, +) / Double(period)
        ema.append(firstSMA)
        
        // Calculate subsequent EMAs
        for i in period..<values.count {
            let newEMA = (values[i] * multiplier) + (ema.last! * (1 - multiplier))
            ema.append(newEMA)
        }
        
        return ema
    }
    
    /// Calculate Weighted Moving Average
    public static func calculateWMA(values: [Double], period: Int) -> [Double] {
        guard values.count >= period else { return [] }
        
        var wma: [Double] = []
        let weightSum = Double(period * (period + 1) / 2)
        
        for i in (period - 1)..<values.count {
            var weightedSum: Double = 0
            
            for j in 0..<period {
                let weight = Double(j + 1)
                weightedSum += values[i - period + 1 + j] * weight
            }
            
            wma.append(weightedSum / weightSum)
        }
        
        return wma
    }
    
    // MARK: - Oscillators
    
    /// Calculate RSI (Relative Strength Index)
    public static func calculateRSI(candles: [Candle], period: Int) -> [Double] {
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
        var avgGain = gains.prefix(period).reduce(0, +) / Double(period)
        var avgLoss = losses.prefix(period).reduce(0, +) / Double(period)
        
        // Calculate first RSI
        if avgLoss == 0 {
            rsi.append(100)
        } else {
            let rs = avgGain / avgLoss
            rsi.append(100 - (100 / (1 + rs)))
        }
        
        // Calculate subsequent RSI values using Wilder's smoothing
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
    
    /// Calculate Stochastic Oscillator
    public static func calculateStochastic(candles: [Candle], kPeriod: Int, dPeriod: Int) -> (k: [Double], d: [Double]) {
        guard candles.count >= kPeriod + dPeriod else { return ([], []) }
        
        var kValues: [Double] = []
        
        // Calculate %K values
        for i in (kPeriod - 1)..<candles.count {
            let periodCandles = Array(candles[(i - kPeriod + 1)...i])
            let highestHigh = periodCandles.map { $0.high }.max() ?? 0
            let lowestLow = periodCandles.map { $0.low }.min() ?? 0
            let currentClose = candles[i].close
            
            let kValue = ((currentClose - lowestLow) / (highestHigh - lowestLow)) * 100
            kValues.append(kValue.isNaN ? 50 : kValue)
        }
        
        // Calculate %D (moving average of %K)
        let dValues = calculateSMA(values: kValues, period: dPeriod)
        
        return (kValues, dValues)
    }
    
    /// Calculate Williams %R
    public static func calculateWilliamsR(candles: [Candle], period: Int) -> [Double] {
        guard candles.count >= period else { return [] }
        
        var williamsR: [Double] = []
        
        for i in (period - 1)..<candles.count {
            let periodCandles = Array(candles[(i - period + 1)...i])
            let highestHigh = periodCandles.map { $0.high }.max() ?? 0
            let lowestLow = periodCandles.map { $0.low }.min() ?? 0
            let currentClose = candles[i].close
            
            let wr = ((highestHigh - currentClose) / (highestHigh - lowestLow)) * -100
            williamsR.append(wr.isNaN ? -50 : wr)
        }
        
        return williamsR
    }
    
    // MARK: - Trend Indicators
    
    /// Calculate MACD (Moving Average Convergence Divergence)
    public static func calculateMACD(candles: [Candle], fastPeriod: Int, slowPeriod: Int, signalPeriod: Int) -> (macd: [Double], signal: [Double], histogram: [Double]) {
        let closes = candles.map { $0.close }
        let fastEMA = calculateEMA(values: closes, period: fastPeriod)
        let slowEMA = calculateEMA(values: closes, period: slowPeriod)
        
        guard fastEMA.count == slowEMA.count && !fastEMA.isEmpty else {
            return ([], [], [])
        }
        
        let macd = zip(fastEMA, slowEMA).map { $0 - $1 }
        let signal = calculateEMA(values: macd, period: signalPeriod)
        
        let histogram = zip(macd.suffix(signal.count), signal).map { $0 - $1 }
        
        return (macd, signal, histogram)
    }
    
    /// Calculate Average True Range (ATR)
    public static func calculateATR(candles: [Candle], period: Int) -> [Double] {
        guard candles.count > 1 else { return [] }
        
        var trueRanges: [Double] = []
        
        // Calculate True Range for each candle
        for i in 1..<candles.count {
            let current = candles[i]
            let previous = candles[i-1]
            
            let tr1 = current.high - current.low
            let tr2 = abs(current.high - previous.close)
            let tr3 = abs(current.low - previous.close)
            
            trueRanges.append(max(tr1, max(tr2, tr3)))
        }
        
        // Calculate ATR using Wilder's smoothing
        guard trueRanges.count >= period else { return [] }
        
        var atr: [Double] = []
        
        // First ATR is simple average
        let firstATR = trueRanges.prefix(period).reduce(0, +) / Double(period)
        atr.append(firstATR)
        
        // Subsequent ATR values use Wilder's smoothing
        for i in period..<trueRanges.count {
            let newATR = (atr.last! * Double(period - 1) + trueRanges[i]) / Double(period)
            atr.append(newATR)
        }
        
        return atr
    }
    
    // MARK: - Volume Indicators
    
    /// Calculate On-Balance Volume (OBV)
    public static func calculateOBV(candles: [Candle]) -> [Double] {
        guard candles.count > 1 else { return [] }
        
        var obv: [Double] = [0] // Start with 0
        
        for i in 1..<candles.count {
            let current = candles[i]
            let previous = candles[i-1]
            let lastOBV = obv.last!
            
            if current.close > previous.close {
                obv.append(lastOBV + current.volume)
            } else if current.close < previous.close {
                obv.append(lastOBV - current.volume)
            } else {
                obv.append(lastOBV)
            }
        }
        
        return obv
    }
    
    /// Calculate Volume Weighted Average Price (VWAP)
    public static func calculateVWAP(candles: [Candle]) -> [Double] {
        guard !candles.isEmpty else { return [] }
        
        var vwap: [Double] = []
        var cumulativeVolumePrice: Double = 0
        var cumulativeVolume: Double = 0
        
        for candle in candles {
            let typicalPrice = (candle.high + candle.low + candle.close) / 3
            cumulativeVolumePrice += typicalPrice * candle.volume
            cumulativeVolume += candle.volume
            
            if cumulativeVolume > 0 {
                vwap.append(cumulativeVolumePrice / cumulativeVolume)
            } else {
                vwap.append(typicalPrice)
            }
        }
        
        return vwap
    }
    
    // MARK: - Support and Resistance
    
    /// Find pivot points (potential support and resistance levels)
    public static func findPivotPoints(candles: [Candle], lookback: Int = 5) -> (supports: [Double], resistances: [Double]) {
        guard candles.count >= lookback * 2 + 1 else { return ([], []) }
        
        var supports: [Double] = []
        var resistances: [Double] = []
        
        for i in lookback..<(candles.count - lookback) {
            let currentLow = candles[i].low
            let currentHigh = candles[i].high
            
            // Check for support (local minimum)
            var isSupport = true
            for j in (i - lookback)..<(i + lookback + 1) {
                if j != i && candles[j].low <= currentLow {
                    isSupport = false
                    break
                }
            }
            
            if isSupport {
                supports.append(currentLow)
            }
            
            // Check for resistance (local maximum)
            var isResistance = true
            for j in (i - lookback)..<(i + lookback + 1) {
                if j != i && candles[j].high >= currentHigh {
                    isResistance = false
                    break
                }
            }
            
            if isResistance {
                resistances.append(currentHigh)
            }
        }
        
        return (supports, resistances)
    }
    
    // MARK: - Pattern Recognition
    
    /// Detect candlestick patterns
    public static func detectCandlestickPatterns(candles: [Candle]) -> [CandlestickPattern] {
        guard candles.count >= 3 else { return [] }
        
        var patterns: [CandlestickPattern] = []
        
        for i in 2..<candles.count {
            let current = candles[i]
            let previous = candles[i-1]
            let beforePrevious = candles[i-2]
            
            // Doji pattern
            if isDoji(candle: current) {
                patterns.append(CandlestickPattern(type: .doji, index: i, strength: 0.6))
            }
            
            // Hammer pattern
            if isHammer(candle: current) {
                patterns.append(CandlestickPattern(type: .hammer, index: i, strength: 0.7))
            }
            
            // Shooting star pattern
            if isShootingStar(candle: current) {
                patterns.append(CandlestickPattern(type: .shootingStar, index: i, strength: 0.7))
            }
            
            // Engulfing patterns
            if isBullishEngulfing(current: current, previous: previous) {
                patterns.append(CandlestickPattern(type: .bullishEngulfing, index: i, strength: 0.8))
            }
            
            if isBearishEngulfing(current: current, previous: previous) {
                patterns.append(CandlestickPattern(type: .bearishEngulfing, index: i, strength: 0.8))
            }
        }
        
        return patterns
    }
    
    // MARK: - Private Helper Methods
    
    private static func isDoji(candle: Candle) -> Bool {
        let bodySize = abs(candle.close - candle.open)
        let totalRange = candle.high - candle.low
        return totalRange > 0 && (bodySize / totalRange) < 0.1
    }
    
    private static func isHammer(candle: Candle) -> Bool {
        let bodySize = abs(candle.close - candle.open)
        let lowerShadow = min(candle.open, candle.close) - candle.low
        let upperShadow = candle.high - max(candle.open, candle.close)
        
        return lowerShadow > bodySize * 2 && upperShadow < bodySize * 0.5
    }
    
    private static func isShootingStar(candle: Candle) -> Bool {
        let bodySize = abs(candle.close - candle.open)
        let lowerShadow = min(candle.open, candle.close) - candle.low
        let upperShadow = candle.high - max(candle.open, candle.close)
        
        return upperShadow > bodySize * 2 && lowerShadow < bodySize * 0.5
    }
    
    private static func isBullishEngulfing(current: Candle, previous: Candle) -> Bool {
        return previous.close < previous.open && // Previous is bearish
               current.close > current.open && // Current is bullish
               current.open < previous.close && // Current opens below previous close
               current.close > previous.open    // Current closes above previous open
    }
    
    private static func isBearishEngulfing(current: Candle, previous: Candle) -> Bool {
        return previous.close > previous.open && // Previous is bullish
               current.close < current.open && // Current is bearish
               current.open > previous.close && // Current opens above previous close
               current.close < previous.open    // Current closes below previous open
    }
}

// MARK: - Supporting Types

public struct CandlestickPattern {
    public enum PatternType {
        case doji
        case hammer
        case shootingStar
        case bullishEngulfing
        case bearishEngulfing
    }
    
    public let type: PatternType
    public let index: Int
    public let strength: Double // 0.0 to 1.0
}