import Foundation

public class RegimeDetector {
    public enum MarketRegime {
        case trending(direction: TrendDirection)
        case ranging
        case volatile
        
        public enum TrendDirection {
            case bullish
            case bearish
        }
    }
    
    private let atrPeriod: Int = 14
    private let trendPeriod: Int = 20
    private let volatilityThreshold: Double = 0.02 // 2% of price
    
    public init() {}
    
    public func detectRegime(candles: [Candle]) -> MarketRegime {
        guard candles.count >= max(atrPeriod, trendPeriod) else {
            return .ranging
        }
        
        // Calculate volatility using ATR
        let volatility = calculateVolatility(candles: candles)
        
        // Calculate trend strength
        let trendInfo = calculateTrend(candles: candles)
        
        // Determine regime based on volatility and trend
        if volatility > volatilityThreshold {
            return .volatile
        } else if abs(trendInfo.strength) > 0.5 {
            let direction: MarketRegime.TrendDirection = trendInfo.slope > 0 ? .bullish : .bearish
            return .trending(direction: direction)
        } else {
            return .ranging
        }
    }
    
    public func recommendStrategies(for regime: MarketRegime) -> [String] {
        switch regime {
        case .trending(let direction):
            switch direction {
            case .bullish:
                return ["EMA Crossover", "MACD", "ATR Breakout"]
            case .bearish:
                return ["EMA Crossover", "MACD", "RSI Swing"]
            }
        case .ranging:
            return ["Mean Reversion", "RSI Swing"]
        case .volatile:
            return ["ATR Breakout", "Mean Reversion"]
        }
    }
    
    private func calculateVolatility(candles: [Candle]) -> Double {
        guard candles.count >= atrPeriod else { return 0 }
        
        var trueRanges: [Double] = []
        
        for i in 1..<candles.count {
            let current = candles[i]
            let previous = candles[i-1]
            
            let tr1 = current.high - current.low
            let tr2 = abs(current.high - previous.close)
            let tr3 = abs(current.low - previous.close)
            
            let trueRange = max(tr1, tr2, tr3)
            trueRanges.append(trueRange)
        }
        
        let recentTRs = Array(trueRanges.suffix(atrPeriod))
        let atr = recentTRs.reduce(0, +) / Double(recentTRs.count)
        guard let currentPrice = candles.last?.close else { return 0 }
        
        return atr / currentPrice // Normalized volatility
    }
    
    private func calculateTrend(candles: [Candle]) -> (slope: Double, strength: Double) {
        let recentCandles = Array(candles.suffix(trendPeriod))
        let closes = recentCandles.map { $0.close }
        
        // Calculate linear regression
        let n = Double(closes.count)
        let indices = (0..<closes.count).map { Double($0) }
        
        let sumX = indices.reduce(0, +)
        let sumY = closes.reduce(0, +)
        let sumXY = zip(indices, closes).map { $0 * $1 }.reduce(0, +)
        let sumX2 = indices.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        
        // Calculate R-squared for trend strength
        let meanY = sumY / n
        let totalSS = closes.map { pow($0 - meanY, 2) }.reduce(0, +)
        
        var predictedY: [Double] = []
        for i in 0..<closes.count {
            predictedY.append(slope * Double(i) + (sumY - slope * sumX) / n)
        }
        
        let residualSS = zip(closes, predictedY).map { pow($0 - $1, 2) }.reduce(0, +)
        let rSquared = totalSS > 0 ? 1 - (residualSS / totalSS) : 0
        
        // Normalize slope relative to price
        let normalizedSlope = slope / (closes.last ?? 1)
        
        return (slope: normalizedSlope, strength: rSquared)
    }
}
