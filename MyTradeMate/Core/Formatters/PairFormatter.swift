import Foundation
import SwiftUI

/// Single source of truth for trading pair display formatting
/// Prevents inconsistencies like ETH/EUR vs ETH/USDT across the app
final class PairFormatter {
    
    // MARK: - Singleton
    static let shared = PairFormatter()
    
    // MARK: - Configuration
    
    private let knownPairs: [String: TradingPairInfo] = [
        // Bitcoin pairs
        "BTCUSD": TradingPairInfo(base: "BTC", quote: "USD", displayName: "BTC/USD", priority: 1),
        "BTCUSDT": TradingPairInfo(base: "BTC", quote: "USDT", displayName: "BTC/USDT", priority: 2),
        "BTCEUR": TradingPairInfo(base: "BTC", quote: "EUR", displayName: "BTC/EUR", priority: 3),
        "BTCGBP": TradingPairInfo(base: "BTC", quote: "GBP", displayName: "BTC/GBP", priority: 4),
        
        // Ethereum pairs
        "ETHUSD": TradingPairInfo(base: "ETH", quote: "USD", displayName: "ETH/USD", priority: 5),
        "ETHUSDT": TradingPairInfo(base: "ETH", quote: "USDT", displayName: "ETH/USDT", priority: 6),
        "ETHEUR": TradingPairInfo(base: "ETH", quote: "EUR", displayName: "ETH/EUR", priority: 7),
        "ETHBTC": TradingPairInfo(base: "ETH", quote: "BTC", displayName: "ETH/BTC", priority: 8),
        
        // Cardano pairs
        "ADAUSD": TradingPairInfo(base: "ADA", quote: "USD", displayName: "ADA/USD", priority: 9),
        "ADAUSDT": TradingPairInfo(base: "ADA", quote: "USDT", displayName: "ADA/USDT", priority: 10),
        "ADAEUR": TradingPairInfo(base: "ADA", quote: "EUR", displayName: "ADA/EUR", priority: 11),
        "ADABTC": TradingPairInfo(base: "ADA", quote: "BTC", displayName: "ADA/BTC", priority: 12),
        
        // Solana pairs
        "SOLUSD": TradingPairInfo(base: "SOL", quote: "USD", displayName: "SOL/USD", priority: 13),
        "SOLUSDT": TradingPairInfo(base: "SOL", quote: "USDT", displayName: "SOL/USDT", priority: 14),
        "SOLEUR": TradingPairInfo(base: "SOL", quote: "EUR", displayName: "SOL/EUR", priority: 15),
        
        // Other major pairs
        "LINKUSD": TradingPairInfo(base: "LINK", quote: "USD", displayName: "LINK/USD", priority: 16),
        "LINKUSDT": TradingPairInfo(base: "LINK", quote: "USDT", displayName: "LINK/USDT", priority: 17),
        "DOTUSD": TradingPairInfo(base: "DOT", quote: "USD", displayName: "DOT/USD", priority: 18),
        "DOTUSDT": TradingPairInfo(base: "DOT", quote: "USDT", displayName: "DOT/USDT", priority: 19),
        "AVAXUSD": TradingPairInfo(base: "AVAX", quote: "USD", displayName: "AVAX/USD", priority: 20),
        "AVAXUSDT": TradingPairInfo(base: "AVAX", quote: "USDT", displayName: "AVAX/USDT", priority: 21)
    ]
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Format trading pair for consistent display across the app
    func format(_ pair: String, style: PairDisplayStyle = .standard) -> FormattedPair {
        let normalizedPair = pair.uppercased().replacingOccurrences(of: "/", with: "")
        
        if let pairInfo = knownPairs[normalizedPair] {
            return FormattedPair(
                displayString: formatPairInfo(pairInfo, style: style),
                baseCurrency: pairInfo.base,
                quoteCurrency: pairInfo.quote,
                rawPair: pair,
                isKnown: true,
                priority: pairInfo.priority
            )
        } else {
            // Fallback parsing for unknown pairs
            let parsed = parseUnknownPair(normalizedPair)
            let displayString = formatParsedPair(parsed, style: style)
            
            return FormattedPair(
                displayString: displayString,
                baseCurrency: parsed.base,
                quoteCurrency: parsed.quote,
                rawPair: pair,
                isKnown: false,
                priority: 999
            )
        }
    }
    
    /// Get all known trading pairs sorted by priority
    func getAllKnownPairs() -> [FormattedPair] {
        return knownPairs.values
            .sorted { $0.priority < $1.priority }
            .map { pairInfo in
                FormattedPair(
                    displayString: formatPairInfo(pairInfo, style: .standard),
                    baseCurrency: pairInfo.base,
                    quoteCurrency: pairInfo.quote,
                    rawPair: pairInfo.base + pairInfo.quote,
                    isKnown: true,
                    priority: pairInfo.priority
                )
            }
    }
    
    /// Get pairs filtered by quote currency
    func getPairs(quoteCurrency: String) -> [FormattedPair] {
        let filteredPairs = knownPairs.values
            .filter { $0.quote.uppercased() == quoteCurrency.uppercased() }
            .sorted { $0.priority < $1.priority }
        
        return filteredPairs.map { pairInfo in
            FormattedPair(
                displayString: formatPairInfo(pairInfo, style: .standard),
                baseCurrency: pairInfo.base,
                quoteCurrency: pairInfo.quote,
                rawPair: pairInfo.base + pairInfo.quote,
                isKnown: true,
                priority: pairInfo.priority
            )
        }
    }
    
    /// Get pairs filtered by base currency
    func getPairs(baseCurrency: String) -> [FormattedPair] {
        let filteredPairs = knownPairs.values
            .filter { $0.base.uppercased() == baseCurrency.uppercased() }
            .sorted { $0.priority < $1.priority }
        
        return filteredPairs.map { pairInfo in
            FormattedPair(
                displayString: formatPairInfo(pairInfo, style: .standard),
                baseCurrency: pairInfo.base,
                quoteCurrency: pairInfo.quote,
                rawPair: pairInfo.base + pairInfo.quote,
                isKnown: true,
                priority: pairInfo.priority
            )
        }
    }
    
    /// Extract base and quote currencies from any pair string
    func extractCurrencies(from pair: String) -> (base: String, quote: String) {
        let formatted = format(pair)
        return (formatted.baseCurrency, formatted.quoteCurrency)
    }
    
    // MARK: - Private Methods
    
    private func formatPairInfo(_ pairInfo: TradingPairInfo, style: PairDisplayStyle) -> String {
        switch style {
        case .standard:
            return pairInfo.displayName
        case .compact:
            return "\(pairInfo.base)/\(pairInfo.quote)"
        case .baseOnly:
            return pairInfo.base
        case .quoteOnly:
            return pairInfo.quote
        case .raw:
            return pairInfo.base + pairInfo.quote
        }
    }
    
    private func formatParsedPair(_ parsed: (base: String, quote: String), style: PairDisplayStyle) -> String {
        switch style {
        case .standard, .compact:
            return "\(parsed.base)/\(parsed.quote)"
        case .baseOnly:
            return parsed.base
        case .quoteOnly:
            return parsed.quote
        case .raw:
            return parsed.base + parsed.quote
        }
    }
    
    private func parseUnknownPair(_ pair: String) -> (base: String, quote: String) {
        // Common quote currencies in order of likelihood
        let commonQuotes = ["USDT", "USD", "USDC", "EUR", "GBP", "BTC", "ETH"]
        
        for quote in commonQuotes {
            if pair.hasSuffix(quote) {
                let base = String(pair.dropLast(quote.count))
                if !base.isEmpty {
                    return (base, quote)
                }
            }
        }
        
        // Fallback: split roughly in the middle or assume 3-char base
        if pair.count >= 6 {
            let baseEndIndex = pair.index(pair.startIndex, offsetBy: 3)
            let base = String(pair[..<baseEndIndex])
            let quote = String(pair[baseEndIndex...])
            return (base, quote)
        }
        
        // Last resort: return as-is
        return (pair, "")
    }
}

// MARK: - Supporting Types

/// Trading pair information with metadata
struct TradingPairInfo {
    let base: String
    let quote: String
    let displayName: String
    let priority: Int
}

/// Pair display style options
enum PairDisplayStyle {
    case standard   // BTC/USD
    case compact    // BTC/USD (same as standard)
    case baseOnly   // BTC
    case quoteOnly  // USD
    case raw        // BTCUSD
}

/// Formatted trading pair result with metadata
struct FormattedPair: Identifiable, Equatable {
    let id = UUID()
    let displayString: String
    let baseCurrency: String
    let quoteCurrency: String
    let rawPair: String
    let isKnown: Bool
    let priority: Int
    
    static func == (lhs: FormattedPair, rhs: FormattedPair) -> Bool {
        lhs.rawPair == rhs.rawPair
    }
}

// MARK: - SwiftUI Integration

extension FormattedPair {
    /// Get appropriate color for base currency
    var baseColor: Color {
        switch baseCurrency {
        case "BTC":
            return Color.orange
        case "ETH":
            return Color.blue
        case "ADA":
            return Color.blue
        case "SOL":
            return Color.purple
        case "LINK":
            return Color.blue
        case "DOT":
            return Color.pink
        case "AVAX":
            return Color.red
        default:
            return DesignTokens.Colors.onSurface
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension PairFormatter {
    static let preview = PairFormatter.shared
    
    static var samplePairs: [String] {
        ["BTCUSD", "ETHUSD", "ETHEUR", "ADAUSDT", "SOLUSDT", "LINKUSD", "UNKNOWN_PAIR"]
    }
}
#endif