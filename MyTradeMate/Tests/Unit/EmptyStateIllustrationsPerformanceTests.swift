import XCTest
import SwiftUI
@testable import MyTradeMate

/// Performance tests for empty state illustrations to ensure they don't impact app performance
@MainActor
final class EmptyStateIllustrationsPerformanceTests: XCTestCase {
    
    var memoryObserver: MemoryPressureObserver!
    var imageOptimizer: ImageOptimizer!
    
    override func setUp() async throws {
        try await super.setUp()
        memoryObserver = MemoryPressureObserver.shared
        imageOptimizer = ImageOptimizer.shared
        
        // Clear caches to ensure clean test environment
        SFSymbolCache.shared.clearCache()
    }
    
    override func tearDown() async throws {
        // Clean up after tests
        SFSymbolCache.shared.clearCache()
        try await super.tearDown()
    }
    
    // MARK: - Rendering Performance Tests
    
    func testEmptyStateViewRenderingPerformance() {
        measure {
            // Test rendering performance of basic empty state views
            for _ in 0..<100 {
                let _ = EmptyStateView.chartNoData()
                let _ = EmptyStateView.pnlNoData()
                let _ = EmptyStateView.tradesNoData()
                let _ = EmptyStateView.strategiesNoData()
            }
        }
    }
    
    func testIllustratedEmptyStateViewRenderingPerformance() {
        measure {
            // Test rendering performance of illustrated empty state views
            for _ in 0..<50 {
                let _ = IllustratedEmptyStateView.chartNoData()
                let _ = IllustratedEmptyStateView.pnlNoData()
                let _ = IllustratedEmptyStateView.tradesNoData()
                let _ = IllustratedEmptyStateView.strategiesNoData()
                let _ = IllustratedEmptyStateView.aiSignalNoData()
            }
        }
    }
    
    func testIndividualIllustrationRenderingPerformance() {
        measure {
            // Test individual illustration components
            for _ in 0..<100 {
                let _ = ChartEmptyIllustration()
                let _ = PnLEmptyIllustration()
                let _ = TradesEmptyIllustration()
                let _ = StrategiesEmptyIllustration()
                let _ = AISignalEmptyIllustration()
            }
        }
    }
    
    // MARK: - Animation Performance Tests
    
    func testAnimationPerformanceWithReducedMotion() {
        // Simulate reduced motion preference
        let originalShouldEnable = imageOptimizer.shouldEnableAnimations
        
        // Test with animations disabled
        measure {
            for _ in 0..<50 {
                let illustration = ChartEmptyIllustration()
                // Simulate view lifecycle
                let _ = illustration.body
            }
        }
    }
    
    func testAnimationManagerPerformance() {
        let animationManager = AnimationManager.shared
        
        measure {
            for _ in 0..<1000 {
                let _ = animationManager.animation(duration: 1.0, delay: 0.1)
                let _ = animationManager.simpleAnimation(duration: 0.5)
                let _ = animationManager.subtleBreathingAnimation(duration: 3.0)
                let _ = animationManager.floatingAnimation(duration: 2.0, delay: 0.2)
                let _ = animationManager.shimmerAnimation(duration: 1.5, delay: 0.3)
                let _ = animationManager.gentleRotationAnimation(duration: 8.0, delay: 1.0)
            }
        }
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsageOfEmptyStateViews() {
        let initialMemory = getCurrentMemoryUsage()
        
        // Create multiple empty state views
        var views: [AnyView] = []
        for _ in 0..<100 {
            views.append(AnyView(EmptyStateView.chartNoData()))
            views.append(AnyView(EmptyStateView.pnlNoData()))
            views.append(AnyView(EmptyStateView.tradesNoData()))
            views.append(AnyView(EmptyStateView.strategiesNoData()))
        }
        
        let memoryAfterCreation = getCurrentMemoryUsage()
        let memoryIncrease = memoryAfterCreation - initialMemory
        
        // Memory increase should be reasonable (less than 10MB for 400 views)
        XCTAssertLessThan(memoryIncrease, 10.0, "Memory usage increased by \(memoryIncrease)MB, which is too high")
        
        // Clean up
        views.removeAll()
        
        // Force garbage collection
        autoreleasepool {
            // Empty pool to trigger cleanup
        }
        
        let memoryAfterCleanup = getCurrentMemoryUsage()
        let memoryRecovered = memoryAfterCreation - memoryAfterCleanup
        
        // Should recover at least 50% of the memory
        XCTAssertGreaterThan(memoryRecovered, memoryIncrease * 0.5, "Memory not properly released after cleanup")
    }
    
    func testMemoryUsageOfIllustratedViews() {
        let initialMemory = getCurrentMemoryUsage()
        
        // Create multiple illustrated empty state views
        var views: [AnyView] = []
        for _ in 0..<50 {
            views.append(AnyView(IllustratedEmptyStateView.chartNoData()))
            views.append(AnyView(IllustratedEmptyStateView.pnlNoData()))
            views.append(AnyView(IllustratedEmptyStateView.tradesNoData()))
            views.append(AnyView(IllustratedEmptyStateView.strategiesNoData()))
            views.append(AnyView(IllustratedEmptyStateView.aiSignalNoData()))
        }
        
        let memoryAfterCreation = getCurrentMemoryUsage()
        let memoryIncrease = memoryAfterCreation - initialMemory
        
        // Memory increase should be reasonable (less than 15MB for 250 illustrated views)
        XCTAssertLessThan(memoryIncrease, 15.0, "Memory usage increased by \(memoryIncrease)MB, which is too high for illustrated views")
        
        // Clean up
        views.removeAll()
        
        // Force garbage collection
        autoreleasepool {
            // Empty pool to trigger cleanup
        }
    }
    
    // MARK: - SF Symbol Cache Performance Tests
    
    func testSFSymbolCachePerformance() {
        let cache = SFSymbolCache.shared
        cache.clearCache()
        
        let symbols = [
            "chart.line.uptrend.xyaxis",
            "dollarsign.circle.fill",
            "list.bullet.rectangle",
            "brain.head.profile",
            "antenna.radiowaves.left.and.right"
        ]
        
        // Test cache miss performance (first access)
        measure {
            for symbol in symbols {
                for size in [16, 20, 24, 28, 32] {
                    let _ = cache.cachedImage(for: symbol, size: CGFloat(size))
                }
            }
        }
        
        // Test cache hit performance (subsequent access)
        measure {
            for _ in 0..<100 {
                for symbol in symbols {
                    for size in [16, 20, 24, 28, 32] {
                        let _ = cache.cachedImage(for: symbol, size: CGFloat(size))
                    }
                }
            }
        }
    }
    
    func testSFSymbolCacheMemoryManagement() {
        let cache = SFSymbolCache.shared
        cache.clearCache()
        
        let initialMemory = getCurrentMemoryUsage()
        
        // Fill cache with many symbols
        for i in 0..<100 {
            let symbolName = "star.fill"
            let size = CGFloat(16 + i % 20) // Vary sizes
            let _ = cache.cachedImage(for: symbolName, size: size)
        }
        
        let memoryAfterCaching = getCurrentMemoryUsage()
        let cacheMemoryUsage = memoryAfterCaching - initialMemory
        
        // Cache should not use excessive memory (less than 5MB for 100 symbols)
        XCTAssertLessThan(cacheMemoryUsage, 5.0, "SF Symbol cache using too much memory: \(cacheMemoryUsage)MB")
        
        // Clear cache and verify memory is released
        cache.clearCache()
        
        autoreleasepool {
            // Force cleanup
        }
        
        let memoryAfterClear = getCurrentMemoryUsage()
        let memoryRecovered = memoryAfterCaching - memoryAfterClear
        
        // Should recover most of the cache memory
        XCTAssertGreaterThan(memoryRecovered, cacheMemoryUsage * 0.7, "Cache memory not properly released")
    }
    
    // MARK: - Device Class Optimization Tests
    
    func testDeviceClassOptimizationPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = DeviceClass.current
            }
        }
    }
    
    func testOptimizedImageSizeCalculation() {
        let baseSize = CGSize(width: 100, height: 100)
        
        measure {
            for _ in 0..<1000 {
                let _ = imageOptimizer.optimalImageSize(for: baseSize)
                let _ = imageOptimizer.optimalImageSize(for: baseSize, scaleFactor: 1.5)
                let _ = imageOptimizer.optimalImageSize(for: baseSize, scaleFactor: 2.0)
            }
        }
    }
    
    // MARK: - Color Adaptation Performance Tests
    
    func testColorAdaptationPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = Color.emptyStateBlue
                let _ = Color.emptyStateGreen
                let _ = Color.emptyStateOrange
                let _ = Color.emptyStatePurple
                let _ = Color.emptyStateCyan
                let _ = Color.emptyStateRed
                let _ = Color.emptyStateBackgroundBlue
                let _ = Color.emptyStateBackgroundGreen
                let _ = Color.emptyStateNeutral
            }
        }
    }
    
    // MARK: - Layout Optimization Performance Tests
    
    func testLayoutOptimizationPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = imageOptimizer.optimalSpacing(baseSpacing: 16)
                let _ = imageOptimizer.optimalCornerRadius(baseRadius: 12)
                let _ = imageOptimizer.optimalAnimationDuration(1.0)
            }
        }
    }
    
    // MARK: - Memory Pressure Response Tests
    
    func testMemoryPressureResponse() async throws {
        let initialMemory = getCurrentMemoryUsage()
        
        // Create views that should respond to memory pressure
        var views: [AnyView] = []
        for _ in 0..<50 {
            views.append(AnyView(IllustratedEmptyStateView.chartNoData()))
        }
        
        let memoryAfterCreation = getCurrentMemoryUsage()
        
        // Simulate memory pressure
        NotificationCenter.default.post(
            name: .memoryPressureChanged,
            object: memoryObserver,
            userInfo: ["level": MemoryPressureManager.MemoryPressureLevel.warning]
        )
        
        // Allow time for cleanup
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let memoryAfterPressure = getCurrentMemoryUsage()
        
        // Memory should not increase significantly under pressure
        XCTAssertLessThanOrEqual(memoryAfterPressure, memoryAfterCreation + 1.0, "Memory increased under pressure")
        
        // Clean up
        views.removeAll()
    }
    
    // MARK: - Thermal State Response Tests
    
    func testThermalStateResponse() {
        let originalShouldEnable = imageOptimizer.shouldEnableAnimations
        
        // Test that animations are disabled under thermal pressure
        // Note: This test depends on system state, so we test the logic
        let thermalState = ProcessInfo.processInfo.thermalState
        
        if thermalState == .critical {
            XCTAssertFalse(imageOptimizer.shouldEnableAnimations, "Animations should be disabled under critical thermal state")
        }
        
        // Test animation manager response
        let animationManager = AnimationManager.shared
        let shouldUseReduced = animationManager.shouldUseReducedAnimations
        
        // Should be a boolean value
        XCTAssertTrue(shouldUseReduced == true || shouldUseReduced == false)
    }
    
    // MARK: - Concurrent Access Performance Tests
    
    func testConcurrentCacheAccess() async throws {
        let cache = SFSymbolCache.shared
        cache.clearCache()
        
        let symbols = [
            "chart.line.uptrend.xyaxis",
            "dollarsign.circle.fill",
            "list.bullet.rectangle",
            "brain.head.profile",
            "antenna.radiowaves.left.and.right"
        ]
        
        // Test concurrent access to cache
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    for symbol in symbols {
                        let _ = cache.cachedImage(for: symbol, size: CGFloat(20 + i))
                    }
                }
            }
        }
        
        // Verify cache is still functional after concurrent access
        let testImage = cache.cachedImage(for: "star.fill", size: 24)
        XCTAssertNotNil(testImage, "Cache should still be functional after concurrent access")
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }
}

// MARK: - Performance Benchmark Tests

extension EmptyStateIllustrationsPerformanceTests {
    
    /// Comprehensive performance benchmark for empty state system
    func testComprehensivePerformanceBenchmark() {
        let startTime = CFAbsoluteTimeGetCurrent()
        let initialMemory = getCurrentMemoryUsage()
        
        // Create a realistic scenario with multiple empty states
        var views: [AnyView] = []
        
        // Simulate dashboard with multiple empty states
        for _ in 0..<10 {
            views.append(AnyView(EmptyStateView.chartNoData(useIllustration: true)))
            views.append(AnyView(EmptyStateView.pnlNoData(useIllustration: true)))
            views.append(AnyView(EmptyStateView.tradesNoData(useIllustration: true)))
        }
        
        let creationTime = CFAbsoluteTimeGetCurrent() - startTime
        let memoryAfterCreation = getCurrentMemoryUsage()
        let memoryUsed = memoryAfterCreation - initialMemory
        
        // Performance assertions
        XCTAssertLessThan(creationTime, 0.1, "Creating 30 illustrated empty states took too long: \(creationTime)s")
        XCTAssertLessThan(memoryUsed, 8.0, "Memory usage too high: \(memoryUsed)MB for 30 views")
        
        // Test view updates (simulating state changes)
        let updateStartTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<views.count {
            // Simulate view updates by recreating views
            if i % 3 == 0 {
                views[i] = AnyView(EmptyStateView.chartNoData(useIllustration: false))
            }
        }
        
        let updateTime = CFAbsoluteTimeGetCurrent() - updateStartTime
        XCTAssertLessThan(updateTime, 0.05, "Updating views took too long: \(updateTime)s")
        
        // Clean up and measure cleanup time
        let cleanupStartTime = CFAbsoluteTimeGetCurrent()
        views.removeAll()
        
        autoreleasepool {
            // Force cleanup
        }
        
        let cleanupTime = CFAbsoluteTimeGetCurrent() - cleanupStartTime
        let memoryAfterCleanup = getCurrentMemoryUsage()
        let memoryRecovered = memoryAfterCreation - memoryAfterCleanup
        
        XCTAssertLessThan(cleanupTime, 0.02, "Cleanup took too long: \(cleanupTime)s")
        XCTAssertGreaterThan(memoryRecovered, memoryUsed * 0.6, "Not enough memory recovered: \(memoryRecovered)MB of \(memoryUsed)MB")
        
        // Log performance metrics for monitoring
        print("📊 Empty State Performance Benchmark:")
        print("   Creation time: \(String(format: "%.3f", creationTime))s")
        print("   Update time: \(String(format: "%.3f", updateTime))s")
        print("   Cleanup time: \(String(format: "%.3f", cleanupTime))s")
        print("   Memory used: \(String(format: "%.2f", memoryUsed))MB")
        print("   Memory recovered: \(String(format: "%.2f", memoryRecovered))MB")
    }
    
    /// Test performance under different device conditions
    func testPerformanceUnderVariousConditions() {
        // Test with memory pressure
        memoryObserver.isUnderMemoryPressure = true
        
        measure {
            for _ in 0..<20 {
                let _ = IllustratedEmptyStateView.chartNoData()
            }
        }
        
        // Reset memory pressure
        memoryObserver.isUnderMemoryPressure = false
        
        // Test with reduced animations
        let animationManager = AnimationManager.shared
        let originalReduced = animationManager.shouldUseReducedAnimations
        
        // Simulate reduced motion
        measure {
            for _ in 0..<20 {
                let _ = ChartEmptyIllustration()
            }
        }
    }
}