import XCTest
@testable import MyTradeMate

final class PositionTrackingTests: XCTestCase {
    
    // MARK: - Position Model Tests
    
    func testPositionInitialization() {
        // Given
        let symbol = Symbol(name: "BTCUSDT")
        let quantity = 0.01
        let avgPrice = 45000.0
        
        // When
        let position = Position(symbol: symbol, quantity: quantity, avgPrice: avgPrice)
        
        // Then
        XCTAssertEqual(position.symbol.name, "BTCUSDT")
        XCTAssertEqual(position.quantity, 0.01)
        XCTAssertEqual(position.avgPrice, 45000.0)
        XCTAssertFalse(position.isFlat)
    }
    
    func testPositionIsFlat() {
        // Given
        let symbol = Symbol(name: "BTCUSDT")
        let position = Position(symbol: symbol, quantity: 0.0, avgPrice: 45000.0)
        
        // When & Then
        XCTAssertTrue(position.isFlat, "Position with zero quantity should be flat")
    }
    
    func testPositionIsNotFlat() {
        // Given
        let symbol = Symbol(name: "BTCUSDT")
        let longPosition = Position(symbol: symbol, quantity: 0.01, avgPrice: 45000.0)
        let shortPosition = Position(symbol: symbol, quantity: -0.01, avgPrice: 45000.0)
        
        // When & Then
        XCTAssertFalse(longPosition.isFlat, "Long position should not be flat")
        XCTAssertFalse(shortPosition.isFlat, "Short position should not be flat")
    }
    
    func testUnrealizedPnLForLongPosition() {
        // Given
        let symbol = Symbol(name: "BTCUSDT")
        let position = Position(symbol: symbol, quantity: 0.01, avgPrice: 45000.0)
        let currentPrice = 46000.0
        let expectedPnL = (46000.0 - 45000.0) * 0.01 // $10
        
        // When
        let actualPnL = position.unrealizedPnL(mark: currentPrice)
        
        // Then
        XCTAssertEqual(actualPnL, expectedPnL, accuracy: 0.01)
    }
    
    func testUnrealizedPnLForShortPosition() {
        // Given
        let symbol = Symbol(name: "BTCUSDT")
        let position = Position(symbol: symbol, quantity: -0.01, avgPrice: 45000.0)
        let currentPrice = 44000.0
        let expectedPnL = (44000.0 - 45000.0) * (-0.01) // $10 profit for short
        
        // When
        let actualPnL = position.unrealizedPnL(mark: currentPrice)
        
        // Then
        XCTAssertEqual(actualPnL, expectedPnL, accuracy: 0.01)
    }
    
    func testUnrealizedPnLWhenPriceUnchanged() {
        // Given
        let symbol = Symbol(name: "BTCUSDT")
        let position = Position(symbol: symbol, quantity: 0.01, avgPrice: 45000.0)
        let currentPrice = 45000.0
        
        // When
        let actualPnL = position.unrealizedPnL(mark: currentPrice)
        
        // Then
        XCTAssertEqual(actualPnL, 0.0, accuracy: 0.01)
    }
    
    func testUnrealizedPnLForLossPosition() {
        // Given
        let symbol = Symbol(name: "BTCUSDT")
        let position = Position(symbol: symbol, quantity: 0.01, avgPrice: 45000.0)
        let currentPrice = 44000.0
        let expectedPnL = (44000.0 - 45000.0) * 0.01 // -$10 loss
        
        // When
        let actualPnL = position.unrealizedPnL(mark: currentPrice)
        
        // Then
        XCTAssertEqual(actualPnL, expectedPnL, accuracy: 0.01)
        XCTAssertLessThan(actualPnL, 0, "Should be negative for loss")
    }
}

// MARK: - PnL Manager Tests
final class PnLManagerTests: XCTestCase {
    
    var pnlManager: PnLManager!
    
    override func setUp() async throws {
        try await super.setUp()
        pnlManager = PnLManager.shared
        await pnlManager.resetIfNeeded()
    }
    
    override func tearDown() async throws {
        pnlManager = nil
        try await super.tearDown()
    }
    
    func testInitialSnapshot() async {
        // Given
        let price = 45000.0
        let equity = 10000.0
        
        // When
        let snapshot = await pnlManager.snapshot(price: price, position: nil, equity: equity)
        
        // Then
        XCTAssertEqual(snapshot.equity, equity)
        XCTAssertEqual(snapshot.realizedToday, 0.0)
        XCTAssertEqual(snapshot.unrealized, 0.0)
        XCTAssertNotNil(snapshot.ts)
    }
    
    func testSnapshotWithLongPosition() async {
        // Given
        let symbol = Symbol(name: "BTCUSDT")
        let position = Position(symbol: symbol, quantity: 0.01, avgPrice: 45000.0)
        let currentPrice = 46000.0
        let equity = 10000.0
        let expectedUnrealized = (46000.0 - 45000.0) * 0.01 // $10
        
        // When
        let snapshot = await pnlManager.snapshot(price: currentPrice, position: position, equity: equity)
        
        // Then
        XCTAssertEqual(snapshot.equity, equity + expectedUnrealized)
        XCTAssertEqual(snapshot.unrealized, expectedUnrealized, accuracy: 0.01)
        XCTAssertEqual(snapshot.realizedToday, 0.0)
    }
    
    func testSnapshotWithShortPosition() async {
        // Given
        let symbol = Symbol(name: "BTCUSDT")
        let position = Position(symbol: symbol, quantity: -0.01, avgPrice: 45000.0)
        let currentPrice = 44000.0
        let equity = 10000.0
        let expectedUnrealized = (44000.0 - 45000.0) * (-0.01) // $10 profit for short
        
        // When
        let snapshot = await pnlManager.snapshot(price: currentPrice, position: position, equity: equity)
        
        // Then
        XCTAssertEqual(snapshot.equity, equity + expectedUnrealized)
        XCTAssertEqual(snapshot.unrealized, expectedUnrealized, accuracy: 0.01)
    }
    
    func testSnapshotWithFlatPosition() async {
        // Given
        let symbol = Symbol(name: "BTCUSDT")
        let position = Position(symbol: symbol, quantity: 0.0, avgPrice: 45000.0)
        let currentPrice = 46000.0
        let equity = 10000.0
        
        // When
        let snapshot = await pnlManager.snapshot(price: currentPrice, position: position, equity: equity)
        
        // Then
        XCTAssertEqual(snapshot.equity, equity)
        XCTAssertEqual(snapshot.unrealized, 0.0)
    }
    
    func testAddRealizedProfit() async {
        // Given
        let profit = 150.0
        
        // When
        await pnlManager.addRealized(profit)
        let snapshot = await pnlManager.snapshot(price: 45000.0, position: nil, equity: 10000.0)
        
        // Then
        XCTAssertEqual(snapshot.realizedToday, profit)
    }
    
    func testAddRealizedLoss() async {
        // Given
        let loss = -75.0
        
        // When
        await pnlManager.addRealized(loss)
        let snapshot = await pnlManager.snapshot(price: 45000.0, position: nil, equity: 10000.0)
        
        // Then
        XCTAssertEqual(snapshot.realizedToday, loss)
    }
    
    func testMultipleRealizedTrades() async {
        // Given
        let trades = [100.0, -50.0, 25.0, -30.0]
        let expectedTotal = trades.reduce(0, +) // 45.0
        
        // When
        for trade in trades {
            await pnlManager.addRealized(trade)
        }
        let snapshot = await pnlManager.snapshot(price: 45000.0, position: nil, equity: 10000.0)
        
        // Then
        XCTAssertEqual(snapshot.realizedToday, expectedTotal, accuracy: 0.01)
    }
    
    func testSnapshotTimestamp() async {
        // Given
        let beforeTime = Date()
        
        // When
        let snapshot = await pnlManager.snapshot(price: 45000.0, position: nil, equity: 10000.0)
        let afterTime = Date()
        
        // Then
        XCTAssertGreaterThanOrEqual(snapshot.ts, beforeTime)
        XCTAssertLessThanOrEqual(snapshot.ts, afterTime)
    }
    
    func testComplexScenario() async {
        // Given - Complex trading scenario
        let symbol = Symbol(name: "BTCUSDT")
        let position = Position(symbol: symbol, quantity: 0.05, avgPrice: 44000.0)
        let currentPrice = 45500.0
        let equity = 9800.0 // Reduced from initial 10000 due to previous losses
        let realizedToday = -200.0 // Net loss for the day
        
        await pnlManager.addRealized(realizedToday)
        
        // When
        let snapshot = await pnlManager.snapshot(price: currentPrice, position: position, equity: equity)
        
        // Then
        let expectedUnrealized = (45500.0 - 44000.0) * 0.05 // $75 unrealized profit
        XCTAssertEqual(snapshot.unrealized, expectedUnrealized, accuracy: 0.01)
        XCTAssertEqual(snapshot.realizedToday, realizedToday)
        XCTAssertEqual(snapshot.equity, equity + expectedUnrealized, accuracy: 0.01)
    }
}

// MARK: - Trade Store Tests
final class TradeStoreTests: XCTestCase {
    
    var tradeStore: TradeStore!
    
    override func setUp() async throws {
        try await super.setUp()
        tradeStore = TradeStore()
    }
    
    override func tearDown() async throws {
        tradeStore = nil
        try await super.tearDown()
    }
    
    func testAppendTrade() async {
        // Given
        let trade = Trade(
            id: UUID(),
            date: Date(),
            symbol: "BTCUSDT",
            side: .buy,
            qty: 0.01,
            price: 45000.0,
            pnl: 0.0
        )
        
        // When
        await tradeStore.append(trade)
        let trades = await tradeStore.fetchTrades(offset: 0, limit: 10)
        
        // Then
        XCTAssertEqual(trades.count, 1)
        XCTAssertEqual(trades.first?.id, trade.id)
    }
    
    func testTradesOrderedNewestFirst() async {
        // Given
        let trade1 = Trade(id: UUID(), date: Date().addingTimeInterval(-100), symbol: "BTCUSDT", side: .buy, qty: 0.01, price: 45000.0, pnl: 0.0)
        let trade2 = Trade(id: UUID(), date: Date().addingTimeInterval(-50), symbol: "BTCUSDT", side: .sell, qty: 0.01, price: 46000.0, pnl: 10.0)
        let trade3 = Trade(id: UUID(), date: Date(), symbol: "BTCUSDT", side: .buy, qty: 0.01, price: 45500.0, pnl: 0.0)
        
        // When
        await tradeStore.append(trade1)
        await tradeStore.append(trade2)
        await tradeStore.append(trade3)
        
        let trades = await tradeStore.fetchTrades(offset: 0, limit: 10)
        
        // Then
        XCTAssertEqual(trades.count, 3)
        XCTAssertEqual(trades[0].id, trade3.id) // Newest first
        XCTAssertEqual(trades[1].id, trade2.id)
        XCTAssertEqual(trades[2].id, trade1.id) // Oldest last
    }
    
    func testFetchTradesWithPagination() async {
        // Given - Add 5 trades
        let trades = (0..<5).map { i in
            Trade(
                id: UUID(),
                date: Date().addingTimeInterval(TimeInterval(-i * 10)),
                symbol: "BTCUSDT",
                side: i % 2 == 0 ? .buy : .sell,
                qty: 0.01,
                price: 45000.0 + Double(i * 100),
                pnl: Double(i * 10)
            )
        }
        
        for trade in trades {
            await tradeStore.append(trade)
        }
        
        // When - Fetch first 2 trades
        let firstPage = await tradeStore.fetchTrades(offset: 0, limit: 2)
        let secondPage = await tradeStore.fetchTrades(offset: 2, limit: 2)
        let thirdPage = await tradeStore.fetchTrades(offset: 4, limit: 2)
        
        // Then
        XCTAssertEqual(firstPage.count, 2)
        XCTAssertEqual(secondPage.count, 2)
        XCTAssertEqual(thirdPage.count, 1) // Only 1 remaining
        
        // Verify no overlap
        let allFetchedIds = firstPage.map(\.id) + secondPage.map(\.id) + thirdPage.map(\.id)
        let uniqueIds = Set(allFetchedIds)
        XCTAssertEqual(allFetchedIds.count, uniqueIds.count, "Should have no duplicate trades")
    }
    
    func testFetchTradesWithOffsetBeyondRange() async {
        // Given
        let trade = Trade(id: UUID(), date: Date(), symbol: "BTCUSDT", side: .buy, qty: 0.01, price: 45000.0, pnl: 0.0)
        await tradeStore.append(trade)
        
        // When
        let trades = await tradeStore.fetchTrades(offset: 10, limit: 5)
        
        // Then
        XCTAssertEqual(trades.count, 0, "Should return empty array for offset beyond range")
    }
    
    func testFetchTradesWithZeroLimit() async {
        // Given
        let trade = Trade(id: UUID(), date: Date(), symbol: "BTCUSDT", side: .buy, qty: 0.01, price: 45000.0, pnl: 0.0)
        await tradeStore.append(trade)
        
        // When
        let trades = await tradeStore.fetchTrades(offset: 0, limit: 0)
        
        // Then
        XCTAssertEqual(trades.count, 0, "Should return empty array for zero limit")
    }
    
    func testTradeEquality() {
        // Given
        let id = UUID()
        let date = Date()
        let trade1 = Trade(id: id, date: date, symbol: "BTCUSDT", side: .buy, qty: 0.01, price: 45000.0, pnl: 0.0)
        let trade2 = Trade(id: id, date: date, symbol: "BTCUSDT", side: .buy, qty: 0.01, price: 45000.0, pnl: 0.0)
        let trade3 = Trade(id: UUID(), date: date, symbol: "BTCUSDT", side: .buy, qty: 0.01, price: 45000.0, pnl: 0.0)
        
        // When & Then
        XCTAssertEqual(trade1, trade2, "Trades with same properties should be equal")
        XCTAssertNotEqual(trade1, trade3, "Trades with different IDs should not be equal")
    }
}

// MARK: - Supporting Types
extension Symbol {
    init(name: String) {
        // This is a simplified initializer for testing
        // In the real implementation, Symbol might have more complex initialization
        self.init(base: String(name.prefix(3)), quote: String(name.suffix(4)))
    }
}