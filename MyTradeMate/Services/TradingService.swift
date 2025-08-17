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
    private let logger = Logger(subsystem: "com.mytrademate", category: "Trading")
    
    private init() {}
    
    // MARK: - Trading Operations
    
    public func placeOrder(symbol: String, side: OrderSide, amount: Double, price: Double? = nil) async throws -> Order {
        logger.info("Placing \(side.rawValue) order: \(amount) \(symbol)")
        
        let order = Order(
            id: UUID().uuidString,
            symbol: symbol,
            side: side,
            amount: amount,
            price: price ?? 0,
            status: .pending,
            timestamp: Date()
        )
        
        orders.append(order)
        
        // Simulate order execution
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index].status = .filled
            
            // Update balance and positions
            updatePositions(for: order)
        }
        
        return order
    }
    
    public func cancelOrder(orderId: String) async throws {
        if let index = orders.firstIndex(where: { $0.id == orderId }) {
            orders[index].status = .cancelled
            logger.info("Order cancelled: \(orderId)")
        }
    }
    
    public func closePosition(positionId: String) async throws {
        if let index = positions.firstIndex(where: { $0.id == positionId }) {
            let position = positions[index]
            
            // Place opposite order to close position
            let oppositeSide: OrderSide = position.side == .buy ? .sell : .buy
            _ = try await placeOrder(
                symbol: position.symbol,
                side: oppositeSide,
                amount: position.amount,
                price: position.currentPrice
            )
            
            positions.remove(at: index)
            logger.info("Position closed: \(positionId)")
        }
    }
    
    // MARK: - Private Methods
    
    private func updatePositions(for order: Order) {
        // Simple position tracking
        if let existingIndex = positions.firstIndex(where: { $0.symbol == order.symbol }) {
            var position = positions[existingIndex]
            
            if position.side == order.side {
                // Add to existing position
                let totalAmount = position.amount + order.amount
                let avgPrice = ((position.entryPrice * position.amount) + (order.price * order.amount)) / totalAmount
                position.amount = totalAmount
                position.entryPrice = avgPrice
            } else {
                // Reduce or close position
                if order.amount >= position.amount {
                    positions.remove(at: existingIndex)
                } else {
                    position.amount -= order.amount
                }
            }
            
            if position.amount > 0 {
                positions[existingIndex] = position
            }
        } else {
            // Create new position
            let position = Position(
                id: UUID().uuidString,
                symbol: order.symbol,
                side: order.side,
                amount: order.amount,
                entryPrice: order.price,
                currentPrice: order.price,
                pnl: 0,
                pnlPercent: 0
            )
            positions.append(position)
        }
        
        // Update balance
        let cost = order.amount * order.price
        balance -= (order.side == .buy ? cost : -cost)
    }
    
    public func updatePositionPrices(symbol: String, currentPrice: Double) {
        for index in positions.indices {
            if positions[index].symbol == symbol {
                positions[index].currentPrice = currentPrice
                
                let priceDiff = currentPrice - positions[index].entryPrice
                let multiplier = positions[index].side == .buy ? 1.0 : -1.0
                
                positions[index].pnl = priceDiff * positions[index].amount * multiplier
                positions[index].pnlPercent = (priceDiff / positions[index].entryPrice) * 100 * multiplier
            }
        }
    }
}

// MARK: - Supporting Types

public struct Position: Identifiable, Codable {
    public let id: String
    public let symbol: String
    public let side: OrderSide
    public var amount: Double
    public var entryPrice: Double
    public var currentPrice: Double
    public var pnl: Double
    public var pnlPercent: Double
    
    public init(id: String, symbol: String, side: OrderSide, amount: Double, entryPrice: Double, currentPrice: Double, pnl: Double, pnlPercent: Double) {
        self.id = id
        self.symbol = symbol
        self.side = side
        self.amount = amount
        self.entryPrice = entryPrice
        self.currentPrice = currentPrice
        self.pnl = pnl
        self.pnlPercent = pnlPercent
    }
}

public struct Order: Identifiable, Codable {
    public let id: String
    public let symbol: String
    public let side: OrderSide
    public let amount: Double
    public let price: Double
    public var status: OrderStatus
    public let timestamp: Date
    
    public init(id: String, symbol: String, side: OrderSide, amount: Double, price: Double, status: OrderStatus, timestamp: Date) {
        self.id = id
        self.symbol = symbol
        self.side = side
        self.amount = amount
        self.price = price
        self.status = status
        self.timestamp = timestamp
    }
}

public enum OrderSide: String, Codable, CaseIterable {
    case buy = "BUY"
    case sell = "SELL"
}

public enum OrderStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case filled = "FILLED"
    case cancelled = "CANCELLED"
    case rejected = "REJECTED"
}