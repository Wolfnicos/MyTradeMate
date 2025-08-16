import Foundation
import Combine
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "OrderStatusTracker")



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
                symbol: Symbol(raw: request.symbol),
                side: request.side,
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