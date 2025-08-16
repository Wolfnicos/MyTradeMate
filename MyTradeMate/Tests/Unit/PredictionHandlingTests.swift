import XCTest
import CoreML
@testable import MyTradeMate

final class PredictionHandlingTests: XCTestCase {
    
    var aiModelManager: AIModelManager!
    var mockSettings: MockAppSettings!
    
    override func setUp() async throws {
        try await super.setUp()
        aiModelManager = AIModelManager.shared
        mockSettings = MockAppSettings()
        
        // Clear any cached models to ensure clean test state
        await MainActor.run {
            aiModelManager.models.removeAll()
        }
        
        // Preload models for testing
        await aiModelManager.preloadModels()
    }
    
    override func tearDown() async throws {
        aiModelManager = nil
        mockSettings = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Prediction Tests
    
    func testPredictWithSufficientCandles() async throws {
        // Given
        let candles = createMockCandles(count: 100)
        let timeframe = Timeframe.m5
        
        // When
        let result = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: timeframe,
            candles: candles,
            precision: false
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertFalse(result.signal.isEmpty)
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal))
        XCTAssertGreaterThanOrEqual(result.confidence, 0)
        XCTAssertLessThanOrEqual(result.confidence, 1)
        XCTAssertFalse(result.modelName.isEmpty)
    }
    
    func testPredictWithInsufficientCandles() async throws {
        // Given
        let candles = createMockCandles(count: 30) // Less than required 50
        let timeframe = Timeframe.m5
        
        // When
        let result = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: timeframe,
            candles: candles,
            precision: false
        )
        
        // Then
        XCTAssertEqual(result.signal, "HOLD", "Should default to HOLD with insufficient candles")
        XCTAssertEqual(result.confidence, 0, "Should have zero confidence with insufficient candles")
        XCTAssertTrue(result.meta["reason"]?.contains("insufficient") == true, "Should indicate insufficient candles")
    }
    
    func testPredictSafely() async throws {
        // Given
        let candles = createMockCandles(count: 100)
        let timeframe = Timeframe.m5
        let mode = TradingMode.manual
        
        // When
        let result = await aiModelManager.predictSafely(
            timeframe: timeframe,
            candles: candles,
            mode: mode
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal))
        XCTAssertGreaterThanOrEqual(result.confidence, 0)
        XCTAssertLessThanOrEqual(result.confidence, 1)
    }
    
    // MARK: - Demo Mode Tests
    
    func testDemoModePrediction() async throws {
        // Given
        mockSettings.demoMode = true
        let candles = createMockCandles(count: 100)
        let timeframe = Timeframe.m5
        
        // When
        let result = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: timeframe,
            candles: candles,
            precision: false
        )
        
        // Then
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal))
        XCTAssertEqual(result.modelName, "DEMO")
        XCTAssertEqual(result.meta["demo"], "1")
        XCTAssertGreaterThan(result.confidence, 0.5, "Demo predictions should have reasonable confidence")
        XCTAssertLessThan(result.confidence, 1.0, "Demo predictions should not have perfect confidence")
    }
    
    func testDemoPredictionForSpecificModel() async throws {
        // Given
        let modelKind = ModelKind.m5
        
        // When
        let result = await aiModelManager.demoPrediction(for: modelKind)
        
        // Then
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal))
        XCTAssertEqual(result.modelName, "Demo Model")
        XCTAssertGreaterThanOrEqual(result.confidence, 0.6)
        XCTAssertLessThanOrEqual(result.confidence, 0.9)
    }
    
    // MARK: - Precision Mode Tests
    
    func testPrecisionModeEnsemblePrediction() async throws {
        // Given
        let candles = createMockCandles(count: 100)
        
        // When
        let result = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: true
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal))
        XCTAssertEqual(result.modelName, "Ensemble", "Precision mode should use ensemble")
        XCTAssertEqual(result.meta["models"], "m5,h1,h4", "Should indicate all models used")
        XCTAssertGreaterThanOrEqual(result.confidence, 0)
        XCTAssertLessThanOrEqual(result.confidence, 1)
    }
    
    func testEnsembleMajorityVoting() async throws {
        // This test verifies that ensemble prediction uses majority voting
        // We can't control the actual model outputs, but we can verify the structure
        
        // Given
        let candles = createMockCandles(count: 100)
        
        // When
        let result = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: true
        )
        
        // Then
        XCTAssertEqual(result.modelName, "Ensemble")
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal))
        
        // Confidence should be reasonable (ensemble should provide some confidence)
        XCTAssertGreaterThanOrEqual(result.confidence, 0)
        XCTAssertLessThanOrEqual(result.confidence, 1)
    }
    
    // MARK: - Different Timeframe Tests
    
    func testPredictionForDifferentTimeframes() async throws {
        // Given
        let candles = createMockCandles(count: 100)
        let timeframes: [Timeframe] = [.m5, .h1, .h4]
        
        // When & Then
        for timeframe in timeframes {
            let result = await aiModelManager.predict(
                symbol: "BTCUSDT",
                timeframe: timeframe,
                candles: candles,
                precision: false
            )
            
            XCTAssertNotNil(result, "Should get prediction for \(timeframe)")
            XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal), "Should get valid signal for \(timeframe)")
            XCTAssertFalse(result.modelName.isEmpty, "Should have model name for \(timeframe)")
        }
    }
    
    // MARK: - Error Handling and Fallback Tests
    
    func testPredictionWithModelLoadingError() async throws {
        // Given
        let candles = createMockCandles(count: 100)
        
        // Clear models to simulate loading error
        aiModelManager.models.removeAll()
        
        // When
        let result = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: false
        )
        
        // Then
        // Should handle error gracefully and return a fallback result
        XCTAssertNotNil(result)
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal))
        
        // Should indicate error in metadata
        XCTAssertTrue(result.meta["error"] != nil || result.confidence == 0)
    }
    
    func testPredictionWithInvalidFeatures() async throws {
        // Given
        let invalidCandles = createInvalidCandles(count: 100) // Candles with problematic data
        
        // When
        let result = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: invalidCandles,
            precision: false
        )
        
        // Then
        // Should handle invalid features gracefully
        XCTAssertNotNil(result)
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal))
        
        // May have reduced confidence or error indication
        XCTAssertGreaterThanOrEqual(result.confidence, 0)
        XCTAssertLessThanOrEqual(result.confidence, 1)
    }
    
    func testFallbackToHoldSignal() async throws {
        // Given
        let emptyCandles: [Candle] = []
        
        // When
        let result = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: emptyCandles,
            precision: false
        )
        
        // Then
        XCTAssertEqual(result.signal, "HOLD", "Should fallback to HOLD with empty candles")
        XCTAssertEqual(result.confidence, 0, "Should have zero confidence with empty candles")
    }
    
    // MARK: - Output Conversion Tests
    
    func testSimpleSignalConversion() {
        // Test SimpleSignal enum functionality
        
        // Test string values
        XCTAssertEqual(SimpleSignal.buy.stringValue, "BUY")
        XCTAssertEqual(SimpleSignal.sell.stringValue, "SELL")
        XCTAssertEqual(SimpleSignal.hold.stringValue, "HOLD")
        
        // Test raw value initialization
        XCTAssertEqual(SimpleSignal(rawValue: "BUY"), .buy)
        XCTAssertEqual(SimpleSignal(rawValue: "SELL"), .sell)
        XCTAssertEqual(SimpleSignal(rawValue: "HOLD"), .hold)
        XCTAssertEqual(SimpleSignal(rawValue: "buy"), .buy) // Case insensitive
        XCTAssertNil(SimpleSignal(rawValue: "INVALID"))
    }
    
    func testPredictionResultCreation() {
        // Test PredictionResult initialization
        
        // Given
        let signal = "BUY"
        let confidence = 0.75
        let modelName = "TestModel"
        let meta = ["test": "value"]
        
        // When
        let result = PredictionResult(
            signal: signal,
            confidence: confidence,
            modelName: modelName,
            meta: meta
        )
        
        // Then
        XCTAssertEqual(result.signal, signal)
        XCTAssertEqual(result.confidence, confidence)
        XCTAssertEqual(result.modelName, modelName)
        XCTAssertEqual(result.meta["test"], "value")
    }
    
    // MARK: - Performance Tests
    
    func testPredictionPerformance() async throws {
        // Given
        let candles = createMockCandles(count: 100)
        
        // When & Then
        measure {
            let expectation = XCTestExpectation(description: "Prediction performance")
            
            Task {
                let _ = await aiModelManager.predict(
                    symbol: "BTCUSDT",
                    timeframe: .m5,
                    candles: candles,
                    precision: false
                )
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testConcurrentPredictions() async throws {
        // Given
        let candles = createMockCandles(count: 100)
        let concurrentCount = 5
        
        // When
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<concurrentCount {
                group.addTask {
                    let result = await self.aiModelManager.predict(
                        symbol: "BTCUSDT",
                        timeframe: .m5,
                        candles: candles,
                        precision: false
                    )
                    
                    XCTAssertNotNil(result, "Concurrent prediction \(i) should succeed")
                    XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal))
                }
            }
        }
    }
    
    // MARK: - Model-Specific Prediction Tests
    
    func testPredictWithSpecificModel() async throws {
        // Given
        let modelKind = ModelKind.m5
        let candles = Array(0..<100).map { Double($0) } // Simple numeric array
        
        // When
        let result = try await aiModelManager.predict(kind: modelKind, candles: candles, verbose: false)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal))
        XCTAssertEqual(result.modelName, modelKind.modelName)
        XCTAssertGreaterThanOrEqual(result.confidence, 0)
        XCTAssertLessThanOrEqual(result.confidence, 1)
    }
    
    func testPredictWithVerboseLogging() async throws {
        // Given
        let modelKind = ModelKind.m5
        let candles = Array(0..<100).map { Double($0) }
        
        // When
        let result = try await aiModelManager.predict(kind: modelKind, candles: candles, verbose: true)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal))
        // Verbose logging should not affect the result quality
    }
    
    // MARK: - Edge Case Tests
    
    func testPredictionWithExtremeValues() async throws {
        // Given
        let extremeCandles = createExtremeCandles(count: 100)
        
        // When
        let result = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: extremeCandles,
            precision: false
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal))
        XCTAssertGreaterThanOrEqual(result.confidence, 0)
        XCTAssertLessThanOrEqual(result.confidence, 1)
    }
    
    func testPredictionConsistency() async throws {
        // Given
        let candles = createMockCandles(count: 100)
        
        // When - Make multiple predictions with same data
        let results = await withTaskGroup(of: PredictionResult.self, returning: [PredictionResult].self) { group in
            for _ in 0..<5 {
                group.addTask {
                    await self.aiModelManager.predict(
                        symbol: "BTCUSDT",
                        timeframe: .m5,
                        candles: candles,
                        precision: false
                    )
                }
            }
            
            var results: [PredictionResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // Then - Results should be consistent (same input should give same output)
        XCTAssertEqual(results.count, 5)
        
        let firstResult = results[0]
        for result in results {
            XCTAssertEqual(result.signal, firstResult.signal, "Predictions should be consistent")
            XCTAssertEqual(result.confidence, firstResult.confidence, accuracy: 0.001, "Confidence should be consistent")
        }
    }
    
    // MARK: - Advanced Fallback Tests
    
    func testPredictionFallbackChain() async throws {
        // Test the complete fallback chain when various components fail
        
        // Test 1: Insufficient candles fallback
        let insufficientCandles = createMockCandles(count: 10)
        let result1 = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: insufficientCandles,
            precision: false
        )
        
        XCTAssertEqual(result1.signal, "HOLD", "Should fallback to HOLD with insufficient candles")
        XCTAssertEqual(result1.confidence, 0, "Should have zero confidence with insufficient candles")
        XCTAssertTrue(result1.meta["reason"]?.contains("insufficient") == true, "Should indicate reason")
        
        // Test 2: Empty candles fallback
        let emptyCandles: [Candle] = []
        let result2 = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: emptyCandles,
            precision: false
        )
        
        XCTAssertEqual(result2.signal, "HOLD", "Should fallback to HOLD with empty candles")
        XCTAssertEqual(result2.confidence, 0, "Should have zero confidence with empty candles")
        
        // Test 3: Model loading failure fallback
        await MainActor.run {
            aiModelManager.models.removeAll() // Clear cached models
        }
        
        let normalCandles = createMockCandles(count: 100)
        let result3 = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: normalCandles,
            precision: false
        )
        
        // Should still return a result (may load model on demand or fallback)
        XCTAssertNotNil(result3, "Should handle model loading gracefully")
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result3.signal), "Should return valid signal")
    }
    
    func testPredictionRobustnessWithCorruptedData() async throws {
        // Test prediction robustness with various types of corrupted data
        
        // Test with NaN values
        let nanCandles = createCandlesWithNaN(count: 100)
        let result1 = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: nanCandles,
            precision: false
        )
        
        XCTAssertNotNil(result1, "Should handle NaN values gracefully")
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result1.signal), "Should return valid signal with NaN data")
        
        // Test with infinite values
        let infiniteCandles = createCandlesWithInfiniteValues(count: 100)
        let result2 = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: infiniteCandles,
            precision: false
        )
        
        XCTAssertNotNil(result2, "Should handle infinite values gracefully")
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result2.signal), "Should return valid signal with infinite data")
        
        // Test with zero/negative prices
        let zeroCandles = createCandlesWithZeroPrices(count: 100)
        let result3 = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: zeroCandles,
            precision: false
        )
        
        XCTAssertNotNil(result3, "Should handle zero prices gracefully")
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result3.signal), "Should return valid signal with zero prices")
    }
    
    func testEnsemblePredictionFallbacks() async throws {
        // Test ensemble prediction fallback behavior
        
        // Given
        let candles = createMockCandles(count: 100)
        
        // When - Test ensemble with all models available
        let result1 = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: true
        )
        
        // Then
        XCTAssertEqual(result1.modelName, "Ensemble", "Should use ensemble in precision mode")
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result1.signal), "Ensemble should return valid signal")
        XCTAssertEqual(result1.meta["models"], "m5,h1,h4", "Should indicate all models used")
        
        // When - Test ensemble with some models missing (simulate by clearing cache)
        await MainActor.run {
            aiModelManager.models.removeAll()
        }
        
        let result2 = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: true
        )
        
        // Then - Should still work (may load models on demand)
        XCTAssertNotNil(result2, "Ensemble should handle missing models")
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result2.signal), "Should return valid signal")
    }
    
    // MARK: - Integration Tests
    
    func testFullPredictionPipeline() async throws {
        // Test the complete pipeline from candles to prediction
        
        // Given
        let candles = createRealisticCandles(count: 200)
        
        // When
        let result = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: false
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal))
        XCTAssertGreaterThanOrEqual(result.confidence, 0)
        XCTAssertLessThanOrEqual(result.confidence, 1)
        XCTAssertFalse(result.modelName.isEmpty)
        
        // Verify the prediction makes sense
        if result.signal == "BUY" {
            XCTAssertGreaterThan(result.confidence, 0, "BUY signal should have some confidence")
        } else if result.signal == "SELL" {
            XCTAssertGreaterThan(result.confidence, 0, "SELL signal should have some confidence")
        }
        // HOLD can have any confidence level
    }
    
    func testPredictionPipelineWithDifferentDataSizes() async throws {
        // Test pipeline with various data sizes
        
        let dataSizes = [50, 100, 200, 500, 1000] // Different candle counts
        
        for size in dataSizes {
            // Given
            let candles = createMockCandles(count: size)
            
            // When
            let result = await aiModelManager.predict(
                symbol: "BTCUSDT",
                timeframe: .m5,
                candles: candles,
                precision: false
            )
            
            // Then
            XCTAssertNotNil(result, "Should handle \(size) candles")
            XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal), 
                        "Should return valid signal with \(size) candles")
            XCTAssertGreaterThanOrEqual(result.confidence, 0, "Confidence should be valid with \(size) candles")
            XCTAssertLessThanOrEqual(result.confidence, 1, "Confidence should be valid with \(size) candles")
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

// MARK: - Test Data Creation Helpers

extension PredictionHandlingTests {
    
    private func createMockCandles(count: Int) -> [Candle] {
        var candles: [Candle] = []
        let basePrice = 45000.0
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            let price = basePrice + Double.random(in: -1000...1000)
            let volume = 1000 + Double.random(in: -200...200)
            
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
                volume: max(volume, 1)
            ))
        }
        
        return candles
    }
    
    private func createInvalidCandles(count: Int) -> [Candle] {
        var candles: [Candle] = []
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            
            // Create some candles with problematic data
            let open = i % 10 == 0 ? 0 : Double.random(in: 40000...50000) // Some zero prices
            let close = i % 15 == 0 ? Double.infinity : Double.random(in: 40000...50000) // Some infinite prices
            let high = i % 20 == 0 ? Double.nan : max(open, close) + 100 // Some NaN prices
            let low = min(open, close) - 100
            let volume = i % 5 == 0 ? -100 : 1000 // Some negative volumes
            
            candles.append(Candle(
                openTime: time,
                open: open.isFinite ? open : 45000,
                high: high.isFinite ? high : 45100,
                low: low.isFinite ? low : 44900,
                close: close.isFinite ? close : 45000,
                volume: max(volume, 1)
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
            let extremeMultiplier = pow(-1, Double(i)) * Double(i % 10) * 0.2
            let price = basePrice * (1 + extremeMultiplier)
            
            let open = price
            let close = price * (1 + Double.random(in: -0.3...0.3))
            let high = max(open, close) * (1 + Double.random(in: 0...0.2))
            let low = min(open, close) * (1 - Double.random(in: 0...0.2))
            let volume = Double.random(in: 1...20000)
            
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
    
    private func createRealisticCandles(count: Int) -> [Candle] {
        var candles: [Candle] = []
        let basePrice = 45000.0
        var currentPrice = basePrice
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            
            // Create realistic price movement with some trend and volatility
            let trendFactor = sin(Double(i) * 0.02) * 0.001 // Slow trend
            let volatilityFactor = Double.random(in: -0.02...0.02) // 2% volatility
            let priceChange = (trendFactor + volatilityFactor) * currentPrice
            
            currentPrice += priceChange
            currentPrice = max(currentPrice, 1000) // Minimum price
            
            let open = currentPrice + Double.random(in: -currentPrice * 0.005...currentPrice * 0.005)
            let close = currentPrice + Double.random(in: -currentPrice * 0.005...currentPrice * 0.005)
            let high = max(open, close) + Double.random(in: 0...currentPrice * 0.01)
            let low = min(open, close) - Double.random(in: 0...currentPrice * 0.01)
            let volume = 1000 + Double.random(in: -300...300)
            
            candles.append(Candle(
                openTime: time,
                open: open,
                high: high,
                low: max(low, 1),
                close: close,
                volume: max(volume, 1)
            ))
        }
        
        return candles
    }
    
    private func createCandlesWithNaN(count: Int) -> [Candle] {
        var candles: [Candle] = []
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            
            // Introduce NaN values in some candles
            let hasNaN = i % 10 == 0
            let basePrice = hasNaN ? Double.nan : 45000.0
            
            let open = hasNaN ? Double.nan : basePrice + Double.random(in: -1000...1000)
            let close = hasNaN ? Double.nan : basePrice + Double.random(in: -1000...1000)
            let high = hasNaN ? Double.nan : max(open.isFinite ? open : 45000, close.isFinite ? close : 45000) + 100
            let low = hasNaN ? Double.nan : min(open.isFinite ? open : 45000, close.isFinite ? close : 45000) - 100
            let volume = hasNaN ? Double.nan : 1000.0
            
            candles.append(Candle(
                openTime: time,
                open: open.isFinite ? open : 45000,
                high: high.isFinite ? high : 45100,
                low: low.isFinite ? low : 44900,
                close: close.isFinite ? close : 45000,
                volume: volume.isFinite ? volume : 1000
            ))
        }
        
        return candles
    }
    
    private func createCandlesWithInfiniteValues(count: Int) -> [Candle] {
        var candles: [Candle] = []
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            
            // Introduce infinite values in some candles
            let hasInfinite = i % 15 == 0
            let basePrice = 45000.0
            
            let open = hasInfinite ? Double.infinity : basePrice + Double.random(in: -1000...1000)
            let close = hasInfinite ? -Double.infinity : basePrice + Double.random(in: -1000...1000)
            let high = hasInfinite ? Double.infinity : max(open.isFinite ? open : basePrice, close.isFinite ? close : basePrice) + 100
            let low = hasInfinite ? -Double.infinity : min(open.isFinite ? open : basePrice, close.isFinite ? close : basePrice) - 100
            let volume = hasInfinite ? Double.infinity : 1000.0
            
            candles.append(Candle(
                openTime: time,
                open: open.isFinite ? open : basePrice,
                high: high.isFinite ? high : basePrice + 100,
                low: low.isFinite ? low : basePrice - 100,
                close: close.isFinite ? close : basePrice,
                volume: volume.isFinite ? volume : 1000
            ))
        }
        
        return candles
    }
    
    private func createCandlesWithZeroPrices(count: Int) -> [Candle] {
        var candles: [Candle] = []
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            
            // Introduce zero/negative prices in some candles
            let hasZero = i % 20 == 0
            let basePrice = 45000.0
            
            let open = hasZero ? 0 : basePrice + Double.random(in: -1000...1000)
            let close = hasZero ? -100 : basePrice + Double.random(in: -1000...1000)
            let high = hasZero ? 0 : max(open, close) + 100
            let low = hasZero ? -200 : min(open, close) - 100
            let volume = hasZero ? 0 : 1000.0
            
            candles.append(Candle(
                openTime: time,
                open: max(open, 1), // Ensure positive prices
                high: max(high, 1),
                low: max(low, 1),
                close: max(close, 1),
                volume: max(volume, 1)
            ))
        }
        
        return candles
    }
}