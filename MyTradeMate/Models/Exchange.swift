import Foundation

public enum Exchange: String, Codable, CaseIterable, Sendable {
    case binance = "Binance"
    case kraken  = "Kraken"
}

public extension Exchange {
    var displayName: String { rawValue }
}