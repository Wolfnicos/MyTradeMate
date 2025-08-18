import Foundation
import Combine
import OSLog

// MARK: - Trading Service

@MainActor
public final class TradingService: ObservableObject {
    public static let shared = TradingService()
    
    @Published public var isTrading = false
    @Published public var positions: [Position] = []
    @Published public var orders: [Order] = []
    @Published public var balance: Double = 10000.0 // Demo balance
    
    private var cancellables = Set<AnyCancellable>()
    private let logger = os.Logger(subsystem: "com.mytrademate", category: "Trading")
    
    private init() {}
    
    // MARK: - Trading Operations
    
    public func placeOrder(symbol: String, side: OrderSide, amount: Double, price: Double? = nil) async throws -> Order {
        logger.info("Placing \(side.rawValue) order: \(amount) \(symbol)")
        
        let order = Order(
            id: UUID().uuidString,
            symbol: symbol,
            side: side,
            amount: amount,
            price: price,
            status: .pending,
            orderType: .market,
            createdAt: Date()
        )
        
        orders.append(order)
        
        // Simulate order execution
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            let filledOrder = Order(
                id: orders[index].id,
                symbol: orders[index].symbol,
                side: orders[index].side,
                amount: orders[index].amount,
                price: orders[index].price,
                status: .filled,
                orderType: orders[index].orderType,
                createdAt: orders[index].createdAt,
                filledAt: Date()
            )
            orders[index] = filledOrder
            
            // Update balance and positions
            updatePositions(for: filledOrder)
        }
        
        return order
    }
    
    public func cancelOrder(orderId: String) async throws {
        if let index = orders.firstIndex(where: { $0.id == orderId }) {
            let cancelledOrder = Order(
                id: orders[index].id,
                symbol: orders[index].symbol,
                side: orders[index].side,
                amount: orders[index].amount,
                price: orders[index].price,
                status: .cancelled,
                orderType: orders[index].orderType,
                createdAt: orders[index].createdAt,
                filledAt: orders[index].filledAt
            )
            orders[index] = cancelledOrder
            logger.info("Order cancelled: \(orderId)")
        }
    }
    
    public func closePosition(positionId: String) async throws {
        if let index = positions.firstIndex(where: { $0.symbol.raw == positionId }) {
            let position = positions[index]
            
            // Place opposite order to close position
            let oppositeSide: OrderSide = position.quantity > 0 ? .sell : .buy
            _ = try await placeOrder(
                symbol: position.symbol.raw,
                side: oppositeSide,
                amount: abs(position.quantity),
                price: position.avgPrice
            )
            
            positions.remove(at: index)
            logger.info("Position closed: \(positionId)")
        }
    }
    
    // MARK: - Private Methods
    
    private func updatePositions(for order: Order) {
        guard let orderPrice = order.price else { return }
        
        // Simple position tracking
        if let existingIndex = positions.firstIndex(where: { $0.symbol.raw == order.symbol }) {
            var position = positions[existingIndex]
            
            let orderQuantity = order.side == .buy ? order.amount : -order.amount
            let newQuantity = position.quantity + orderQuantity
            
            if newQuantity == 0 {
                // Position closed
                positions.remove(at: existingIndex)
            } else {
                // Update position
                let totalValue = (position.avgPrice * position.quantity) + (orderPrice * orderQuantity)
                let newAvgPrice = totalValue / newQuantity
                
                position.quantity = newQuantity
                position.avgPrice = newAvgPrice
                positions[existingIndex] = position
            }
        } else {
            // Create new position
            let symbol = Symbol(order.symbol, exchange: .binance) // Default to binance for demo
            let quantity = order.side == .buy ? order.amount : -order.amount
            let position = Position(
                symbol: symbol,
                quantity: quantity,
                avgPrice: orderPrice
            )
            positions.append(position)
        }
        
        // Update balance
        let cost = order.amount * orderPrice
        balance -= (order.side == .buy ? cost : -cost)
    }
    
    public func updatePositionPrices(symbol: String, currentPrice: Double) {
        // Position price updates are handled by PnLManager and TradeManager
        // This is a simplified implementation for compatibility
        for position in positions {
            if position.symbol.raw == symbol {
                _ = position.unrealizedPnL(mark: currentPrice)
                // PnL is calculated but not stored in Position struct
            }
        }
    }
}

// MARK: - Supporting Types

// Position and Order structs are defined in Models/Position.swift and Models/Order.swift
// OrderSide enum is defined in Models/OrderSide.swift
