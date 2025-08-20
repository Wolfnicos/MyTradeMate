import Foundation

actor KrakenClient: KrakenClientProtocol {
    let name = "Kraken"
    let supportsWebSocket = true
    let exchange: Exchange = .kraken
    
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
    
    // placeMarketOrder method removed - using placeOrder instead for ExchangeClientProtocol compliance
    
    // MARK: - ExchangeClientProtocol Required Methods
    
    func placeOrder(symbol: String, side: OrderSide, quantity: Double, price: Double?) async throws -> Order {
        // Mock implementation for demo/paper trading
        let symbolObj = Symbol(symbol, exchange: exchange)
        let orderPrice: Double
        if let price = price {
            orderPrice = price
        } else {
            orderPrice = try await bestPrice(for: symbolObj)
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
