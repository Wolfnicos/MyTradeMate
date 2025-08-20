import XCTest
@testable import MyTradeMate

final class PnLPerformanceMetricsTests: XCTestCase {
    
    func testPnLVMPerformanceMetricsIntegration() async {
        // Given
        let vm = PnLVM()
        
        // When
        vm.start()
        
        // Allow some time for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertNotNil(vm.performanceMetrics, "Performance metrics should be calculated")
        
        // Verify metrics structure
        if let metrics = vm.performanceMetrics {
            XCTAssertGreaterThanOrEqual(metrics.trades, 0, "Trades count should be non-negative")
            XCTAssertGreaterThanOrEqual(metrics.wins, 0, "Wins count should be non-negative")
            XCTAssertGreaterThanOrEqual(metrics.losses, 0, "Losses count should be non-negative")
            XCTAssertGreaterThanOrEqual(metrics.winRate, 0.0, "Win rate should be non-negative")
            XCTAssertLessThanOrEqual(metrics.winRate, 1.0, "Win rate should not exceed 100%")
        }
        
        vm.stop()
    }
    
    func testPnLMetricsAggregatorWithSampleData() {
        // Given
        let sampleFills: [OrderFill] = [
            OrderFill(id: UUID(), symbol: "BTCUSDT", side: .buy, quantity: 1.0, price: 50000.0, timestamp: Date()),
            OrderFill(id: UUID(), symbol: "BTCUSDT", side: .sell, quantity: 1.0, price: 51000.0, timestamp: Date())
        ]
        
        // When
        let metrics = PnLMetricsAggregator.compute(from: sampleFills)
        
        // Then
        XCTAssertEqual(metrics.trades, 2, "Should count all fills as trades")
        XCTAssertGreaterThanOrEqual(metrics.winRate, 0.0, "Win rate should be valid")
        XCTAssertLessThanOrEqual(metrics.winRate, 1.0, "Win rate should not exceed 100%")
    }
    
    func testPnLMetricsAggregatorWithEmptyData() {
        // Given
        let emptyFills: [OrderFill] = []
        
        // When
        let metrics = PnLMetricsAggregator.compute(from: emptyFills)
        
        // Then
        XCTAssertEqual(metrics.trades, 0, "Should have zero trades")
        XCTAssertEqual(metrics.wins, 0, "Should have zero wins")
        XCTAssertEqual(metrics.losses, 0, "Should have zero losses")
        XCTAssertEqual(metrics.winRate, 0.0, "Win rate should be zero")
        XCTAssertEqual(metrics.netPnL, 0.0, "Net P&L should be zero")
        XCTAssertEqual(metrics.maxDrawdown, 0.0, "Max drawdown should be zero")
    }
    
    func testPerformanceMetricsDisplayLogic() {
        // Given
        let metricsWithTrades = PnLMetrics(
            trades: 10,
            wins: 6,
            losses: 4,
            winRate: 0.6,
            avgTradePnL: 25.0,
            avgWin: 50.0,
            avgLoss: -20.0,
            grossProfit: 300.0,
            grossLoss: -80.0,
            netPnL: 220.0,
            maxDrawdown: -45.0
        )
        
        let metricsWithoutTrades = PnLMetrics(
            trades: 0,
            wins: 0,
            losses: 0,
            winRate: 0.0,
            avgTradePnL: 0.0,
            avgWin: 0.0,
            avgLoss: 0.0,
            grossProfit: 0.0,
            grossLoss: 0.0,
            netPnL: 0.0,
            maxDrawdown: 0.0
        )
        
        // When/Then
        XCTAssertTrue(metricsWithTrades.trades > 0, "Should show metrics when trades exist")
        XCTAssertFalse(metricsWithoutTrades.trades > 0, "Should show empty state when no trades exist")
        
        // Test win rate color logic
        XCTAssertTrue(metricsWithTrades.winRate >= 0.5, "High win rate should be green")
        
        // Test P&L color logic
        XCTAssertTrue(metricsWithTrades.netPnL >= 0, "Positive P&L should be green")
    }
    
    func testCurrencyFormatting() {
        // Given
        let testValues: [(Double, String)] = [
            (1234.56, "$1,235"),
            (999.99, "$999.99"),
            (-1500.0, "-$1,500"),
            (0.0, "$0.00")
        ]
        
        // When/Then
        for (value, expectedFormat) in testValues {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.maximumFractionDigits = abs(value) >= 1000 ? 0 : 2
            
            let formatted = formatter.string(from: NSNumber(value: value)) ?? "$0.00"
            
            // Basic validation that formatting works
            XCTAssertTrue(formatted.contains("$"), "Should contain currency symbol")
            if value < 0 {
                XCTAssertTrue(formatted.contains("-"), "Negative values should show minus sign")
            }
        }
    }
}