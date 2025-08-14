import Foundation

public actor MarketDataService {
    public static let shared = MarketDataService()
    
    private var task: URLSessionWebSocketTask?
    private var symbol: Symbol?
    private var onTick: ((PriceTick) -> Void)?
    
    public func subscribe(_ handler: @escaping (PriceTick) -> Void) {
        onTick = handler
    }
    
    public func start(symbol: Symbol) async {
        await stop()
        self.symbol = symbol
        
        let (url, subscribeMessage) = wsSpec(for: symbol)
        let session = URLSession(configuration: .default)
        let t = session.webSocketTask(with: url)
        task = t
        t.resume()
        
        if let msgData = try? JSONSerialization.data(withJSONObject: subscribeMessage),
           let txt = String(data: msgData, encoding: .utf8) {
            await send(.string(txt))
        }
        
        receiveLoop()
    }
    
    public func stop() async {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        symbol = nil
    }
    
    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else { return }
            Task {
                switch result {
                case .failure:
                    // reconnect simple backoff
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    if let s = self.symbol { await self.start(symbol: s) }
                case .success(let message):
                    await self.handle(message: message)
                    self.receiveLoop()
                }
            }
        }
    }
    
    private func handle(message: URLSessionWebSocketTask.Message) async {
        guard case let .string(text) = message,
              let data = text.data(using: .utf8) ?? text.replacingOccurrences(of: "\n", with: "").data(using: .utf8)
        else { return }
        
        if let sym = symbol {
            switch sym.exchange {
            case .binance:
                // {"e":"24hrTicker","s":"BTCUSDT","c":"67890.12", ...} OR miniTicker stream {"c":"price","s":"BTCUSDT"}
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let s = (json["s"] as? String),
                   s.caseInsensitiveCompare(sym.raw) == .orderedSame,
                   let cStr = json["c"] as? String,
                   let price = Double(cStr) {
                    let tick = PriceTick(symbol: sym, price: price, change24h: nil, ts: Date())
                    await MarketPriceCache.shared.update(price)
                    await StopMonitor.shared.onTick(price)
                    onTick?(tick)
                }
            case .kraken:
                // [channelID, {"c":"67890.1", ...}, "ticker", "XBT/USDT"]
                if let arr = try? JSONSerialization.jsonObject(with: data) as? [Any],
                   arr.count >= 4,
                   let dict = arr[1] as? [String: Any],
                   let cArr = dict["c"] as? [String],
                   let last = cArr.first,
                   let price = Double(last) {
                    let tick = PriceTick(symbol: sym, price: price, change24h: nil, ts: Date())
                    await MarketPriceCache.shared.update(price)
                    await StopMonitor.shared.onTick(price)
                    onTick?(tick)
                }
            }
        }
    }
    
    private func send(_ message: URLSessionWebSocketTask.Message) async {
        await withCheckedContinuation { cont in
            task?.send(message) { _ in cont.resume() }
        }
    }
    
    private func wsSpec(for symbol: Symbol) -> (URL, [String: Any]) {
        switch symbol.exchange {
        case .binance:
            // miniTicker for single symbol
            let stream = symbol.raw.lowercased() + "@miniTicker"
            let url = URL(string: "wss://stream.binance.com:9443/ws/\(stream)")!
            // no subscribe needed for direct /ws/stream
            return (url, [:])
        case .kraken:
            // needs subscribe message
            let url = URL(string: "wss://ws.kraken.com/")!
            let krakenPair = krakenPairName(symbol.raw)
            let sub: [String: Any] = [
                "event": "subscribe",
                "pair": [krakenPair],
                "subscription": ["name": "ticker"]
            ]
            return (url, sub)
        }
    }
    
    private func krakenPairName(_ s: String) -> String {
        // BTCUSDT -> XBT/USDT, ETHUSDT -> ETH/USDT etc.
        if s.uppercased().hasPrefix("BTC") { return "XBT/\(s.suffix(3))" }
        if s.count >= 6 {
            let base = String(s.prefix(s.count - 4))
            let quote = String(s.suffix(4))
            return "\(base)/\(quote)"
        }
        return "XBT/USDT"
    }
}