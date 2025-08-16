import Foundation

public final class KrakenLiveClient: ExchangeClient {
    public let exchange: Exchange = .kraken
    private let apiKey: String
    private let secret: String
    
    public init(apiKey: String, secret: String) {
        self.apiKey = apiKey
        self.secret = secret
    }
    
    public func normalized(symbol: Symbol) -> String {
        // BTCUSDT -> XBT/USDT etc
        if symbol.raw.uppercased().hasPrefix("BTC") {
            return "XBT/\(symbol.raw.suffix(4))"
        }
        if symbol.raw.count >= 6 {
            let base = String(symbol.raw.prefix(symbol.raw.count - 4))
            let quote = String(symbol.raw.suffix(4))
            return "\(base)/\(quote)"
        }
        return "XBT/USDT"
    }
    
    public func bestPrice(for symbol: Symbol) async throws -> Double {
        return await MarketPriceCache.shared.lastPrice
    }
    
    public func placeMarketOrder(_ req: OrderRequest) async throws -> OrderFill {
        // Validate API credentials
        guard !apiKey.isEmpty && !secret.isEmpty else {
            throw ExchangeError.missingCredentials
        }
        
        // For now, live trading is disabled for safety
        throw ExchangeError.serverError("Live trading is disabled in this build for safety. Please use demo mode.")
    }
}
