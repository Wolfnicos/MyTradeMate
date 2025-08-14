import Foundation

public struct OrderRequest: Codable, Sendable {
    public let symbol: Symbol
    public let side: OrderSide
    public let quantity: Double
    public let limitPrice: Double? // nil = market
    public let stopLoss: Double?
    public let takeProfit: Double?
    
    public init(symbol: Symbol, side: OrderSide, quantity: Double, limitPrice: Double? = nil, stopLoss: Double? = nil, takeProfit: Double? = nil) {
        self.symbol = symbol
        self.side = side
        self.quantity = quantity
        self.limitPrice = limitPrice
        self.stopLoss = stopLoss
        self.takeProfit = takeProfit
    }
}

public struct OrderFill: Identifiable, Codable, Sendable {
    public let id: UUID
    public let symbol: Symbol
    public let side: OrderSide
    public let quantity: Double
    public let price: Double
    public let timestamp: Date
    
    public init(id: UUID = UUID(), symbol: Symbol, side: OrderSide, quantity: Double, price: Double, timestamp: Date) {
        self.id = id
        self.symbol = symbol
        self.side = side
        self.quantity = quantity
        self.price = price
        self.timestamp = timestamp
    }
}
