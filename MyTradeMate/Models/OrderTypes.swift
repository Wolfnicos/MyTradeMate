import Foundation

public struct OrderRequest: Sendable {
    public let symbol: Symbol
    public let side: OrderSide
    public let quantity: Double
    public let limitPrice: Double? // nil = market
    public let stopLoss: Double?
    public let takeProfit: Double?
}

public struct OrderFill: Identifiable, Codable, Sendable {
    public let id: UUID
    public let symbol: Symbol
    public let side: OrderSide
    public let quantity: Double
    public let price: Double
    public let timestamp: Date
}
