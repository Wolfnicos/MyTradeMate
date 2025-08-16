import XCTest
import SwiftUI
@testable import MyTradeMate

/// Tests for empty state implementations in charts
final class EmptyStateTests: XCTestCase {
    
    func testCandlestickChartViewEmptyState() {
        // Given: Empty candle data
        let emptyData: [CandlePoint] = []
        
        // When: Creating a CandlestickChartView with empty data
        let chartView = CandlestickChartView(data: emptyData)
        
        // Then: The view should be created without errors
        XCTAssertNotNil(chartView)
        
        // Note: In a real UI test, we would verify that the empty state UI is displayed
        // For now, we just verify the view can be created with empty data
    }
    
    func testCandlestickChartViewWithData() {
        // Given: Sample candle data
        let sampleData = [
            CandlePoint(time: Date(), open: 100, high: 110, low: 95, close: 105),
            CandlePoint(time: Date().addingTimeInterval(300), open: 105, high: 115, low: 100, close: 110)
        ]
        
        // When: Creating a CandlestickChartView with data
        let chartView = CandlestickChartView(data: sampleData)
        
        // Then: The view should be created without errors
        XCTAssertNotNil(chartView)
    }
    
    func testDashboardCandleChartViewEmptyState() {
        // Given: Empty candle data
        let emptyData: [CandleData] = []
        
        // When: Creating a CandleChartView with empty data
        let chartView = CandleChartView(data: emptyData)
        
        // Then: The view should be created without errors
        XCTAssertNotNil(chartView)
    }
    
    func testDashboardCandleChartViewWithData() {
        // Given: Sample candle data
        let sampleData = [
            CandleData(
                timestamp: Date(),
                open: 100,
                high: 110,
                low: 95,
                close: 105,
                volume: 1000
            )
        ]
        
        // When: Creating a CandleChartView with data
        let chartView = CandleChartView(data: sampleData)
        
        // Then: The view should be created without errors
        XCTAssertNotNil(chartView)
    }
}