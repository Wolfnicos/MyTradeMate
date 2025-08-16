import XCTest
import Foundation
@testable import MyTradeMate

final class KrakenIntegrationTests: XCTestCase {
    
    var krakenClient: KrakenClient!
    
    override func setUp() async throws {
        try await super.setUp()
        krakenClient = KrakenClient()
    }
    
    override func tearDown() async throws {
        await krakenClient?.disconnectTickers()
        krakenClient = nil
        try await super.tearDown()
    }
    
    // MARK: - Kraken API Integration Tests
    
    func testKrakenClientInitialization() async throws {
        // Given & When
        let client = KrakenClient()
        
        // Then
        await MainActor.run {
            XCTAssertEqual(client.name, "Kraken")
            XCTAssertTrue(client.supportsWebSocket)
            XCTAssertEqual(client.exchange, .kraken)
        }
    }
    
    func testKrakenSymbolNormalization() async throws {
        // Given
        let testCases = [
            (Symbol("BTCUSDT", exchange: .kraken), "XBTUSDT"),
            (Symbol("btcusdt", exchange: .kraken), "XBTUSDT"),
            (Symbol("ETHUSDT", exchange: .kraken), "ETHUSDT"),
            (Symbol("ethusdt", exchange: .kraken), "ETHUSDT"),
            (Symbol("BTCUSD", exchange: .kraken), "XBTUSD"),
            (Symbol("ETHUSD", exchange: .kraken), "ETHUSD")
        ]
        
        // When & Then
        for (symbol, expected) in testCases {
            let normalized = await krakenClient.normalized(symbol: symbol)
            XCTAssertEqual(normalized, expected, 
                         "Kraken should normalize \(symbol.raw) to \(expected), got \(normalized)")
        }
    }
    
    func testKrakenBestPriceRetrieval() async throws {
        // Given
        let symbol = Symbol("BTCUSDT", exchange: .kraken)
        
        // When
        do {
            let price = try await krakenClient.bestPrice(for: symbol)
            
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
    
    func testKrakenMarketOrderPlacement() async throws {
        // Given
        let symbol = Symbol("BTCUSDT", exchange: .kraken)
        let orderRequest = OrderRequest(
            symbol: symbol,
            side: .buy,
            quantity: 0.001 // Small amount for testing
        )
        
        // When
        do {
            let orderFill = try await krakenClient.placeMarketOrder(orderRequest)
            
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
    
    func testKrakenWebSocketTickerStream() async throws {
        // Given
        let symbols = ["BTCUSDT", "ETHUSDT"]
        let tickerExpectation = XCTestExpectation(description: "Received ticker data")
        tickerExpectation.expectedFulfillmentCount = 2 // Expect at least 2 tickers
        
        var receivedTickers: [Ticker] = []
        
        // When
        do {
            try await krakenClient.connectTickers(symbols: symbols)
            
            // Start collecting ticker data
            let tickerTask = Task {
                for await ticker in await krakenClient.tickerStream {
                    receivedTickers.append(ticker)
                    tickerExpectation.fulfill()
                    
                    // Stop after receiving enough data
                    if receivedTickers.count >= 2 {
                        break
                    }
                }
            }
            
            // Wait for ticker data (Kraken might be slower than Binance)
            await fulfillment(of: [tickerExpectation], timeout: 45.0)
            
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
    
    func testKrakenWebSocketReconnection() async throws {
        // Given
        let symbols = ["BTCUSDT"]
        let initialConnectionExpectation = XCTestExpectation(description: "Initial connection established")
        let reconnectionExpectation = XCTestExpectation(description: "Reconnection after disconnect")
        
        var tickerCount = 0
        
        // When
        do {
            try await krakenClient.connectTickers(symbols: symbols)
            
            let tickerTask = Task {
                for await ticker in await krakenClient.tickerStream {
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
            await fulfillment(of: [initialConnectionExpectation], timeout: 30.0)
            
            // Simulate disconnection and reconnection
            await krakenClient.disconnectTickers()
            
            // Wait a moment
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            // Reconnect
            try await krakenClient.connectTickers(symbols: symbols)
            
            // Wait for reconnection
            await fulfillment(of: [reconnectionExpectation], timeout: 30.0)
            
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
    
    func testKrakenMultipleSymbolSubscription() async throws {
        // Given
        let symbols = ["BTCUSDT", "ETHUSDT"]
        let tickerExpectation = XCTestExpectation(description: "Received tickers for multiple symbols")
        tickerExpectation.expectedFulfillmentCount = symbols.count
        
        var receivedSymbols: Set<String> = []
        
        // When
        do {
            try await krakenClient.connectTickers(symbols: symbols)
            
            let tickerTask = Task {
                for await ticker in await krakenClient.tickerStream {
                    receivedSymbols.insert(ticker.symbol)
                    tickerExpectation.fulfill()
                    
                    // Stop when we've received all symbols
                    if receivedSymbols.count >= symbols.count {
                        break
                    }
                }
            }
            
            // Wait for ticker data from all symbols (Kraken can be slower)
            await fulfillment(of: [tickerExpectation], timeout: 60.0)
            
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
    
    func testKrakenErrorHandling() async throws {
        // Given
        let invalidSymbol = Symbol("INVALIDPAIR", exchange: .kraken)
        
        // When & Then - Test invalid symbol handling
        do {
            let _ = try await krakenClient.bestPrice(for: invalidSymbol)
            XCTFail("Should have thrown an error for invalid symbol")
        } catch {
            // Expected error for invalid symbol
            XCTAssertTrue(error is URLError || error is DecodingError, 
                        "Should get URL or decoding error for invalid symbol")
        }
        
        // Test invalid WebSocket connection
        do {
            try await krakenClient.connectTickers(symbols: ["INVALIDPAIR"])
            
            // Even with invalid symbols, connection might succeed but no data will be received
            // This is expected behavior as the WebSocket connection itself is valid
            
        } catch {
            // Connection errors are acceptable for invalid symbols
            XCTAssertTrue(error is URLError, "Should get URL error for connection issues")
        }
    }
    
    func testKrakenRateLimitHandling() async throws {
        // Given
        let symbol = Symbol("BTCUSDT", exchange: .kraken)
        let requestCount = 3 // Kraken has stricter rate limits
        
        // When - Make multiple requests with delays
        var results: [Result<Double, Error>] = []
        
        for i in 0..<requestCount {
            do {
                let price = try await krakenClient.bestPrice(for: symbol)
                results.append(.success(price))
            } catch {
                results.append(.failure(error))
            }
            
            // Add delay between requests to respect rate limits
            if i < requestCount - 1 {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
        }
        
        // Then
        XCTAssertEqual(results.count, requestCount, "Should have completed all requests")
        
        // At least some requests should succeed
        let successCount = results.compactMap { result in
            if case .success = result { return result }
            return nil
        }.count
        
        XCTAssertGreaterThan(successCount, 0, "At least one request should succeed")
    }
    
    func testKrakenDataValidation() async throws {
        // Given
        let symbol = Symbol("BTCUSDT", exchange: .kraken)
        
        // When
        do {
            let price = try await krakenClient.bestPrice(for: symbol)
            
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
    
    func testKrakenWebSocketMessageParsing() async throws {
        // Given
        let symbols = ["BTCUSDT"]
        let messageExpectation = XCTestExpectation(description: "Received and parsed WebSocket messages")
        
        var receivedTickers: [Ticker] = []
        
        // When
        do {
            try await krakenClient.connectTickers(symbols: symbols)
            
            let tickerTask = Task {
                for await ticker in await krakenClient.tickerStream {
                    receivedTickers.append(ticker)
                    
                    // Verify message parsing
                    XCTAssertFalse(ticker.symbol.isEmpty, "Parsed ticker should have symbol")
                    XCTAssertGreaterThan(ticker.price, 0, "Parsed ticker should have valid price")
                    XCTAssertTrue(ticker.time.timeIntervalSinceNow < 60, "Ticker timestamp should be recent")
                    
                    messageExpectation.fulfill()
                    break // Just need one valid message
                }
            }
            
            await fulfillment(of: [messageExpectation], timeout: 30.0)
            tickerTask.cancel()
            
            // Then
            XCTAssertGreaterThan(receivedTickers.count, 0, "Should have received and parsed ticker messages")
            
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .timedOut, .cannotConnectToHost:
                    throw XCTSkip("Network connectivity required for this test")
                default:
                    XCTFail("Unexpected URL error: \(urlError)")
                }
            } else {
                XCTFail("Unexpected error testing message parsing: \(error)")
            }
        }
    }
    
    func testKrakenConnectionStability() async throws {
        // Given
        let symbols = ["BTCUSDT"]
        let stabilityExpectation = XCTestExpectation(description: "Connection remains stable")
        
        var tickerCount = 0
        let targetTickerCount = 5
        
        // When
        do {
            try await krakenClient.connectTickers(symbols: symbols)
            
            let tickerTask = Task {
                for await ticker in await krakenClient.tickerStream {
                    tickerCount += 1
                    
                    // Verify each ticker is valid
                    XCTAssertFalse(ticker.symbol.isEmpty, "Each ticker should have a symbol")
                    XCTAssertGreaterThan(ticker.price, 0, "Each ticker should have a positive price")
                    
                    if tickerCount >= targetTickerCount {
                        stabilityExpectation.fulfill()
                        break
                    }
                }
            }
            
            // Wait for multiple tickers to test stability
            await fulfillment(of: [stabilityExpectation], timeout: 60.0)
            tickerTask.cancel()
            
            // Then
            XCTAssertGreaterThanOrEqual(tickerCount, targetTickerCount, 
                                      "Should maintain stable connection and receive multiple tickers")
            
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .timedOut, .cannotConnectToHost:
                    throw XCTSkip("Network connectivity required for this test")
                default:
                    XCTFail("Unexpected URL error: \(urlError)")
                }
            } else {
                XCTFail("Unexpected error testing connection stability: \(error)")
            }
        }
    }
}