import Foundation

actor BinanceClient: ExchangeClient {
    let name = "Binance"
    let supportsWebSocket = true
    let exchange: Exchange = .binance
    
    private var task: URLSessionWebSocketTask?
    private var continuation: AsyncStream<Ticker>.Continuation?
    private let session = URLSession(configuration: .default)
    
    private(set) var tickerStream: AsyncStream<Ticker> = {
        var cont: AsyncStream<Ticker>.Continuation!
        let stream = AsyncStream<Ticker> { c in cont = c }
        return stream
    }()
    
    init() {
        var cont: AsyncStream<Ticker>.Continuation!
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
    
    func disconnectTickers() async {
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
