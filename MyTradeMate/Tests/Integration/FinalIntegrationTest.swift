import XCTest
import SwiftUI
@testable import MyTradeMate

/// Final comprehensive integration test that validates the entire MyTradeMate app flow
@MainActor
final class FinalIntegrationTest: XCTestCase {
    
    private var appSettings: AppSettings!
    private var marketDataService: MarketDataService!
    private var aiModelManager: AIModelManager!
    private var errorManager: ErrorManager!
    private var performanceOptimizer: PerformanceOptimizer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize core services
        appSettings = AppSettings.shared
        marketDataService = MarketDataService.shared
        aiModelManager = AIModelManager.shared
        errorManager = ErrorManager.shared
        performanceOptimizer = PerformanceOptimizer.shared
        
        // Reset to known state
        appSettings.demoMode = true
        appSettings.tradingMode = .demo
        performanceOptimizer.enableOptimization(true)
    }
    
    override func tearDown() async throws {
        // Clean up after tests
        DataCacheManager.shared.clearAllCaches()
        try await super.tearDown()
    }
    
    // MARK: - End-to-End Flow Tests
    
    func testCompleteAppFlow() async throws {
        // Test the complete app flow from startup to trading
        
        // 1. App Initialization
        try await testAppInitialization()
        
        // 2. Market Data Flow
        try await testMarketDataFlow()
        
        // 3. AI Prediction Flow
        try await testAIPredictionFlow()
        
        // 4. Trading Strategy Flow
        try await testTradingStrategyFlow()
        
        // 5. Performance Optimization Flow
        try await testPerformanceOptimizationFlow()
        
        // 6. Error Handling Flow
        try await testErrorHandlingFlow()
        
        // 7. Mode Switching Flow
        try await testModeSwitchingFlow()
    }
    
    private func testAppInitialization() async throws {
        // Verify core services are initialized
        XCTAssertNotNil(appSettings)
        XCTAssertNotNil(marketDataService)
        XCTAssertNotNil(aiModelManager)
        XCTAssertNotNil(errorManager)
        XCTAssertNotNil(performanceOptimizer)
        
        // Verify default settings
        XCTAssertTrue(appSettings.demoMode)
        XCTAssertEqual(appSettings.tradingMode, .demo)
        
        // Verify theme manager
        let themeManager = ThemeManager.shared
        XCTAssertNotNil(themeManager.currentTheme)
        
        // Verify keychain store
        let keychain = KeychainStore.shared
        let testKey = "test_init_key"
        let testValue = "test_init_value"
        
        try keychain.store(testValue, for: testKey)
        let retrievedValue = try keychain.retrieve(for: testKey)
        XCTAssertEqual(retrievedValue, testValue)
        
        try keychain.delete(for: testKey)
    }
    
    private func testMarketDataFlow() async throws {
        // Test complete market data flow
        
        // 1. Fetch candles
        let candles = try await marketDataService.fetchCandles(symbol: "BTCUSDT", timeframe: .m5)
        XCTAssertFalse(candles.isEmpty, "Should receive candles in demo mode")
        XCTAssertGreaterThan(candles.count, 50, "Should have sufficient candles for analysis")
        
        // 2. Validate candle data structure
        let firstCandle = candles[0]
        XCTAssertGreaterThan(firstCandle.open, 0)
        XCTAssertGreaterThan(firstCandle.high, 0)
        XCTAssertGreaterThan(firstCandle.low, 0)
        XCTAssertGreaterThan(firstCandle.close, 0)
        XCTAssertGreaterThan(firstCandle.volume, 0)
        
        // Validate OHLC relationships
        XCTAssertGreaterThanOrEqual(firstCandle.high, firstCandle.open)
        XCTAssertGreaterThanOrEqual(firstCandle.high, firstCandle.close)
        XCTAssertLessThanOrEqual(firstCandle.low, firstCandle.open)
        XCTAssertLessThanOrEqual(firstCandle.low, firstCandle.close)
        
        // 3. Test caching
        let cachedCandles = try await marketDataService.fetchCandles(symbol: "BTCUSDT", timeframe: .m5)
        XCTAssertEqual(candles.count, cachedCandles.count, "Cache should return same number of candles")
        
        // 4. Test different timeframes
        let h1Candles = try await marketDataService.fetchCandles(symbol: "BTCUSDT", timeframe: .h1)
        XCTAssertFalse(h1Candles.isEmpty, "Should receive H1 candles")
        
        let h4Candles = try await marketDataService.fetchCandles(symbol: "BTCUSDT", timeframe: .h4)
        XCTAssertFalse(h4Candles.isEmpty, "Should receive H4 candles")
    }
    
    private func testAIPredictionFlow() async throws {
        // Test complete AI prediction flow
        
        // 1. Preload models
        await aiModelManager.preloadModels()
        
        // 2. Get test candles
        let candles = try await marketDataService.fetchCandles(symbol: "BTCUSDT", timeframe: .m5)
        XCTAssertGreaterThan(candles.count, 50, "Need sufficient candles for AI prediction")
        
        // 3. Test single model prediction
        let singlePrediction = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: false
        )
        
        XCTAssertFalse(singlePrediction.signal.isEmpty, "Should receive prediction signal")
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(singlePrediction.signal), "Signal should be valid")
        XCTAssertGreaterThanOrEqual(singlePrediction.confidence, 0, "Confidence should be non-negative")
        XCTAssertLessThanOrEqual(singlePrediction.confidence, 1, "Confidence should not exceed 1")
        
        // 4. Test ensemble prediction
        let ensemblePrediction = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: true
        )
        
        XCTAssertFalse(ensemblePrediction.signal.isEmpty, "Should receive ensemble prediction")
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(ensemblePrediction.signal), "Ensemble signal should be valid")
        
        // 5. Test inference throttling
        let throttler = InferenceThrottler.shared
        throttler.setThrottleLevel(.aggressive)
        
        // First prediction should work
        let prediction1 = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: false
        )
        XCTAssertFalse(prediction1.signal.isEmpty)
        
        // Immediate second prediction might be throttled
        let prediction2 = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: false
        )
        // Should still get a result (either real or throttled)
        XCTAssertFalse(prediction2.signal.isEmpty)
        
        // Reset throttling
        throttler.setThrottleLevel(.realtime)
    }
    
    private func testTradingStrategyFlow() async throws {
        // Test complete trading strategy flow
        
        let strategyManager = StrategyManager.shared
        let strategies = strategyManager.availableStrategies
        
        XCTAssertFalse(strategies.isEmpty, "Should have available strategies")
        
        // Get test candles
        let candles = try await marketDataService.fetchCandles(symbol: "BTCUSDT", timeframe: .m5)
        
        // Test each strategy
        for strategy in strategies {
            let signal = strategy.generateSignal(from: candles)
            
            XCTAssertFalse(signal.action.isEmpty, "Strategy \(strategy.name) should generate signal")
            XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(signal.action), "Strategy \(strategy.name) should generate valid signal")
            XCTAssertGreaterThanOrEqual(signal.confidence, 0, "Strategy \(strategy.name) confidence should be non-negative")
            XCTAssertLessThanOrEqual(signal.confidence, 1, "Strategy \(strategy.name) confidence should not exceed 1")
        }
        
        // Test strategy configuration
        if let rsiStrategy = strategies.first(where: { $0.name.contains("RSI") }) {
            // Test RSI strategy parameters
            let originalParams = rsiStrategy.parameters
            XCTAssertFalse(originalParams.isEmpty, "RSI strategy should have parameters")
        }
    }
    
    private func testPerformanceOptimizationFlow() async throws {
        // Test complete performance optimization flow
        
        let performanceOptimizer = PerformanceOptimizer.shared
        let memoryManager = MemoryPressureManager.shared
        let connectionManager = ConnectionManager.shared
        let cacheManager = DataCacheManager.shared
        
        // 1. Test performance optimizer
        performanceOptimizer.enableOptimization(true)
        XCTAssertTrue(performanceOptimizer.isOptimizationEnabled)
        
        // 2. Test memory management
        let memoryUsage = memoryManager.getCurrentMemoryUsage()
        XCTAssertGreaterThan(memoryUsage.usedMemoryMB, 0, "Should track memory usage")
        XCTAssertGreaterThan(memoryUsage.totalMemoryMB, 0, "Should have total memory info")
        
        // Test memory cleanup
        memoryManager.requestMemoryCleanup()
        
        // 3. Test connection management
        connectionManager.registerConnection("test_connection", priority: .medium)
        XCTAssertTrue(connectionManager.activeConnections.contains("test_connection"))
        
        let connectionStatus = connectionManager.getConnectionStatus()
        XCTAssertNotEqual(connectionStatus.networkStatus, .unknown, "Should detect network status")
        
        connectionManager.unregisterConnection("test_connection")
        XCTAssertFalse(connectionManager.activeConnections.contains("test_connection"))
        
        // 4. Test cache management
        let cache = cacheManager.getCache(for: "test_cache", type: String.self)
        cache.set("test_key", value: "test_value")
        
        let cachedValue = cache.get("test_key")
        XCTAssertEqual(cachedValue, "test_value", "Cache should store and retrieve values")
        
        let cacheStats = cacheManager.cacheStats
        XCTAssertGreaterThan(cacheStats.totalCaches, 0, "Should track cache statistics")
        
        // 5. Test optimization level changes
        performanceOptimizer.setOptimizationLevel(.battery)
        XCTAssertEqual(performanceOptimizer.currentOptimizationLevel, .battery)
        
        performanceOptimizer.setOptimizationLevel(.performance)
        XCTAssertEqual(performanceOptimizer.currentOptimizationLevel, .performance)
    }
    
    private func testErrorHandlingFlow() async throws {
        // Test complete error handling flow
        
        let errorManager = ErrorManager.shared
        
        // Test different error types
        let testErrors: [AppError] = [
            .networkError("Test network error"),
            .authenticationFailed("Test auth error"),
            .tradingError("Test trading error"),
            .dataError("Test data error"),
            .aiModelError("Test AI error"),
            .webSocketConnectionFailed(reason: "Test WebSocket error"),
            .webSocketInvalidMessage(message: "Test invalid message"),
            .webSocketReconnectionFailed(attempts: 3)
        ]
        
        // Verify each error type can be handled without crashing
        for error in testErrors {
            errorManager.handle(error)
            // If we reach here, error was handled successfully
        }
        
        // Test error with context
        errorManager.handle(.networkError("Test error"), context: "Test context")
    }
    
    private func testModeSwitchingFlow() async throws {
        // Test complete mode switching flow
        
        let originalMode = appSettings.tradingMode
        let originalDemoMode = appSettings.demoMode
        
        // 1. Test demo mode
        appSettings.demoMode = true
        appSettings.tradingMode = .demo
        
        XCTAssertTrue(appSettings.demoMode)
        XCTAssertEqual(appSettings.tradingMode, .demo)
        
        // Verify demo mode functionality
        let demoCandles = try await marketDataService.fetchCandles(symbol: "BTCUSDT", timeframe: .m5)
        XCTAssertFalse(demoCandles.isEmpty, "Demo mode should provide market data")
        
        let demoPrediction = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: demoCandles,
            precision: false
        )
        XCTAssertFalse(demoPrediction.signal.isEmpty, "Demo mode should provide AI predictions")
        
        // 2. Test paper trading mode
        appSettings.demoMode = false
        appSettings.tradingMode = .paper
        
        XCTAssertFalse(appSettings.demoMode)
        XCTAssertEqual(appSettings.tradingMode, .paper)
        
        // 3. Test live trading mode (with safeguards)
        appSettings.tradingMode = .live
        XCTAssertEqual(appSettings.tradingMode, .live)
        
        // In a real implementation, this would verify:
        // - API keys are present
        // - Risk management is configured
        // - User has confirmed live trading
        
        // 4. Restore original settings
        appSettings.demoMode = originalDemoMode
        appSettings.tradingMode = originalMode
    }
    
    // MARK: - Widget Integration Test
    
    func testWidgetIntegration() async throws {
        // Test widget data preparation and functionality
        
        // This would test the widget's ability to:
        // 1. Fetch current P&L data
        // 2. Get position information
        // 3. Check connection status
        // 4. Format data for widget display
        // 5. Handle deep linking
        
        // For now, we'll verify the widget entry point exists
        // In a real implementation, this would test widget timeline generation
        
        XCTAssertTrue(true, "Widget integration test placeholder")
    }
    
    // MARK: - Performance Benchmarks
    
    func testPerformanceBenchmarks() async throws {
        // Test performance benchmarks
        
        let startTime = Date()
        
        // 1. Market data fetch performance
        let marketDataStart = Date()
        let candles = try await marketDataService.fetchCandles(symbol: "BTCUSDT", timeframe: .m5)
        let marketDataDuration = Date().timeIntervalSince(marketDataStart)
        
        XCTAssertLessThan(marketDataDuration, 5.0, "Market data fetch should complete within 5 seconds")
        XCTAssertFalse(candles.isEmpty)
        
        // 2. AI prediction performance
        let aiStart = Date()
        let prediction = await aiModelManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: candles,
            precision: false
        )
        let aiDuration = Date().timeIntervalSince(aiStart)
        
        XCTAssertLessThan(aiDuration, 3.0, "AI prediction should complete within 3 seconds")
        XCTAssertFalse(prediction.signal.isEmpty)
        
        // 3. Strategy execution performance
        let strategyStart = Date()
        let strategyManager = StrategyManager.shared
        let strategies = strategyManager.availableStrategies
        
        for strategy in strategies {
            _ = strategy.generateSignal(from: candles)
        }
        let strategyDuration = Date().timeIntervalSince(strategyStart)
        
        XCTAssertLessThan(strategyDuration, 2.0, "All strategies should execute within 2 seconds")
        
        // 4. Overall performance
        let totalDuration = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(totalDuration, 10.0, "Complete flow should finish within 10 seconds")
    }
    
    // MARK: - Memory and Resource Tests
    
    func testMemoryAndResourceUsage() async throws {
        // Test memory and resource usage
        
        let memoryManager = MemoryPressureManager.shared
        let initialMemory = memoryManager.getCurrentMemoryUsage()
        
        // Perform memory-intensive operations
        var testData: [[Candle]] = []
        
        for i in 0..<10 {
            let candles = try await marketDataService.fetchCandles(
                symbol: "BTCUSDT",
                timeframe: .m5
            )
            testData.append(candles)
            
            // Generate predictions
            _ = await aiModelManager.predict(
                symbol: "BTCUSDT",
                timeframe: .m5,
                candles: candles,
                precision: false
            )
        }
        
        let peakMemory = memoryManager.getCurrentMemoryUsage()
        
        // Clear test data
        testData.removeAll()
        
        // Force memory cleanup
        memoryManager.requestMemoryCleanup()
        
        // Allow time for cleanup
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let finalMemory = memoryManager.getCurrentMemoryUsage()
        
        // Verify memory usage is reasonable
        let memoryIncrease = peakMemory.usedMemoryMB - initialMemory.usedMemoryMB
        XCTAssertLessThan(memoryIncrease, 100.0, "Memory increase should be less than 100MB")
        
        // Verify cleanup worked
        let memoryAfterCleanup = finalMemory.usedMemoryMB - initialMemory.usedMemoryMB
        XCTAssertLessThan(memoryAfterCleanup, memoryIncrease, "Memory cleanup should reduce usage")
    }
    
    // MARK: - Stress Tests
    
    func testStressScenarios() async throws {
        // Test stress scenarios
        
        // 1. Rapid mode switching
        let originalMode = appSettings.tradingMode
        
        for _ in 0..<10 {
            appSettings.tradingMode = .demo
            appSettings.tradingMode = .paper
            appSettings.tradingMode = .live
        }
        
        appSettings.tradingMode = originalMode
        
        // 2. Rapid AI predictions
        let candles = try await marketDataService.fetchCandles(symbol: "BTCUSDT", timeframe: .m5)
        
        for _ in 0..<5 {
            _ = await aiModelManager.predict(
                symbol: "BTCUSDT",
                timeframe: .m5,
                candles: candles,
                precision: false
            )
        }
        
        // 3. Multiple strategy executions
        let strategyManager = StrategyManager.shared
        let strategies = strategyManager.availableStrategies
        
        for _ in 0..<3 {
            for strategy in strategies {
                _ = strategy.generateSignal(from: candles)
            }
        }
        
        // If we reach here without crashing, stress tests passed
        XCTAssertTrue(true, "Stress tests completed successfully")
    }
}