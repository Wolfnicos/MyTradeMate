import Foundation

public struct Position: Codable, Sendable {
    public let symbol: Symbol
    public var quantity: Double
    public var avgPrice: Double
    
    public func unrealizedPnL(mark: Double) -> Double {
        (mark - avgPrice) * quantity
    }
    
    public var isFlat: Bool { quantity == 0 }
}