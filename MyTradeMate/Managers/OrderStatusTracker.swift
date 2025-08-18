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
}