import Foundation

/// Quote currency for trading pairs (account currency)
public enum QuoteCurrency: String, CaseIterable, Codable {
    case USD = "USD"
    case EUR = "EUR"
    
    public var symbol: String {
        switch self {
        case .USD: return "$"
        case .EUR: return "€"
        }
    }
    
    public var displayName: String {
        return rawValue
    }
}

/// Trading asset with exchange constraints and precision
public struct Asset: Hashable, Codable, Identifiable {
    public let id: String
    public let symbol: String          // "BTC", "ETH", "DOGE"
    public let name: String           // "Bitcoin", "Ethereum", "Dogecoin"
    public let basePrecision: Int     // quantity decimals
    public let pricePrecision: Int    // price decimals (tick size)
    public let minNotional: Double    // minimum order size in USD (paper can ignore)
    public let icon: String          // SF Symbol name
    
    public init(symbol: String, name: String, basePrecision: Int, pricePrecision: Int, minNotional: Double, icon: String) {
        self.id = symbol
        self.symbol = symbol
        self.name = name
        self.basePrecision = basePrecision
        self.pricePrecision = pricePrecision
        self.minNotional = minNotional
        self.icon = icon
    }
    
    /// Format quantity with proper precision
    public func formatQuantity(_ quantity: Double) -> String {
        return String(format: "%.\(basePrecision)f", quantity)
    }
    
    /// Format price with proper precision
    public func formatPrice(_ price: Double) -> String {
        return String(format: "%.\(pricePrecision)f", price)
    }
    
    /// Round quantity to asset precision
    public func roundQuantity(_ quantity: Double) -> Double {
        let multiplier = pow(10.0, Double(basePrecision))
        return round(quantity * multiplier) / multiplier
    }
    
    /// Round price to asset precision
    public func roundPrice(_ price: Double) -> Double {
        let multiplier = pow(10.0, Double(pricePrecision))
        return round(price * multiplier) / multiplier
    }
}

/// Trading pair combining base asset and quote currency
public struct TradingPair: Hashable, Codable, Identifiable {
    public let base: Asset
    public let quote: QuoteCurrency
    
    public var id: String {
        return symbol
    }
    
    public var symbol: String {
        return "\(base.symbol)/\(quote.rawValue)"
    }
    
    public var displayName: String {
        return "\(base.name) (\(symbol))"
    }
    
    public init(base: Asset, quote: QuoteCurrency) {
        self.base = base
        self.quote = quote
    }
    
    /// Format a price value for this pair
    public func formatPrice(_ price: Double) -> String {
        return "\(quote.symbol)\(base.formatPrice(price))"
    }
    
    /// Format a quantity value for this pair
    public func formatQuantity(_ quantity: Double) -> String {
        return "\(base.formatQuantity(quantity)) \(base.symbol)"
    }
    
    /// Format notional value
    public func formatNotional(_ notional: Double) -> String {
        return "\(quote.symbol)\(String(format: "%.2f", notional))"
    }
    
    /// Exchange-specific symbol format (e.g., "BTCUSDT" for Binance)
    public var exchangeSymbol: String {
        return "\(base.symbol)\(quote.rawValue)"
    }
}

// MARK: - Predefined Assets

extension Asset {
    /// Bitcoin asset
    public static let bitcoin = Asset(
        symbol: "BTC",
        name: "Bitcoin", 
        basePrecision: 6,     // 0.000001 BTC
        pricePrecision: 2,    // $0.01
        minNotional: 10.0,    // $10 minimum
        icon: "bitcoinsign.circle"
    )
    
    /// Ethereum asset
    public static let ethereum = Asset(
        symbol: "ETH",
        name: "Ethereum",
        basePrecision: 5,     // 0.00001 ETH
        pricePrecision: 2,    // $0.01
        minNotional: 10.0,    // $10 minimum
        icon: "e.circle"
    )
    
    /// Dogecoin asset
    public static let dogecoin = Asset(
        symbol: "DOGE",
        name: "Dogecoin",
        basePrecision: 2,     // 0.01 DOGE
        pricePrecision: 5,    // $0.00001
        minNotional: 5.0,     // $5 minimum
        icon: "d.circle"
    )
    
    /// All supported assets
    public static let allAssets: [Asset] = [bitcoin, ethereum, dogecoin]
    
    /// Get asset by symbol
    public static func asset(for symbol: String) -> Asset? {
        return allAssets.first { $0.symbol == symbol }
    }
}

// MARK: - Predefined Trading Pairs

extension TradingPair {
    /// All supported trading pairs
    public static let allPairs: [TradingPair] = {
        var pairs: [TradingPair] = []
        for asset in Asset.allAssets {
            for quote in QuoteCurrency.allCases {
                pairs.append(TradingPair(base: asset, quote: quote))
            }
        }
        return pairs
    }()
    
    /// Get trading pair by symbol (e.g., "BTC/USD")
    public static func pair(for symbol: String) -> TradingPair? {
        return allPairs.first { $0.symbol == symbol }
    }
    
    /// Common default pairs
    public static let btcUsd = TradingPair(base: .bitcoin, quote: .USD)
    public static let ethUsd = TradingPair(base: .ethereum, quote: .USD)
    public static let dogeUsd = TradingPair(base: .dogecoin, quote: .USD)
    public static let btcEur = TradingPair(base: .bitcoin, quote: .EUR)
    public static let ethEur = TradingPair(base: .ethereum, quote: .EUR)
    public static let dogeEur = TradingPair(base: .dogecoin, quote: .EUR)
    
    /// Popular trading pairs for UI selection
    public static let popular: [TradingPair] = [btcUsd, ethUsd, btcEur, ethEur]
}