import XCTest
import SwiftUI
@testable import MyTradeMate

/// Integration tests for empty state performance in realistic app scenarios
@MainActor
final class EmptyStatePerformanceIntegrationTests: XCTestCase {
    
    var performanceMonitor: EmptyStatePerformanceMonitor!
    var memoryObserver: MemoryPressureObserver!
    
    override func setUp() async throws {
        try await super.setUp()
        performanceMonitor = EmptyStatePerformanceMonitor.shared
        memoryObserver = MemoryPressureObserver.shared
        
        // Reset monitoring state
        performanceMonitor.resetMetrics()
        SFSymbolCache.shared.clearCache()
    }
    
    override func tearDown() async throws {
        // Clean up after tests
        performanceMonitor.resetMetrics()
        SFSymbolCache.shared.clearCache()
        try await super.tearDown()
    }
    
    // MARK: - Dashboard Integration Tests
    
    func testDashboardWithMultipleEmptyStates() async throws {
        let initialMemory = getCurrentMemoryUsage()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate dashboard loading with multiple empty states
        var dashboardViews: [AnyView] = []
        
        // Chart section - no data
        dashboardViews.append(AnyView(
            EmptyStateView.chartNoData(useIllustration: true)
                .withPerformanceMonitoring()
        ))
        
        // AI Signal section - no signal
        dashboardViews.append(AnyView(
            IllustratedEmptyStateView.aiSignalNoData()
                .withPerformanceMonitoring()
        ))
        
        // P&L section - no trades
        dashboardViews.append(AnyView(
            EmptyStateView.pnlNoData(useIllustration: true)
                .withPerformanceMonitoring()
        ))
        
        let creationTime = CFAbsoluteTimeGetCurrent() - startTime
        let memoryAfterCreation = getCurrentMemoryUsage()
        let memoryUsed = memoryAfterCreation - initialMemory
        
        // Performance assertions for dashboard scenario
        XCTAssertLessThan(creationTime, 0.05, "Dashboard empty states creation took too long: \(creationTime)s")
        XCTAssertLessThan(memoryUsed, 5.0, "Dashboard empty states used too much memory: \(memoryUsed)MB")
        
        // Simulate user interaction - switching between tabs
        let interactionStartTime = CFAbsoluteTimeGetCurrent()
        
        // Remove chart, add trades view
        dashboardViews[0] = AnyView(
            EmptyStateView.tradesNoData(useIllustration: true)
                .withPerformanceMonitoring()
        )
        
        let interactionTime = CFAbsoluteTimeGetCurrent() - interactionStartTime
        XCTAssertLessThan(interactionTime, 0.02, "View switching took too long: \(interactionTime)s")
        
        // Allow time for performance monitoring
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Check performance metrics
        let metrics = performanceMonitor.metrics
        XCTAssertLessThan(metrics.averageRenderingTime, 0.02, "Average rendering time too high: \(metrics.averageRenderingTime)s")
        XCTAssertGreaterThan(metrics.overallHealthScore, 80.0, "Overall health score too low: \(metrics.overallHealthScore)")
        
        // Clean up
        dashboardViews.removeAll()
    }
    
    // MARK: - List View Integration Tests
    
    func testTradesListWithEmptyState() async throws {
        let initialMemory = getCurrentMemoryUsage()
        
        // Simulate trades list loading
        var listViews: [AnyView] = []
        
        // Initially show loading, then empty state
        for i in 0..<20 {
            if i % 2 == 0 {
                listViews.append(AnyView(
                    EmptyStateView.tradesNoData(useIllustration: true)
                        .withPerformanceMonitoring()
                ))
            } else {
                listViews.append(AnyView(
                    EmptyStateView.tradesNoData(useIllustration: false)
                        .withPerformanceMonitoring()
                ))
            }
        }
        
        let memoryAfterCreation = getCurrentMemoryUsage()
        let memoryUsed = memoryAfterCreation - initialMemory
        
        // Should handle multiple empty states efficiently
        XCTAssertLessThan(memoryUsed, 8.0, "Multiple empty states used too much memory: \(memoryUsed)MB")
        
        // Simulate scrolling (view recycling)
        let scrollStartTime = CFAbsoluteTimeGetCurrent()
        
        // Remove first 10, add 10 new ones
        listViews.removeFirst(10)
        for _ in 0..<10 {
            listViews.append(AnyView(
                EmptyStateView.tradesNoData(useIllustration: true)
                    .withPerformanceMonitoring()
            ))
        }
        
        let scrollTime = CFAbsoluteTimeGetCurrent() - scrollStartTime
        XCTAssertLessThan(scrollTime, 0.03, "View recycling took too long: \(scrollTime)s")
        
        // Clean up
        listViews.removeAll()
    }
    
    // MARK: - Memory Pressure Integration Tests
    
    func testPerformanceUnderMemoryPressure() async throws {
        let initialMemory = getCurrentMemoryUsage()
        
        // Create views under normal conditions
        var views: [AnyView] = []
        for _ in 0..<30 {
            views.append(AnyView(
                IllustratedEmptyStateView.chartNoData()
                    .withPerformanceMonitoring()
            ))
        }
        
        let memoryAfterNormal = getCurrentMemoryUsage()
        
        // Simulate memory pressure
        NotificationCenter.default.post(
            name: .memoryPressureChanged,
            object: memoryObserver,
            userInfo: ["level": MemoryPressureManager.MemoryPressureLevel.warning]
        )
        
        // Allow time for pressure response
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Create more views under pressure
        for _ in 0..<20 {
            views.append(AnyView(
                IllustratedEmptyStateView.pnlNoData()
                    .withPerformanceMonitoring()
            ))
        }
        
        let memoryAfterPressure = getCurrentMemoryUsage()
        let memoryIncrease = memoryAfterPressure - memoryAfterNormal
        
        // Memory increase should be minimal under pressure
        XCTAssertLessThan(memoryIncrease, 3.0, "Memory increased too much under pressure: \(memoryIncrease)MB")
        
        // Performance should still be acceptable
        let metrics = performanceMonitor.metrics
        XCTAssertGreaterThan(metrics.overallHealthScore, 70.0, "Performance degraded too much under memory pressure")
        
        // Clean up
        views.removeAll()
    }
    
    // MARK: - Animation Performance Integration Tests
    
    func testAnimationPerformanceInRealScenario() async throws {
        // Test animations in a realistic scenario with multiple concurrent animations
        var animatedViews: [AnyView] = []
        
        let animationStartTime = CFAbsoluteTimeGetCurrent()
        
        // Create views with different animation types
        for i in 0..<15 {
            switch i % 5 {
            case 0:
                animatedViews.append(AnyView(ChartEmptyIllustration()))
            case 1:
                animatedViews.append(AnyView(PnLEmptyIllustration()))
            case 2:
                animatedViews.append(AnyView(TradesEmptyIllustration()))
            case 3:
                animatedViews.append(AnyView(StrategiesEmptyIllustration()))
            case 4:
                animatedViews.append(AnyView(AISignalEmptyIllustration()))
            default:
                break
            }
        }
        
        // Allow animations to start
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let animationSetupTime = CFAbsoluteTimeGetCurrent() - animationStartTime
        XCTAssertLessThan(animationSetupTime, 0.1, "Animation setup took too long: \(animationSetupTime)s")
        
        // Check for frame drops during animation
        let metrics = performanceMonitor.metrics
        XCTAssertLessThan(metrics.totalFrameDrops, 5, "Too many frame drops during animations: \(metrics.totalFrameDrops)")
        XCTAssertGreaterThan(metrics.animationPerformanceScore, 75.0, "Animation performance score too low: \(metrics.animationPerformanceScore)")
        
        // Test animation cleanup
        let cleanupStartTime = CFAbsoluteTimeGetCurrent()
        animatedViews.removeAll()
        
        // Allow cleanup to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let cleanupTime = CFAbsoluteTimeGetCurrent() - cleanupStartTime
        XCTAssertLessThan(cleanupTime, 0.05, "Animation cleanup took too long: \(cleanupTime)s")
    }
    
    // MARK: - Cache Performance Integration Tests
    
    func testSFSymbolCacheIntegration() async throws {
        let cache = SFSymbolCache.shared
        cache.clearCache()
        
        // Simulate realistic symbol usage pattern
        let symbols = [
            "chart.line.uptrend.xyaxis",
            "dollarsign.circle.fill",
            "list.bullet.rectangle",
            "brain.head.profile",
            "antenna.radiowaves.left.and.right",
            "star.fill",
            "heart.fill",
            "gear",
            "person.fill",
            "house.fill"
        ]
        
        let sizes: [CGFloat] = [16, 20, 24, 28, 32]
        
        // First pass - cache misses
        let firstPassStartTime = CFAbsoluteTimeGetCurrent()
        
        for symbol in symbols {
            for size in sizes {
                let _ = cache.cachedImage(for: symbol, size: size)
            }
        }
        
        let firstPassTime = CFAbsoluteTimeGetCurrent() - firstPassStartTime
        
        // Second pass - cache hits
        let secondPassStartTime = CFAbsoluteTimeGetCurrent()
        
        for symbol in symbols {
            for size in sizes {
                let _ = cache.cachedImage(for: symbol, size: size)
            }
        }
        
        let secondPassTime = CFAbsoluteTimeGetCurrent() - secondPassStartTime
        
        // Cache hits should be significantly faster
        XCTAssertLessThan(secondPassTime, firstPassTime * 0.3, "Cache hits not significantly faster than misses")
        
        // Check cache statistics
        let stats = cache.getStats()
        XCTAssertGreaterThan(stats.hitRate, 50.0, "Cache hit rate too low: \(stats.hitRate)%")
        XCTAssertEqual(stats.cacheSize, symbols.count * sizes.count, "Cache size doesn't match expected")
        
        // Test cache under memory pressure
        NotificationCenter.default.post(
            name: .memoryPressureChanged,
            object: memoryObserver,
            userInfo: ["level": MemoryPressureManager.MemoryPressureLevel.critical]
        )
        
        // Allow time for cleanup
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let statsAfterPressure = cache.getStats()
        XCTAssertLessThanOrEqual(statsAfterPressure.cacheSize, stats.cacheSize, "Cache should be cleaned under memory pressure")
    }
    
    // MARK: - Device Class Integration Tests
    
    func testPerformanceAcrossDeviceClasses() async throws {
        // Test performance optimizations for different device classes
        let deviceClass = DeviceClass.current
        
        // Create views optimized for current device class
        var views: [AnyView] = []
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<25 {
            views.append(AnyView(
                IllustratedEmptyStateView.chartNoData()
                    .withPerformanceMonitoring()
            ))
        }
        
        let creationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Performance expectations based on device class
        let expectedMaxTime: TimeInterval
        let expectedMaxMemory: Double
        
        switch deviceClass {
        case .compact:
            expectedMaxTime = 0.08
            expectedMaxMemory = 6.0
        case .regular:
            expectedMaxTime = 0.06
            expectedMaxMemory = 8.0
        case .large:
            expectedMaxTime = 0.05
            expectedMaxMemory = 10.0
        case .extraLarge:
            expectedMaxTime = 0.04
            expectedMaxMemory = 12.0
        }
        
        XCTAssertLessThan(creationTime, expectedMaxTime, "Creation time exceeded expectations for \(deviceClass): \(creationTime)s")
        
        let memoryUsed = getCurrentMemoryUsage()
        XCTAssertLessThan(memoryUsed, expectedMaxMemory, "Memory usage exceeded expectations for \(deviceClass): \(memoryUsed)MB")
        
        // Clean up
        views.removeAll()
    }
    
    // MARK: - Thermal State Integration Tests
    
    func testPerformanceUnderThermalPressure() async throws {
        let thermalState = ProcessInfo.processInfo.thermalState
        
        // Only run this test if we can detect thermal state
        guard thermalState != .nominal else {
            throw XCTSkip("Thermal state is nominal, skipping thermal pressure test")
        }
        
        // Create views under thermal pressure
        var views: [AnyView] = []
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<20 {
            views.append(AnyView(
                IllustratedEmptyStateView.chartNoData()
                    .withPerformanceMonitoring()
            ))
        }
        
        let creationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Under thermal pressure, creation should still be reasonable
        XCTAssertLessThan(creationTime, 0.1, "Creation time too high under thermal pressure: \(creationTime)s")
        
        // Animations should be reduced or disabled
        let imageOptimizer = ImageOptimizer.shared
        if thermalState == .critical {
            XCTAssertFalse(imageOptimizer.shouldEnableAnimations, "Animations should be disabled under critical thermal state")
        }
        
        // Clean up
        views.removeAll()
    }
    
    // MARK: - Comprehensive Performance Test
    
    func testComprehensiveRealWorldScenario() async throws {
        let initialMemory = getCurrentMemoryUsage()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate a complete app flow with empty states
        var appViews: [AnyView] = []
        
        // 1. App launch - Dashboard with empty states
        appViews.append(AnyView(EmptyStateView.chartNoData(useIllustration: true)))
        appViews.append(AnyView(IllustratedEmptyStateView.aiSignalNoData()))
        
        // 2. Navigate to Trades - empty list
        appViews.append(AnyView(EmptyStateView.tradesNoData(useIllustration: true)))
        
        // 3. Navigate to P&L - no data
        appViews.append(AnyView(EmptyStateView.pnlNoData(useIllustration: true)))
        
        // 4. Navigate to Strategies - empty list
        appViews.append(AnyView(IllustratedEmptyStateView.strategiesNoData()))
        
        let navigationTime = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(navigationTime, 0.1, "App navigation with empty states took too long: \(navigationTime)s")
        
        // 5. Simulate background/foreground cycle
        let backgroundStartTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate app going to background (cleanup)
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Simulate app coming to foreground (recreation)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        let backgroundCycleTime = CFAbsoluteTimeGetCurrent() - backgroundStartTime
        XCTAssertLessThan(backgroundCycleTime, 0.2, "Background/foreground cycle took too long: \(backgroundCycleTime)s")
        
        // 6. Check final performance metrics
        let finalMemory = getCurrentMemoryUsage()
        let totalMemoryUsed = finalMemory - initialMemory
        
        XCTAssertLessThan(totalMemoryUsed, 10.0, "Total memory usage too high: \(totalMemoryUsed)MB")
        
        let metrics = performanceMonitor.metrics
        XCTAssertGreaterThan(metrics.overallHealthScore, 75.0, "Overall performance score too low: \(metrics.overallHealthScore)")
        XCTAssertLessThan(metrics.averageRenderingTime, 0.02, "Average rendering time too high: \(metrics.averageRenderingTime)s")
        
        // Generate performance report
        let report = performanceMonitor.getDetailedReport()
        print("📊 Comprehensive Performance Test Results:")
        print(report.summary)
        
        // Clean up
        appViews.removeAll()
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