import Foundation

public actor PaperExchangeClient: ExchangeClient {
    public let exchange: Exchange
    private var lastPrices: [Symbol: Double] = [:]
    
    public init(exchange: Exchange) {
        self.exchange = exchange
    }
    
    nonisolated public func normalized(symbol: Symbol) -> String {
        switch exchange {
        case .binance: return symbol.raw.replacingOccurrences(of: "-", with: "") // e.g. BTCUSDT
        case .kraken: return symbol.raw                                          // e.g. BTC/USDT or BTCUSDT
        }
    }
    
    public func bestPrice(for symbol: Symbol) async throws -> Double {
        if let p = lastPrices[symbol] { return p }
        // Default seed price to avoid nils during early dev
        let p = 50000.0
        lastPrices[symbol] = p
        return p
    }
    
    public func setMarkPrice(_ price: Double, for symbol: Symbol) {
        lastPrices[symbol] = price
    }
    
    public func placeMarketOrder(_ req: OrderRequest) async throws -> OrderFill {
        let price = try await bestPrice(for: req.symbol)
        return OrderFill(
            id: UUID(),
            symbol: req.symbol,
            side: req.side,
            quantity: req.quantity,
            price: price,
            timestamp: Date()
        )
    }
}
