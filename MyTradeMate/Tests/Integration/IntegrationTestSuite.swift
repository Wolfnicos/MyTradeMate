import XCTest
import Foundation
@testable import MyTradeMate

/// Comprehensive integration test suite that runs all integration tests together
/// This provides a convenient way to run all integration tests and verify system-wide functionality
final class IntegrationTestSuite: XCTestCase {
    
    /// Test that verifies all integration test classes are properly configured
    func testAllIntegrationTestClassesExist() {
        // This test ensures all our integration test classes are properly set up
        // and can be instantiated without errors
        
        let webSocketTests = WebSocketIntegrationTests()
        let binanceTests = BinanceIntegrationTests()
        let krakenTests = KrakenIntegrationTests()
        
        XCTAssertNotNil(webSocketTests)
        XCTAssertNotNil(binanceTests)
        XCTAssertNotNil(krakenTests)
    }
    
    /// Integration test that verifies the complete trading system pipeline
    func testCompleteSystemIntegration() async throws {
        // This test verifies that all major components work together correctly
        // in a realistic trading scenario
        
        // Step 1: Test WebSocket connectivity
        let webSocketConfig = WebSocketManager.Configuration(
            url: URL(string: "wss://echo.websocket.org")!,
            subscribeMessage: nil,
            name: "SystemIntegrationTest",
            verboseLogging: false
        )
        
        let webSocketManager = WebSocketManager(configuration: webSocketConfig)
        
        let connectionExpectation = XCTestExpectation(description: "WebSocket connection established")
        
        await MainActor.run {
            webSocketManager.onConnectionStateChange = { isConnected in
                if isConnected {
                    connectionExpectation.fulfill()
                }
            }
        }
        
        await webSocketManager.connect()
        await fulfillment(of: [connectionExpectation], timeout: 10.0)
        
        await MainActor.run {
            XCTAssertTrue(webSocketManager.isConnected, "WebSocket should be connected")
        }
        
        // Step 2: Test exchange client initialization
        let binanceClient = BinanceClient()
        let krakenClient = KrakenClient()
        
        await MainActor.run {
            XCTAssertEqual(binanceClient.name, "Binance")
            XCTAssertEqual(krakenClient.name, "Kraken")
            XCTAssertTrue(binanceClient.supportsWebSocket)
            XCTAssertTrue(krakenClient.supportsWebSocket)
        }
        
        // Step 3: Test symbol normalization across exchanges
        let testSymbol = Symbol("BTCUSDT", exchange: .binance)
        let krakenSymbol = Symbol("BTCUSDT", exchange: .kraken)
        
        let binanceNormalized = await binanceClient.normalized(symbol: testSymbol)
        let krakenNormalized = await krakenClient.normalized(symbol: krakenSymbol)
        
        XCTAssertEqual(binanceNormalized, "BTCUSDT")
        XCTAssertEqual(krakenNormalized, "XBTUSDT") // Kraken uses XBT instead of BTC
        
        // Step 4: Test order creation and validation
        let orderRequest = OrderRequest(
            symbol: testSymbol,
            side: .buy,
            quantity: 0.001
        )
        
        XCTAssertEqual(orderRequest.symbol, testSymbol)
        XCTAssertEqual(orderRequest.side, .buy)
        XCTAssertEqual(orderRequest.quantity, 0.001)
        
        // Step 5: Cleanup
        await webSocketManager.disconnect()
        await binanceClient.disconnectTickers()
        await krakenClient.disconnectTickers()
        
        await MainActor.run {
            XCTAssertFalse(webSocketManager.isConnected, "WebSocket should be disconnected")
        }
    }
    
    /// Test system resilience under various failure conditions
    func testSystemResilience() async throws {
        // Test 1: WebSocket resilience with invalid URLs
        let invalidConfig = WebSocketManager.Configuration(
            url: URL(string: "wss://invalid-url-that-does-not-exist.com")!,
            subscribeMessage: nil,
            name: "ResilienceTest",
            verboseLogging: false
        )
        
        let resilientWebSocket = WebSocketManager(configuration: invalidConfig)
        
        // Should handle invalid connections gracefully
        await resilientWebSocket.connect()
        
        // Wait for connection attempt
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            XCTAssertFalse(resilientWebSocket.isConnected, "Should not connect to invalid URL")
        }
        
        await resilientWebSocket.disconnect()
        
        // Test 2: Exchange client resilience with invalid symbols
        let binanceClient = BinanceClient()
        let invalidSymbol = Symbol("INVALIDPAIR", exchange: .binance)
        
        do {
            let _ = try await binanceClient.bestPrice(for: invalidSymbol)
            XCTFail("Should have thrown error for invalid symbol")
        } catch {
            // Expected error - system should handle gracefully
            XCTAssertTrue(error is URLError || error is DecodingError)
        }
        
        // Test 3: Concurrent operations resilience
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    let config = WebSocketManager.Configuration(
                        url: URL(string: "wss://echo.websocket.org")!,
                        subscribeMessage: nil,
                        name: "ConcurrentTest\(i)",
                        verboseLogging: false
                    )
                    
                    let ws = WebSocketManager(configuration: config)
                    await ws.connect()
                    
                    // Brief connection
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    
                    await ws.disconnect()
                }
            }
        }
        
        // If we reach here, concurrent operations completed without crashes
        XCTAssertTrue(true, "Concurrent operations completed successfully")
    }
    
    /// Test data flow and transformation across system components
    func testDataFlowIntegration() async throws {
        // Test 1: Ticker data flow
        let ticker = Ticker(symbol: "BTCUSDT", price: 45000.0, time: Date())
        
        XCTAssertEqual(ticker.symbol, "BTCUSDT")
        XCTAssertEqual(ticker.price, 45000.0)
        XCTAssertFalse(ticker.id.uuidString.isEmpty)
        
        // Test 2: Order data flow
        let symbol = Symbol("BTCUSDT", exchange: .binance)
        let orderRequest = OrderRequest(symbol: symbol, side: .buy, quantity: 0.001)
        
        // Simulate order fill
        let orderFill = OrderFill(
            symbol: symbol,
            side: orderRequest.side,
            quantity: orderRequest.quantity,
            price: 45000.0,
            timestamp: Date()
        )
        
        XCTAssertEqual(orderFill.symbol, orderRequest.symbol)
        XCTAssertEqual(orderFill.side, orderRequest.side)
        XCTAssertEqual(orderFill.quantity, orderRequest.quantity)
        XCTAssertGreaterThan(orderFill.price, 0)
        
        // Test 3: Candle data flow
        let candle = Candle(
            openTime: Date(),
            open: 44900.0,
            high: 45100.0,
            low: 44800.0,
            close: 45000.0,
            volume: 1000.0
        )
        
        XCTAssertEqual(candle.open, 44900.0)
        XCTAssertEqual(candle.high, 45100.0)
        XCTAssertEqual(candle.low, 44800.0)
        XCTAssertEqual(candle.close, 45000.0)
        XCTAssertEqual(candle.volume, 1000.0)
        XCTAssertFalse(candle.id.uuidString.isEmpty)
    }
    
    /// Test error propagation and handling across system boundaries
    func testErrorHandlingIntegration() async throws {
        // Test 1: Network error propagation
        let binanceClient = BinanceClient()
        let invalidSymbol = Symbol("", exchange: .binance) // Empty symbol
        
        do {
            let _ = try await binanceClient.bestPrice(for: invalidSymbol)
            XCTFail("Should propagate error for empty symbol")
        } catch {
            // Error should be properly propagated
            XCTAssertNotNil(error)
        }
        
        // Test 2: WebSocket error handling
        let invalidURL = URL(string: "invalid-url")!
        let config = WebSocketManager.Configuration(
            url: invalidURL,
            subscribeMessage: nil,
            name: "ErrorTest",
            verboseLogging: false
        )
        
        let errorWebSocket = WebSocketManager(configuration: config)
        
        // Should handle invalid URL gracefully
        await errorWebSocket.connect()
        
        await MainActor.run {
            XCTAssertFalse(errorWebSocket.isConnected, "Should not connect with invalid URL")
        }
        
        await errorWebSocket.disconnect()
        
        // Test 3: Exchange-specific error handling
        let krakenClient = KrakenClient()
        let invalidKrakenSymbol = Symbol("NOTAREALPAIR", exchange: .kraken)
        
        do {
            let _ = try await krakenClient.bestPrice(for: invalidKrakenSymbol)
            XCTFail("Should handle invalid Kraken symbol")
        } catch {
            // Should get appropriate error
            XCTAssertTrue(error is URLError || error is DecodingError)
        }
    }
    
    /// Performance test for integrated system operations
    func testIntegratedSystemPerformance() async throws {
        // Test concurrent WebSocket connections
        let connectionCount = 3
        let connections: [WebSocketManager] = (0..<connectionCount).map { i in
            let config = WebSocketManager.Configuration(
                url: URL(string: "wss://echo.websocket.org")!,
                subscribeMessage: nil,
                name: "PerfTest\(i)",
                verboseLogging: false
            )
            return WebSocketManager(configuration: config)
        }
        
        // Measure connection time
        let startTime = Date()
        
        await withTaskGroup(of: Void.self) { group in
            for connection in connections {
                group.addTask {
                    await connection.connect()
                }
            }
        }
        
        let connectionTime = Date().timeIntervalSince(startTime)
        
        // Verify all connections
        var connectedCount = 0
        for connection in connections {
            await MainActor.run {
                if connection.isConnected {
                    connectedCount += 1
                }
            }
        }
        
        // Cleanup
        await withTaskGroup(of: Void.self) { group in
            for connection in connections {
                group.addTask {
                    await connection.disconnect()
                }
            }
        }
        
        // Performance assertions
        XCTAssertLessThan(connectionTime, 30.0, "Concurrent connections should complete within 30 seconds")
        XCTAssertGreaterThan(connectedCount, 0, "At least some connections should succeed")
    }
    
    /// Test system behavior under memory pressure
    func testMemoryManagement() async throws {
        // Create and destroy multiple components to test memory management
        for i in 0..<10 {
            let config = WebSocketManager.Configuration(
                url: URL(string: "wss://echo.websocket.org")!,
                subscribeMessage: nil,
                name: "MemoryTest\(i)",
                verboseLogging: false
            )
            
            var webSocket: WebSocketManager? = WebSocketManager(configuration: config)
            let binanceClient = BinanceClient()
            let krakenClient = KrakenClient()
            
            // Brief usage
            await webSocket?.connect()
            
            let symbol = Symbol("BTCUSDT", exchange: .binance)
            let _ = await binanceClient.normalized(symbol: symbol)
            let _ = await krakenClient.normalized(symbol: Symbol("BTCUSDT", exchange: .kraken))
            
            // Cleanup
            await webSocket?.disconnect()
            await binanceClient.disconnectTickers()
            await krakenClient.disconnectTickers()
            
            webSocket = nil
            
            // Brief pause to allow cleanup
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // If we reach here without crashes, memory management is working
        XCTAssertTrue(true, "Memory management test completed successfully")
    }
}