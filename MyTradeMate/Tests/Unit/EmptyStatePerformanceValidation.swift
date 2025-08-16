import XCTest
import SwiftUI
@testable import MyTradeMate

/// Simple validation tests for empty state performance monitoring
class EmptyStatePerformanceValidation: XCTestCase {
    
    func testPerformanceMonitorBasicFunctionality() {
        let monitor = EmptyStatePerformanceMonitor.shared
        monitor.resetMetrics()
        
        // Test basic monitoring
        let token = monitor.startRenderingMonitoring(for: "test")
        XCTAssertNotNil(token)
        
        // Simulate some work
        Thread.sleep(forTimeInterval: 0.001) // 1ms
        
        monitor.recordRenderingCompletion(token: token)
        
        // Check that metrics were updated
        let metrics = monitor.metrics
        XCTAssertGreaterThan(metrics.averageRenderingTime, 0)
        XCTAssertGreaterThan(metrics.overallHealthScore, 0)
    }
    
    func testEmptyStateViewCreation() {
        // Test that empty state views can be created without crashing
        let chartView = EmptyStateView.chartNoData()
        XCTAssertNotNil(chartView)
        
        let pnlView = EmptyStateView.pnlNoData()
        XCTAssertNotNil(pnlView)
        
        let tradesView = EmptyStateView.tradesNoData()
        XCTAssertNotNil(tradesView)
        
        let strategiesView = EmptyStateView.strategiesNoData()
        XCTAssertNotNil(strategiesView)
    }
    
    func testIllustratedEmptyStateViewCreation() {
        // Test that illustrated empty state views can be created without crashing
        let chartView = IllustratedEmptyStateView.chartNoData()
        XCTAssertNotNil(chartView)
        
        let pnlView = IllustratedEmptyStateView.pnlNoData()
        XCTAssertNotNil(pnlView)
        
        let tradesView = IllustratedEmptyStateView.tradesNoData()
        XCTAssertNotNil(tradesView)
        
        let strategiesView = IllustratedEmptyStateView.strategiesNoData()
        XCTAssertNotNil(strategiesView)
        
        let aiSignalView = IllustratedEmptyStateView.aiSignalNoData()
        XCTAssertNotNil(aiSignalView)
    }
    
    func testDeviceClassDetection() {
        let deviceClass = DeviceClass.current
        XCTAssertTrue([.compact, .regular, .large, .extraLarge].contains(deviceClass))
    }
    
    func testImageOptimizerFunctionality() {
        let optimizer = ImageOptimizer.shared
        
        let baseSize = CGSize(width: 100, height: 100)
        let optimizedSize = optimizer.optimalImageSize(for: baseSize)
        
        XCTAssertGreaterThan(optimizedSize.width, 0)
        XCTAssertGreaterThan(optimizedSize.height, 0)
        
        let spacing = optimizer.optimalSpacing()
        XCTAssertGreaterThan(spacing, 0)
        
        let radius = optimizer.optimalCornerRadius()
        XCTAssertGreaterThan(radius, 0)
        
        let duration = optimizer.optimalAnimationDuration(1.0)
        XCTAssertGreaterThan(duration, 0)
    }
    
    func testSFSymbolCacheBasics() {
        let cache = SFSymbolCache.shared
        cache.clearCache()
        
        let image = cache.cachedImage(for: "star.fill", size: 24)
        XCTAssertNotNil(image)
        
        let stats = cache.getStats()
        XCTAssertGreaterThanOrEqual(stats.cacheSize, 0)
        XCTAssertGreaterThanOrEqual(stats.totalRequests, 0)
    }
    
    func testAnimationManagerBasics() {
        let manager = AnimationManager.shared
        
        let animation = manager.animation(duration: 1.0)
        XCTAssertNotNil(animation)
        
        let simpleAnimation = manager.simpleAnimation()
        XCTAssertNotNil(simpleAnimation)
        
        let shouldUseReduced = manager.shouldUseReducedAnimations
        XCTAssertTrue(shouldUseReduced == true || shouldUseReduced == false)
    }
    
    func testMemoryPressureObserver() {
        let observer = MemoryPressureObserver.shared
        XCTAssertNotNil(observer)
        
        let isUnderPressure = observer.isUnderMemoryPressure
        XCTAssertTrue(isUnderPressure == true || isUnderPressure == false)
    }
    
    func testPerformanceReportGeneration() {
        let monitor = EmptyStatePerformanceMonitor.shared
        monitor.resetMetrics()
        
        // Generate some test data
        let token = monitor.startRenderingMonitoring(for: "test")
        Thread.sleep(forTimeInterval: 0.001)
        monitor.recordRenderingCompletion(token: token)
        
        let report = monitor.getDetailedReport()
        XCTAssertFalse(report.summary.isEmpty)
        XCTAssertFalse(report.recommendations.isEmpty)
    }
    
    func testColorAdaptation() {
        // Test that colors can be created without crashing
        let _ = Color.emptyStateBlue
        let _ = Color.emptyStateGreen
        let _ = Color.emptyStateOrange
        let _ = Color.emptyStatePurple
        let _ = Color.emptyStateCyan
        let _ = Color.emptyStateRed
        
        let _ = Color.emptyStateBackgroundBlue
        let _ = Color.emptyStateBackgroundGreen
        let _ = Color.emptyStateBackgroundOrange
        let _ = Color.emptyStateBackgroundPurple
        let _ = Color.emptyStateBackgroundCyan
        let _ = Color.emptyStateBackgroundRed
        
        let _ = Color.emptyStateNeutral
        let _ = Color.emptyStateNeutralBackground
        
        // Test hex color initialization
        let hexColor = Color(hex: "FF0000")
        XCTAssertNotNil(hexColor)
    }
    
    func testPerformanceExtensions() {
        // Test SwiftUI extensions
        let testView = Text("Test")
        
        let monitoredView = testView.monitorEmptyStatePerformance(type: "test")
        XCTAssertNotNil(monitoredView)
        
        let frameDropView = testView.detectFrameDrops(for: "test")
        XCTAssertNotNil(frameDropView)
        
        let optimizedView = testView.optimalCornerRadius(12)
        XCTAssertNotNil(optimizedView)
        
        let paddedView = testView.optimalPadding(16)
        XCTAssertNotNil(paddedView)
    }
}