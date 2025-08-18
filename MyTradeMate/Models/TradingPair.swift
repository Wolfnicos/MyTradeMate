import Foundation

// MARK: - Trading Pair Model
public struct TradingPair: Codable, Hashable, Identifiable {
    public let id = UUID()
    public let base: String
    public let quote: String
    public let symbol: String
    
    public init(base: String, quote: String, symbol: String) {
        self.base = base
        self.quote = quote
        self.symbol = symbol
    }
    
    public init(base: String, quote: String) {
        self.base = base
        self.quote = quote
        self.symbol = "\(base)\(quote)"
    }
    
    public var displayName: String {
        "\(base)/\(quote)"
    }
    
    // Common trading pairs
    public static let btcUsdt = TradingPair(base: "BTC", quote: "USDT")
    public static let ethUsdt = TradingPair(base: "ETH", quote: "USDT")
    public static let adaUsdt = TradingPair(base: "ADA", quote: "USDT")
    public static let dotUsdt = TradingPair(base: "DOT", quote: "USDT")
    public static let linkUsdt = TradingPair(base: "LINK", quote: "USDT")
    public static let bnbUsdt = TradingPair(base: "BNB", quote: "USDT")
    
    public static let popular: [TradingPair] = [
        .btcUsdt, .ethUsdt, .adaUsdt, .dotUsdt, .linkUsdt, .bnbUsdt
    ]
}

