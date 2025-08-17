import Foundation

// MARK: - Order Fill Model
public struct OrderFill: Identifiable, Codable {
    public let id: UUID
    public let symbol: Symbol
    public let side: OrderSide
    public let quantity: Double
    public let price: Double
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        symbol: Symbol,
        side: OrderSide,
        quantity: Double,
        price: Double,
        timestamp: Date
    ) {
        self.id = id
        self.symbol = symbol
        self.side = side
        self.quantity = quantity
        self.price = price
        self.timestamp = timestamp
    }
}