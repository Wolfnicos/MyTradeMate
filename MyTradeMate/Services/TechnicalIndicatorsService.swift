import Foundation
import Accelerate

// MARK: - Technical Indicators Service

public final class TechnicalIndicatorsService {
    public static let shared = TechnicalIndicatorsService()
    
    private init() {}
    
    // MARK: - Moving Averages
    
    /// Simple Moving Average
    public func sma(prices: [Double], period: Int) -> [Double] {
        guard prices.count >= period else { return [] }
        
        var result: [Double] = []
        
        for i in (period - 1)..<prices.count {
            let slice = Array(prices[(i - period + 1)...i])
            let average = slice.reduce(0, +) / Double(period)
            result.append(average)
        }
        
        return result
    }
    
    /// Exponential Moving Average
    public func ema(prices: [Double], period: Int) -> [Double] {
        guard prices.count >= period else { return [] }
        
        let multiplier = 2.0 / (Double(period) + 1.0)
        var result: [Double] = []
        
        // First EMA is SMA
        let firstSMA = Array(prices[0..<period]).reduce(0, +) / Double(period)
        result.append(firstSMA)
        
        // Calculate subsequent EMAs
        for i in period..<prices.count {
            guard let lastResult = result.last else { continue }
            let ema = (prices[i] * multiplier) + (lastResult * (1 - multiplier))
            result.append(ema)
        }
        
        return result
    }
    
    /// Weighted Moving Average
    public func wma(prices: [Double], period: Int) -> [Double] {
        guard prices.count >= period else { return [] }
        
        var result: [Double] = []
        let weightSum = Double(period * (period + 1) / 2)
        
        for i in (period - 1)..<prices.count {
            var weightedSum = 0.0
            
            for j in 0..<period {
                let weight = Double(j + 1)
                weightedSum += prices[i - period + 1 + j] * weight
            }
            
            result.append(weightedSum / weightSum)
        }
        
        return result
    }
    
    // MARK: - Oscillators
    
    /// Relative Strength Index
    public func rsi(prices: [Double], period: Int = 14) -> [Double] {
        guard prices.count > period else { return [] }
        
        var gains: [Double] = []
        var losses: [Double] = []
        
        // Calculate price changes
        for i in 1..<prices.count {
            let change = prices[i] - prices[i - 1]
            gains.append(max(change, 0))
            losses.append(max(-change, 0))
        }
        
        var result: [Double] = []
        
        // Calculate initial average gain and loss
        let initialAvgGain = Array(gains[0..<period]).reduce(0, +) / Double(period)
        let initialAvgLoss = Array(losses[0..<period]).reduce(0, +) / Double(period)
        
        var avgGain = initialAvgGain
        var avgLoss = initialAvgLoss
        
        // Calculate first RSI
        let rs = avgGain / avgLoss
        result.append(100 - (100 / (1 + rs)))
        
        // Calculate subsequent RSI values using smoothed averages
        for i in period..<gains.count {
            avgGain = ((avgGain * Double(period - 1)) + gains[i]) / Double(period)
            avgLoss = ((avgLoss * Double(period - 1)) + losses[i]) / Double(period)
            
            let rs = avgLoss == 0 ? 100 : avgGain / avgLoss
            result.append(100 - (100 / (1 + rs)))
        }
        
        return result
    }
    
    /// Stochastic Oscillator
    public func stochastic(candles: [Candle], kPeriod: Int = 14, dPeriod: Int = 3) -> StochasticResult {
        guard candles.count >= kPeriod else { 
            return StochasticResult(k: [], d: [])
        }
        
        var kValues: [Double] = []
        
        // Calculate %K
        for i in (kPeriod - 1)..<candles.count {
            let slice = Array(candles[(i - kPeriod + 1)...i])
            let highestHigh = slice.map { $0.high }.max() ?? 0
            let lowestLow = slice.map { $0.low }.min() ?? 0
            let currentClose = candles[i].close
            
            let k = lowestLow == highestHigh ? 50.0 : 
                    ((currentClose - lowestLow) / (highestHigh - lowestLow)) * 100
            kValues.append(k)
        }
        
        // Calculate %D (SMA of %K)
        let dValues = sma(prices: kValues, period: dPeriod)
        
        return StochasticResult(k: kValues, d: dValues)
    }
    
    // MARK: - MACD
    
    /// Moving Average Convergence Divergence
    public func macd(prices: [Double], fastPeriod: Int = 12, slowPeriod: Int = 26, signalPeriod: Int = 9) -> MACDResult {
        let fastEMA = ema(prices: prices, period: fastPeriod)
        let slowEMA = ema(prices: prices, period: slowPeriod)
        
        guard fastEMA.count == slowEMA.count else {
            return MACDResult(macd: [], signal: [], histogram: [])
        }
        
        // Calculate MACD line
        var macdLine: [Double] = []
        let startIndex = slowPeriod - fastPeriod
        
        for i in 0..<slowEMA.count {
            let macdValue = fastEMA[i + startIndex] - slowEMA[i]
            macdLine.append(macdValue)
        }
        
        // Calculate Signal line (EMA of MACD)
        let signalLine = ema(prices: macdLine, period: signalPeriod)
        
        // Calculate Histogram
        var histogram: [Double] = []
        let histogramStartIndex = signalPeriod - 1
        
        for i in 0..<signalLine.count {
            let histValue = macdLine[i + histogramStartIndex] - signalLine[i]
            histogram.append(histValue)
        }
        
        return MACDResult(macd: macdLine, signal: signalLine, histogram: histogram)
    }
    
    // MARK: - Bollinger Bands
    
    /// Bollinger Bands
    public func bollingerBands(prices: [Double], period: Int = 20, standardDeviations: Double = 2.0) -> BollingerBandsResult {
        let smaValues = sma(prices: prices, period: period)
        var upperBand: [Double] = []
        var lowerBand: [Double] = []
        
        for i in 0..<smaValues.count {
            let startIndex = i
            let endIndex = min(i + period, prices.count)
            let slice = Array(prices[startIndex..<endIndex])
            
            // Calculate standard deviation
            guard !slice.isEmpty else { continue }
            let mean = smaValues[i]
            let variance = slice.map { pow($0 - mean, 2) }.reduce(0, +) / Double(slice.count)
            let stdDev = sqrt(variance)
            
            upperBand.append(mean + (standardDeviations * stdDev))
            lowerBand.append(mean - (standardDeviations * stdDev))
        }
        
        return BollingerBandsResult(
            upper: upperBand,
            middle: smaValues,
            lower: lowerBand
        )
    }
    
    // MARK: - Volume Indicators
    
    /// Volume Weighted Average Price
    public func vwap(candles: [Candle]) -> [Double] {
        guard !candles.isEmpty else { return [] }
        
        var result: [Double] = []
        var cumulativeVolumePrice = 0.0
        var cumulativeVolume = 0.0
        
        for candle in candles {
            let typicalPrice = (candle.high + candle.low + candle.close) / 3.0
            let volumePrice = typicalPrice * candle.volume
            
            cumulativeVolumePrice += volumePrice
            cumulativeVolume += candle.volume
            
            let vwap = cumulativeVolume == 0 ? typicalPrice : cumulativeVolumePrice / cumulativeVolume
            result.append(vwap)
        }
        
        return result
    }
    
    /// On-Balance Volume
    public func obv(candles: [Candle]) -> [Double] {
        guard candles.count > 1 else { return [] }
        
        var result: [Double] = [0] // Start with 0
        var currentOBV = 0.0
        
        for i in 1..<candles.count {
            let currentClose = candles[i].close
            let previousClose = candles[i - 1].close
            let volume = candles[i].volume
            
            if currentClose > previousClose {
                currentOBV += volume
            } else if currentClose < previousClose {
                currentOBV -= volume
            }
            // If prices are equal, OBV remains unchanged
            
            result.append(currentOBV)
        }
        
        return result
    }
    
    // MARK: - Volatility Indicators
    
    /// Average True Range
    public func atr(candles: [Candle], period: Int = 14) -> [Double] {
        guard candles.count > 1 else { return [] }
        
        var trueRanges: [Double] = []
        
        // Calculate True Range for each period
        for i in 1..<candles.count {
            let high = candles[i].high
            let low = candles[i].low
            let previousClose = candles[i - 1].close
            
            let tr1 = high - low
            let tr2 = abs(high - previousClose)
            let tr3 = abs(low - previousClose)
            
            let trueRange = max(tr1, max(tr2, tr3))
            trueRanges.append(trueRange)
        }
        
        // Calculate ATR using smoothed moving average
        return sma(prices: trueRanges, period: period)
    }
    
    /// Bollinger Band Width
    public func bollingerBandWidth(prices: [Double], period: Int = 20, standardDeviations: Double = 2.0) -> [Double] {
        let bb = bollingerBands(prices: prices, period: period, standardDeviations: standardDeviations)
        
        var result: [Double] = []
        for i in 0..<bb.upper.count {
            let width = (bb.upper[i] - bb.lower[i]) / bb.middle[i]
            result.append(width)
        }
        
        return result
    }
    
    // MARK: - Trend Indicators
    
    /// Average Directional Index (ADX)
    public func adx(candles: [Candle], period: Int = 14) -> ADXResult {
        guard candles.count > period else {
            return ADXResult(adx: [], plusDI: [], minusDI: [])
        }
        
        var plusDM: [Double] = []
        var minusDM: [Double] = []
        var trueRanges: [Double] = []
        
        // Calculate +DM, -DM, and TR
        for i in 1..<candles.count {
            let highDiff = candles[i].high - candles[i - 1].high
            let lowDiff = candles[i - 1].low - candles[i].low
            
            let plusDMValue = (highDiff > lowDiff && highDiff > 0) ? highDiff : 0
            let minusDMValue = (lowDiff > highDiff && lowDiff > 0) ? lowDiff : 0
            
            plusDM.append(plusDMValue)
            minusDM.append(minusDMValue)
            
            // True Range
            let high = candles[i].high
            let low = candles[i].low
            let previousClose = candles[i - 1].close
            
            let tr1 = high - low
            let tr2 = abs(high - previousClose)
            let tr3 = abs(low - previousClose)
            
            trueRanges.append(max(tr1, max(tr2, tr3)))
        }
        
        // Smooth the values
        let smoothedPlusDM = ema(prices: plusDM, period: period)
        let smoothedMinusDM = ema(prices: minusDM, period: period)
        let smoothedTR = ema(prices: trueRanges, period: period)
        
        // Calculate +DI and -DI
        var plusDI: [Double] = []
        var minusDI: [Double] = []
        var dx: [Double] = []
        
        for i in 0..<smoothedTR.count {
            let plusDIValue = smoothedTR[i] == 0 ? 0 : (smoothedPlusDM[i] / smoothedTR[i]) * 100
            let minusDIValue = smoothedTR[i] == 0 ? 0 : (smoothedMinusDM[i] / smoothedTR[i]) * 100
            
            plusDI.append(plusDIValue)
            minusDI.append(minusDIValue)
            
            // Calculate DX
            let diSum = plusDIValue + minusDIValue
            let dxValue = diSum == 0 ? 0 : (abs(plusDIValue - minusDIValue) / diSum) * 100
            dx.append(dxValue)
        }
        
        // Calculate ADX (smoothed DX)
        let adxValues = ema(prices: dx, period: period)
        
        return ADXResult(adx: adxValues, plusDI: plusDI, minusDI: minusDI)
    }
    
    // MARK: - Support and Resistance
    
    /// Pivot Points
    public func pivotPoints(candle: Candle) -> PivotPointsResult {
        let pivot = (candle.high + candle.low + candle.close) / 3.0
        
        let r1 = (2 * pivot) - candle.low
        let s1 = (2 * pivot) - candle.high
        
        let r2 = pivot + (candle.high - candle.low)
        let s2 = pivot - (candle.high - candle.low)
        
        let r3 = candle.high + 2 * (pivot - candle.low)
        let s3 = candle.low - 2 * (candle.high - pivot)
        
        return PivotPointsResult(
            pivot: pivot,
            r1: r1, r2: r2, r3: r3,
            s1: s1, s2: s2, s3: s3
        )
    }
    
    // MARK: - Pattern Recognition
    
    /// Detect Doji candlestick pattern
    public func isDoji(candle: Candle, threshold: Double = 0.1) -> Bool {
        let bodySize = abs(candle.close - candle.open)
        let totalRange = candle.high - candle.low
        
        return totalRange > 0 && (bodySize / totalRange) <= threshold
    }
    
    /// Detect Hammer candlestick pattern
    public func isHammer(candle: Candle) -> Bool {
        let bodySize = abs(candle.close - candle.open)
        let lowerShadow = min(candle.open, candle.close) - candle.low
        let upperShadow = candle.high - max(candle.open, candle.close)
        
        return lowerShadow >= (bodySize * 2) && upperShadow <= (bodySize * 0.5)
    }
    
    /// Detect Shooting Star candlestick pattern
    public func isShootingStar(candle: Candle) -> Bool {
        let bodySize = abs(candle.close - candle.open)
        let lowerShadow = min(candle.open, candle.close) - candle.low
        let upperShadow = candle.high - max(candle.open, candle.close)
        
        return upperShadow >= (bodySize * 2) && lowerShadow <= (bodySize * 0.5)
    }
    
    // MARK: - Utility Functions
    
    /// Calculate correlation between two price series
    public func correlation(series1: [Double], series2: [Double]) -> Double {
        guard series1.count == series2.count && !series1.isEmpty else { return 0 }
        
        let n = Double(series1.count)
        let sum1 = series1.reduce(0, +)
        let sum2 = series2.reduce(0, +)
        let sum1Sq = series1.map { $0 * $0 }.reduce(0, +)
        let sum2Sq = series2.map { $0 * $0 }.reduce(0, +)
        let sumProducts = zip(series1, series2).map { $0 * $1 }.reduce(0, +)
        
        let numerator = (n * sumProducts) - (sum1 * sum2)
        let denominator = sqrt(((n * sum1Sq) - (sum1 * sum1)) * ((n * sum2Sq) - (sum2 * sum2)))
        
        return denominator == 0 ? 0 : numerator / denominator
    }
    
    /// Calculate standard deviation
    public func standardDeviation(values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        
        return sqrt(variance)
    }
}

// MARK: - Result Types

public struct StochasticResult {
    public let k: [Double]
    public let d: [Double]
    
    public init(k: [Double], d: [Double]) {
        self.k = k
        self.d = d
    }
}

public struct MACDResult {
    public let macd: [Double]
    public let signal: [Double]
    public let histogram: [Double]
    
    public init(macd: [Double], signal: [Double], histogram: [Double]) {
        self.macd = macd
        self.signal = signal
        self.histogram = histogram
    }
}

public struct BollingerBandsResult {
    public let upper: [Double]
    public let middle: [Double]
    public let lower: [Double]
    
    public init(upper: [Double], middle: [Double], lower: [Double]) {
        self.upper = upper
        self.middle = middle
        self.lower = lower
    }
}

public struct ADXResult {
    public let adx: [Double]
    public let plusDI: [Double]
    public let minusDI: [Double]
    
    public init(adx: [Double], plusDI: [Double], minusDI: [Double]) {
        self.adx = adx
        self.plusDI = plusDI
        self.minusDI = minusDI
    }
}

public struct PivotPointsResult {
    public let pivot: Double
    public let r1: Double
    public let r2: Double
    public let r3: Double
    public let s1: Double
    public let s2: Double
    public let s3: Double
    
    public init(pivot: Double, r1: Double, r2: Double, r3: Double, s1: Double, s2: Double, s3: Double) {
        self.pivot = pivot
        self.r1 = r1
        self.r2 = r2
        self.r3 = r3
        self.s1 = s1
        self.s2 = s2
        self.s3 = s3
    }
}