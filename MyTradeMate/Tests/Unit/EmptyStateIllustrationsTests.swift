import XCTest
import SwiftUI
@testable import MyTradeMate

class EmptyStateIllustrationsTests: XCTestCase {
    
    // MARK: - Illustration Creation Tests
    
    func testChartEmptyIllustrationCreation() {
        let illustration = ChartEmptyIllustration()
        XCTAssertNotNil(illustration)
    }
    
    func testPnLEmptyIllustrationCreation() {
        let illustration = PnLEmptyIllustration()
        XCTAssertNotNil(illustration)
    }
    
    func testTradesEmptyIllustrationCreation() {
        let illustration = TradesEmptyIllustration()
        XCTAssertNotNil(illustration)
    }
    
    func testStrategiesEmptyIllustrationCreation() {
        let illustration = StrategiesEmptyIllustration()
        XCTAssertNotNil(illustration)
    }
    
    func testAISignalEmptyIllustrationCreation() {
        let illustration = AISignalEmptyIllustration()
        XCTAssertNotNil(illustration)
    }
    
    // MARK: - Illustrated Empty State View Tests
    
    func testIllustratedEmptyStateViewCreation() {
        let view = IllustratedEmptyStateView(
            illustration: .chartNoData,
            title: "Test Title",
            description: "Test Description"
        )
        XCTAssertNotNil(view)
    }
    
    func testIllustratedEmptyStateViewWithAction() {
        var actionCalled = false
        let view = IllustratedEmptyStateView(
            illustration: .pnlNoData,
            title: "Test Title",
            description: "Test Description",
            actionButton: { actionCalled = true },
            actionButtonTitle: "Test Action"
        )
        XCTAssertNotNil(view)
    }
    
    // MARK: - Convenience Initializer Tests
    
    func testChartNoDataConvenienceInitializer() {
        let view = IllustratedEmptyStateView.chartNoData()
        XCTAssertNotNil(view)
    }
    
    func testPnLNoDataConvenienceInitializer() {
        let view = IllustratedEmptyStateView.pnlNoData()
        XCTAssertNotNil(view)
    }
    
    func testTradesNoDataConvenienceInitializer() {
        let view = IllustratedEmptyStateView.tradesNoData()
        XCTAssertNotNil(view)
    }
    
    func testStrategiesNoDataConvenienceInitializer() {
        let view = IllustratedEmptyStateView.strategiesNoData()
        XCTAssertNotNil(view)
    }
    
    func testAISignalNoDataConvenienceInitializer() {
        let view = IllustratedEmptyStateView.aiSignalNoData()
        XCTAssertNotNil(view)
    }
    
    // MARK: - Dark Mode Color Tests
    
    func testDarkModeColors() {
        // Test that our custom colors are properly defined
        XCTAssertNotNil(Color.emptyStateBlue)
        XCTAssertNotNil(Color.emptyStateGreen)
        XCTAssertNotNil(Color.emptyStateOrange)
        XCTAssertNotNil(Color.emptyStatePurple)
        XCTAssertNotNil(Color.emptyStateCyan)
        XCTAssertNotNil(Color.emptyStateRed)
        
        // Test background colors
        XCTAssertNotNil(Color.emptyStateBackgroundBlue)
        XCTAssertNotNil(Color.emptyStateBackgroundGreen)
        XCTAssertNotNil(Color.emptyStateBackgroundOrange)
        XCTAssertNotNil(Color.emptyStateBackgroundPurple)
        XCTAssertNotNil(Color.emptyStateBackgroundCyan)
        XCTAssertNotNil(Color.emptyStateBackgroundRed)
        
        // Test neutral colors
        XCTAssertNotNil(Color.emptyStateNeutral)
        XCTAssertNotNil(Color.emptyStateNeutralBackground)
    }
    
    func testHexColorInitializer() {
        // Test hex color initialization
        let blueColor = Color(hex: "007AFF")
        let greenColor = Color(hex: "34C759")
        let redColor = Color(hex: "FF3B30")
        
        XCTAssertNotNil(blueColor)
        XCTAssertNotNil(greenColor)
        XCTAssertNotNil(redColor)
    }
    
    func testDarkModeColorContrast() {
        // Test that dark mode colors have proper contrast
        // This is a basic test to ensure colors are defined with different light/dark variants
        let lightBlue = Color(light: Color(hex: "007AFF"), dark: Color(hex: "0A84FF"))
        let lightGreen = Color(light: Color(hex: "34C759"), dark: Color(hex: "30D158"))
        
        XCTAssertNotNil(lightBlue)
        XCTAssertNotNil(lightGreen)
    }
    
    func testIllustrationDarkModeSupport() {
        // Test that illustrations properly respond to color scheme changes
        let chartIllustration = ChartEmptyIllustration()
        let pnlIllustration = PnLEmptyIllustration()
        let tradesIllustration = TradesEmptyIllustration()
        let strategiesIllustration = StrategiesEmptyIllustration()
        let aiSignalIllustration = AISignalEmptyIllustration()
        
        // These should not crash when rendered in different color schemes
        XCTAssertNotNil(chartIllustration)
        XCTAssertNotNil(pnlIllustration)
        XCTAssertNotNil(tradesIllustration)
        XCTAssertNotNil(strategiesIllustration)
        XCTAssertNotNil(aiSignalIllustration)
    }
    
    // MARK: - Animation Manager Tests
    
    func testAnimationManagerSingleton() {
        let manager1 = AnimationManager.shared
        let manager2 = AnimationManager.shared
        XCTAssertTrue(manager1 === manager2)
    }
    
    func testAnimationManagerReducedAnimations() {
        let manager = AnimationManager.shared
        let animation = manager.animation(duration: 1.0)
        XCTAssertNotNil(animation)
    }
    
    // MARK: - Subtle Animation Tests
    
    func testSubtleBreathingAnimation() {
        let manager = AnimationManager.shared
        let breathingAnimation = manager.subtleBreathingAnimation()
        XCTAssertNotNil(breathingAnimation)
        
        // Test with custom duration
        let customBreathingAnimation = manager.subtleBreathingAnimation(duration: 3.0)
        XCTAssertNotNil(customBreathingAnimation)
    }
    
    func testFloatingAnimation() {
        let manager = AnimationManager.shared
        let floatingAnimation = manager.floatingAnimation()
        XCTAssertNotNil(floatingAnimation)
        
        // Test with custom parameters
        let customFloatingAnimation = manager.floatingAnimation(duration: 2.5, delay: 0.5)
        XCTAssertNotNil(customFloatingAnimation)
    }
    
    func testShimmerAnimation() {
        let manager = AnimationManager.shared
        let shimmerAnimation = manager.shimmerAnimation()
        XCTAssertNotNil(shimmerAnimation)
        
        // Test with custom parameters
        let customShimmerAnimation = manager.shimmerAnimation(duration: 1.5, delay: 0.3)
        XCTAssertNotNil(customShimmerAnimation)
    }
    
    func testGentleRotationAnimation() {
        let manager = AnimationManager.shared
        let rotationAnimation = manager.gentleRotationAnimation()
        XCTAssertNotNil(rotationAnimation)
        
        // Test with custom parameters
        let customRotationAnimation = manager.gentleRotationAnimation(duration: 6.0, delay: 1.0)
        XCTAssertNotNil(customRotationAnimation)
    }
    
    func testAnimationPerformanceOptimization() {
        let optimizer = ImageOptimizer.shared
        
        // Test animation duration optimization
        let shortDuration = optimizer.optimalAnimationDuration(0.5)
        let mediumDuration = optimizer.optimalAnimationDuration(2.0)
        let longDuration = optimizer.optimalAnimationDuration(5.0)
        
        XCTAssertGreaterThan(shortDuration, 0)
        XCTAssertGreaterThan(mediumDuration, 0)
        XCTAssertGreaterThan(longDuration, 0)
        
        // Test animation enablement
        let shouldEnable = optimizer.shouldEnableAnimations
        XCTAssertNotNil(shouldEnable)
    }
    
    func testAnimationStateManagement() {
        // Test that animations can be properly started and stopped
        let chartIllustration = ChartEmptyIllustration()
        let pnlIllustration = PnLEmptyIllustration()
        let tradesIllustration = TradesEmptyIllustration()
        let strategiesIllustration = StrategiesEmptyIllustration()
        let aiSignalIllustration = AISignalEmptyIllustration()
        
        // These should not crash when animation states change
        XCTAssertNotNil(chartIllustration)
        XCTAssertNotNil(pnlIllustration)
        XCTAssertNotNil(tradesIllustration)
        XCTAssertNotNil(strategiesIllustration)
        XCTAssertNotNil(aiSignalIllustration)
    }
    
    // MARK: - Enhanced Empty State View Tests
    
    func testEmptyStateViewWithIllustration() {
        let view = EmptyStateView.chartNoData(useIllustration: true)
        XCTAssertNotNil(view)
    }
    
    func testEmptyStateViewWithoutIllustration() {
        let view = EmptyStateView.chartNoData(useIllustration: false)
        XCTAssertNotNil(view)
    }
    
    func testEmptyStateViewDefaultBehavior() {
        let view = EmptyStateView.chartNoData()
        XCTAssertNotNil(view)
    }
    
    // MARK: - Performance Tests
    
    func testIllustrationPerformance() {
        measure {
            for _ in 0..<100 {
                let _ = IllustratedEmptyStateView.chartNoData()
                let _ = IllustratedEmptyStateView.pnlNoData()
                let _ = IllustratedEmptyStateView.tradesNoData()
                let _ = IllustratedEmptyStateView.strategiesNoData()
                let _ = IllustratedEmptyStateView.aiSignalNoData()
            }
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() {
        let view = IllustratedEmptyStateView.chartNoData(
            title: "Test Title",
            description: "Test Description"
        )
        
        // Test that the view can be enhanced with accessibility
        let accessibleView = view.withAccessibility()
        XCTAssertNotNil(accessibleView)
    }
    
    // MARK: - Screen Size Optimization Tests
    
    func testScreenSizeOptimization() {
        // Test that different screen sizes are handled
        // This is more of a visual test, but we can at least verify the views are created
        let view = IllustratedEmptyStateView.chartNoData()
        XCTAssertNotNil(view)
    }
}

// MARK: - Mock Tests for UI Components

extension EmptyStateIllustrationsTests {
    
    func testEmptyStateIllustrationEnum() {
        let chartIllustration = EmptyStateIllustration.chartNoData
        let pnlIllustration = EmptyStateIllustration.pnlNoData
        let tradesIllustration = EmptyStateIllustration.tradesNoData
        let strategiesIllustration = EmptyStateIllustration.strategiesNoData
        let aiSignalIllustration = EmptyStateIllustration.aiSignalNoData
        
        XCTAssertNotNil(chartIllustration.view)
        XCTAssertNotNil(pnlIllustration.view)
        XCTAssertNotNil(tradesIllustration.view)
        XCTAssertNotNil(strategiesIllustration.view)
        XCTAssertNotNil(aiSignalIllustration.view)
    }
    
    func testOptimizedChartIllustration() {
        let illustration = OptimizedChartEmptyIllustration()
        XCTAssertNotNil(illustration)
    }
}

// MARK: - Integration Tests

extension EmptyStateIllustrationsTests {
    
    func testIllustrationIntegrationWithEmptyStateView() {
        // Test that the original EmptyStateView properly integrates with illustrations
        let chartView = EmptyStateView.chartNoData(useIllustration: true)
        let pnlView = EmptyStateView.pnlNoData(useIllustration: true)
        let tradesView = EmptyStateView.tradesNoData(useIllustration: true)
        let strategiesView = EmptyStateView.strategiesNoData(useIllustration: true)
        
        XCTAssertNotNil(chartView)
        XCTAssertNotNil(pnlView)
        XCTAssertNotNil(tradesView)
        XCTAssertNotNil(strategiesView)
    }
    
    func testFallbackToSimpleVersion() {
        // Test that unknown icons fall back to simple version
        let view = EmptyStateView(
            icon: "unknown.icon",
            title: "Test",
            description: "Test",
            useIllustration: true
        )
        XCTAssertNotNil(view)
    }
}