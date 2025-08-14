import Foundation

actor KrakenClient: ExchangeClient {
    let name = "Kraken"
    let supportsWebSocket = true
    let exchange: Exchange = .kraken
    
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
        guard let url = URL(string: "wss://ws.kraken.com/") else {
            throw URLError(.badURL)
        }
        let ws = session.webSocketTask(with: url)
        task = ws
        ws.resume()
        
        // Subscribe to "trade" channel
        // Kraken symbols use pairs like "XBT/USDT"
        let pairs = symbols.map {
            $0.replacingOccurrences(of: "USDT", with: "USD")
             .replacingOccurrences(of: "BTC", with: "XBT")
        }
        let sub: [String: Any] = [
            "event": "subscribe",
            "pair": pairs,
            "subscription": ["name": "trade"]
        ]
        let payload = try JSONSerialization.data(withJSONObject: sub)
        ws.send(.data(payload)) { _ in }
        
        receive(ws, originalSymbols: symbols)
    }
    
    func disconnectTickers() async {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }
    
    private func receive(_ ws: URLSessionWebSocketTask, originalSymbols: [String]) {
        ws.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                break
            case .success(let msg):
                if case .string(let s) = msg,
                   let data = s.data(using: .utf8),
                   let obj = try? JSONSerialization.jsonObject(with: data) {
                    
                    // Trade messages are arrays: [channelID, [[price, volume, time, side, orderType, misc], ...], pair, "trade"]
                    if let arr = obj as? [Any],
                       arr.count >= 4,
                       let tradesArr = arr[1] as? [[Any]],
                       let pair = arr[3] as? String,
                       let first = tradesArr.first,
                       first.count >= 1,
                       let pStr = first[0] as? String,
                       let price = Double(pStr) {
                        
                        // Map back to original symbol format (XBT/USD → BTCUSDT)
                        let symbol = pair
                            .replacingOccurrences(of: "XBT", with: "BTC")
                            .replacingOccurrences(of: "/", with: "")
                            .replacingOccurrences(of: "USD", with: "USDT")
                            .uppercased()
                        let tick = Ticker(symbol: symbol, price: price, ts: Date())
                        continuation?.yield(tick)
                    }
                }
            }
            self.receive(ws, originalSymbols: originalSymbols)
        }
    }
    
    // MARK: - ExchangeClient Protocol
    
    nonisolated func normalized(symbol: Symbol) -> String {
        let symbol = symbol.raw.uppercased()
        // Convert BTC to XBT for Kraken
        if symbol.hasPrefix("BTC") {
            return "XBT" + String(symbol.dropFirst(3))
        }
        return symbol
    }
    
    func bestPrice(for symbol: Symbol) async throws -> Double {
        // Simple implementation - get current market price from API
        let symbolStr = normalized(symbol: symbol)
        guard let url = URL(string: "https://api.kraken.com/0/public/Ticker?pair=\(symbolStr)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let pair = result.values.first as? [String: Any],
              let askArray = pair["a"] as? [String],
              let priceStr = askArray.first,
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
