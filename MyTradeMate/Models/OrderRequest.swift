import Foundation

// MARK: - Order Request Model
public struct OrderRequest {
    public let symbol: Symbol
    public let side: OrderSide
    public let quantity: Double
    
    public init(symbol: Symbol, side: OrderSide, quantity: Double) {
        self.symbol = symbol
        self.side = side
        self.quantity = quantity
    }
}