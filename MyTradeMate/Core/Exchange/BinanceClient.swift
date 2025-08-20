import Foundation

actor BinanceClient: BinanceClientProtocol {
    let name = "Binance"
    let supportsWebSocket = true
    let exchange: Exchange = .binance
    
    private var task: URLSessionWebSocketTask?
    private var continuation: AsyncStream<Ticker>.Continuation?
    private let session = URLSession(configuration: .default)
    
    nonisolated let tickerStream: AsyncStream<Ticker>
    
    init() {
        var cont: AsyncStream<Ticker>.Continuation?
        self.tickerStream = AsyncStream<Ticker> { c in cont = c }
        self.continuation = cont
    }
    
    func connectTickers(symbols: [String]) async throws {
        try await disconnectTickers()
        // Binance expects lowercase like btcusdt
        let streams = symbols.map { "\($0.lowercased())@trade" }.joined(separator: "/")
        guard let url = URL(string: "wss://stream.binance.com:9443/stream?streams=\(streams)") else {
            throw URLError(.badURL)
        }
        let ws = session.webSocketTask(with: url)
        task = ws
        ws.resume()
        receive(ws)
    }
    
    func disconnectTickers() async throws {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }
    
    private func receive(_ ws: URLSessionWebSocketTask) {
        ws.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                // Best-effort: ignore; reconnection policy can be added
                break
            case .success(let msg):
                if case .string(let s) = msg,
                   let data = s.data(using: .utf8),
                   let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let stream = obj["stream"] as? String,
                   let payload = obj["data"] as? [String: Any],
                   let pStr = payload["p"] as? String,
                   let price = Double(pStr) {
                    // stream is like "btcusdt@trade" → extract symbol
                    let symbol = stream.replacingOccurrences(of: "@trade", with: "").uppercased()
                    let tick = Ticker(symbol: symbol, price: price, ts: Date())
                    continuation?.yield(tick)
                }
            }
            // keep receiving
            self.receive(ws)
        }
    }
    
    // MARK: - ExchangeClient Protocol
    
    nonisolated func normalized(symbol: Symbol) -> String {
        return symbol.raw.uppercased() // Binance uses BTCUSDT format
    }
    
    func bestPrice(for symbol: Symbol) async throws -> Double {
        // Simple implementation - get current market price from API
        let symbolStr = normalized(symbol: symbol)
        guard let url = URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=\(symbolStr)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let priceStr = json["price"] as? String,
              let price = Double(priceStr) else {
            throw URLError(.cannotParseResponse)
        }
        
        return price
    }
    
    func placeMarketOrder(_ req: OrderRequest) async throws -> OrderFill {
        // Mock implementation for paper trading
        let price = try await bestPrice(for: Symbol(req.pair.exchangeSymbol, exchange: .binance))
        let quantity = req.calculateQuantity(currentPrice: price, equity: 1000.0) // Mock equity
        return OrderFill(
            id: UUID(),
            pair: req.pair,
            side: req.side,
            quantity: quantity,
            price: price,
            timestamp: Date()
        )
    }
    
    // MARK: - ExchangeClientProtocol Required Methods
    
    func placeOrder(symbol: String, side: OrderSide, quantity: Double, price: Double?) async throws -> Order {
        // Mock implementation for demo/paper trading
        let orderPrice: Double
        if let price = price {
            orderPrice = price
        } else {
            orderPrice = try await bestPrice(for: Symbol(symbol, exchange: .binance))
        }
        return Order(
            id: UUID().uuidString,
            symbol: symbol,
            side: side,
            amount: quantity,
            price: orderPrice,
            status: .filled,
            orderType: .market,
            createdAt: Date(),
            filledAt: Date()
        )
    }
    
    func getAccountInfo() async throws -> Account {
        // Mock account for demo trading
        return Account(
            equity: 10000.0,
            cash: 10000.0,
            positions: [],
            balances: []
        )
    }
    
    func getOpenOrders(symbol: String?) async throws -> [Order] {
        // Return empty array for demo trading
        return []
    }
    
    func cancelOrder(orderId: String, symbol: String) async throws {
        // No-op for demo trading
    }
}
