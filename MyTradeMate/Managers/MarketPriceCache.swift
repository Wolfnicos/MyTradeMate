import Foundation

public actor MarketPriceCache {
    public static let shared = MarketPriceCache()
    public private(set) var lastPrice: Double = 0
    public func update(_ p: Double) { lastPrice = p }
}
