import Foundation

public struct Order: Codable, Sendable, Identifiable {
    public let id: String
    public let symbol: String
    public let side: OrderSide
    public let amount: Double
    public let price: Double?
    public let status: Status
    public let orderType: OrderType
    public let createdAt: Date
    public let filledAt: Date?
    
    public init(id: String, symbol: String, side: OrderSide, amount: Double, price: Double?, status: Status, orderType: OrderType = .market, createdAt: Date, filledAt: Date? = nil) {
        self.id = id
        self.symbol = symbol
        self.side = side
        self.amount = amount
        self.price = price
        self.status = status
        self.orderType = orderType
        self.createdAt = createdAt
        self.filledAt = filledAt
    }
    
    public enum Status: String, Codable, Sendable {
        case pending
        case filled
        case cancelled
        case rejected
    }
    
    public enum OrderType: String, Codable, Sendable {
        case market
        case limit
        case stopLoss = "stop_loss"
        case takeProfit = "take_profit"
    }
}