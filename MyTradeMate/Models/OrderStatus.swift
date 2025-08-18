import Foundation

// MARK: - Order Status Tracking Models

/// Represents the current status of an order with additional context
public struct OrderStatusUpdate: Identifiable, Sendable {
    public let id: String
    public let orderId: String
    public let status: Order.Status
    public let message: String?
    public let timestamp: Date
    public let progress: Double // 0.0 to 1.0 for UI progress indicators
    public let previousStatus: ExtendedOrderStatus?
    
    public init(
        id: String = UUID().uuidString,
        orderId: String,
        status: Order.Status,
        message: String? = nil,
        timestamp: Date = Date(),
        progress: Double = 0.0,
        previousStatus: ExtendedOrderStatus? = nil
    ) {
        self.id = id
        self.orderId = orderId
        self.status = status
        self.message = message
        self.timestamp = timestamp
        self.progress = progress
        self.previousStatus = previousStatus
    }
}

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
    
    /// Convert to base Order.Status
    public var baseStatus: Order.Status {
        switch self {
        case .submitting, .submitted, .pending, .partiallyFilled:
            return .pending
        case .filled:
            return .filled
        case .cancelled:
            return .cancelled
        case .rejected, .failed:
            return .rejected
        }
    }
    
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
    
    /// Whether this status indicates success
    public var isSuccess: Bool {
        return self == .filled
    }
    
    /// Whether this status indicates failure
    public var isFailure: Bool {
        switch self {
        case .cancelled, .rejected, .failed:
            return true
        default:
            return false
        }
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
            status: status.baseStatus,
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
        return currentStatus.isFailure
    }
}