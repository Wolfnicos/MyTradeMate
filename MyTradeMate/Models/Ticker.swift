import Foundation

public struct Ticker: Codable, Sendable, Identifiable {
    public let id: UUID
    public let symbol: String
    public let price: Double
    public let time: Date
    
    public init(id: UUID = UUID(), symbol: String, price: Double, time: Date) {
        self.id = id
        self.symbol = symbol
        self.price = price
        self.time = time
    }
    
    // Convenience initializer for backward compatibility
    public init(symbol: String, price: Double, ts: Date) {
        self.init(id: UUID(), symbol: symbol, price: price, time: ts)
    }
}