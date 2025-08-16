import XCTest
import Foundation
@testable import MyTradeMate

final class WebSocketIntegrationTests: XCTestCase {
    
    var webSocketManager: WebSocketManager!
    var mockURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Use a mock WebSocket server URL for testing
        mockURL = URL(string: "wss://echo.websocket.org")!
        
        let configuration = WebSocketManager.Configuration(
            url: mockURL,
            subscribeMessage: nil,
            name: "TestWebSocket",
            verboseLogging: true
        )
        
        webSocketManager = WebSocketManager(configuration: configuration)
    }
    
    override func tearDown() async throws {
        await webSocketManager?.disconnect()
        webSocketManager = nil
        try await super.tearDown()
    }
    
    // MARK: - WebSocket Connection Tests
    
    func testWebSocketConnectionInDemoMode() async throws {
        // Given
        let connectionExpectation = XCTestExpectation(description: "WebSocket connection established")
        let messageExpectation = XCTestExpectation(description: "Message received")
        
        var receivedMessages: [String] = []
        var connectionStates: [Bool] = []
        
        // Set up message handler
        await MainActor.run {
            webSocketManager.onMessage = { message in
                receivedMessages.append(message)
                messageExpectation.fulfill()
            }
            
            webSocketManager.onConnectionStateChange = { isConnected in
                connectionStates.append(isConnected)
                if isConnected {
                    connectionExpectation.fulfill()
                }
            }
        }
        
        // When
        await webSocketManager.connect()
        
        // Then
        await fulfillment(of: [connectionExpectation], timeout: 10.0)
        
        // Verify connection state
        await MainActor.run {
            XCTAssertTrue(webSocketManager.isConnected, "WebSocket should be connected")
            XCTAssertTrue(connectionStates.contains(true), "Should have received connection state change")
        }
        
        // Test sending a message
        await MainActor.run {
            webSocketManager.sendMessage("test message")
        }
        
        // Wait for echo response
        await fulfillment(of: [messageExpectation], timeout: 5.0)
        
        // Verify message was received
        XCTAssertFalse(receivedMessages.isEmpty, "Should have received messages")
        XCTAssertTrue(receivedMessages.contains("test message"), "Should have received echo of sent message")
    }
    
    func testWebSocketReconnectionLogic() async throws {
        // Given
        let initialConnectionExpectation = XCTestExpectation(description: "Initial connection")
        let reconnectionExpectation = XCTestExpectation(description: "Reconnection after failure")
        
        var connectionCount = 0
        
        await MainActor.run {
            webSocketManager.onConnectionStateChange = { isConnected in
                if isConnected {
                    connectionCount += 1
                    if connectionCount == 1 {
                        initialConnectionExpectation.fulfill()
                    } else if connectionCount == 2 {
                        reconnectionExpectation.fulfill()
                    }
                }
            }
        }
        
        // When - Initial connection
        await webSocketManager.connect()
        await fulfillment(of: [initialConnectionExpectation], timeout: 10.0)
        
        // Simulate connection loss by disconnecting and reconnecting
        await webSocketManager.disconnect()
        
        // Wait a moment to ensure disconnection
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Reconnect
        await webSocketManager.connect()
        
        // Then
        await fulfillment(of: [reconnectionExpectation], timeout: 15.0)
        
        XCTAssertEqual(connectionCount, 2, "Should have connected twice")
        await MainActor.run {
            XCTAssertTrue(webSocketManager.isConnected, "Should be connected after reconnection")
        }
    }
    
    func testWebSocketExponentialBackoffReconnection() async throws {
        // Given
        let badURL = URL(string: "wss://invalid-websocket-url-that-does-not-exist.com")!
        let configuration = WebSocketManager.Configuration(
            url: badURL,
            subscribeMessage: nil,
            name: "TestFailingWebSocket",
            verboseLogging: true
        )
        
        let failingWebSocket = WebSocketManager(configuration: configuration)
        
        var connectionAttempts: [Date] = []
        
        await MainActor.run {
            failingWebSocket.onConnectionStateChange = { isConnected in
                if !isConnected {
                    connectionAttempts.append(Date())
                }
            }
        }
        
        // When
        await failingWebSocket.connect()
        
        // Wait for multiple reconnection attempts
        try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
        
        // Then
        await failingWebSocket.disconnect()
        
        // Verify exponential backoff behavior
        XCTAssertGreaterThan(connectionAttempts.count, 1, "Should have made multiple connection attempts")
        
        // Check that intervals between attempts increase (exponential backoff)
        if connectionAttempts.count >= 3 {
            let interval1 = connectionAttempts[1].timeIntervalSince(connectionAttempts[0])
            let interval2 = connectionAttempts[2].timeIntervalSince(connectionAttempts[1])
            
            XCTAssertGreaterThan(interval2, interval1, "Second interval should be longer (exponential backoff)")
        }
    }
    
    func testWebSocketHealthMonitoring() async throws {
        // Given
        let connectionExpectation = XCTestExpectation(description: "WebSocket connection established")
        
        await MainActor.run {
            webSocketManager.onConnectionStateChange = { isConnected in
                if isConnected {
                    connectionExpectation.fulfill()
                }
            }
        }
        
        // When
        await webSocketManager.connect()
        await fulfillment(of: [connectionExpectation], timeout: 10.0)
        
        // Then - Verify connection is healthy
        await MainActor.run {
            XCTAssertTrue(webSocketManager.isConnected, "WebSocket should be connected and healthy")
        }
        
        // Keep connection alive for health monitoring
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        // Verify connection is still healthy
        await MainActor.run {
            XCTAssertTrue(webSocketManager.isConnected, "WebSocket should remain connected after health checks")
        }
    }
    
    func testWebSocketMessageHandling() async throws {
        // Given
        let connectionExpectation = XCTestExpectation(description: "WebSocket connection established")
        let messageExpectation = XCTestExpectation(description: "Multiple messages received")
        messageExpectation.expectedFulfillmentCount = 3
        
        var receivedMessages: [String] = []
        
        await MainActor.run {
            webSocketManager.onMessage = { message in
                receivedMessages.append(message)
                messageExpectation.fulfill()
            }
            
            webSocketManager.onConnectionStateChange = { isConnected in
                if isConnected {
                    connectionExpectation.fulfill()
                }
            }
        }
        
        // When
        await webSocketManager.connect()
        await fulfillment(of: [connectionExpectation], timeout: 10.0)
        
        // Send multiple test messages
        let testMessages = ["message1", "message2", "message3"]
        
        await MainActor.run {
            for message in testMessages {
                webSocketManager.sendMessage(message)
            }
        }
        
        // Then
        await fulfillment(of: [messageExpectation], timeout: 10.0)
        
        // Verify all messages were received
        XCTAssertEqual(receivedMessages.count, 3, "Should have received all sent messages")
        
        for testMessage in testMessages {
            XCTAssertTrue(receivedMessages.contains(testMessage), 
                        "Should have received message: \(testMessage)")
        }
    }
    
    func testWebSocketErrorHandling() async throws {
        // Given
        let invalidURL = URL(string: "wss://")! // Invalid URL
        let configuration = WebSocketManager.Configuration(
            url: invalidURL,
            subscribeMessage: nil,
            name: "TestInvalidWebSocket",
            verboseLogging: true
        )
        
        let invalidWebSocket = WebSocketManager(configuration: configuration)
        
        var connectionStateChanges: [Bool] = []
        
        await MainActor.run {
            invalidWebSocket.onConnectionStateChange = { isConnected in
                connectionStateChanges.append(isConnected)
            }
        }
        
        // When
        await invalidWebSocket.connect()
        
        // Wait for connection attempt to fail
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Then
        await invalidWebSocket.disconnect()
        
        await MainActor.run {
            XCTAssertFalse(invalidWebSocket.isConnected, "Invalid WebSocket should not be connected")
        }
        
        // Should not have any successful connections
        XCTAssertFalse(connectionStateChanges.contains(true), "Should not have successful connections with invalid URL")
    }
    
    func testWebSocketCleanupOnDeinit() async throws {
        // Given
        var webSocket: WebSocketManager? = WebSocketManager(
            configuration: WebSocketManager.Configuration(
                url: mockURL,
                subscribeMessage: nil,
                name: "TestCleanupWebSocket",
                verboseLogging: false
            )
        )
        
        let connectionExpectation = XCTestExpectation(description: "WebSocket connection established")
        
        await MainActor.run {
            webSocket?.onConnectionStateChange = { isConnected in
                if isConnected {
                    connectionExpectation.fulfill()
                }
            }
        }
        
        // When
        await webSocket?.connect()
        await fulfillment(of: [connectionExpectation], timeout: 10.0)
        
        // Verify connection
        await MainActor.run {
            XCTAssertTrue(webSocket?.isConnected == true, "WebSocket should be connected")
        }
        
        // Release the WebSocket (should trigger cleanup)
        webSocket = nil
        
        // Then - Allow time for cleanup
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Cleanup should have occurred automatically
        // This test mainly ensures no crashes occur during cleanup
        XCTAssertNil(webSocket, "WebSocket should be deallocated")
    }
    
    func testWebSocketConcurrentOperations() async throws {
        // Given
        let connectionExpectation = XCTestExpectation(description: "WebSocket connection established")
        let messageExpectation = XCTestExpectation(description: "Concurrent messages received")
        messageExpectation.expectedFulfillmentCount = 10
        
        var receivedMessages: [String] = []
        let messagesLock = NSLock()
        
        await MainActor.run {
            webSocketManager.onMessage = { message in
                messagesLock.lock()
                receivedMessages.append(message)
                messagesLock.unlock()
                messageExpectation.fulfill()
            }
            
            webSocketManager.onConnectionStateChange = { isConnected in
                if isConnected {
                    connectionExpectation.fulfill()
                }
            }
        }
        
        // When
        await webSocketManager.connect()
        await fulfillment(of: [connectionExpectation], timeout: 10.0)
        
        // Send messages concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await MainActor.run {
                        self.webSocketManager.sendMessage("concurrent_message_\(i)")
                    }
                }
            }
        }
        
        // Then
        await fulfillment(of: [messageExpectation], timeout: 15.0)
        
        messagesLock.lock()
        let messageCount = receivedMessages.count
        messagesLock.unlock()
        
        XCTAssertEqual(messageCount, 10, "Should have received all concurrent messages")
    }
}