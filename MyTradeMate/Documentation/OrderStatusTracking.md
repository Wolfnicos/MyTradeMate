# Order Status Tracking Implementation

## Overview

This document describes the implementation of order status tracking in MyTradeMate, which provides real-time visibility into the lifecycle of trading orders from submission to completion.

## Architecture

### Core Components

1. **OrderStatus.swift** - Data models for order status tracking
2. **OrderStatusTracker.swift** - Manager class for tracking order lifecycle
3. **OrderStatusView.swift** - UI components for displaying order status
4. **ActiveOrdersView.swift** - Dashboard widget for active orders

### Data Models

#### ExtendedOrderStatus
Provides granular order status tracking beyond the basic Order.Status:

```swift
public enum ExtendedOrderStatus: String, CaseIterable, Sendable {
    case submitting = "submitting"      // Order being prepared
    case submitted = "submitted"        // Order sent to exchange
    case pending = "pending"           // Order pending execution
    case partiallyFilled = "partially_filled"  // Partial execution
    case filled = "filled"            // Complete execution
    case cancelled = "cancelled"      // User cancelled
    case rejected = "rejected"        // Exchange rejected
    case failed = "failed"           // System failure
}
```

#### TrackedOrder
Represents a complete order with full lifecycle information:

```swift
public struct TrackedOrder: Identifiable, Sendable {
    public let id: String
    public let originalRequest: TradeRequest
    public let createdAt: Date
    public var currentStatus: ExtendedOrderStatus
    public var statusHistory: [OrderStatusUpdate]
    public var orderFill: OrderFill?
    public var errorMessage: String?
    public var estimatedCompletion: Date?
}
```

#### OrderStatusUpdate
Individual status change events:

```swift
public struct OrderStatusUpdate: Identifiable, Sendable {
    public let id: String
    public let orderId: String
    public let status: Order.Status
    public let message: String?
    public let timestamp: Date
    public let progress: Double // 0.0 to 1.0 for UI progress indicators
}
```

## Order Lifecycle

### Status Flow

1. **Submitting** (0.1 progress) - Order being prepared for submission
2. **Submitted** (0.2 progress) - Order sent to exchange
3. **Pending** (0.3 progress) - Order waiting for execution
4. **Partially Filled** (0.7 progress) - Order partially executed
5. **Filled** (1.0 progress) - Order completely executed
6. **Cancelled/Rejected/Failed** (0.0 progress) - Order terminated

### State Transitions

```
Submitting → Submitted → Pending → [Partially Filled] → Filled
     ↓           ↓          ↓              ↓              ↓
  Failed      Failed    Cancelled      Cancelled      [Complete]
                           ↓              ↓
                       Rejected       Rejected
```

## Usage

### Starting Order Tracking

```swift
let orderTracker = OrderStatusTracker.shared
let orderId = orderTracker.startTracking(request: tradeRequest)
```

### Updating Order Status

```swift
orderTracker.updateOrderStatus(
    orderId: orderId,
    status: .pending,
    message: "Order is pending execution"
)
```

### Executing Order with Full Tracking

```swift
let trackedOrder = await orderTracker.executeOrderWithTracking(tradeRequest)
```

### Retrieving Order Information

```swift
// Get specific order
let order = orderTracker.getTrackedOrder(orderId: orderId)

// Get orders for symbol
let btcOrders = orderTracker.getOrdersForSymbol("BTC/USDT")

// Get recent orders (last 24 hours)
let recentOrders = orderTracker.getRecentOrders()

// Get statistics
let stats = orderTracker.getOrderStatistics()
```

## UI Components

### OrderStatusView
Displays detailed order status with progress indicators:

```swift
OrderStatusView(trackedOrder: order, showDetails: true)
```

### CompactOrderStatusView
Compact display for lists and widgets:

```swift
CompactOrderStatusView(trackedOrder: order)
```

### ActiveOrdersView
Dashboard widget showing active orders:

```swift
ActiveOrdersView() // Shows up to 3 active orders with "View All" button
```

### OrderStatusListView
Full-screen view of all orders:

```swift
OrderStatusListView() // Filterable list of active/all orders
```

## Integration Points

### TradeConfirmationViewModel
Updated to use order status tracking:

```swift
func executeTradeOrder(_ request: TradeRequest) async -> Bool {
    let trackedOrder = await orderTracker.executeOrderWithTracking(request)
    currentOrderStatus = trackedOrder
    return trackedOrder.isCompleted
}
```

### DashboardView
Includes ActiveOrdersView widget:

```swift
VStack {
    // ... other sections
    activeOrdersSection  // Shows active orders
    // ... other sections
}
```

### Toast Notifications
Integrated with existing toast system:

```swift
// Success notification
toastManager.showTradeExecuted(symbol: "BTC/USDT", side: "buy")

// Error notification
toastManager.showTradeExecutionFailed(error: "Insufficient funds")
```

## Performance Considerations

### Memory Management
- Active orders: Unlimited (cleared when completed)
- Completed orders: Limited to 100 most recent
- Status updates: Limited to 50 most recent
- Automatic cleanup of orders older than 7 days

### Background Processing
- Status updates processed on main actor
- Order execution uses async/await for non-blocking UI
- Cleanup timer runs every hour

### Data Persistence
- Orders are kept in memory only (not persisted)
- Status history maintained for debugging
- Statistics calculated on-demand

## Error Handling

### Order Execution Errors
- Network errors: Retry with exponential backoff
- Exchange errors: Convert to AppError with context
- Validation errors: Immediate failure with clear message

### Status Update Errors
- Missing order ID: Log warning, continue
- Invalid status transition: Log error, allow update
- Concurrent updates: Last update wins

## Testing

### Unit Tests
- OrderStatusTrackingTests.swift provides comprehensive test coverage
- Tests for all status transitions
- Tests for order retrieval and filtering
- Tests for statistics calculation

### Integration Tests
- End-to-end order execution with status tracking
- UI component rendering with different order states
- Toast notification integration

## Future Enhancements

### Planned Features
1. **Order Modification Tracking** - Track order amendments and cancellations
2. **Batch Order Support** - Track multiple related orders as a group
3. **Performance Metrics** - Detailed execution time analysis
4. **Historical Analytics** - Long-term order performance trends
5. **Push Notifications** - Real-time status updates when app is backgrounded

### Potential Improvements
1. **Data Persistence** - Save order history to Core Data
2. **Real-time Updates** - WebSocket integration for live status updates
3. **Advanced Filtering** - Filter by date range, symbol, status, etc.
4. **Export Functionality** - Export order history to CSV/JSON
5. **Order Grouping** - Group related orders (e.g., bracket orders)

## API Reference

### OrderStatusTracker Methods

```swift
// Order Management
func startTracking(request: TradeRequest) -> String
func updateOrderStatus(orderId: String, status: ExtendedOrderStatus, ...)
func cancelOrder(orderId: String, reason: String)
func executeOrderWithTracking(_ request: TradeRequest) async -> TrackedOrder

// Order Retrieval
func getTrackedOrder(orderId: String) -> TrackedOrder?
func getOrdersForSymbol(_ symbol: String) -> [TrackedOrder]
func getRecentOrders() -> [TrackedOrder]

// Statistics
func getOrderStatistics() -> OrderStatistics
```

### OrderStatistics Properties

```swift
public struct OrderStatistics {
    public let totalOrders: Int
    public let successfulOrders: Int
    public let failedOrders: Int
    public let activeOrders: Int
    public let successRate: Double
    public let averageExecutionTime: TimeInterval
}
```

## Troubleshooting

### Common Issues

1. **Orders not appearing in UI**
   - Check if OrderStatusTracker.shared is being used consistently
   - Verify @StateObject is used for UI components

2. **Status updates not reflecting**
   - Ensure updates are called on @MainActor
   - Check if order ID matches exactly

3. **Memory usage growing**
   - Verify cleanup timer is running
   - Check if completed orders are being moved correctly

### Debug Information

Enable verbose logging to see detailed order tracking:

```swift
// In development builds
Log.verbose("Order status updated: \(orderId) -> \(status)")
```

## Conclusion

The order status tracking implementation provides comprehensive visibility into trading order lifecycle while maintaining good performance and user experience. The modular design allows for easy extension and integration with existing MyTradeMate components.