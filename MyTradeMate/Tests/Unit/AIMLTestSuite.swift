import XCTest
import CoreML

/// Comprehensive AI/ML test suite that runs all AI/ML-related tests
/// This provides a convenient way to run all AI/ML tests together
final class AIMLTestSuite: XCTestCase {
    
    /// Test that verifies all AI/ML test classes are properly configured
    func testAllAIMLTestClassesExist() {
        // This test ensures all our AI/ML test classes are properly set up
        // and can be instantiated without errors
        
        let coreMLModelTests = CoreMLModelTests()
        let featurePreparationTests = FeaturePreparationTests()
        let predictionHandlingTests = PredictionHandlingTests()
        
        XCTAssertNotNil(coreMLModelTests)
        XCTAssertNotNil(featurePreparationTests)
        XCTAssertNotNil(predictionHandlingTests)
    }
    
    /// Performance test for AI/ML operations
    func testAIMLOperationsPerformance() async throws {
        let aiModelManager = AIModelManager.shared
        let featureBuilder = FeatureBuilder()
        
        // Preload models for performance testing
        await aiModelManager.preloadModels()
        
        // Create test data
        let candles = createPerformanceTestCandles(count: 200)
        
        // Measure performance of AI/ML operations
        measure {
            let expectation = XCTestExpectation(description: "AI/ML operations performance")
            
            Task {
                do {
                    // Feature building performance
                    let _ = try featureBuilder.buildFeatures(from: candles)
                    
                    // Model prediction performance
                    let _ = await aiModelManager.predict(
                        symbol: "BTCUSDT",
                        timeframe: .m5,
                        candles: candles,
                        precision: false
                    )
                    
                    expectation.fulfill()
                } catch {
                    XCTFail("AI/ML operations should not fail: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    /// Integration test that verifies the complete AI/ML pipeline
    func testCompleteAIMLPipeline() async throws {
        // This test verifies that all AI/ML components work together correctly
        // in a realistic AI/ML scenario
        
        let aiModelManager = AIModelManager.shared
        let featureBuilder = FeatureBuilder()
        
        // Step 1: Ensure models are loaded
        await aiModelManager.preloadModels()
        XCTAssertFalse(aiModelManager.models.isEmpty, "Should have loaded models")
        
        // Step 2: Validate models
        try await aiModelManager.validateModels()
        
        // Step 3: Create realistic market data
        let candles = createRealisticMarketData(count: 150)
        XCTAssertEqual(candles.count, 150)
        
        // Step 4: Build features from market data
        let features = try featureBuilder.buildFeatures(from: candles)
        XCTAssertEqual(features.count, 10, "Should build 10 features")
        
        // Verify features are valid
        for (index, feature) in features.enumerated() {
            XCTAssertTrue(feature.isFinite, "Feature \(index + 1) should be finite")
            XCTAssertFalse(feature.isNaN, "Feature \(index + 1) should not be NaN")
        }
        
        // Step 5: Generate prediction using features
        let prediction = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: false
        )
        
        // Verify prediction quality
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(prediction.signal))
        XCTAssertGreaterThanOrEqual(prediction.confidence, 0)
        XCTAssertLessThanOrEqual(prediction.confidence, 1)
        XCTAssertFalse(prediction.modelName.isEmpty)
        
        // Step 6: Test ensemble prediction (precision mode)
        let ensemblePrediction = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: true
        )
        
        XCTAssertEqual(ensemblePrediction.modelName, "Ensemble")
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(ensemblePrediction.signal))
        XCTAssertGreaterThanOrEqual(ensemblePrediction.confidence, 0)
        XCTAssertLessThanOrEqual(ensemblePrediction.confidence, 1)
    }
    
    /// Test AI/ML system resilience and error recovery
    func testAIMLSystemResilience() async throws {
        let aiModelManager = AIModelManager.shared
        let featureBuilder = FeatureBuilder()
        
        // Test 1: Handle insufficient data gracefully
        let insufficientCandles = createRealisticMarketData(count: 30)
        
        do {
            let _ = try featureBuilder.buildFeatures(from: insufficientCandles)
            XCTFail("Should throw error with insufficient candles")
        } catch {
            // Expected error - system should handle gracefully
        }
        
        let predictionWithInsufficientData = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: insufficientCandles,
            precision: false
        )
        
        XCTAssertEqual(predictionWithInsufficientData.signal, "HOLD")
        XCTAssertEqual(predictionWithInsufficientData.confidence, 0)
        
        // Test 2: Handle extreme market conditions
        let extremeCandles = createExtremeMarketConditions(count: 100)
        
        let featuresFromExtreme = try featureBuilder.buildFeatures(from: extremeCandles)
        XCTAssertEqual(featuresFromExtreme.count, 10)
        
        for feature in featuresFromExtreme {
            XCTAssertTrue(feature.isFinite, "Features should handle extreme conditions")
            XCTAssertFalse(feature.isNaN, "Features should not be NaN with extreme data")
        }
        
        let predictionFromExtreme = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: extremeCandles,
            precision: false
        )
        
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(predictionFromExtreme.signal))
        XCTAssertGreaterThanOrEqual(predictionFromExtreme.confidence, 0)
        XCTAssertLessThanOrEqual(predictionFromExtreme.confidence, 1)
        
        // Test 3: Model recovery after clearing cache
        aiModelManager.models.removeAll()
        XCTAssertTrue(aiModelManager.models.isEmpty)
        
        // Should be able to reload and predict
        let candles = createRealisticMarketData(count: 100)
        let recoveryPrediction = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: false
        )
        
        XCTAssertNotNil(recoveryPrediction)
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(recoveryPrediction.signal))
    }
    
    /// Test concurrent AI/ML operations
    func testConcurrentAIMLOperations() async throws {
        let aiModelManager = AIModelManager.shared
        let featureBuilder = FeatureBuilder()
        
        // Preload models
        await aiModelManager.preloadModels()
        
        let candles = createRealisticMarketData(count: 100)
        let concurrentCount = 5
        
        // Test concurrent feature building
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<concurrentCount {
                group.addTask {
                    do {
                        let features = try featureBuilder.buildFeatures(from: candles)
                        XCTAssertEqual(features.count, 10, "Concurrent feature building \(i) should work")
                        
                        for feature in features {
                            XCTAssertTrue(feature.isFinite, "Concurrent features should be finite")
                        }
                    } catch {
                        XCTFail("Concurrent feature building \(i) failed: \(error)")
                    }
                }
            }
        }
        
        // Test concurrent predictions
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<concurrentCount {
                group.addTask {
                    let prediction = await aiModelManager.predict(
                        symbol: "BTCUSDT",
                        timeframe: .m5,
                        candles: candles,
                        precision: false
                    )
                    
                    XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(prediction.signal), 
                                "Concurrent prediction \(i) should be valid")
                    XCTAssertGreaterThanOrEqual(prediction.confidence, 0)
                    XCTAssertLessThanOrEqual(prediction.confidence, 1)
                }
            }
        }
    }
    
    /// Test AI/ML system with different market scenarios
    func testAIMLWithDifferentMarketScenarios() async throws {
        let aiModelManager = AIModelManager.shared
        let featureBuilder = FeatureBuilder()
        
        await aiModelManager.preloadModels()
        
        // Test scenarios
        let scenarios = [
            ("Bull Market", createBullMarketData(count: 100)),
            ("Bear Market", createBearMarketData(count: 100)),
            ("Sideways Market", createSidewaysMarketData(count: 100)),
            ("Volatile Market", createVolatileMarketData(count: 100))
        ]
        
        for (scenarioName, candles) in scenarios {
            // Test feature building for each scenario
            let features = try featureBuilder.buildFeatures(from: candles)
            XCTAssertEqual(features.count, 10, "\(scenarioName): Should build 10 features")
            
            for (index, feature) in features.enumerated() {
                XCTAssertTrue(feature.isFinite, "\(scenarioName): Feature \(index + 1) should be finite")
                XCTAssertFalse(feature.isNaN, "\(scenarioName): Feature \(index + 1) should not be NaN")
            }
            
            // Test prediction for each scenario
            let prediction = await aiModelManager.predict(
                symbol: "BTCUSDT",
                timeframe: .m5,
                candles: candles,
                precision: false
            )
            
            XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(prediction.signal), 
                        "\(scenarioName): Should have valid signal")
            XCTAssertGreaterThanOrEqual(prediction.confidence, 0, 
                                      "\(scenarioName): Confidence should be >= 0")
            XCTAssertLessThanOrEqual(prediction.confidence, 1, 
                                   "\(scenarioName): Confidence should be <= 1")
            
            // Log scenario results for analysis
            print("\(scenarioName) - Signal: \(prediction.signal), Confidence: \(String(format: "%.3f", prediction.confidence))")
        }
    }
    
    /// Test AI/ML model validation and integrity
    func testAIMLModelValidationAndIntegrity() async throws {
        let aiModelManager = AIModelManager.shared
        
        // Load all models
        await aiModelManager.preloadModels()
        
        // Validate all models
        try await aiModelManager.validateModels()
        
        // Test each model individually
        for modelKind in [ModelKind.m5, .h1, .h4] {
            let model = try await aiModelManager.loadModel(kind: modelKind)
            
            // Verify model structure
            let inputDescriptions = model.modelDescription.inputDescriptionsByName
            let outputDescriptions = model.modelDescription.outputDescriptionsByName
            
            XCTAssertFalse(inputDescriptions.isEmpty, "\(modelKind.modelName) should have inputs")
            XCTAssertFalse(outputDescriptions.isEmpty, "\(modelKind.modelName) should have outputs")
            
            // Test model prediction capability
            let testCandles = Array(0..<100).map { Double($0) }
            let result = try await aiModelManager.predict(kind: modelKind, candles: testCandles)
            
            XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(result.signal), 
                        "\(modelKind.modelName) should produce valid signals")
            XCTAssertEqual(result.modelName, modelKind.modelName)
        }
    }
    
    /// Test AI/ML system memory management
    func testAIMLMemoryManagement() async throws {
        let aiModelManager = AIModelManager.shared
        
        // Test model loading and unloading
        let initialModelCount = aiModelManager.models.count
        
        // Load models
        await aiModelManager.preloadModels()
        let loadedCount = aiModelManager.models.count
        XCTAssertGreaterThan(loadedCount, initialModelCount)
        
        // Clear models
        aiModelManager.models.removeAll()
        XCTAssertEqual(aiModelManager.models.count, 0)
        
        // Verify we can reload
        let model = try await aiModelManager.loadModel(kind: .m5)
        XCTAssertNotNil(model)
        
        // Test feature building memory efficiency
        let largeDataset = createRealisticMarketData(count: 1000)
        let featureBuilder = FeatureBuilder()
        
        // Should handle large datasets without memory issues
        let features = try featureBuilder.buildFeatures(from: largeDataset)
        XCTAssertEqual(features.count, 10)
        
        // Features should be released after use
        // (We can't directly test memory release, but ensure no crashes)
    }
}

// MARK: - AI/ML Test Utilities

/// Utility class for setting up AI/ML test data and common test scenarios
final class AIMLTestUtilities {
    
    /// Creates realistic market data for testing
    static func createRealisticMarketData(count: Int, basePrice: Double = 45000) -> [Candle] {
        var candles: [Candle] = []
        var currentPrice = basePrice
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            
            // Realistic price movement
            let trendFactor = sin(Double(i) * 0.01) * 0.0005
            let volatilityFactor = Double.random(in: -0.01...0.01)
            let priceChange = (trendFactor + volatilityFactor) * currentPrice
            
            currentPrice += priceChange
            currentPrice = max(currentPrice, 1000)
            
            let open = currentPrice + Double.random(in: -currentPrice * 0.002...currentPrice * 0.002)
            let close = currentPrice + Double.random(in: -currentPrice * 0.002...currentPrice * 0.002)
            let high = max(open, close) + Double.random(in: 0...currentPrice * 0.005)
            let low = min(open, close) - Double.random(in: 0...currentPrice * 0.005)
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
    
    /// Creates bull market scenario data
    static func createBullMarketData(count: Int) -> [Candle] {
        var candles: [Candle] = []
        let startPrice = 40000.0
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            let price = startPrice * pow(1.001, Double(i)) // 0.1% growth per period
            let noise = Double.random(in: -price * 0.01...price * 0.01)
            
            let open = price + noise
            let close = price + noise + Double.random(in: 0...price * 0.005) // Slight upward bias
            let high = max(open, close) + Double.random(in: 0...price * 0.01)
            let low = min(open, close) - Double.random(in: 0...price * 0.005)
            let volume = 1000 + Double.random(in: -200...400) // Higher volume in bull market
            
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
    
    /// Creates bear market scenario data
    static func createBearMarketData(count: Int) -> [Candle] {
        var candles: [Candle] = []
        let startPrice = 50000.0
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            let price = startPrice * pow(0.999, Double(i)) // -0.1% decline per period
            let noise = Double.random(in: -price * 0.01...price * 0.01)
            
            let open = price + noise
            let close = price + noise - Double.random(in: 0...price * 0.005) // Slight downward bias
            let high = max(open, close) + Double.random(in: 0...price * 0.005)
            let low = min(open, close) - Double.random(in: 0...price * 0.01)
            let volume = 1200 + Double.random(in: -300...300) // Higher volume in bear market
            
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
    
    /// Creates sideways market scenario data
    static func createSidewaysMarketData(count: Int) -> [Candle] {
        var candles: [Candle] = []
        let basePrice = 45000.0
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            let price = basePrice + sin(Double(i) * 0.1) * 500 // Oscillation around base price
            let noise = Double.random(in: -price * 0.005...price * 0.005)
            
            let open = price + noise
            let close = price + noise + Double.random(in: -price * 0.003...price * 0.003)
            let high = max(open, close) + Double.random(in: 0...price * 0.005)
            let low = min(open, close) - Double.random(in: 0...price * 0.005)
            let volume = 800 + Double.random(in: -200...200) // Lower volume in sideways market
            
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
    
    /// Creates volatile market scenario data
    static func createVolatileMarketData(count: Int) -> [Candle] {
        var candles: [Candle] = []
        let basePrice = 45000.0
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            let volatility = 0.03 // 3% volatility
            let priceChange = Double.random(in: -volatility...volatility) * basePrice
            let price = basePrice + priceChange
            
            let open = price + Double.random(in: -price * 0.02...price * 0.02)
            let close = price + Double.random(in: -price * 0.02...price * 0.02)
            let high = max(open, close) + Double.random(in: 0...price * 0.03)
            let low = min(open, close) - Double.random(in: 0...price * 0.03)
            let volume = 1500 + Double.random(in: -500...500) // High volume in volatile market
            
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
    
    /// Creates extreme market conditions for stress testing
    static func createExtremeMarketConditions(count: Int) -> [Candle] {
        var candles: [Candle] = []
        let basePrice = 45000.0
        
        for i in 0..<count {
            let time = Date().addingTimeInterval(-Double(count - i) * 300)
            
            // Extreme volatility with occasional flash crashes/spikes
            let extremeEvent = i % 20 == 0 // 5% chance of extreme event
            let volatility = extremeEvent ? 0.2 : 0.05 // 20% vs 5% volatility
            
            let priceMultiplier = 1 + Double.random(in: -volatility...volatility)
            let price = basePrice * priceMultiplier
            
            let open = price + Double.random(in: -price * 0.05...price * 0.05)
            let close = price + Double.random(in: -price * 0.05...price * 0.05)
            let high = max(open, close) + Double.random(in: 0...price * 0.1)
            let low = min(open, close) - Double.random(in: 0...price * 0.1)
            let volume = extremeEvent ? 5000 : 1000 // High volume during extreme events
            
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

// MARK: - Test Extensions

extension AIMLTestSuite {
    
    private func createPerformanceTestCandles(count: Int) -> [Candle] {
        return AIMLTestUtilities.createRealisticMarketData(count: count)
    }
    
    private func createRealisticMarketData(count: Int) -> [Candle] {
        return AIMLTestUtilities.createRealisticMarketData(count: count)
    }
    
    private func createExtremeMarketConditions(count: Int) -> [Candle] {
        return AIMLTestUtilities.createExtremeMarketConditions(count: count)
    }
    
    private func createBullMarketData(count: Int) -> [Candle] {
        return AIMLTestUtilities.createBullMarketData(count: count)
    }
    
    private func createBearMarketData(count: Int) -> [Candle] {
        return AIMLTestUtilities.createBearMarketData(count: count)
    }
    
    private func createSidewaysMarketData(count: Int) -> [Candle] {
        return AIMLTestUtilities.createSidewaysMarketData(count: count)
    }
    
    private func createVolatileMarketData(count: Int) -> [Candle] {
        return AIMLTestUtilities.createVolatileMarketData(count: count)
    }
}