import Foundation

public struct PriceTick: Sendable {
    public let symbol: Symbol
    public let price: Double
    public let change24h: Double? // in %
    public let ts: Date
}
