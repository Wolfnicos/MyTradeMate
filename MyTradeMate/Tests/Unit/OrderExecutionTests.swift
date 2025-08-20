import XCTest
@testable import MyTradeMate

@MainActor
final class OrderExecutionTests: XCTestCase {
    
    var tradeManager: TradeManager!
    var mockExchangeClient: MockExchangeClient!
    
    override func setUp() async throws {
        try await super.setUp()
        tradeManager = TradeManager.shared
        mockExchangeClient = MockExchangeClient()
        
        // Reset trade manager state
        await tradeManager.setMode(.paper)
        await tradeManager.setExchange(.binance)
    }
    
    override func tearDown() async throws {
        tradeManager = nil
        mockExchangeClient = nil
        try await super.tearDown()
    }
    
    // MARK: - Order Execution Tests
    
    func testSuccessfulMarketBuyOrder() async throws {
        // Given
        let orderRequest = OrderRequest(
            symbol: "BTCUSDT",
            side: .buy,
            quantity: 0.01,
            price: nil // Market order
        )
        
        let expectedFill = OrderFill(
            id: "test-fill-1",
            symbol: "BTCUSDT",
            side: .buy,
            quantity: 0.01,
            price: 45000.0,
            timestamp: Date()
        )
        
        mockExchangeClient.mockFill = expectedFill
        
        // When
        let actualFill = try await tradeManager.manualOrder(orderRequest)
        
        // Then
        XCTAssertEqual(actualFill.id, expectedFill.id)
        XCTAssertEqual(actualFill.symbol, expectedFill.symbol)
        XCTAssertEqual(actualFill.side, expectedFill.side)
        XCTAssertEqual(actualFill.quantity, expectedFill.quantity)
        XCTAssertEqual(actualFill.price, expectedFill.price)
        
        // Verify position was created
        XCTAssertNotNil(tradeManager.position)
        XCTAssertEqual(tradeManager.position?.quantity, 0.01)
        XCTAssertEqual(tradeManager.position?.avgPrice, 45000.0)
    }
    
    func testSuccessfulMarketSellOrder() async throws {
        // Given - First establish a long position
        let buyRequest = OrderRequest(symbol: "BTCUSDT", side: .buy, quantity: 0.02, price: nil)
        let buyFill = OrderFill(id: "buy-1", symbol: "BTCUSDT", side: .buy, quantity: 0.02, price: 45000.0, timestamp: Date())
        mockExchangeClient.mockFill = buyFill
        _ = try await tradeManager.manualOrder(buyRequest)
        
        // When - Sell half the position
        let sellRequest = OrderRequest(symbol: "BTCUSDT", side: .sell, quantity: 0.01, price: nil)
        let sellFill = OrderFill(id: "sell-1", symbol: "BTCUSDT", side: .sell, quantity: 0.01, price: 46000.0, timestamp: Date())
        mockExchangeClient.mockFill = sellFill
        
        let actualFill = try await tradeManager.manualOrder(sellRequest)
        
        // Then
        XCTAssertEqual(actualFill.quantity, 0.01)
        XCTAssertEqual(actualFill.price, 46000.0)
        
        // Verify position was reduced
        XCTAssertNotNil(tradeManager.position)
        XCTAssertEqual(tradeManager.position?.quantity, 0.01)
        XCTAssertEqual(tradeManager.position?.avgPrice, 45000.0)
        
        // Verify realized P&L was calculated (profit of $10 per unit * 0.01 = $0.10)
        let expectedRealizedPnL = (46000.0 - 45000.0) * 0.01
        XCTAssertEqual(tradeManager.equity, 10000.0 + expectedRealizedPnL, accuracy: 0.01)
    }
    
    func testCompletePositionClose() async throws {
        // Given - Establish a position
        let buyRequest = OrderRequest(symbol: "BTCUSDT", side: .buy, quantity: 0.01, price: nil)
        let buyFill = OrderFill(id: "buy-1", symbol: "BTCUSDT", side: .buy, quantity: 0.01, price: 45000.0, timestamp: Date())
        mockExchangeClient.mockFill = buyFill
        _ = try await tradeManager.manualOrder(buyRequest)
        
        // When - Close the entire position
        let sellRequest = OrderRequest(symbol: "BTCUSDT", side: .sell, quantity: 0.01, price: nil)
        let sellFill = OrderFill(id: "sell-1", symbol: "BTCUSDT", side: .sell, quantity: 0.01, price: 46000.0, timestamp: Date())
        mockExchangeClient.mockFill = sellFill
        
        _ = try await tradeManager.manualOrder(sellRequest)
        
        // Then
        XCTAssertNil(tradeManager.position, "Position should be nil when flat")
        
        // Verify realized P&L
        let expectedRealizedPnL = (46000.0 - 45000.0) * 0.01
        XCTAssertEqual(tradeManager.equity, 10000.0 + expectedRealizedPnL, accuracy: 0.01)
    }
    
    func testShortPositionExecution() async throws {
        // Given
        let sellRequest = OrderRequest(symbol: "BTCUSDT", side: .sell, quantity: 0.01, price: nil)
        let sellFill = OrderFill(id: "sell-1", symbol: "BTCUSDT", side: .sell, quantity: 0.01, price: 45000.0, timestamp: Date())
        mockExchangeClient.mockFill = sellFill
        
        // When
        let actualFill = try await tradeManager.manualOrder(sellRequest)
        
        // Then
        XCTAssertEqual(actualFill.side, .sell)
        XCTAssertNotNil(tradeManager.position)
        XCTAssertEqual(tradeManager.position?.quantity, -0.01) // Negative for short
        XCTAssertEqual(tradeManager.position?.avgPrice, 45000.0)
    }
    
    func testOrderRejectionWhenRiskLimitReached() async throws {
        // Given - Set up risk manager to reject trades
        let riskManager = RiskManager.shared
        riskManager.params.maxDailyLossPercent = 0.1 // Very low limit
        await riskManager.record(realizedPnL: -100.0, equity: 10000.0) // Exceed limit
        
        let orderRequest = OrderRequest(symbol: "BTCUSDT", side: .buy, quantity: 0.01, price: nil)
        
        // When & Then
        do {
            _ = try await tradeManager.manualOrder(orderRequest)
            XCTFail("Expected order to be rejected due to risk limits")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Daily loss limit reached"))
        }
    }
    
    func testMultipleOrdersUpdatePosition() async throws {
        // Given
        let orders = [
            (OrderRequest(symbol: "BTCUSDT", side: .buy, quantity: 0.01, price: nil), 
             OrderFill(id: "1", symbol: "BTCUSDT", side: .buy, quantity: 0.01, price: 45000.0, timestamp: Date())),
            (OrderRequest(symbol: "BTCUSDT", side: .buy, quantity: 0.01, price: nil),
             OrderFill(id: "2", symbol: "BTCUSDT", side: .buy, quantity: 0.01, price: 46000.0, timestamp: Date()))
        ]
        
        // When
        for (request, fill) in orders {
            mockExchangeClient.mockFill = fill
            _ = try await tradeManager.manualOrder(request)
        }
        
        // Then
        XCTAssertNotNil(tradeManager.position)
        XCTAssertEqual(tradeManager.position?.quantity, 0.02)
        
        // Verify average price calculation: (45000 * 0.01 + 46000 * 0.01) / 0.02 = 45500
        XCTAssertEqual(tradeManager.position?.avgPrice, 45500.0, accuracy: 0.01)
    }
    
    func testFillsAreRecorded() async throws {
        // Given
        let orderRequest = OrderRequest(symbol: "BTCUSDT", side: .buy, quantity: 0.01, price: nil)
        let expectedFill = OrderFill(id: "test-1", symbol: "BTCUSDT", side: .buy, quantity: 0.01, price: 45000.0, timestamp: Date())
        mockExchangeClient.mockFill = expectedFill
        
        // When
        _ = try await tradeManager.manualOrder(orderRequest)
        
        // Then
        XCTAssertEqual(tradeManager.fills.count, 1)
        XCTAssertEqual(tradeManager.fills.first?.id, expectedFill.id)
    }
}

// MARK: - Mock Exchange Client
class MockExchangeClient: ExchangeClient {
    var name: String = "Mock"
    var supportsWebSocket: Bool = false
    var exchange: Exchange = .binance
    var tickerStream: AsyncStream<Ticker> = AsyncStream { _ in }
    
    var mockFill: OrderFill?
    var shouldThrowError = false
    var errorToThrow: Error?
    
    func connectTickers(symbols: [String]) async throws {
        // Mock implementation
    }
    
    func disconnectTickers() async throws {
        // Mock implementation
    }
    
    func placeOrder(symbol: String, side: OrderSide, quantity: Double, price: Double?) async throws -> Order {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "MockError", code: 1)
        }
        
        return Order(
            id: UUID().uuidString,
            symbol: symbol,
            side: side,
            amount: quantity,
            price: price,
            status: .filled,
            createdAt: Date(),
            filledAt: Date()
        )
    }
    
    func placeMarketOrder(_ request: OrderRequest) async throws -> OrderFill {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "MockError", code: 1)
        }
        
        guard let fill = mockFill else {
            throw NSError(domain: "MockError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No mock fill configured"])
        }
        
        return fill
    }
    
    func getAccountInfo() async throws -> Account {
        return Account(balance: 10000.0, availableBalance: 10000.0)
    }
    
    func getOpenOrders(symbol: String?) async throws -> [Order] {
        return []
    }
    
    func cancelOrder(orderId: String, symbol: String) async throws {
        // Mock implementation
    }
}

// MARK: - Supporting Types
struct OrderRequest {
    let symbol: String
    let side: OrderSide
    let quantity: Double
    let price: Double?
}

struct OrderFill {
    let id: String
    let symbol: String
    let side: OrderSide
    let quantity: Double
    let price: Double
    let timestamp: Date
}

struct Account {
    let balance: Double
    let availableBalance: Double
}