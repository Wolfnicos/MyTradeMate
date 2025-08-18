import Foundation
import Combine
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "OrderStatusTracker")

// MARK: - Order Status Types (Local definitions to resolve build issues)

/// Extended order status for more granular tracking
public enum ExtendedOrderStatus: String, CaseIterable, Sendable {
    case submitting = "submitting"
    case submitted = "submitted"
    case pending = "pending"
    case partiallyFilled = "partially_filled"
    case filled = "filled"
    case cancelled = "cancelled"
    case rejected = "rejected"
    case failed = "failed"
    
    /// User-friendly display text
    public var displayText: String {
        switch self {
        case .submitting:
            return "Submitting Order..."
        case .submitted:
            return "Order Submitted"
        case .pending:
            return "Pending"
        case .partiallyFilled:
            return "Partially Filled"
        case .filled:
            return "Filled"
        case .cancelled:
            return "Cancelled"
        case .rejected:
            return "Rejected"
        case .failed:
            return "Failed"
        }
    }
    
    /// Progress value for UI indicators (0.0 to 1.0)
    public var progress: Double {
        switch self {
        case .submitting:
            return 0.1
        case .submitted:
            return 0.2
        case .pending:
            return 0.3
        case .partiallyFilled:
            return 0.7
        case .filled:
            return 1.0
        case .cancelled, .rejected, .failed:
            return 0.0
        }
    }
    
    /// Whether this status indicates the order is still active
    public var isActive: Bool {
        switch self {
        case .submitting, .submitted, .pending, .partiallyFilled:
            return true
        case .filled, .cancelled, .rejected, .failed:
            return false
        }
    }
}

/// Represents the current status of an order with additional context
public struct OrderStatusUpdate: Identifiable, Sendable {
    public let id: String
    public let orderId: String
    public let message: String?
    public let timestamp: Date
    public let progress: Double
    public let previousStatus: ExtendedOrderStatus?
    
    public init(
        id: String = UUID().uuidString,
        orderId: String,
        message: String? = nil,
        timestamp: Date = Date(),
        progress: Double = 0.0,
        previousStatus: ExtendedOrderStatus? = nil
    ) {
        self.id = id
        self.orderId = orderId
        self.message = message
        self.timestamp = timestamp
        self.progress = progress
        self.previousStatus = previousStatus
    }
}

/// Tracked order with full lifecycle information
public struct TrackedOrder: Identifiable, Sendable {
    public let id: String
    public let originalRequest: TradeRequest
    public let createdAt: Date
    public var currentStatus: ExtendedOrderStatus
    public var statusHistory: [OrderStatusUpdate]
    public var orderFill: OrderFill?
    public var errorMessage: String?
    public var estimatedCompletion: Date?
    
    public init(
        id: String = UUID().uuidString,
        originalRequest: TradeRequest,
        createdAt: Date = Date(),
        currentStatus: ExtendedOrderStatus = .submitting
    ) {
        self.id = id
        self.originalRequest = originalRequest
        self.createdAt = createdAt
        self.currentStatus = currentStatus
        self.statusHistory = []
        self.orderFill = nil
        self.errorMessage = nil
        self.estimatedCompletion = nil
    }
    
    /// Add a status update to the order
    public mutating func updateStatus(
        _ status: ExtendedOrderStatus,
        message: String? = nil,
        orderFill: OrderFill? = nil,
        errorMessage: String? = nil
    ) {
        let previousStatus = self.currentStatus
        self.currentStatus = status
        self.orderFill = orderFill
        self.errorMessage = errorMessage
        
        let update = OrderStatusUpdate(
            orderId: id,
            message: message ?? status.displayText,
            progress: status.progress,
            previousStatus: previousStatus
        )
        
        statusHistory.append(update)
        
        // Set estimated completion for active orders
        if status.isActive && estimatedCompletion == nil {
            estimatedCompletion = Date().addingTimeInterval(30) // 30 seconds estimate
        } else if !status.isActive {
            estimatedCompletion = nil
        }
    }
    
    /// Get the latest status update
    public var latestUpdate: OrderStatusUpdate? {
        return statusHistory.last
    }
    
    /// Duration since order creation
    public var duration: TimeInterval {
        return Date().timeIntervalSince(createdAt)
    }
    
    /// Whether the order is still being processed
    public var isActive: Bool {
        return currentStatus.isActive
    }
    
    /// Whether the order completed successfully
    public var isCompleted: Bool {
        return currentStatus == .filled
    }
    
    /// Whether the order failed
    public var isFailed: Bool {
        switch currentStatus {
        case .cancelled, .rejected, .failed:
            return true
        default:
            return false
        }
    }
}



/// Manages order status tracking throughout the order lifecycle
@MainActor
public final class OrderStatusTracker: ObservableObject {
    public static let shared = OrderStatusTracker()
    
    // MARK: - Published Properties
    @Published public private(set) var activeOrders: [TrackedOrder] = []
    @Published public private(set) var completedOrders: [TrackedOrder] = []
    @Published public private(set) var recentStatusUpdates: [OrderStatusUpdate] = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let maxRecentUpdates = 50
    private let maxCompletedOrders = 100
    
    // MARK: - Dependencies
    private let tradeManager = TradeManager.shared
    
    private init() {
        setupCleanupTimer()
    }
    
    // MARK: - Order Tracking
    
    /// Start tracking a new order
    public func startTracking(request: TradeRequest) -> String {
        let orderId = UUID().uuidString
        var trackedOrder = TrackedOrder(
            id: orderId,
            originalRequest: request,
            currentStatus: .submitting
        )
        
        // Add initial status update
        trackedOrder.updateStatus(.submitting, message: "Preparing order for submission...")
        
        activeOrders.append(trackedOrder)
        addRecentUpdate(trackedOrder.latestUpdate!)
        
        logger.info("Started tracking order: \(orderId) - \(request.side.rawValue) \(request.amount) \(request.symbol)")
        
        return orderId
    }
    
    /// Update order status
    public func updateOrderStatus(
        orderId: String,
        status: ExtendedOrderStatus,
        message: String? = nil,
        orderFill: OrderFill? = nil,
        errorMessage: String? = nil
    ) {
        guard let index = activeOrders.firstIndex(where: { $0.id == orderId }) else {
            logger.warning("Attempted to update non-existent order: \(orderId)")
            return
        }
        
        activeOrders[index].updateStatus(
            status,
            message: message,
            orderFill: orderFill,
            errorMessage: errorMessage
        )
        
        if let update = activeOrders[index].latestUpdate {
            addRecentUpdate(update)
        }
        
        // Move to completed orders if order is no longer active
        if !status.isActive {
            let completedOrder = activeOrders.remove(at: index)
            addCompletedOrder(completedOrder)
            
            logger.info("Order completed: \(orderId) - Status: \(status.displayText)")
        }
    }
    
    /// Execute an order with full status tracking
    public func executeOrderWithTracking(_ request: TradeRequest) async -> TrackedOrder {
        let orderId = startTracking(request: request)
        
        // Update status to submitted
        updateOrderStatus(orderId: orderId, status: .submitted, message: "Order submitted to exchange")
        
        // Simulate network delay for demo purposes
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Update to pending
        updateOrderStatus(orderId: orderId, status: .pending, message: "Order is pending execution")
        
        do {
            // Convert TradeRequest to OrderRequest
            let orderRequest = OrderRequest(
                symbol: Symbol(request.symbol, exchange: .binance),
                side: request.side.toOrderSide,
                quantity: request.amount
            )
            
            // Execute through TradeManager
            let fill = try await tradeManager.manualOrder(orderRequest)
            
            // Update to filled
            updateOrderStatus(
                orderId: orderId,
                status: .filled,
                message: "Order executed successfully",
                orderFill: fill
            )
            
            logger.info("✅ Order executed successfully: \(orderId)")
            
        } catch let error as AppError {
            // Update to failed with error details
            updateOrderStatus(
                orderId: orderId,
                status: .failed,
                message: "Order execution failed",
                errorMessage: error.localizedDescription
            )
            
            logger.error("❌ Order execution failed: \(orderId) - \(error.localizedDescription)")
            
        } catch {
            // Handle unexpected errors
            updateOrderStatus(
                orderId: orderId,
                status: .failed,
                message: "Order execution failed",
                errorMessage: error.localizedDescription
            )
            
            logger.error("❌ Order execution failed with unexpected error: \(orderId) - \(error.localizedDescription)")
        }
        
        // Return the final tracked order
        if let completedOrder = completedOrders.first(where: { $0.id == orderId }) {
            return completedOrder
        } else if let activeOrder = activeOrders.first(where: { $0.id == orderId }) {
            return activeOrder
        } else {
            // This shouldn't happen, but return a default order if it does
            return TrackedOrder(id: orderId, originalRequest: request, currentStatus: .failed)
        }
    }
    
    /// Cancel an active order
    public func cancelOrder(orderId: String, reason: String = "User cancelled") {
        updateOrderStatus(
            orderId: orderId,
            status: .cancelled,
            message: reason
        )
        
        logger.info("Order cancelled: \(orderId) - \(reason)")
    }
    
    /// Get a specific tracked order by ID
    public func getTrackedOrder(orderId: String) -> TrackedOrder? {
        return activeOrders.first(where: { $0.id == orderId }) ??
               completedOrders.first(where: { $0.id == orderId })
    }
    
    /// Get all orders (active and completed) for a specific symbol
    public func getOrdersForSymbol(_ symbol: String) -> [TrackedOrder] {
        let active = activeOrders.filter { $0.originalRequest.symbol == symbol }
        let completed = completedOrders.filter { $0.originalRequest.symbol == symbol }
        return active + completed
    }
    
    /// Get recent orders (last 24 hours)
    public func getRecentOrders() -> [TrackedOrder] {
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
        let recentActive = activeOrders.filter { $0.createdAt > cutoff }
        let recentCompleted = completedOrders.filter { $0.createdAt > cutoff }
        return (recentActive + recentCompleted).sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Private Methods
    
    private func addRecentUpdate(_ update: OrderStatusUpdate) {
        recentStatusUpdates.insert(update, at: 0)
        
        // Keep only the most recent updates
        if recentStatusUpdates.count > maxRecentUpdates {
            recentStatusUpdates = Array(recentStatusUpdates.prefix(maxRecentUpdates))
        }
    }
    
    private func addCompletedOrder(_ order: TrackedOrder) {
        completedOrders.insert(order, at: 0)
        
        // Keep only the most recent completed orders
        if completedOrders.count > maxCompletedOrders {
            completedOrders = Array(completedOrders.prefix(maxCompletedOrders))
        }
    }
    
    private func setupCleanupTimer() {
        // Clean up old completed orders every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupOldOrders()
            }
            .store(in: &cancellables)
    }
    
    private func cleanupOldOrders() {
        let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        
        let oldOrdersCount = completedOrders.count
        completedOrders.removeAll { $0.createdAt < cutoff }
        
        let removedCount = oldOrdersCount - completedOrders.count
        if removedCount > 0 {
            logger.info("Cleaned up \(removedCount) old completed orders")
        }
        
        // Also clean up old status updates
        let oldUpdatesCount = recentStatusUpdates.count
        recentStatusUpdates.removeAll { $0.timestamp < cutoff }
        
        let removedUpdatesCount = oldUpdatesCount - recentStatusUpdates.count
        if removedUpdatesCount > 0 {
            logger.info("Cleaned up \(removedUpdatesCount) old status updates")
        }
    }
    
    // MARK: - Statistics
    
    /// Get order statistics for the current session
    public func getOrderStatistics() -> OrderStatistics {
        let allOrders = activeOrders + completedOrders
        
        let totalOrders = allOrders.count
        let successfulOrders = allOrders.filter { $0.isCompleted }.count
        let failedOrders = allOrders.filter { $0.isFailed }.count
        let activeOrdersCount = activeOrders.count
        
        let successRate = totalOrders > 0 ? Double(successfulOrders) / Double(totalOrders) : 0.0
        
        let averageExecutionTime = calculateAverageExecutionTime()
        
        return OrderStatistics(
            totalOrders: totalOrders,
            successfulOrders: successfulOrders,
            failedOrders: failedOrders,
            activeOrders: activeOrdersCount,
            successRate: successRate,
            averageExecutionTime: averageExecutionTime
        )
    }
    
    private func calculateAverageExecutionTime() -> TimeInterval {
        let completedOrdersWithFills = completedOrders.filter { $0.isCompleted }
        
        guard !completedOrdersWithFills.isEmpty else { return 0.0 }
        
        let totalTime = completedOrdersWithFills.reduce(0.0) { sum, order in
            return sum + order.duration
        }
        
        return totalTime / Double(completedOrdersWithFills.count)
    }
}

// MARK: - Order Statistics

public struct OrderStatistics {
    public let totalOrders: Int
    public let successfulOrders: Int
    public let failedOrders: Int
    public let activeOrders: Int
    public let successRate: Double
    public let averageExecutionTime: TimeInterval
    
    public var successRatePercentage: String {
        return String(format: "%.1f%%", successRate * 100)
    }
    
    public var averageExecutionTimeFormatted: String {
        if averageExecutionTime < 1.0 {
            return String(format: "%.0fms", averageExecutionTime * 1000)
        } else {
            return String(format: "%.1fs", averageExecutionTime)
        }
    }
}