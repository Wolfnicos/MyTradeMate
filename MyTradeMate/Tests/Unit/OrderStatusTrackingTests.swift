import XCTest
@testable import MyTradeMate

/// Unit tests for order status tracking functionality
@MainActor
final class OrderStatusTrackingTests: XCTestCase {
    
    private var orderTracker: OrderStatusTracker!
    private var sampleTradeRequest: TradeRequest!
    
    override func setUp() async throws {
        try await super.setUp()
        orderTracker = OrderStatusTracker.shared
        
        // Clear any existing orders for clean tests
        orderTracker.activeOrders.removeAll()
        orderTracker.completedOrders.removeAll()
        orderTracker.recentStatusUpdates.removeAll()
        
        sampleTradeRequest = TradeRequest(
            symbol: "BTC/USDT",
            side: .buy,
            amount: 0.001,
            price: 45000.0,
            mode: .manual,
            isDemo: true
        )
    }
    
    override func tearDown() async throws {
        orderTracker = nil
        sampleTradeRequest = nil
        try await super.tearDown()
    }
    
    // MARK: - Order Tracking Tests
    
    func testStartTrackingOrder() {
        // Given
        let initialActiveCount = orderTracker.activeOrders.count
        let initialUpdatesCount = orderTracker.recentStatusUpdates.count
        
        // When
        let orderId = orderTracker.startTracking(request: sampleTradeRequest)
        
        // Then
        XCTAssertFalse(orderId.isEmpty, "Order ID should not be empty")
        XCTAssertEqual(orderTracker.activeOrders.count, initialActiveCount + 1, "Should have one more active order")
        XCTAssertEqual(orderTracker.recentStatusUpdates.count, initialUpdatesCount + 1, "Should have one more status update")
        
        let trackedOrder = orderTracker.activeOrders.first { $0.id == orderId }
        XCTAssertNotNil(trackedOrder, "Tracked order should exist")
        XCTAssertEqual(trackedOrder?.currentStatus, .submitting, "Initial status should be submitting")
        XCTAssertEqual(trackedOrder?.originalRequest.symbol, sampleTradeRequest.symbol, "Symbol should match")
    }
    
    func testUpdateOrderStatus() {
        // Given
        let orderId = orderTracker.startTracking(request: sampleTradeRequest)
        let initialUpdatesCount = orderTracker.recentStatusUpdates.count
        
        // When
        orderTracker.updateOrderStatus(
            orderId: orderId,
            status: .pending,
            message: "Order is pending execution"
        )
        
        // Then
        let trackedOrder = orderTracker.activeOrders.first { $0.id == orderId }
        XCTAssertNotNil(trackedOrder, "Tracked order should still exist")
        XCTAssertEqual(trackedOrder?.currentStatus, .pending, "Status should be updated to pending")
        XCTAssertEqual(orderTracker.recentStatusUpdates.count, initialUpdatesCount + 1, "Should have one more status update")
        
        let latestUpdate = trackedOrder?.latestUpdate
        XCTAssertNotNil(latestUpdate, "Should have latest update")
        XCTAssertEqual(latestUpdate?.message, "Order is pending execution", "Update message should match")
    }
    
    func testOrderCompletionMovesToCompletedOrders() {
        // Given
        let orderId = orderTracker.startTracking(request: sampleTradeRequest)
        let initialActiveCount = orderTracker.activeOrders.count
        let initialCompletedCount = orderTracker.completedOrders.count
        
        // When
        orderTracker.updateOrderStatus(
            orderId: orderId,
            status: .filled,
            message: "Order executed successfully"
        )
        
        // Then
        XCTAssertEqual(orderTracker.activeOrders.count, initialActiveCount - 1, "Should have one less active order")
        XCTAssertEqual(orderTracker.completedOrders.count, initialCompletedCount + 1, "Should have one more completed order")
        
        let completedOrder = orderTracker.completedOrders.first { $0.id == orderId }
        XCTAssertNotNil(completedOrder, "Order should be in completed orders")
        XCTAssertEqual(completedOrder?.currentStatus, .filled, "Status should be filled")
        XCTAssertTrue(completedOrder?.isCompleted == true, "Order should be marked as completed")
    }
    
    func testOrderFailureMovesToCompletedOrders() {
        // Given
        let orderId = orderTracker.startTracking(request: sampleTradeRequest)
        let errorMessage = "Insufficient funds"
        
        // When
        orderTracker.updateOrderStatus(
            orderId: orderId,
            status: .failed,
            message: "Order execution failed",
            errorMessage: errorMessage
        )
        
        // Then
        let completedOrder = orderTracker.completedOrders.first { $0.id == orderId }
        XCTAssertNotNil(completedOrder, "Failed order should be in completed orders")
        XCTAssertEqual(completedOrder?.currentStatus, .failed, "Status should be failed")
        XCTAssertTrue(completedOrder?.isFailed == true, "Order should be marked as failed")
        XCTAssertEqual(completedOrder?.errorMessage, errorMessage, "Error message should be preserved")
    }
    
    func testCancelOrder() {
        // Given
        let orderId = orderTracker.startTracking(request: sampleTradeRequest)
        let cancelReason = "User cancelled"
        
        // When
        orderTracker.cancelOrder(orderId: orderId, reason: cancelReason)
        
        // Then
        let completedOrder = orderTracker.completedOrders.first { $0.id == orderId }
        XCTAssertNotNil(completedOrder, "Cancelled order should be in completed orders")
        XCTAssertEqual(completedOrder?.currentStatus, .cancelled, "Status should be cancelled")
        XCTAssertTrue(completedOrder?.isFailed == true, "Cancelled order should be marked as failed")
    }
    
    // MARK: - Order Retrieval Tests
    
    func testGetTrackedOrder() {
        // Given
        let orderId = orderTracker.startTracking(request: sampleTradeRequest)
        
        // When
        let retrievedOrder = orderTracker.getTrackedOrder(orderId: orderId)
        
        // Then
        XCTAssertNotNil(retrievedOrder, "Should be able to retrieve tracked order")
        XCTAssertEqual(retrievedOrder?.id, orderId, "Retrieved order should have correct ID")
        XCTAssertEqual(retrievedOrder?.originalRequest.symbol, sampleTradeRequest.symbol, "Symbol should match")
    }
    
    func testGetOrdersForSymbol() {
        // Given
        let btcRequest = TradeRequest(symbol: "BTC/USDT", side: .buy, amount: 0.001, price: 45000.0, mode: .manual, isDemo: true)
        let ethRequest = TradeRequest(symbol: "ETH/USDT", side: .sell, amount: 0.5, price: 3200.0, mode: .manual, isDemo: true)
        
        let btcOrderId = orderTracker.startTracking(request: btcRequest)
        let ethOrderId = orderTracker.startTracking(request: ethRequest)
        
        // When
        let btcOrders = orderTracker.getOrdersForSymbol("BTC/USDT")
        let ethOrders = orderTracker.getOrdersForSymbol("ETH/USDT")
        
        // Then
        XCTAssertEqual(btcOrders.count, 1, "Should have one BTC order")
        XCTAssertEqual(ethOrders.count, 1, "Should have one ETH order")
        XCTAssertEqual(btcOrders.first?.id, btcOrderId, "BTC order ID should match")
        XCTAssertEqual(ethOrders.first?.id, ethOrderId, "ETH order ID should match")
    }
    
    func testGetRecentOrders() {
        // Given
        let orderId1 = orderTracker.startTracking(request: sampleTradeRequest)
        let orderId2 = orderTracker.startTracking(request: sampleTradeRequest)
        
        // Complete one order
        orderTracker.updateOrderStatus(orderId: orderId1, status: .filled)
        
        // When
        let recentOrders = orderTracker.getRecentOrders()
        
        // Then
        XCTAssertEqual(recentOrders.count, 2, "Should have two recent orders")
        XCTAssertTrue(recentOrders.contains { $0.id == orderId1 }, "Should contain completed order")
        XCTAssertTrue(recentOrders.contains { $0.id == orderId2 }, "Should contain active order")
    }
    
    // MARK: - Statistics Tests
    
    func testOrderStatistics() {
        // Given
        let orderId1 = orderTracker.startTracking(request: sampleTradeRequest)
        let orderId2 = orderTracker.startTracking(request: sampleTradeRequest)
        let orderId3 = orderTracker.startTracking(request: sampleTradeRequest)
        
        // Complete orders with different outcomes
        orderTracker.updateOrderStatus(orderId: orderId1, status: .filled)
        orderTracker.updateOrderStatus(orderId: orderId2, status: .failed)
        // Leave orderId3 active
        
        // When
        let statistics = orderTracker.getOrderStatistics()
        
        // Then
        XCTAssertEqual(statistics.totalOrders, 3, "Should have 3 total orders")
        XCTAssertEqual(statistics.successfulOrders, 1, "Should have 1 successful order")
        XCTAssertEqual(statistics.failedOrders, 1, "Should have 1 failed order")
        XCTAssertEqual(statistics.activeOrders, 1, "Should have 1 active order")
        XCTAssertEqual(statistics.successRate, 1.0/3.0, accuracy: 0.01, "Success rate should be 33.33%")
    }
    
    // MARK: - Extended Order Status Tests
    
    func testExtendedOrderStatusProperties() {
        // Test active statuses
        XCTAssertTrue(ExtendedOrderStatus.submitting.isActive, "Submitting should be active")
        XCTAssertTrue(ExtendedOrderStatus.pending.isActive, "Pending should be active")
        XCTAssertTrue(ExtendedOrderStatus.partiallyFilled.isActive, "Partially filled should be active")
        
        // Test inactive statuses
        XCTAssertFalse(ExtendedOrderStatus.filled.isActive, "Filled should not be active")
        XCTAssertFalse(ExtendedOrderStatus.cancelled.isActive, "Cancelled should not be active")
        XCTAssertFalse(ExtendedOrderStatus.failed.isActive, "Failed should not be active")
        
        // Test success status
        XCTAssertTrue(ExtendedOrderStatus.filled.isSuccess, "Filled should be success")
        XCTAssertFalse(ExtendedOrderStatus.failed.isSuccess, "Failed should not be success")
        
        // Test failure statuses
        XCTAssertTrue(ExtendedOrderStatus.failed.isFailure, "Failed should be failure")
        XCTAssertTrue(ExtendedOrderStatus.cancelled.isFailure, "Cancelled should be failure")
        XCTAssertTrue(ExtendedOrderStatus.rejected.isFailure, "Rejected should be failure")
        XCTAssertFalse(ExtendedOrderStatus.filled.isFailure, "Filled should not be failure")
    }
    
    func testExtendedOrderStatusProgress() {
        // Test progress values
        XCTAssertEqual(ExtendedOrderStatus.submitting.progress, 0.1, accuracy: 0.01, "Submitting progress should be 0.1")
        XCTAssertEqual(ExtendedOrderStatus.pending.progress, 0.3, accuracy: 0.01, "Pending progress should be 0.3")
        XCTAssertEqual(ExtendedOrderStatus.partiallyFilled.progress, 0.7, accuracy: 0.01, "Partially filled progress should be 0.7")
        XCTAssertEqual(ExtendedOrderStatus.filled.progress, 1.0, accuracy: 0.01, "Filled progress should be 1.0")
        XCTAssertEqual(ExtendedOrderStatus.failed.progress, 0.0, accuracy: 0.01, "Failed progress should be 0.0")
    }
    
    func testExtendedOrderStatusDisplayText() {
        XCTAssertEqual(ExtendedOrderStatus.submitting.displayText, "Submitting Order...")
        XCTAssertEqual(ExtendedOrderStatus.filled.displayText, "Filled")
        XCTAssertEqual(ExtendedOrderStatus.failed.displayText, "Failed")
    }
    
    // MARK: - TrackedOrder Tests
    
    func testTrackedOrderInitialization() {
        // When
        let trackedOrder = TrackedOrder(originalRequest: sampleTradeRequest)
        
        // Then
        XCTAssertFalse(trackedOrder.id.isEmpty, "Order ID should not be empty")
        XCTAssertEqual(trackedOrder.currentStatus, .submitting, "Initial status should be submitting")
        XCTAssertTrue(trackedOrder.statusHistory.isEmpty, "Status history should be empty initially")
        XCTAssertNil(trackedOrder.orderFill, "Order fill should be nil initially")
        XCTAssertNil(trackedOrder.errorMessage, "Error message should be nil initially")
        XCTAssertTrue(trackedOrder.isActive, "Order should be active initially")
        XCTAssertFalse(trackedOrder.isCompleted, "Order should not be completed initially")
        XCTAssertFalse(trackedOrder.isFailed, "Order should not be failed initially")
    }
    
    func testTrackedOrderStatusUpdate() {
        // Given
        var trackedOrder = TrackedOrder(originalRequest: sampleTradeRequest)
        let testMessage = "Order is pending execution"
        
        // When
        trackedOrder.updateStatus(.pending, message: testMessage)
        
        // Then
        XCTAssertEqual(trackedOrder.currentStatus, .pending, "Status should be updated")
        XCTAssertEqual(trackedOrder.statusHistory.count, 1, "Should have one status update")
        XCTAssertEqual(trackedOrder.latestUpdate?.message, testMessage, "Latest update message should match")
        XCTAssertNotNil(trackedOrder.estimatedCompletion, "Should have estimated completion for active order")
    }
    
    func testTrackedOrderDuration() {
        // Given
        let trackedOrder = TrackedOrder(originalRequest: sampleTradeRequest, createdAt: Date().addingTimeInterval(-60))
        
        // When
        let duration = trackedOrder.duration
        
        // Then
        XCTAssertGreaterThan(duration, 59, "Duration should be at least 59 seconds")
        XCTAssertLessThan(duration, 61, "Duration should be less than 61 seconds")
    }
}

// MARK: - Order Status Update Tests

final class OrderStatusUpdateTests: XCTestCase {
    
    func testOrderStatusUpdateInitialization() {
        // Given
        let orderId = "test-order-123"
        let status = Order.Status.pending
        let message = "Order is pending"
        let progress = 0.5
        
        // When
        let update = OrderStatusUpdate(
            orderId: orderId,
            status: status,
            message: message,
            progress: progress
        )
        
        // Then
        XCTAssertFalse(update.id.isEmpty, "Update ID should not be empty")
        XCTAssertEqual(update.orderId, orderId, "Order ID should match")
        XCTAssertEqual(update.status, status, "Status should match")
        XCTAssertEqual(update.message, message, "Message should match")
        XCTAssertEqual(update.progress, progress, accuracy: 0.01, "Progress should match")
        XCTAssertNotNil(update.timestamp, "Timestamp should not be nil")
    }
    
    func testOrderStatusUpdateDefaults() {
        // Given
        let orderId = "test-order-123"
        let status = Order.Status.filled
        
        // When
        let update = OrderStatusUpdate(orderId: orderId, status: status)
        
        // Then
        XCTAssertNil(update.message, "Message should be nil by default")
        XCTAssertEqual(update.progress, 0.0, accuracy: 0.01, "Progress should be 0.0 by default")
    }
}

// MARK: - Order Statistics Tests

final class OrderStatisticsTests: XCTestCase {
    
    func testOrderStatisticsFormatting() {
        // Given
        let statistics = OrderStatistics(
            totalOrders: 10,
            successfulOrders: 8,
            failedOrders: 2,
            activeOrders: 1,
            successRate: 0.8,
            averageExecutionTime: 2.5
        )
        
        // Then
        XCTAssertEqual(statistics.successRatePercentage, "80.0%", "Success rate percentage should be formatted correctly")
        XCTAssertEqual(statistics.averageExecutionTimeFormatted, "2.5s", "Average execution time should be formatted correctly")
    }
    
    func testOrderStatisticsFormattingMilliseconds() {
        // Given
        let statistics = OrderStatistics(
            totalOrders: 5,
            successfulOrders: 5,
            failedOrders: 0,
            activeOrders: 0,
            successRate: 1.0,
            averageExecutionTime: 0.5
        )
        
        // Then
        XCTAssertEqual(statistics.averageExecutionTimeFormatted, "500ms", "Sub-second times should be formatted in milliseconds")
    }
}