import Foundation
import CoreML
import os.log

final class FeatureBuilder {
    private static let logger = Logger(subsystem: "com.mytrade.mate", category: "FeatureBuilder")
    
    // MARK: - Static Feature Building
    static func vector10(from candles: [Candle]) throws -> MLMultiArray {
        let builder = FeatureBuilder()
        return try builder.buildFeatures(from: candles)
    }
    
    // MARK: - Constants
    private enum Constants {
        static let featureCount = 10
        static let lookbackPeriods = [5, 10, 20, 50, 100]  // For technical indicators
        static let priceScalingFactor = 10000.0  // For BTC prices
    }
    
    private let settings: AppSettings
    
    init(settings: AppSettings = .shared) {
        self.settings = settings
    }
    
    // MARK: - Feature Building
    func buildFeatures(from candles: [Candle]) throws -> MLMultiArray {
        guard candles.count >= Constants.lookbackPeriods.max() ?? 0 else {
            throw AIModelError.invalidFeatureCount
        }
        
        let features = try MLMultiArray(shape: [1, Constants.featureCount as NSNumber], 
                                      dataType: .double)
        
        // 1. Price momentum (close/close_prev - 1)
        features[0] = calculateMomentum(candles: candles, period: 1)
        
        // 2. Price volatility (std dev of returns)
        features[1] = calculateVolatility(candles: candles, period: 20)
        
        // 3-5. Moving averages crossovers
        features[2] = calculateMACrossover(candles: candles, fast: 5, slow: 20)
        features[3] = calculateMACrossover(candles: candles, fast: 10, slow: 50)
        features[4] = calculateMACrossover(candles: candles, fast: 20, slow: 100)
        
        // 6-7. RSI indicators
        features[5] = calculateRSI(candles: candles, period: 14)
        features[6] = calculateRSI(candles: candles, period: 28)
        
        // 8. Volume trend
        features[7] = calculateVolumeTrend(candles: candles)
        
        // 9. Price range position
        features[8] = calculatePriceRangePosition(candles: candles)
        
        // 10. Trend strength
        features[9] = calculateTrendStrength(candles: candles)
        
        if settings.shouldLogVerbose {
            Self.logger.debug("""
                Built features vector:
                1. Momentum: \(features[0])
                2. Volatility: \(features[1])
                3. MA Cross 5/20: \(features[2])
                4. MA Cross 10/50: \(features[3])
                5. MA Cross 20/100: \(features[4])
                6. RSI-14: \(features[5])
                7. RSI-28: \(features[6])
                8. Volume Trend: \(features[7])
                9. Price Range: \(features[8])
                10. Trend Strength: \(features[9])
                """)
        }
        
        return features
    }
    
    // MARK: - Feature Calculations
    private func calculateMomentum(candles: [Candle], period: Int) -> Double {
        guard candles.count > period else { return 0 }
        let current = candles.last!.close
        let previous = candles[candles.count - 1 - period].close
        return (current - previous) / previous
    }
    
    private func calculateVolatility(candles: [Candle], period: Int) -> Double {
        let returns = candles.suffix(period).windows(ofCount: 2).map { window in
            let prices = Array(window)
            return (prices[1].close - prices[0].close) / prices[0].close
        }
        return returns.standardDeviation()
    }
    
    private func calculateMACrossover(candles: [Candle], fast: Int, slow: Int) -> Double {
        let fastMA = candles.suffix(fast).map { $0.close }.average()
        let slowMA = candles.suffix(slow).map { $0.close }.average()
        return (fastMA - slowMA) / slowMA
    }
    
    private func calculateRSI(candles: [Candle], period: Int) -> Double {
        let changes = candles.suffix(period + 1).windows(ofCount: 2).map { window in
            let prices = Array(window)
            return prices[1].close - prices[0].close
        }
        
        let gains = changes.filter { $0 > 0 }.average()
        let losses = abs(changes.filter { $0 < 0 }.average())
        
        guard losses != 0 else { return 100 }
        let rs = gains / losses
        return 100 - (100 / (1 + rs))
    }
    
    private func calculateVolumeTrend(candles: [Candle]) -> Double {
        let shortPeriod = 5
        let longPeriod = 20
        
        let shortVol = candles.suffix(shortPeriod).map { $0.volume }.average()
        let longVol = candles.suffix(longPeriod).map { $0.volume }.average()
        
        return (shortVol - longVol) / longVol
    }
    
    private func calculatePriceRangePosition(candles: [Candle]) -> Double {
        let period = 50
        let recentCandles = Array(candles.suffix(period))
        let high = recentCandles.map { $0.high }.max() ?? 0
        let low = recentCandles.map { $0.low }.min() ?? 0
        let current = candles.last?.close ?? 0
        
        guard high != low else { return 0.5 }
        return (current - low) / (high - low)
    }
    
    private func calculateTrendStrength(candles: [Candle]) -> Double {
        let period = 20
        let prices = candles.suffix(period).map { $0.close }
        let x = Array(0..<period).map(Double.init)
        
        // Linear regression slope
        let slope = linearRegressionSlope(y: prices, x: x)
        let averagePrice = prices.average()
        
        return slope / averagePrice  // Normalized slope
    }
}

// MARK: - Array Extensions
extension Array where Element: BinaryFloatingPoint {
    func average() -> Element {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Element(count)
    }
    
    func standardDeviation() -> Element {
        guard count > 1 else { return 0 }
        let avg = average()
        let variance = map { pow($0 - avg, 2) }.average()
        return sqrt(variance)
    }
}

extension Array {
    func windows(ofCount count: Int) -> [ArraySlice<Element>] {
        guard count > 0, self.count >= count else { return [] }
        return (0...self.count - count).map {
            self[$0..<$0 + count]
        }
    }
}

// MARK: - Helper Functions
func linearRegressionSlope(y: [Double], x: [Double]) -> Double {
    guard y.count == x.count, y.count > 1 else { return 0 }
    
    let n = Double(y.count)
    let sumX = x.reduce(0, +)
    let sumY = y.reduce(0, +)
    let sumXY = zip(x, y).map(*).reduce(0, +)
    let sumX2 = x.map { $0 * $0 }.reduce(0, +)
    
    return (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
}