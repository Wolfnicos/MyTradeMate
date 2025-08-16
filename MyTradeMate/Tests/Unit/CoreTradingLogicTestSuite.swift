import XCTest

/// Test suite that runs all core trading logic tests
/// This provides a convenient way to run all trading-related tests together
final class CoreTradingLogicTestSuite: XCTestCase {
    
    /// Test that verifies all core trading test classes are properly configured
    func testAllCoreTestClassesExist() {
        // This test ensures all our core trading test classes are properly set up
        // and can be instantiated without errors
        
        let orderExecutionTests = OrderExecutionTests()
        let riskManagementTests = RiskManagementTests()
        let positionTrackingTests = PositionTrackingTests()
        let pnlManagerTests = PnLManagerTests()
        let tradeStoreTests = TradeStoreTests()
        
        XCTAssertNotNil(orderExecutionTests)
        XCTAssertNotNil(riskManagementTests)
        XCTAssertNotNil(positionTrackingTests)
        XCTAssertNotNil(pnlManagerTests)
        XCTAssertNotNil(tradeStoreTests)
    }
    
    /// Performance test for core trading operations
    func testCoreOperationsPerformance() async throws {
        let tradeManager = TradeManager.shared
        let riskManager = RiskManager.shared
        let pnlManager = PnLManager.shared
        
        // Reset state
        await tradeManager.setMode(.paper)
        riskManager.resetDay()
        
        // Measure performance of core operations
        measure {
            // Risk calculations
            let _ = riskManager.positionSize(equity: 10000.0, entry: 45000.0, stop: 44000.0)
            let _ = riskManager.defaultSL(entry: 45000.0, side: .buy)
            let _ = riskManager.defaultTP(entry: 45000.0, side: .buy)
            let _ = riskManager.canTrade(equity: 10000.0)
            
            // Position calculations
            let symbol = Symbol(base: "BTC", quote: "USDT")
            let position = Position(symbol: symbol, quantity: 0.01, avgPrice: 45000.0)
            let _ = position.unrealizedPnL(mark: 46000.0)
            let _ = position.isFlat
        }
    }
    
    /// Integration test that verifies the complete trading flow
    func testCompleteTradingFlow() async throws {
        // This test verifies that all components work together correctly
        // in a realistic trading scenario
        
        let tradeManager = TradeManager.shared
        let riskManager = RiskManager.shared
        
        // Setup
        await tradeManager.setMode(.paper)
        riskManager.resetDay()
        
        // Verify initial state
        XCTAssertNil(tradeManager.position)
        XCTAssertEqual(tradeManager.equity, 10000.0)
        XCTAssertTrue(riskManager.canTrade(equity: tradeManager.equity))
        
        // Calculate position size
        let entryPrice = 45000.0
        let stopPrice = riskManager.defaultSL(entry: entryPrice, side: .buy)
        let positionSize = riskManager.positionSize(
            equity: tradeManager.equity,
            entry: entryPrice,
            stop: stopPrice
        )
        
        XCTAssertGreaterThan(positionSize, 0)
        XCTAssertLessThan(positionSize, 1.0) // Reasonable position size
        
        // Verify risk parameters are working
        let takeProfitPrice = riskManager.defaultTP(entry: entryPrice, side: .buy)
        XCTAssertGreaterThan(takeProfitPrice, entryPrice)
        XCTAssertLessThan(stopPrice, entryPrice)
        
        // Test that risk limits are enforced
        let maxDailyLoss = tradeManager.equity * (riskManager.params.maxDailyLossPercent / 100.0)
        riskManager.record(realizedPnL: -maxDailyLoss, equity: tradeManager.equity)
        XCTAssertFalse(riskManager.canTrade(equity: tradeManager.equity))
        
        // Reset and verify trading is allowed again
        riskManager.resetDay()
        XCTAssertTrue(riskManager.canTrade(equity: tradeManager.equity))
    }
}

// MARK: - Test Configuration and Utilities

/// Utility class for setting up test data and common test scenarios
final class TradingTestUtilities {
    
    /// Creates a sample position for testing
    static func createSamplePosition(
        symbol: String = "BTCUSDT",
        quantity: Double = 0.01,
        avgPrice: Double = 45000.0
    ) -> Position {
        let symbolObj = Symbol(base: String(symbol.prefix(3)), quote: String(symbol.suffix(4)))
        return Position(symbol: symbolObj, quantity: quantity, avgPrice: avgPrice)
    }
    
    /// Creates a sample trade for testing
    static func createSampleTrade(
        symbol: String = "BTCUSDT",
        side: Trade.Side = .buy,
        quantity: Double = 0.01,
        price: Double = 45000.0,
        pnl: Double = 0.0
    ) -> Trade {
        return Trade(
            id: UUID(),
            date: Date(),
            symbol: symbol,
            side: side,
            qty: quantity,
            price: price,
            pnl: pnl
        )
    }
    
    /// Sets up a clean test environment
    @MainActor
    static func setupCleanTestEnvironment() async {
        let tradeManager = TradeManager.shared
        let riskManager = RiskManager.shared
        let pnlManager = PnLManager.shared
        
        // Reset all managers to clean state
        await tradeManager.setMode(.paper)
        riskManager.resetDay()
        riskManager.params = RiskManager.Params() // Reset to defaults
        await pnlManager.resetIfNeeded()
    }
    
    /// Validates that a position is correctly calculated
    static func validatePosition(
        _ position: Position?,
        expectedQuantity: Double,
        expectedAvgPrice: Double,
        accuracy: Double = 0.01
    ) {
        XCTAssertNotNil(position, "Position should not be nil")
        XCTAssertEqual(position?.quantity, expectedQuantity, accuracy: accuracy)
        XCTAssertEqual(position?.avgPrice, expectedAvgPrice, accuracy: accuracy)
    }
    
    /// Validates that PnL calculations are correct
    static func validatePnL(
        _ snapshot: PnLSnapshot,
        expectedEquity: Double,
        expectedRealized: Double,
        expectedUnrealized: Double,
        accuracy: Double = 0.01
    ) {
        XCTAssertEqual(snapshot.equity, expectedEquity, accuracy: accuracy)
        XCTAssertEqual(snapshot.realizedToday, expectedRealized, accuracy: accuracy)
        XCTAssertEqual(snapshot.unrealized, expectedUnrealized, accuracy: accuracy)
    }
}

// MARK: - Test Data Builders

/// Builder pattern for creating test orders
struct TestOrderBuilder {
    private var symbol = "BTCUSDT"
    private var side: OrderSide = .buy
    private var quantity: Double = 0.01
    private var price: Double?
    
    func withSymbol(_ symbol: String) -> TestOrderBuilder {
        var builder = self
        builder.symbol = symbol
        return builder
    }
    
    func withSide(_ side: OrderSide) -> TestOrderBuilder {
        var builder = self
        builder.side = side
        return builder
    }
    
    func withQuantity(_ quantity: Double) -> TestOrderBuilder {
        var builder = self
        builder.quantity = quantity
        return builder
    }
    
    func withPrice(_ price: Double?) -> TestOrderBuilder {
        var builder = self
        builder.price = price
        return builder
    }
    
    func build() -> OrderRequest {
        return OrderRequest(symbol: symbol, side: side, quantity: quantity, price: price)
    }
}

/// Builder pattern for creating test fills
struct TestFillBuilder {
    private var id = UUID().uuidString
    private var symbol = "BTCUSDT"
    private var side: OrderSide = .buy
    private var quantity: Double = 0.01
    private var price: Double = 45000.0
    private var timestamp = Date()
    
    func withId(_ id: String) -> TestFillBuilder {
        var builder = self
        builder.id = id
        return builder
    }
    
    func withSymbol(_ symbol: String) -> TestFillBuilder {
        var builder = self
        builder.symbol = symbol
        return builder
    }
    
    func withSide(_ side: OrderSide) -> TestFillBuilder {
        var builder = self
        builder.side = side
        return builder
    }
    
    func withQuantity(_ quantity: Double) -> TestFillBuilder {
        var builder = self
        builder.quantity = quantity
        return builder
    }
    
    func withPrice(_ price: Double) -> TestFillBuilder {
        var builder = self
        builder.price = price
        return builder
    }
    
    func withTimestamp(_ timestamp: Date) -> TestFillBuilder {
        var builder = self
        builder.timestamp = timestamp
        return builder
    }
    
    func build() -> OrderFill {
        return OrderFill(id: id, symbol: symbol, side: side, quantity: quantity, price: price, timestamp: timestamp)
    }
}