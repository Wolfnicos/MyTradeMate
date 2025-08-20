import Foundation
import CoreML
import os.log
import TabularData

// MARK: - Feature Error Types
enum FeatureError: Error {
    case notEnoughCandles
    case invalidInput(String)
}

final class FeatureBuilder {
    private static let logger = os.Logger(subsystem: "com.mytrade.mate", category: "FeatureBuilder")
    
    // MARK: - Static Feature Building
    @MainActor static func vector10(from candles: [Candle]) throws -> MLMultiArray {
        let builder = FeatureBuilder()
        let features = try builder.buildFeatures(from: candles)
        
        // Convert [Float] to MLMultiArray
        let array = try MLMultiArray(shape: [10], dataType: .float32)
        for (i, feature) in features.enumerated() {
            array[i] = NSNumber(value: feature)
        }
        return array
    }
    
    // MARK: - Constants
    private enum Constants {
        static let featureCount = 10
        static let lookbackPeriods = [5, 10, 20, 50, 100]  // For technical indicators
        static let priceScalingFactor = 10000.0  // For BTC prices
    }
    
    private let settings: AppSettings
    
    init(settings: AppSettings = AppSettings.shared) {
        self.settings = settings
    }
    
    // MARK: - Feature Building
    @MainActor func buildFeatures(from candles: [Candle]) throws -> [Float] {
        guard candles.count >= 50 else {
            throw FeatureError.notEnoughCandles
        }
        
        guard candles.last != nil else {
            throw FeatureError.invalidInput("no candles provided")
        }
        
        var features: [Float] = []
        
        // 1. Price momentum (close/close_prev - 1)
        features.append(calculateMomentum(candles: candles, period: 1))
        
        // 2. Price volatility (std dev of returns)
        features.append(calculateVolatility(candles: candles, period: 20))
        
        // 3-5. Moving averages crossovers
        features.append(calculateMACrossover(candles: candles, fast: 5, slow: 20))
        features.append(calculateMACrossover(candles: candles, fast: 10, slow: 50))
        features.append(calculateMACrossover(candles: candles, fast: 20, slow: 100))
        
        // 6-7. RSI indicators
        features.append(calculateRSI(candles: candles, period: 14))
        features.append(calculateRSI(candles: candles, period: 28))
        
        // 8. Volume trend
        features.append(calculateVolumeTrend(candles: candles))
        
        // 9. Price range position
        features.append(calculatePriceRangePosition(candles: candles))
        
        // 10. Trend strength
        features.append(calculateTrendStrength(candles: candles))
        
        if settings.verboseAILogs {
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
    private func calculateMomentum(candles: [Candle], period: Int) -> Float {
        guard candles.count > period,
              let current = safeLast(candles)?.close,
              let previous = safeIndex(candles, candles.count - 1 - period)?.close,
              previous != 0 else { return 0 }
        return Float((current - previous) / previous)
    }
    
    private func calculateVolatility(candles: [Candle], period: Int) -> Float {
        guard candles.count >= period else { return 0 }
        let returns = candles.suffix(period).windows(ofCount: 2).compactMap { window -> Double? in
            let prices = Array(window)
            guard prices.count == 2, prices[0].close != 0 else { return nil }
            return (prices[1].close - prices[0].close) / prices[0].close
        }
        return Float(returns.standardDeviation())
    }
    
    private func calculateMACrossover(candles: [Candle], fast: Int, slow: Int) -> Float {
        guard candles.count >= slow else { return 0 }
        let fastMA = candles.suffix(fast).map { $0.close }.average()
        let slowMA = candles.suffix(slow).map { $0.close }.average()
        guard slowMA != 0 else { return 0 }
        return Float((fastMA - slowMA) / slowMA)
    }
    
    private func calculateRSI(candles: [Candle], period: Int) -> Float {
        guard candles.count >= period + 1 else { return 50 }
        let changes = candles.suffix(period + 1).windows(ofCount: 2).compactMap { window -> Double? in
            let prices = Array(window)
            guard prices.count == 2 else { return nil }
            return prices[1].close - prices[0].close
        }
        
        let gains = changes.filter { $0 > 0 }
        let losses = changes.filter { $0 < 0 }.map { abs($0) }
        
        let avgGain = gains.isEmpty ? 0 : gains.average()
        let avgLoss = losses.isEmpty ? 0 : losses.average()
        
        guard avgLoss != 0 else { return 100 }
        let rs = avgGain / avgLoss
        return Float(100 - (100 / (1 + rs)))
    }
    
    private func calculateVolumeTrend(candles: [Candle]) -> Float {
        let shortPeriod = 5
        let longPeriod = 20
        
        guard candles.count >= longPeriod else { return 0 }
        
        let shortVol = candles.suffix(shortPeriod).map { $0.volume }.average()
        let longVol = candles.suffix(longPeriod).map { $0.volume }.average()
        
        guard longVol != 0 else { return 0 }
        return Float((shortVol - longVol) / longVol)
    }
    
    private func calculatePriceRangePosition(candles: [Candle]) -> Float {
        let period = 50
        guard candles.count >= period,
              let current = safeLast(candles)?.close else { return 0.5 }
        
        let recentCandles = Array(candles.suffix(period))
        let high = recentCandles.map { $0.high }.max() ?? current
        let low = recentCandles.map { $0.low }.min() ?? current
        
        guard high != low else { return 0.5 }
        return Float((current - low) / (high - low))
    }
    
    private func calculateTrendStrength(candles: [Candle]) -> Float {
        let period = 20
        guard candles.count >= period else { return 0 }
        
        let prices = candles.suffix(period).map { $0.close }
        let x = Array(0..<period).map(Double.init)
        
        // Linear regression slope
        let slope = linearRegressionSlope(y: prices, x: x)
        let averagePrice = prices.average()
        
        guard averagePrice != 0 else { return 0 }
        return Float(slope / averagePrice)  // Normalized slope
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
        let variance = map { ($0 - avg) * ($0 - avg) }.average()
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

// MARK: - Safe Access Helpers
private extension FeatureBuilder {
    func safeLast<T>(_ array: [T]) -> T? {
        return array.last
    }
    
    func safeIndex<T>(_ array: [T], _ index: Int) -> T? {
        guard index >= 0 && index < array.count else {
            return nil
        }
        return array[index]
    }
}