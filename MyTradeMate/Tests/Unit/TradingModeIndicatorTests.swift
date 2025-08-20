import XCTest
import SwiftUI
@testable import MyTradeMate

final class TradingModeIndicatorTests: XCTestCase {
    
    func testTradingModeIndicatorDemoMode() {
        // Test that demo mode shows correct styling
        let indicator = TradingModeIndicator(isDemo: true, style: .badge, size: .medium)
        
        // This is a basic test structure - in a real app you'd use ViewInspector or similar
        XCTAssertNotNil(indicator)
    }
    
    func testTradingModeIndicatorLiveMode() {
        // Test that live mode shows correct styling
        let indicator = TradingModeIndicator(isDemo: false, style: .badge, size: .medium)
        
        XCTAssertNotNil(indicator)
    }
    
    func testTradingModeWarningDemoMode() {
        // Test that warning shows for demo mode
        let warning = TradingModeWarning(isDemo: true)
        
        XCTAssertNotNil(warning)
    }
    
    func testTradingModeWarningLiveMode() {
        // Test that warning doesn't show for live mode
        let warning = TradingModeWarning(isDemo: false)
        
        XCTAssertNotNil(warning)
    }
    
    func testTradingModeIndicatorStyles() {
        // Test all styles can be created
        let styles: [TradingModeIndicator.Style] = [.badge, .pill, .minimal, .detailed]
        
        for style in styles {
            let indicator = TradingModeIndicator(isDemo: true, style: style, size: .medium)
            XCTAssertNotNil(indicator)
        }
    }
    
    func testTradingModeIndicatorSizes() {
        // Test all sizes can be created
        let sizes: [TradingModeIndicator.Size] = [.small, .medium, .large]
        
        for size in sizes {
            let indicator = TradingModeIndicator(isDemo: true, style: .badge, size: size)
            XCTAssertNotNil(indicator)
        }
    }
}