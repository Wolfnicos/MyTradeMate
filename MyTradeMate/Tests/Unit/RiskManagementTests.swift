import XCTest
@testable import MyTradeMate

@MainActor
final class RiskManagementTests: XCTestCase {
    
    var riskManager: RiskManager!
    
    override func setUp() async throws {
        try await super.setUp()
        riskManager = RiskManager.shared
        
        // Reset to default parameters
        riskManager.params = RiskManager.Params()
        riskManager.resetDay()
    }
    
    override func tearDown() async throws {
        riskManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Daily Loss Limit Tests
    
    func testCanTradeWhenNoDailyLoss() {
        // Given
        let equity = 10000.0
        
        // When
        let canTrade = riskManager.canTrade(equity: equity)
        
        // Then
        XCTAssertTrue(canTrade, "Should be able to trade when no daily loss")
    }
    
    func testCannotTradeWhenDailyLossLimitExceeded() {
        // Given
        let equity = 10000.0
        let maxDailyLoss = equity * (riskManager.params.maxDailyLossPercent / 100.0) // 5% = $500
        
        // When - Record a loss exceeding the daily limit
        riskManager.record(realizedPnL: -(maxDailyLoss + 1), equity: equity)
        let canTrade = riskManager.canTrade(equity: equity)
        
        // Then
        XCTAssertFalse(canTrade, "Should not be able to trade when daily loss limit exceeded")
    }
    
    func testCanTradeWhenDailyLossAtLimit() {
        // Given
        let equity = 10000.0
        let maxDailyLoss = equity * (riskManager.params.maxDailyLossPercent / 100.0) // 5% = $500
        
        // When - Record a loss exactly at the limit
        riskManager.record(realizedPnL: -maxDailyLoss, equity: equity)
        let canTrade = riskManager.canTrade(equity: equity)
        
        // Then
        XCTAssertFalse(canTrade, "Should not be able to trade when at daily loss limit")
    }
    
    func testCanTradeWhenDailyLossJustUnderLimit() {
        // Given
        let equity = 10000.0
        let maxDailyLoss = equity * (riskManager.params.maxDailyLossPercent / 100.0) // 5% = $500
        
        // When - Record a loss just under the limit
        riskManager.record(realizedPnL: -(maxDailyLoss - 1), equity: equity)
        let canTrade = riskManager.canTrade(equity: equity)
        
        // Then
        XCTAssertTrue(canTrade, "Should be able to trade when daily loss is under limit")
    }
    
    func testProfitsDoNotAffectDailyLossAccumulation() {
        // Given
        let equity = 10000.0
        
        // When - Record profits
        riskManager.record(realizedPnL: 1000.0, equity: equity)
        let canTrade = riskManager.canTrade(equity: equity)
        
        // Then
        XCTAssertTrue(canTrade, "Profits should not affect ability to trade")
    }
    
    func testResetDayClearsLossAccumulation() {
        // Given
        let equity = 10000.0
        let maxDailyLoss = equity * (riskManager.params.maxDailyLossPercent / 100.0)
        
        // When - Record loss exceeding limit, then reset day
        riskManager.record(realizedPnL: -(maxDailyLoss + 100), equity: equity)
        XCTAssertFalse(riskManager.canTrade(equity: equity), "Should not be able to trade after loss")
        
        riskManager.resetDay()
        let canTradeAfterReset = riskManager.canTrade(equity: equity)
        
        // Then
        XCTAssertTrue(canTradeAfterReset, "Should be able to trade after day reset")
    }
    
    // MARK: - Position Sizing Tests
    
    func testPositionSizingBasicCalculation() {
        // Given
        let equity = 10000.0
        let entryPrice = 45000.0
        let stopPrice = 44000.0 // 1000 point risk
        let expectedRiskCash = equity * (riskManager.params.maxRiskPercentPerTrade / 100.0) // 1% = $100
        let expectedPositionSize = expectedRiskCash / 1000.0 // $100 / $1000 = 0.1
        
        // When
        let actualPositionSize = riskManager.positionSize(equity: equity, entry: entryPrice, stop: stopPrice)
        
        // Then
        XCTAssertEqual(actualPositionSize, expectedPositionSize, accuracy: 0.001)
    }
    
    func testPositionSizingWithCustomRiskPercent() {
        // Given
        riskManager.params.maxRiskPercentPerTrade = 2.0 // 2% instead of default 1%
        let equity = 10000.0
        let entryPrice = 45000.0
        let stopPrice = 44500.0 // 500 point risk
        let expectedRiskCash = equity * 0.02 // 2% = $200
        let expectedPositionSize = expectedRiskCash / 500.0 // $200 / $500 = 0.4
        
        // When
        let actualPositionSize = riskManager.positionSize(equity: equity, entry: entryPrice, stop: stopPrice)
        
        // Then
        XCTAssertEqual(actualPositionSize, expectedPositionSize, accuracy: 0.001)
    }
    
    func testPositionSizingWithVerySmallRisk() {
        // Given
        let equity = 10000.0
        let entryPrice = 45000.0
        let stopPrice = 44999.9 // Very small risk
        
        // When
        let actualPositionSize = riskManager.positionSize(equity: equity, entry: entryPrice, stop: stopPrice)
        
        // Then
        XCTAssertGreaterThan(actualPositionSize, 0, "Position size should be positive even with very small risk")
        XCTAssertLessThan(actualPositionSize, Double.infinity, "Position size should not be infinite")
    }
    
    func testPositionSizingWithZeroRisk() {
        // Given
        let equity = 10000.0
        let entryPrice = 45000.0
        let stopPrice = 45000.0 // Zero risk (entry = stop)
        
        // When
        let actualPositionSize = riskManager.positionSize(equity: equity, entry: entryPrice, stop: stopPrice)
        
        // Then
        XCTAssertGreaterThan(actualPositionSize, 0, "Should handle zero risk gracefully")
    }
    
    // MARK: - Default Stop Loss Tests
    
    func testDefaultStopLossForBuyOrder() {
        // Given
        let entryPrice = 45000.0
        let expectedStopLoss = entryPrice * (1 - riskManager.params.defaultSLPercent / 100.0) // 1% below entry
        
        // When
        let actualStopLoss = riskManager.defaultSL(entry: entryPrice, side: .buy)
        
        // Then
        XCTAssertEqual(actualStopLoss, expectedStopLoss, accuracy: 0.01)
        XCTAssertLessThan(actualStopLoss, entryPrice, "Stop loss should be below entry for buy orders")
    }
    
    func testDefaultStopLossForSellOrder() {
        // Given
        let entryPrice = 45000.0
        let expectedStopLoss = entryPrice * (1 + riskManager.params.defaultSLPercent / 100.0) // 1% above entry
        
        // When
        let actualStopLoss = riskManager.defaultSL(entry: entryPrice, side: .sell)
        
        // Then
        XCTAssertEqual(actualStopLoss, expectedStopLoss, accuracy: 0.01)
        XCTAssertGreaterThan(actualStopLoss, entryPrice, "Stop loss should be above entry for sell orders")
    }
    
    func testDefaultStopLossWithCustomPercent() {
        // Given
        riskManager.params.defaultSLPercent = 2.5 // 2.5% instead of default 1%
        let entryPrice = 45000.0
        let expectedStopLoss = entryPrice * (1 - 2.5 / 100.0) // 2.5% below entry
        
        // When
        let actualStopLoss = riskManager.defaultSL(entry: entryPrice, side: .buy)
        
        // Then
        XCTAssertEqual(actualStopLoss, expectedStopLoss, accuracy: 0.01)
    }
    
    // MARK: - Default Take Profit Tests
    
    func testDefaultTakeProfitForBuyOrder() {
        // Given
        let entryPrice = 45000.0
        let expectedTakeProfit = entryPrice * (1 + riskManager.params.defaultTPPercent / 100.0) // 1.5% above entry
        
        // When
        let actualTakeProfit = riskManager.defaultTP(entry: entryPrice, side: .buy)
        
        // Then
        XCTAssertEqual(actualTakeProfit, expectedTakeProfit, accuracy: 0.01)
        XCTAssertGreaterThan(actualTakeProfit, entryPrice, "Take profit should be above entry for buy orders")
    }
    
    func testDefaultTakeProfitForSellOrder() {
        // Given
        let entryPrice = 45000.0
        let expectedTakeProfit = entryPrice * (1 - riskManager.params.defaultTPPercent / 100.0) // 1.5% below entry
        
        // When
        let actualTakeProfit = riskManager.defaultTP(entry: entryPrice, side: .sell)
        
        // Then
        XCTAssertEqual(actualTakeProfit, expectedTakeProfit, accuracy: 0.01)
        XCTAssertLessThan(actualTakeProfit, entryPrice, "Take profit should be below entry for sell orders")
    }
    
    func testDefaultTakeProfitWithCustomPercent() {
        // Given
        riskManager.params.defaultTPPercent = 3.0 // 3% instead of default 1.5%
        let entryPrice = 45000.0
        let expectedTakeProfit = entryPrice * (1 + 3.0 / 100.0) // 3% above entry
        
        // When
        let actualTakeProfit = riskManager.defaultTP(entry: entryPrice, side: .buy)
        
        // Then
        XCTAssertEqual(actualTakeProfit, expectedTakeProfit, accuracy: 0.01)
    }
    
    // MARK: - Risk Parameters Tests
    
    func testRiskParametersDefaultValues() {
        // Given
        let params = RiskManager.Params()
        
        // Then
        XCTAssertEqual(params.maxRiskPercentPerTrade, 1.0)
        XCTAssertEqual(params.maxDailyLossPercent, 5.0)
        XCTAssertEqual(params.defaultSLPercent, 1.0)
        XCTAssertEqual(params.defaultTPPercent, 1.5)
    }
    
    func testRiskParametersCanBeModified() {
        // Given
        var params = RiskManager.Params()
        
        // When
        params.maxRiskPercentPerTrade = 2.5
        params.maxDailyLossPercent = 10.0
        params.defaultSLPercent = 2.0
        params.defaultTPPercent = 4.0
        
        // Then
        XCTAssertEqual(params.maxRiskPercentPerTrade, 2.5)
        XCTAssertEqual(params.maxDailyLossPercent, 10.0)
        XCTAssertEqual(params.defaultSLPercent, 2.0)
        XCTAssertEqual(params.defaultTPPercent, 4.0)
    }
    
    // MARK: - Edge Cases
    
    func testNegativeEquityHandling() {
        // Given
        let negativeEquity = -1000.0
        let entryPrice = 45000.0
        let stopPrice = 44000.0
        
        // When
        let positionSize = riskManager.positionSize(equity: negativeEquity, entry: entryPrice, stop: stopPrice)
        let canTrade = riskManager.canTrade(equity: negativeEquity)
        
        // Then
        XCTAssertEqual(positionSize, 0, "Position size should be 0 for negative equity")
        XCTAssertTrue(canTrade, "Should handle negative equity gracefully")
    }
    
    func testZeroEquityHandling() {
        // Given
        let zeroEquity = 0.0
        let entryPrice = 45000.0
        let stopPrice = 44000.0
        
        // When
        let positionSize = riskManager.positionSize(equity: zeroEquity, entry: entryPrice, stop: stopPrice)
        let canTrade = riskManager.canTrade(equity: zeroEquity)
        
        // Then
        XCTAssertEqual(positionSize, 0, "Position size should be 0 for zero equity")
        XCTAssertTrue(canTrade, "Should handle zero equity gracefully")
    }
}