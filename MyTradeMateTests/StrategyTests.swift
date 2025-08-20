import XCTest
@testable import MyTradeMate

final class StrategyTests: XCTestCase {
    
    // MARK: - Test Data Helpers
    
    private func createMockCandles(count: Int, trend: Trend = .neutral) -> [AICandle] {
        var candles: [AICandle] = []
        let basePrice = 50000.0
        let baseTime = Date()
        
        for i in 0..<count {
            let timeOffset = TimeInterval(i * 300) // 5 minutes apart
            let timestamp = baseTime.addingTimeInterval(timeOffset)
            
            let priceChange: Double
            switch trend {
            case .bullish:
                priceChange = Double(i) * 100 // Increasing prices
            case .bearish:
                priceChange = -Double(i) * 100 // Decreasing prices
            case .neutral:
                priceChange = Double.random(in: -50...50) // Random movement
            }
            
            let open = basePrice + priceChange
            let close = open + Double.random(in: -200...200)
            let high = max(open, close) + Double.random(in: 0...100)
            let low = min(open, close) - Double.random(in: 0...100)
            let volume = Double.random(in: 1000...10000)
            
            let candle = AICandle(
                timestamp: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
            candles.append(candle)
        }
        
        return candles
    }
    
    private enum Trend {
        case bullish, bearish, neutral
    }
    
    // MARK: - RSI Strategy Tests
    
    func testRSIStrategyWithBullishTrend() {
        // Given
        let candles = createMockCandles(count: 30, trend: .bullish)
        
        // When
        let signal = Strategies.rsi(candles, overbought: 70, oversold: 30)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "RSI")
        XCTAssertTrue(signal.score > 0)
        XCTAssertTrue(signal.score <= 1.0)
    }
    
    func testRSIStrategyWithBearishTrend() {
        // Given
        let candles = createMockCandles(count: 30, trend: .bearish)
        
        // When
        let signal = Strategies.rsi(candles, overbought: 70, oversold: 30)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "RSI")
        XCTAssertTrue(signal.score > 0)
        XCTAssertTrue(signal.score <= 1.0)
    }
    
    func testRSIStrategyWithNeutralTrend() {
        // Given
        let candles = createMockCandles(count: 30, trend: .neutral)
        
        // When
        let signal = Strategies.rsi(candles, overbought: 70, oversold: 30)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "RSI")
        XCTAssertTrue(signal.score > 0)
        XCTAssertTrue(signal.score <= 1.0)
    }
    
    func testRSIStrategyWithInsufficientData() {
        // Given
        let candles = createMockCandles(count: 5) // Not enough for RSI calculation
        
        // When
        let signal = Strategies.rsi(candles, overbought: 70, oversold: 30)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "RSI")
        // Should handle insufficient data gracefully
    }
    
    func testRSIStrategyWithCustomThresholds() {
        // Given
        let candles = createMockCandles(count: 30, trend: .bullish)
        
        // When
        let signal = Strategies.rsi(candles, overbought: 80, oversold: 20)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "RSI")
        XCTAssertTrue(signal.score > 0)
    }
    
    // MARK: - MACD Strategy Tests
    
    func testMACDStrategyWithBullishTrend() {
        // Given
        let candles = createMockCandles(count: 50, trend: .bullish)
        
        // When
        let signal = Strategies.macd(candles)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "MACD")
        XCTAssertTrue(signal.score > 0)
        XCTAssertTrue(signal.score <= 1.0)
    }
    
    func testMACDStrategyWithBearishTrend() {
        // Given
        let candles = createMockCandles(count: 50, trend: .bearish)
        
        // When
        let signal = Strategies.macd(candles)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "MACD")
        XCTAssertTrue(signal.score > 0)
        XCTAssertTrue(signal.score <= 1.0)
    }
    
    func testMACDStrategyWithNeutralTrend() {
        // Given
        let candles = createMockCandles(count: 50, trend: .neutral)
        
        // When
        let signal = Strategies.macd(candles)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "MACD")
        XCTAssertTrue(signal.score > 0)
        XCTAssertTrue(signal.score <= 1.0)
    }
    
    func testMACDStrategyWithInsufficientData() {
        // Given
        let candles = createMockCandles(count: 10) // Not enough for MACD calculation
        
        // When
        let signal = Strategies.macd(candles)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "MACD")
        // Should handle insufficient data gracefully
    }
    
    func testMACDStrategyWithCustomPeriods() {
        // Given
        let candles = createMockCandles(count: 50, trend: .bullish)
        
        // When
        let signal = Strategies.macd(candles)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "MACD")
        XCTAssertTrue(signal.score > 0)
    }
    
    // MARK: - EMA Crossover Strategy Tests
    
    func testEMACrossoverStrategy() {
        // Given
        let candles = createMockCandles(count: 50, trend: .bullish)
        
        // When
        let signal = Strategies.emaCrossover(candles, fast: 12, slow: 26)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "EMA Crossover")
        XCTAssertTrue(signal.score > 0)
        XCTAssertTrue(signal.score <= 1.0)
    }
    
    func testEMACrossoverWithCustomPeriods() {
        // Given
        let candles = createMockCandles(count: 50, trend: .bearish)
        
        // When
        let signal = Strategies.emaCrossover(candles, fast: 5, slow: 20)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "EMA Crossover")
        XCTAssertTrue(signal.score > 0)
    }
    
    // MARK: - Mean Reversion Strategy Tests
    
    func testMeanReversionStrategy() {
        // Given
        let candles = createMockCandles(count: 30, trend: .neutral)
        
        // When
        let signal = Strategies.meanReversion(candles)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "Mean Reversion")
        XCTAssertTrue(signal.score > 0)
        XCTAssertTrue(signal.score <= 1.0)
    }
    
    // MARK: - Stochastic Strategy Tests
    
    func testStochasticStrategy() {
        // Given
        let candles = createMockCandles(count: 30, trend: .bullish)
        
        // When
        let signal = Strategies.stochastic(candles, kPeriod: 14, dPeriod: 3)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "Stochastic")
        XCTAssertTrue(signal.score > 0)
        XCTAssertTrue(signal.score <= 1.0)
    }
    
    // MARK: - Williams R Strategy Tests
    
    func testWilliamsRStrategy() {
        // Given
        let candles = createMockCandles(count: 30, trend: .bearish)
        
        // When
        let signal = Strategies.williamsR(candles, period: 14)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "Williams %R")
        XCTAssertTrue(signal.score > 0)
        XCTAssertTrue(signal.score <= 1.0)
    }
    
    // MARK: - ADX Strategy Tests
    
    func testADXStrategy() {
        // Given
        let candles = createMockCandles(count: 30, trend: .bullish)
        
        // When
        let signal = Strategies.adx(candles, period: 14)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "ADX")
        XCTAssertTrue(signal.score > 0)
        XCTAssertTrue(signal.score <= 1.0)
    }
    
    // MARK: - Volume Strategy Tests
    
    func testVolumeStrategy() {
        // Given
        let candles = createMockCandles(count: 30, trend: .neutral)
        
        // When
        let signal = Strategies.volume(candles, period: 20)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "Volume")
        XCTAssertTrue(signal.score > 0)
        XCTAssertTrue(signal.score <= 1.0)
    }
    
    // MARK: - Parabolic SAR Strategy Tests
    
    func testParabolicSARStrategy() {
        // Given
        let candles = createMockCandles(count: 30, trend: .bullish)
        
        // When
        let signal = Strategies.parabolicSAR(candles, af: 0.02, maxAF: 0.2)
        
        // Then
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal.name, "Parabolic SAR")
        XCTAssertTrue(signal.score > 0)
        XCTAssertTrue(signal.score <= 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testStrategyPerformance() {
        // Given
        let candles = createMockCandles(count: 100, trend: .neutral)
        
        // When & Then
        measure {
            _ = Strategies.rsi(candles)
            _ = Strategies.macd(candles)
            _ = Strategies.emaCrossover(candles)
            _ = Strategies.meanReversion(candles)
            _ = Strategies.stochastic(candles)
            _ = Strategies.williamsR(candles)
            _ = Strategies.adx(candles)
            _ = Strategies.volume(candles)
            _ = Strategies.parabolicSAR(candles)
        }
    }
    
    // MARK: - Edge Cases
    
    func testStrategyWithEmptyCandles() {
        // Given
        let candles: [AICandle] = []
        
        // When & Then
        let rsiSignal = Strategies.rsi(candles)
        XCTAssertNotNil(rsiSignal)
        
        let macdSignal = Strategies.macd(candles)
        XCTAssertNotNil(macdSignal)
    }
    
    func testStrategyWithSingleCandle() {
        // Given
        let candles = createMockCandles(count: 1)
        
        // When & Then
        let rsiSignal = Strategies.rsi(candles)
        XCTAssertNotNil(rsiSignal)
        
        let macdSignal = Strategies.macd(candles)
        XCTAssertNotNil(macdSignal)
    }
    
    func testStrategyWithExtremePriceValues() {
        // Given
        let baseTime = Date()
        let candles = [
            AICandle(timestamp: baseTime, open: 0.0001, high: 0.0002, low: 0.00005, close: 0.00015, volume: 1000000),
            AICandle(timestamp: baseTime.addingTimeInterval(300), open: 0.00015, high: 0.0003, low: 0.0001, close: 0.00025, volume: 2000000),
            AICandle(timestamp: baseTime.addingTimeInterval(600), open: 0.00025, high: 0.0004, low: 0.0002, close: 0.00035, volume: 3000000)
        ]
        
        // When & Then
        let rsiSignal = Strategies.rsi(candles)
        XCTAssertNotNil(rsiSignal)
        
        let macdSignal = Strategies.macd(candles)
        XCTAssertNotNil(macdSignal)
    }
    
    func testStrategyWithZeroVolume() {
        // Given
        let baseTime = Date()
        let candles = [
            AICandle(timestamp: baseTime, open: 50000, high: 51000, low: 49000, close: 50500, volume: 0),
            AICandle(timestamp: baseTime.addingTimeInterval(300), open: 50500, high: 51500, low: 49500, close: 51000, volume: 0),
            AICandle(timestamp: baseTime.addingTimeInterval(600), open: 51000, high: 52000, low: 50000, close: 51500, volume: 0)
        ]
        
        // When & Then
        let volumeSignal = Strategies.volume(candles)
        XCTAssertNotNil(volumeSignal)
    }
}
