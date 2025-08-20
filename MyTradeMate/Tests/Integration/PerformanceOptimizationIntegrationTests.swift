import XCTest
@testable import MyTradeMate

@MainActor
final class PerformanceOptimizationIntegrationTests: XCTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        // Reset all performance systems to default state
        PerformanceOptimizer.shared.enableOptimization(true)
        InferenceThrottler.shared.resetStatistics()
        DataCacheManager.shared.clearAllCaches()
    }
    
    override func tearDown() async throws {
        // Clean up after tests
        DataCacheManager.shared.clearAllCaches()
        try await super.tearDown()
    }
    
    func testMemoryPressureHandling() async throws {
        let memoryManager = MemoryPressureManager.shared
        let initialMemoryUsage = memoryManager.getCurrentMemoryUsage()
        
        // Simulate memory pressure
        NotificationCenter.default.post(
            name: .memoryPressureChanged,
            object: memoryManager,
            userInfo: ["level": MemoryPressureManager.MemoryPressureLevel.warning]
        )
        
        // Allow time for cleanup
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify that memory cleanup was triggered
        let postCleanupUsage = memoryManager.getCurrentMemoryUsage()
        
        // Memory usage should be same or lower after cleanup
        XCTAssertLessThanOrEqual(postCleanupUsage.usedMemoryMB, initialMemoryUsage.usedMemoryMB + 10) // Allow some variance
    }
    
    func testInferenceThrottling() async throws {
        let throttler = InferenceThrottler.shared
        
        // Set aggressive throttling
        throttler.setThrottleLevel(.aggressive)
        
        // First inference should be allowed
        XCTAssertTrue(throttler.shouldAllowInference())
        throttler.recordInference()
        
        // Immediate second inference should be throttled
        XCTAssertFalse(throttler.shouldAllowInference())
        
        // Reset to normal throttling
        throttler.setThrottleLevel(.realtime)
        XCTAssertTrue(throttler.shouldAllowInference())
    }
    
    func testConnectionManagerOptimization() async throws {
        let connectionManager = ConnectionManager.shared
        
        // Register a test connection
        connectionManager.registerConnection("test_connection", priority: .medium)
        
        // Test cellular optimization
        NotificationCenter.default.post(
            name: .optimizeForCellular,
            object: connectionManager,
            userInfo: ["maxConnections": 2, "updateInterval": 10.0]
        )
        
        // Allow time for processing
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Verify connection is still registered
        XCTAssertTrue(connectionManager.activeConnections.contains("test_connection"))
        
        // Clean up
        connectionManager.unregisterConnection("test_connection")
    }
    
    func testDataCachePerformance() async throws {
        let cacheManager = DataCacheManager.shared
        let cache = cacheManager.getCache(for: "test_cache", type: String.self)
        
        // Add test data
        cache.set("key1", value: "value1")
        cache.set("key2", value: "value2")
        
        // Verify data is cached
        XCTAssertEqual(cache.get("key1"), "value1")
        XCTAssertEqual(cache.get("key2"), "value2")
        
        // Test cache statistics
        let stats = cacheManager.cacheStats
        XCTAssertGreaterThan(stats.totalCaches, 0)
        XCTAssertGreaterThan(stats.totalItems, 0)
        
        // Test memory pressure cleanup
        NotificationCenter.default.post(
            name: .memoryPressureChanged,
            object: MemoryPressureManager.shared,
            userInfo: ["level": MemoryPressureManager.MemoryPressureLevel.critical]
        )
        
        // Allow time for cleanup
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify cleanup occurred
        let postCleanupStats = cacheManager.cacheStats
        XCTAssertLessThanOrEqual(postCleanupStats.totalItems, stats.totalItems)
    }
    
    func testPerformanceOptimizerIntegration() async throws {
        let optimizer = PerformanceOptimizer.shared
        
        // Enable optimization
        optimizer.enableOptimization(true)
        
        // Force optimization check
        optimizer.forceOptimizationCheck()
        
        // Get detailed metrics
        let metrics = optimizer.getDetailedMetrics()
        
        // Verify metrics are populated
        XCTAssertGreaterThanOrEqual(metrics.memoryUsage.usedMemoryMB, 0)
        XCTAssertTrue(metrics.isOptimizationEnabled)
        
        // Test optimization level changes
        optimizer.setOptimizationLevel(.battery)
        XCTAssertEqual(optimizer.currentOptimizationLevel, .battery)
        
        optimizer.setOptimizationLevel(.performance)
        XCTAssertEqual(optimizer.currentOptimizationLevel, .performance)
    }
    
    func testAIModelManagerPerformanceIntegration() async throws {
        let aiManager = AIModelManager.shared
        let throttler = InferenceThrottler.shared
        
        // Set aggressive throttling
        throttler.setThrottleLevel(.aggressive)
        
        // Generate test candles
        let testCandles = generateTestCandles(count: 100)
        
        // First prediction should work
        let result1 = await aiManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: testCandles,
            precision: false
        )
        
        XCTAssertFalse(result1.signal.isEmpty)
        
        // Immediate second prediction should be throttled
        let result2 = await aiManager.predict(
            symbol: "BTCUSDT",
            timeframe: .m5,
            candles: testCandles,
            precision: false
        )
        
        // In demo mode, should still get a result but might be throttled
        XCTAssertFalse(result2.signal.isEmpty)
        
        // If throttled, should have throttled metadata
        if result2.modelName == "THROTTLED" {
            XCTAssertEqual(result2.meta["throttled"], "true")
        }
    }
    
    func testMarketDataServiceCacheIntegration() async throws {
        let marketDataService = MarketDataService.shared
        
        // Clear existing data
        await marketDataService.clearOldData()
        
        // Fetch candles (should use cache)
        let candles1 = try await marketDataService.fetchCandles(symbol: "BTCUSDT", timeframe: .m5)
        XCTAssertFalse(candles1.isEmpty)
        
        // Fetch same candles again (should hit cache)
        let candles2 = try await marketDataService.fetchCandles(symbol: "BTCUSDT", timeframe: .m5)
        XCTAssertEqual(candles1.count, candles2.count)
        
        // Get performance metrics
        let metrics = marketDataService.getPerformanceMetrics()
        XCTAssertGreaterThan(metrics.fetchCount, 0)
        XCTAssertGreaterThan(metrics.cachedSymbols, 0)
    }
    
    // MARK: - Helper Methods
    
    private func generateTestCandles(count: Int) -> [Candle] {
        var candles: [Candle] = []
        let basePrice: Double = 45000
        let baseTime = Date().addingTimeInterval(-Double(count * 300)) // 5 minutes apart
        
        for i in 0..<count {
            let timestamp = baseTime.addingTimeInterval(Double(i * 300))
            let price = basePrice + Double.random(in: -1000...1000)
            
            candles.append(Candle(
                openTime: timestamp,
                open: price,
                high: price + Double.random(in: 0...500),
                low: price - Double.random(in: 0...500),
                close: price + Double.random(in: -200...200),
                volume: Double.random(in: 100...1000)
            ))
        }
        
        return candles
    }
}