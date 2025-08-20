import XCTest
import CoreML
@testable import MyTradeMate

final class FeaturePreparationTests: XCTestCase {
    
    var featureBuilder: FeatureBuilder!
    var mockSettings: MockAppSettings!
    
    override func setUp() async throws {
        try await super.setUp()
        mockSettings = MockAppSettings()
        featureBuilder = FeatureBuilder(settings: mockSettings)
    }
    
    override func tearDown() async throws {
        featureBuilder = nil
        mockSettings = nil
        try await super.tearDown()
    }
    
    // MARK: - Feature Building Tests
    
    func testBuildFeaturesWithSufficientCandles() throws {
        // Given
        let candles = createMockCandles(count: 100)
        
        // When
        let features = try featureBuilder.buildFeatures(from: candles)
        
        // Then
        XCTAssertEqual(features.count, 10, "Should build exactly 10 features")
        
        // Verify all features are finite numbers
        for (index, feature) in features.enumerated() {
            XCTAssertTrue(feature.isFinite, "Feature \(index + 1) should be finite, got \(feature)")
            XCTAssertFalse(feature.isNaN, "Feature \(index + 1) should not be NaN")
        }
    }
    
    func testBuildFeaturesWithInsufficientCandles() throws {
        // Given
        let candles = createMockCandles(count: 30) // Less than required 50
        
        // When & Then
        XCTAssertThrowsError(try featureBuilder.buildFeatures(from: candles)) { error in
            // Verify it's the expected error type
            XCTAssertTrue(error is FeatureError || error.localizedDescription.contains("candles"))
        }
    }
    
    func testBuildFeaturesWithEmptyCandles() throws {
        // Given
        let candles: [Candle] = []
        
        // When & Then
        XCTAssertThrowsError(try featureBuilder.buildFeatures(from: candles)) { error in
            XCTAssertTrue(error is FeatureError || error.localizedDescription.contains("candles"))
        }
    }
    
    func testBuildFeaturesWithExactMinimumCandles() throws {
        // Given
        let candles = createMockCandles(count: 50) // Exactly the minimum
        
        // When
        let features = try featureBuilder.buildFeatures(from: candles)
        
        // Then
        XCTAssertEqual(features.count, 10)
        
        // All features should be valid
        for feature in features {
            XCTAssertTrue(feature.isFinite)
            XCTAssertFalse(feature.isNaN)
        }
    }
    
    // MARK: - Individual Feature Tests
    
    func testMomentumCalculation() throws {
        // Given
        let candles = createTrendingCandles(count: 100, startPrice: 45000, trend: 0.01) // 1% uptrend
        
        // When
        let features = try featureBuilder.buildFeatures(from: candles)
        let momentum = features[0] // First feature is momentum
        
        // Then
        XCTAssertGreaterThan(momentum, 0, "Uptrending candles should have positive momentum")
        XCTAssertLessThan(momentum, 1, "Momentum should be reasonable (< 100%)")
    }
    
    func testVolatilityCalculation() throws {
        // Given
        let volatileCandles = createVolatileCandles(count: 100, basePrice: 45000, volatility: 0.05)
        let stableCandles = createStableCandles(count: 100, price: 45000)
        
        // When
        let volatileFeatures = try featureBuilder.buildFeatures(from: volatileCandles)
        let stableFeatures = try featureBuilder.buildFeatures(from: stableCandles)
        
        let volatileVolatility = volatileFeatures[1] // Second feature is volatility
        let stableVolatility = stableFeatures[1]
        
        // Then
        XCTAssertGreaterThan(volatileVolatility, stableVolatility, 
                           "Volatile candles should have higher volatility than stable candles")
        XCTAssertGreaterThan(volatileVolatility, 0, "Volatile candles should have positive volatility")
    }
    
    func testMovingAverageCrossoverCalculation() throws {
        // Given
        let candles = createMockCandles(count: 100)
        
        // When
        let features = try featureBuilder.buildFeatures(from: candles)
        let maCross5_20 = features[2]  // Third feature is MA 5/20 crossover
        let maCross10_50 = features[3] // Fourth feature is MA 10/50 crossover
        let maCross20_100 = features[4] // Fifth feature is MA 20/100 crossover
        
        // Then
        XCTAssertTrue(maCross5_20.isFinite, "MA crossover 5/20 should be finite")
        XCTAssertTrue(maCross10_50.isFinite, "MA crossover 10/50 should be finite")
        XCTAssertTrue(maCross20_100.isFinite, "MA crossover 20/100 should be finite")
        
        // Values should be reasonable (typically between -1 and 1 for normalized crossovers)
        XCTAssertGreaterThan(maCross5_20, -2, "MA crossover should be reasonable")
        XCTAssertLessThan(maCross5_20, 2, "MA crossover should be reasonable")
    }
    
    func testRSICalculation() throws {
        // Given
        let candles = createMockCandles(count: 100)
        
        // When
        let features = try featureBuilder.buildFeatures(from: candles)
        let rsi14 = features[5] // Sixth feature is RSI-14
        let rsi28 = features[6] // Seventh feature is RSI-28
        
        // Then
        XCTAssertGreaterThanOrEqual(rsi14, 0, "RSI should be >= 0")
        XCTAssertLessThanOrEqual(rsi14, 100, "RSI should be <= 100")
        XCTAssertGreaterThanOrEqual(rsi28, 0, "RSI should be >= 0")
        XCTAssertLessThanOrEqual(rsi28, 100, "RSI should be <= 100")
    }
    
    func testVolumeTrendCalculation() throws {
        // Given
        let candles = createMockCandlesWithVolume(count: 100)
        
        // When
        let features = try featureBuilder.buildFeatures(from: candles)
        let volumeTrend = features[7] // Eighth feature is volume trend
        
        // Then
        XCTAssertTrue(volumeTrend.isFinite, "Volume trend should be finite")
        XCTAssertFalse(volumeTrend.isNaN, "Volume trend should not be NaN")
    }
    
    func testPriceRangePositionCalculation() throws {
        // Given
        let candles = createRangeCandles(count: 100, low: 44000, high: 46000, current: 45000)
        
        // When
        let features = try featureBuilder.buildFeatures(from: candles)
        let priceRangePosition = features[8] // Ninth feature is price range position
        
        // Then
        XCTAssertGreaterThanOrEqual(priceRangePosition, 0, "Price range position should be >= 0")
        XCTAssertLessThanOrEqual(priceRangePosition, 1, "Price range position should be <= 1")
        
        // For a price in the middle of the range, should be around 0.5
        XCTAssertGreaterThan(priceRangePosition, 0.3, "Middle price should be in middle range")
        XCTAssertLessThan(priceRangePosition, 0.7, "Middle price should be in middle range")
    }
    
    func testTrendStrengthCalculation() throws {
        // Given
        let strongUptrend = createTrendingCandles(count: 100, startPrice: 40000, trend: 0.02)
        let strongDowntrend = createTrendingCandles(count: 100, startPrice: 50000, trend: -0.02)
        let sideways = createStableCandles(count: 100, price: 45000)
        
        // When
        let uptrendFeatures = try featureBuilder.buildFeatures(from: strongUptrend)
        let downtrendFeatures = try featureBuilder.buildFeatures(from: strongDowntrend)
        let sidewaysFeatures = try featureBuilder.buildFeatures(from: sideways)
        
        let uptrendStrength = uptrendFeatures[9]
        let downtrendStrength = downtrendFeatures[9]
        let sidewaysStrength = sidewaysFeatures[9]
        
        // Then
        XCTAssertGreaterThan(uptrendStrength, sidewaysStrength, "Uptrend should have stronger trend than sideways")
        XCTAssertLessThan(downtrendStrength, sidewaysStrength, "Downtrend should have negative trend strength")
        XCTAssertGreaterThan(abs(uptrendStrength), abs(sidewaysStrength), "Strong trend should have higher absolute strength")
    }
    
    // MARK: - Feature Normalization Tests
    
    func testFeatureNormalization() throws {
        // Given
        let extremeCandles = createExtremeCandles(count: 100)
        
        // When
        let features = try featureBuilder.buildFeatures(from: extremeCandles)
        
        // Then
        // Most features should be normalized to reasonable ranges
        for (index, feature) in features.enumerated() {
            XCTAssertTrue(feature.isFinite, "Feature \(index + 1) should be finite")
            XCTAssertFalse(feature.isNaN, "Feature \(index + 1) should not be NaN")
            
            // Features should generally be in a reasonable range (not extremely large)
            XCTAssertLessThan(abs(feature), 100, "Feature \(index + 1) should be reasonably bounded")
        }
    }
    
    func testFeatureConsistency() throws {
        // Given
        let candles = createMockCandles(count: 100)
        
        // When - Build features multiple times with same data
        let features1 = try featureBuilder.buildFeatures(from: candles)
        let features2 = try featureBuilder.buildFeatures(from: candles)
        
        // Then - Should get identical results
        XCTAssertEqual(features1.count, features2.count)
        
        for (index, (f1, f2)) in zip(features1, features2).enumerated() {
            XCTAssertEqual(f1, f2, accuracy: 0.0001, "Feature \(index + 1) should be consistent")
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testFeaturesWithZeroPrices() throws {
        // Given
        var candles = createMockCandles(count: 100)
        // Set some prices to zero to test edge case handling
        candles[50] = Candle(openTime: Date(), open: 0, high: 0, low: 0, close: 0, volume: 1000)
        
        // When
        let features = try featureBuilder.buildFeatures(from: candles)
        
        // Then
        XCTAssertEqual(features.count, 10)
        
        // Features should handle zero prices gracefully
        for (index, feature) in features.enumerated() {
            XCTAssertTrue(feature.isFinite, "Feature \(index + 1) should handle zero prices gracefully")
            XCTAssertFalse(feature.isNaN, "Feature \(index + 1) should not be NaN with zero prices")
        }
    }
    
    func testFeaturesWithIdenticalPrices() throws {
        // Given
        let candles = createStableCandles(count: 100, price: 45000) // All same price
        
        // When
        let features = try featureBuilder.buildFeatures(from: candles)
        
        // Then
        XCTAssertEqual(features.count, 10)
        
        // With identical prices, some features should be zero
        let momentum = features[0]
        let volatility = features[1]
        
        XCTAssertEqual(momentum, 0, accuracy: 0.0001, "Momentum should be zero with identical prices")
        XCTAssertEqual(volatility, 0, accuracy: 0.0001, "Volatility should be zero with identical prices")
    }
    
    func testFeaturesWithExtremeVolatility() throws {
        // Given
        let candles = createExtremeVolatilityCandles(count: 100)
        
        // When
        let features = try featureBuilder.buildFeatures(from: candles)
        
        // Then
        XCTAssertEqual(features.count, 10)
        
        // Even with extreme volatility, features should be finite
        for (index, feature) in features.enumerated() {
            XCTAssertTrue(feature.isFinite, "Feature \(index + 1) should handle extreme volatility")
            XCTAssertFalse(feature.isNaN, "Feature \(index + 1) should not be NaN with extreme volatility")
        }
        
        // Volatility feature should be high
        let volatility = features[1]
        XCTAssertGreaterThan(volatility, 0, "Volatility should be positive with extreme price swings")
    }
    
    // MARK: - Performance Tests
    
    func testFeatureBuildingPerformance() throws {
        // Given
        let candles = createMockCandles(count: 1000) // Large dataset
        
        // When & Then
        measure {
            do {
                let _ = try featureBuilder.buildFeatures(from: candles)
            } catch {
                XCTFail("Feature building should not fail: \(error)")
            }
        }
    }
    
    func testConcurrentFeatureBuilding() throws {
        // Given
        let candles = createMockCandles(count: 100)
        let iterations = 10
        
        // When
        let expectation = XCTestExpectation(description: "Concurrent feature building")
        expectation.expectedFulfillmentCount = iterations
        
        for _ in 0..<iterations {
            DispatchQueue.global().async {
                do {
                    let features = try self.featureBuilder.buildFeatures(from: candles)
                    XCTAssertEqual(features.count, 10)
                    expectation.fulfill()
                } catch {
                    XCTFail("Concurrent feature building failed: \(error)")
                    expectation.fulfill()
                }
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Static Method Tests
    
    func testStaticVector10Method() throws {
        // Given
        let candles = createMockCandles(count: 100)
        
        // When
        let mlArray = try FeatureBuilder.vector10(from: candles)
        
        // Then
        XCTAssertNotNil(mlArray)
        XCTAssertEqual(mlArray.count, 10)
        XCTAssertEqual(mlArray.dataType, .float32)
        
        // Verify values are reasonable
        for i in 0..<mlArray.count {
            let value = mlArray[i].floatValue
            XCTAssertTrue(value.isFinite, "MLMultiArray value at index \(i) should be finite")
            XCTAssertFalse(value.isNaN, "MLMultiArray value at index \(i) should not be NaN")
        }
    }
    
    // MARK: - Verbose Logging Tests
    
    func testVerboseLogging() throws {
        // Given
        mockSettings.verboseAILogs = true
        let candles = createMockCandles(count: 100)
        
        // When
        let features = try featureBuilder.buildFeatures(from: candles)
        
        // Then
        XCTAssertEqual(features.count, 10)
        // Note: We can't easily test the actual logging output, but we ensure
        // the verbose logging path doesn't cause errors
    }
    
    func testNonVerboseLogging() throws {
        // Given
        mockSettings.verboseAILogs = false
        let candles = createMockCandles(count: 100)
        
        // When
        let features = try featureBuilder.buildFeatures(from: candles)
        
        // Then
        XCTAssertEqual(features.count, 10)
        // Non-verbose mode should work the same way
    }
    
    // MARK: - Advanced Feature Validation Tests
    
    func testFeatureRangeValidation() throws {
        // Test that features are within expected ranges
        
        // Given
        let candles = createMockCandles(count: 100)
        
        // When
        let features = try featureBuilder.buildFeatures(from: candles)
        
        // Then
        XCTAssertEqual(features.count, 10)
        
        // Feature 1: Momentum should be reasonable (-100% to +100% typically)
        let momentum = features[0]
        XCTAssertGreaterThan(momentum, -2.0, "Momentum should be > -200%")
        XCTAssertLessThan(momentum, 2.0, "Momentum should be < +200%")
        
        // Feature 2: Volatility should be positive
        let volatility = features[1]
        XCTAssertGreaterThanOrEqual(volatility, 0, "Volatility should be non-negative")
        XCTAssertLessThan(volatility, 1.0, "Volatility should be reasonable")
        
        // Features 6-7: RSI should be 0-100
        let rsi14 = features[5]
        let rsi28 = features[6]
        XCTAssertGreaterThanOrEqual(rsi14, 0, "RSI-14 should be >= 0")
        XCTAssertLessThanOrEqual(rsi14, 100, "RSI-14 should be <= 100")
        XCTAssertGreaterThanOrEqual(rsi28, 0, "RSI-28 should be >= 0")
        XCTAssertLessThanOrEqual(rsi28, 100, "RSI-28 should be <= 100")
        
        // Feature 9: Price range position should be 0-1
        let priceRange = features[8]
        XCTAssertGreaterThanOrEqual(priceRange, 0, "Price range position should be >= 0")
        XCTAssertLessThanOrEqual(priceRange, 1, "Price range position should be <= 1")
    }
    
    func testFeatureStabilityWithMinimalData() throws {
        // Test feature calculation with exactly minimum required data
        
        // Given
        let minimalCandles = createMockCandles(count: 50) // Exactly minimum
        
        // When
        let features = try featureBuilder.buildFeatures(from: minimalCandles)
        
        // Then
        XCTAssertEqual(features.count, 10)
        
        // All features should be finite and valid
        for (index, feature) in features.enumerated() {
            XCTAssertTrue(feature.isFinite, "Feature \(index + 1) should be finite with minimal data")
            XCTAssertFalse(feature.isNaN, "Feature \(index + 1) should not be NaN with minimal data")
        }
    }
    
    func testFeatureCalculationWithLargeDataset() throws {
        // Test feature calculation with large dataset
        
        // Given
        let largeCandles = createMockCandles(count: 2000) // Large dataset
        
        // When
        let features = try featureBuilder.buildFeatures(from: largeCandles)
        
        // Then
        XCTAssertEqual(features.count, 10)
        
        // Features should still be valid with large dataset
        for (index, feature) in features.enumerated() {
            XCTAssertTrue(feature.isFinite, "Feature \(index + 1) should be finite with large dataset")
            XCTAssertFalse(feature.isNaN, "Feature \(index + 1) should not be NaN with large dataset")
        }
    }
    
    func testFeatureNormalizationConsistency() throws {
        // Test that feature normalization is consistent across different datasets
        
        // Given
        let dataset1 = createMockCandles(count: 100)
        let dataset2 = createMockCandles(count: 150)
        let dataset3 = createMockCandles(count: 200)
        
        // When
        let features1 = try featureBuilder.buildFeatures(from: dataset1)
        let features2 = try featureBuilder.buildFeatures(from: dataset2)
        let features3 = try featureBuilder.buildFeatures(from: dataset3)
        
        // Then
        XCTAssertEqual(features1.count, 10)
        XCTAssertEqual(features2.count, 10)
        XCTAssertEqual(features3.count, 10)
        
        // Features should be in similar ranges across datasets
        for i in 0..<10 {
            let values = [features1[i], features2[i], features3[i]]
            let maxValue = values.max() ?? 0
            let minValue = values.min() ?? 0
            
            // Range should be reasonable (not wildly different)
            if maxValue != 0 {
                let range = (maxValue - minValue) / abs(maxValue)
                XCTAssertLessThan(range, 10.0, "Feature \(i + 1) range should be consistent across datasets")
            }
        }
    }
    
    func testFeatureBoundaryConditions() throws {
        // Test feature calculation with boundary conditions
        
        // Test with all identical prices
        let flatCandles = createStableCandles(count: 100, price: 45000)
        let flatFeatures = try featureBuilder.buildFeatures(from: flatCandles)
        
        XCTAssertEqual(flatFeatures.count, 10)
        
        // Momentum should be zero with flat prices
        XCTAssertEqual(flatFeatures[0], 0, accuracy: 0.0001, "Momentum should be zero with flat prices")
        
        // Volatility should be zero with flat prices
        XCTAssertEqual(flatFeatures[1], 0, accuracy: 0.0001, "Volatility should be zero with flat prices")
        
        // Test with extreme volatility
        let volatileCandles = createExtremeVolatilityCandles(count: 100)
        let volatileFeatures = try featureBuilder.buildFeatures(from: volatileCandles)
        
        XCTAssertEqual(volatileFeatures.count, 10)
        
        // Volatility should be high with extreme price swings
        XCTAssertGreaterThan(volatileFeatures[1], 0, "Volatility should be positive with extreme swings")
        
        // All features should still be finite
        for (index, feature) in volatileFeatures.enumerated() {
            XCTAssertTrue(feature.isFinite, "Feature \(index + 1) should be finite even with extreme volatility")
            XCTAssertFalse(feature.isNaN, "Feature \(index + 1) should not be NaN with extreme volatility")
        }
    }
}

// MARK: - Test Data Creation Helpers

extension FeaturePreparationTests {
    
    private func createMockCandles(count: Int) -> [Candle] {
        var candles: [Candle] = []
        let basePrice = 45000.0
        let baseVolume = 1000.0
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300) // 5-minute intervals
            let price = basePrice + Double.random(in: -1000...1000)
            let volume = baseVolume + Double.random(in: -200...200)
            
            let open = price + Double.random(in: -50...50)
            let close = price + Double.random(in: -50...50)
            let high = max(open, close) + Double.random(in: 0...100)
            let low = min(open, close) - Double.random(in: 0...100)
            
            candles.append(Candle(
                openTime: time,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: max(volume, 1) // Ensure positive volume
            ))
        }
        
        return candles
    }
    
    private func createTrendingCandles(count: Int, startPrice: Double, trend: Double) -> [Candle] {
        var candles: [Candle] = []
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            let price = startPrice * pow(1 + trend, Double(i))
            let noise = Double.random(in: -price * 0.01...price * 0.01)
            
            let open = price + noise
            let close = price + noise + Double.random(in: -price * 0.005...price * 0.005)
            let high = max(open, close) + Double.random(in: 0...price * 0.01)
            let low = min(open, close) - Double.random(in: 0...price * 0.01)
            let volume = 1000 + Double.random(in: -200...200)
            
            candles.append(Candle(
                openTime: time,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: max(volume, 1)
            ))
        }
        
        return candles
    }
    
    private func createVolatileCandles(count: Int, basePrice: Double, volatility: Double) -> [Candle] {
        var candles: [Candle] = []
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            let priceChange = Double.random(in: -volatility...volatility) * basePrice
            let price = basePrice + priceChange
            
            let open = price + Double.random(in: -price * volatility * 0.5...price * volatility * 0.5)
            let close = price + Double.random(in: -price * volatility * 0.5...price * volatility * 0.5)
            let high = max(open, close) + Double.random(in: 0...price * volatility)
            let low = min(open, close) - Double.random(in: 0...price * volatility)
            let volume = 1000 + Double.random(in: -500...500)
            
            candles.append(Candle(
                openTime: time,
                open: max(open, 1),
                high: max(high, 1),
                low: max(low, 1),
                close: max(close, 1),
                volume: max(volume, 1)
            ))
        }
        
        return candles
    }
    
    private func createStableCandles(count: Int, price: Double) -> [Candle] {
        var candles: [Candle] = []
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            let volume = 1000.0
            
            candles.append(Candle(
                openTime: time,
                open: price,
                high: price,
                low: price,
                close: price,
                volume: volume
            ))
        }
        
        return candles
    }
    
    private func createMockCandlesWithVolume(count: Int) -> [Candle] {
        var candles: [Candle] = []
        let basePrice = 45000.0
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            let price = basePrice + Double.random(in: -1000...1000)
            
            // Create varying volume pattern
            let volumeTrend = sin(Double(i) * 0.1) * 500 + 1000
            let volume = max(volumeTrend + Double.random(in: -200...200), 1)
            
            let open = price + Double.random(in: -50...50)
            let close = price + Double.random(in: -50...50)
            let high = max(open, close) + Double.random(in: 0...100)
            let low = min(open, close) - Double.random(in: 0...100)
            
            candles.append(Candle(
                openTime: time,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
        }
        
        return candles
    }
    
    private func createRangeCandles(count: Int, low: Double, high: Double, current: Double) -> [Candle] {
        var candles: [Candle] = []
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            let volume = 1000.0
            
            // Create prices within the range, with the last candle at the current price
            let price = if i == count - 1 {
                current
            } else {
                Double.random(in: low...high)
            }
            
            let open = price + Double.random(in: -50...50)
            let close = price + Double.random(in: -50...50)
            let candleHigh = max(open, close) + Double.random(in: 0...50)
            let candleLow = min(open, close) - Double.random(in: 0...50)
            
            candles.append(Candle(
                openTime: time,
                open: open,
                high: min(candleHigh, high),
                low: max(candleLow, low),
                close: close,
                volume: volume
            ))
        }
        
        return candles
    }
    
    private func createExtremeCandles(count: Int) -> [Candle] {
        var candles: [Candle] = []
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            
            // Create extreme price movements
            let basePrice = 45000.0
            let extremeMultiplier = pow(-1, Double(i)) * Double(i % 10) * 0.1
            let price = basePrice * (1 + extremeMultiplier)
            
            let open = price
            let close = price * (1 + Double.random(in: -0.2...0.2))
            let high = max(open, close) * (1 + Double.random(in: 0...0.1))
            let low = min(open, close) * (1 - Double.random(in: 0...0.1))
            let volume = Double.random(in: 1...10000)
            
            candles.append(Candle(
                openTime: time,
                open: max(open, 1),
                high: max(high, 1),
                low: max(low, 1),
                close: max(close, 1),
                volume: volume
            ))
        }
        
        return candles
    }
    
    private func createExtremeVolatilityCandles(count: Int) -> [Candle] {
        var candles: [Candle] = []
        let basePrice = 45000.0
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            
            // Extreme volatility - prices can swing wildly
            let volatility = 0.5 // 50% swings
            let priceMultiplier = 1 + (Double.random(in: -volatility...volatility))
            let price = basePrice * priceMultiplier
            
            let open = price * (1 + Double.random(in: -0.1...0.1))
            let close = price * (1 + Double.random(in: -0.1...0.1))
            let high = max(open, close) * (1 + Double.random(in: 0...0.2))
            let low = min(open, close) * (1 - Double.random(in: 0...0.2))
            let volume = Double.random(in: 100...5000)
            
            candles.append(Candle(
                openTime: time,
                open: max(open, 1),
                high: max(high, 1),
                low: max(low, 1),
                close: max(close, 1),
                volume: volume
            ))
        }
        
        return candles
    }
}

// MARK: - Mock Classes

@MainActor
final class MockAppSettings: AppSettingsProtocol {
    @Published var demoMode = false
    @Published var liveMarketData = true
    @Published var defaultSymbol = "BTC/USDT"
    @Published var defaultTimeframe = "5m"
    @Published var darkMode = false
    @Published var verboseAILogs = false
    @Published var autoTrading = false
    @Published var confirmTrades = true
    
    var isDemoPnL: Bool { demoMode }
}

// MARK: - Mock Error Type

enum FeatureError: Error {
    case notEnoughCandles
    case invalidInput(String)
}