import XCTest
import Foundation
@testable import MyTradeMate

final class BinanceIntegrationTests: XCTestCase {
    
    var binanceClient: BinanceClient!
    
    override func setUp() async throws {
        try await super.setUp()
        binanceClient = BinanceClient()
    }
    
    override func tearDown() async throws {
        await binanceClient?.disconnectTickers()
        binanceClient = nil
        try await super.tearDown()
    }
    
    // MARK: - Binance API Integration Tests
    
    func testBinanceClientInitialization() async throws {
        // Given & When
        let client = BinanceClient()
        
        // Then
        await MainActor.run {
            XCTAssertEqual(client.name, "Binance")
            XCTAssertTrue(client.supportsWebSocket)
            XCTAssertEqual(client.exchange, .binance)
        }
    }
    
    func testBinanceSymbolNormalization() async throws {
        // Given
        let testSymbols = [
            Symbol("BTCUSDT", exchange: .binance),
            Symbol("btcusdt", exchange: .binance),
            Symbol("ETHUSDT", exchange: .binance),
            Symbol("ethusdt", exchange: .binance)
        ]
        
        // When & Then
        for symbol in testSymbols {
            let normalized = await binanceClient.normalized(symbol: symbol)
            XCTAssertEqual(normalized, symbol.raw.uppercased(), 
                         "Binance should normalize symbols to uppercase")
        }
    }
    
    func testBinanceBestPriceRetrieval() async throws {
        // Given
        let symbol = Symbol("BTCUSDT", exchange: .binance)
        
        // When
        do {
            let price = try await binanceClient.bestPrice(for: symbol)
            
            // Then
            XCTAssertGreaterThan(price, 0, "Price should be positive")
            XCTAssertLessThan(price, 1_000_000, "Price should be reasonable for BTC")
            XCTAssertGreaterThan(price, 1_000, "BTC price should be greater than $1000")
        } catch {
            // If the API call fails (network issues, rate limiting, etc.), 
            // we should handle it gracefully in tests
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .timedOut, .cannotConnectToHost:
                    throw XCTSkip("Network connectivity required for this test")
                default:
                    XCTFail("Unexpected URL error: \(urlError)")
                }
            } else {
                XCTFail("Unexpected error retrieving price: \(error)")
            }
        }
    }
    
    func testBinanceMarketOrderPlacement() async throws {
        // Given
        let symbol = Symbol("BTCUSDT", exchange: .binance)
        let orderRequest = OrderRequest(
            symbol: symbol,
            side: .buy,
            quantity: 0.001 // Small amount for testing
        )
        
        // When
        do {
            let orderFill = try await binanceClient.placeMarketOrder(orderRequest)
            
            // Then
            XCTAssertEqual(orderFill.symbol, symbol, "Order fill should have correct symbol")
            XCTAssertEqual(orderFill.side, .buy, "Order fill should have correct side")
            XCTAssertEqual(orderFill.quantity, 0.001, accuracy: 0.0001, "Order fill should have correct quantity")
            XCTAssertGreaterThan(orderFill.price, 0, "Order fill should have positive price")
            XCTAssertNotNil(orderFill.id, "Order fill should have an ID")
        } catch {
            // Handle expected errors in paper trading mode
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .timedOut, .cannotConnectToHost:
                    throw XCTSkip("Network connectivity required for this test")
                default:
                    XCTFail("Unexpected URL error: \(urlError)")
                }
            } else {
                XCTFail("Unexpected error placing order: \(error)")
            }
        }
    }
    
    func testBinanceWebSocketTickerStream() async throws {
        // Given
        let symbols = ["BTCUSDT", "ETHUSDT"]
        let tickerExpectation = XCTestExpectation(description: "Received ticker data")
        tickerExpectation.expectedFulfillmentCount = 2 // Expect at least 2 tickers
        
        var receivedTickers: [Ticker] = []
        
        // When
        do {
            try await binanceClient.connectTickers(symbols: symbols)
            
            // Start collecting ticker data
            let tickerTask = Task {
                for await ticker in await binanceClient.tickerStream {
                    receivedTickers.append(ticker)
                    tickerExpectation.fulfill()
                    
                    // Stop after receiving enough data
                    if receivedTickers.count >= 2 {
                        break
                    }
                }
            }
            
            // Wait for ticker data
            await fulfillment(of: [tickerExpectation], timeout: 30.0)
            
            // Cancel the ticker collection task
            tickerTask.cancel()
            
            // Then
            XCTAssertGreaterThanOrEqual(receivedTickers.count, 2, "Should have received ticker data")
            
            // Verify ticker data quality
            for ticker in receivedTickers {
                XCTAssertFalse(ticker.symbol.isEmpty, "Ticker should have a symbol")
                XCTAssertGreaterThan(ticker.price, 0, "Ticker should have positive price")
                XCTAssertTrue(symbols.contains(ticker.symbol), "Ticker symbol should be one we subscribed to")
            }
            
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .timedOut, .cannotConnectToHost:
                    throw XCTSkip("Network connectivity required for this test")
                default:
                    XCTFail("Unexpected URL error: \(urlError)")
                }
            } else {
                XCTFail("Unexpected error connecting to WebSocket: \(error)")
            }
        }
    }
    
    func testBinanceWebSocketReconnection() async throws {
        // Given
        let symbols = ["BTCUSDT"]
        let initialConnectionExpectation = XCTestExpectation(description: "Initial connection established")
        let reconnectionExpectation = XCTestExpectation(description: "Reconnection after disconnect")
        
        var tickerCount = 0
        
        // When
        do {
            try await binanceClient.connectTickers(symbols: symbols)
            
            let tickerTask = Task {
                for await ticker in await binanceClient.tickerStream {
                    tickerCount += 1
                    
                    if tickerCount == 1 {
                        initialConnectionExpectation.fulfill()
                    } else if tickerCount >= 3 {
                        reconnectionExpectation.fulfill()
                        break
                    }
                }
            }
            
            // Wait for initial connection
            await fulfillment(of: [initialConnectionExpectation], timeout: 15.0)
            
            // Simulate disconnection and reconnection
            await binanceClient.disconnectTickers()
            
            // Wait a moment
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Reconnect
            try await binanceClient.connectTickers(symbols: symbols)
            
            // Wait for reconnection
            await fulfillment(of: [reconnectionExpectation], timeout: 15.0)
            
            tickerTask.cancel()
            
            // Then
            XCTAssertGreaterThanOrEqual(tickerCount, 3, "Should have received tickers after reconnection")
            
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .timedOut, .cannotConnectToHost:
                    throw XCTSkip("Network connectivity required for this test")
                default:
                    XCTFail("Unexpected URL error: \(urlError)")
                }
            } else {
                XCTFail("Unexpected error during reconnection test: \(error)")
            }
        }
    }
    
    func testBinanceMultipleSymbolSubscription() async throws {
        // Given
        let symbols = ["BTCUSDT", "ETHUSDT", "ADAUSDT", "DOTUSDT"]
        let tickerExpectation = XCTestExpectation(description: "Received tickers for multiple symbols")
        tickerExpectation.expectedFulfillmentCount = symbols.count
        
        var receivedSymbols: Set<String> = []
        
        // When
        do {
            try await binanceClient.connectTickers(symbols: symbols)
            
            let tickerTask = Task {
                for await ticker in await binanceClient.tickerStream {
                    receivedSymbols.insert(ticker.symbol)
                    tickerExpectation.fulfill()
                    
                    // Stop when we've received all symbols
                    if receivedSymbols.count >= symbols.count {
                        break
                    }
                }
            }
            
            // Wait for ticker data from all symbols
            await fulfillment(of: [tickerExpectation], timeout: 45.0)
            
            tickerTask.cancel()
            
            // Then
            XCTAssertGreaterThanOrEqual(receivedSymbols.count, symbols.count, 
                                      "Should have received tickers for all subscribed symbols")
            
            for symbol in symbols {
                XCTAssertTrue(receivedSymbols.contains(symbol), 
                            "Should have received ticker for \(symbol)")
            }
            
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .timedOut, .cannotConnectToHost:
                    throw XCTSkip("Network connectivity required for this test")
                default:
                    XCTFail("Unexpected URL error: \(urlError)")
                }
            } else {
                XCTFail("Unexpected error with multiple symbol subscription: \(error)")
            }
        }
    }
    
    func testBinanceErrorHandling() async throws {
        // Given
        let invalidSymbol = Symbol("INVALIDPAIR", exchange: .binance)
        
        // When & Then - Test invalid symbol handling
        do {
            let _ = try await binanceClient.bestPrice(for: invalidSymbol)
            XCTFail("Should have thrown an error for invalid symbol")
        } catch {
            // Expected error for invalid symbol
            XCTAssertTrue(error is URLError || error is DecodingError, 
                        "Should get URL or decoding error for invalid symbol")
        }
        
        // Test invalid WebSocket connection
        do {
            try await binanceClient.connectTickers(symbols: ["INVALIDPAIR"])
            
            // Even with invalid symbols, connection might succeed but no data will be received
            // This is expected behavior as the WebSocket connection itself is valid
            
        } catch {
            // Connection errors are acceptable for invalid symbols
            XCTAssertTrue(error is URLError, "Should get URL error for connection issues")
        }
    }
    
    func testBinanceRateLimitHandling() async throws {
        // Given
        let symbol = Symbol("BTCUSDT", exchange: .binance)
        let requestCount = 5
        
        // When - Make multiple rapid requests
        var results: [Result<Double, Error>] = []
        
        await withTaskGroup(of: Result<Double, Error>.self) { group in
            for _ in 0..<requestCount {
                group.addTask {
                    do {
                        let price = try await self.binanceClient.bestPrice(for: symbol)
                        return .success(price)
                    } catch {
                        return .failure(error)
                    }
                }
            }
            
            for await result in group {
                results.append(result)
            }
        }
        
        // Then
        XCTAssertEqual(results.count, requestCount, "Should have completed all requests")
        
        // At least some requests should succeed (unless rate limited)
        let successCount = results.compactMap { result in
            if case .success = result { return result }
            return nil
        }.count
        
        // In a real scenario, we might get rate limited, but at least one should succeed
        XCTAssertGreaterThan(successCount, 0, "At least one request should succeed")
    }
    
    func testBinanceDataValidation() async throws {
        // Given
        let symbol = Symbol("BTCUSDT", exchange: .binance)
        
        // When
        do {
            let price = try await binanceClient.bestPrice(for: symbol)
            
            // Then - Validate data quality
            XCTAssertTrue(price.isFinite, "Price should be a finite number")
            XCTAssertFalse(price.isNaN, "Price should not be NaN")
            XCTAssertGreaterThan(price, 0, "Price should be positive")
            
            // BTC price should be within reasonable bounds
            XCTAssertGreaterThan(price, 100, "BTC price should be greater than $100")
            XCTAssertLessThan(price, 10_000_000, "BTC price should be less than $10M")
            
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .timedOut, .cannotConnectToHost:
                    throw XCTSkip("Network connectivity required for this test")
                default:
                    XCTFail("Unexpected URL error: \(urlError)")
                }
            } else {
                XCTFail("Unexpected error validating data: \(error)")
            }
        }
    }
}