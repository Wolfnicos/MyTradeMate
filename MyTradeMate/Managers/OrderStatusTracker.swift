import Foundation
import Combine

// Using OrderStatusUpdate from Models/OrderStatus.swift

/// Tracks and manages order status updates
@MainActor
final class OrderStatusTracker: ObservableObject {
    static let shared = OrderStatusTracker()
    
    @Published var activeOrders: [String: OrderStatusUpdate] = [:]
    @Published var orderHistory: [OrderStatusUpdate] = []
    
    private init() {}
    
    func trackOrder(_ update: OrderStatusUpdate) {
        activeOrders[update.orderId] = update
        orderHistory.append(update)
    }
    
    func updateOrderStatus(_ orderId: String, status: Order.Status, message: String? = nil) {
        let update = OrderStatusUpdate(
            orderId: orderId,
            status: status,
            message: message
        )
        trackOrder(update)
    }
    
    func removeOrder(_ orderId: String) {
        activeOrders.removeValue(forKey: orderId)
    }
    
    func executeOrderWithTracking(_ request: TradeRequest) async -> TrackedOrder {
        let orderId = UUID().uuidString
        
        // Create initial tracking
        var trackedOrder = TrackedOrder(
            id: orderId,
            originalRequest: request,
            currentStatus: .pending
        )
        
        // Update status to pending
        updateOrderStatus(orderId, status: .pending)
        
        // Simulate order execution
        do {
            // Convert TradeRequest to OrderRequest format
            let orderRequest = OrderRequest(
                pair: TradingPair(base: Asset.bitcoin, quote: QuoteCurrency.USD),
                side: request.side == .buy ? .buy : .sell,
                amountMode: .fixedNotional,
                amountValue: request.amount
            )
            
            // Execute through TradeManager
            let fill = try await TradeManager.shared.manualOrder(orderRequest)
            
            // Update status to completed
            updateOrderStatus(orderId, status: .filled)
            
            trackedOrder.updateStatus(.filled, orderFill: fill)
            
            return trackedOrder
            
        } catch {
            // Update status to failed
            updateOrderStatus(orderId, status: .rejected, message: error.localizedDescription)
            
            trackedOrder.updateStatus(.rejected, errorMessage: error.localizedDescription)
            
            return trackedOrder
        }
    }
}