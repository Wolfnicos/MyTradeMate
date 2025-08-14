import Foundation

struct SymbolCatalog {
    // MARK: - Symbol Mapping
    
    static func defaultSymbol(for exchange: ExchangeID) -> String {
        switch exchange {
        case .binance:
            return "BTCUSDT"
        case .kraken:
            return "XBTUSDT" // Will try XBTUSD if USDT pair not available
        }
    }
    
    static func normalize(_ uiSymbol: String, for exchange: ExchangeID) -> String {
        // Convert UI symbol to exchange-specific format
        switch exchange {
        case .binance:
            return uiSymbol.uppercased()
            
        case .kraken:
            // Kraken uses XBT instead of BTC and different pair format
            let symbol = uiSymbol.uppercased()
            if symbol.hasPrefix("BTC") {
                return "XBT" + symbol.dropFirst(3)
            }
            // Handle special cases for Kraken
            switch symbol {
            case "BTCUSDT":
                return "XBTUSDT" // Try USDT pair first
            case "ETHUSDT":
                return "ETHUSDT"
            case "BTCUSD":
                return "XBTUSD"
            default:
                return symbol
            }
        }
    }
    
    static func quotePrecision(for exchange: ExchangeID, symbol: String) -> Int {
        let normalizedSymbol = normalize(symbol, for: exchange)
        
        // Return standard precisions for common pairs
        switch exchange {
        case .binance:
            switch normalizedSymbol {
            case "BTCUSDT", "ETHUSDT", "BNBUSDT":
                return 2
            case "XRPUSDT", "DOGEUSDT":
                return 5
            default:
                return 2 // Default precision for USDT pairs
            }
            
        case .kraken:
            switch normalizedSymbol {
            case "XBTUSDT", "XBTUSD", "ETHUSDT", "ETHUSD":
                return 2
            case "XRPUSDT", "XRPUSD":
                return 5
            default:
                return 2 // Default precision for USD/USDT pairs
            }
        }
    }
    
    // MARK: - Symbol Validation
    
    static func isValidSymbol(_ symbol: String, for exchange: ExchangeID) -> Bool {
        let normalized = normalize(symbol, for: exchange)
        
        // Basic validation rules
        guard normalized.count >= 6,           // Minimum length for valid pair
              normalized.count <= 12,          // Maximum length for valid pair
              !normalized.contains(" ") else { // No spaces allowed
            return false
        }
        
        // Exchange-specific validation
        switch exchange {
        case .binance:
            // Must end with USDT for spot trading
            return normalized.hasSuffix("USDT")
            
        case .kraken:
            // Must end with USDT or USD
            return normalized.hasSuffix("USDT") || normalized.hasSuffix("USD")
        }
    }
    
    // MARK: - Symbol Components
    
    static func baseAsset(_ symbol: String, for exchange: ExchangeID) -> String {
        let normalized = normalize(symbol, for: exchange)
        
        switch exchange {
        case .binance:
            return String(normalized.dropLast(4)) // Drop USDT
            
        case .kraken:
            if normalized.hasSuffix("USDT") {
                return String(normalized.dropLast(4))
            } else if normalized.hasSuffix("USD") {
                return String(normalized.dropLast(3))
            }
            return normalized
        }
    }
    
    static func quoteAsset(_ symbol: String, for exchange: ExchangeID) -> String {
        let normalized = normalize(symbol, for: exchange)
        
        switch exchange {
        case .binance:
            return "USDT"
            
        case .kraken:
            if normalized.hasSuffix("USDT") {
                return "USDT"
            } else if normalized.hasSuffix("USD") {
                return "USD"
            }
            return "USD" // Default for Kraken
        }
    }
}