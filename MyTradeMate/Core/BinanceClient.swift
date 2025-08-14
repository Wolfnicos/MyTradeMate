import Foundation

actor BinanceClient: ExchangeClient {
    let name = "Binance"
    let supportsWebSocket = true
    
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
}
