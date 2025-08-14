import Foundation

// NOTE: This is a placeholder. Do not enable until keys + legal gating are in place.
public final class BinanceLiveClient: ExchangeClient {
    public let exchange: Exchange = .binance
    private let apiKey: String
    private let secret: String
    
    public init(apiKey: String, secret: String) {
        self.apiKey = apiKey
        self.secret = secret
    }
    
    public func normalized(symbol: Symbol) -> String {
        symbol.raw.replacingOccurrences(of: "-", with: "")
    }
    
    public func bestPrice(for symbol: Symbol) async throws -> Double {
        // Use your WS feed already running; fallback here if needed
        return await MarketPriceCache.shared.lastPrice
    }
    
    public func placeMarketOrder(_ req: OrderRequest) async throws -> OrderFill {
        throw NSError(domain: "LiveTradingDisabled", code: 1, 
                     userInfo: [NSLocalizedDescriptionKey: "Live trading is disabled in this build."])
    }
}
