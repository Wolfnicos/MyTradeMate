import Foundation
import CryptoKit

class BinanceExchangeClient: ExchangeClient {
    let id: Exchange = .binance
    let exchange: Exchange = .binance
    private let baseURL = URL(string: "https://api.binance.com")!
    private let wsURL = URL(string: "wss://stream.binance.com:9443/ws")!
    
    private var wsTask: Task<Void, Error>?
    private var wsStream: URLSessionWebSocketTask?
    private var continuation: AsyncStream<Ticker>.Continuation?
    
    lazy var liveTickerStream: AsyncStream<Ticker> = {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }()
    
    // MARK: - WebSocket Methods
    
    func wsConnect(symbol: String) async {
        wsStream = URLSession.shared.webSocketTask(with: wsURL)
        wsStream?.resume()
        
        // Subscribe to trade stream
        let message = """
        {
            "method": "SUBSCRIBE",
            "params": ["\(symbol.lowercased())@trade"],
            "id": 1
        }
        """
        try? await wsStream?.send(.string(message))
        
        // Start receiving messages
        wsTask = Task {
            while !Task.isCancelled {
                guard let message = try await wsStream?.receive() else { continue }
                
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let trade = try? JSONDecoder().decode(BinanceTrade.self, from: data) {
                        let ticker = Ticker(
                            id: UUID(),
                            symbol: symbol,
                            price: Double(trade.price) ?? 0,
                            time: Date(timeIntervalSince1970: Double(trade.time) / 1000)
                        )
                        continuation?.yield(ticker)
                    }
                default:
                    break
                }
            }
        }
    }
    
    func wsDisconnect() async {
        wsTask?.cancel()
        wsStream?.cancel()
        continuation?.finish()
    }
    
    // MARK: - Market Data
    
    func fetchCandles(symbol: String, interval: String, limit: Int) async throws -> [Candle] {
        var components = URLComponents(url: baseURL.appendingPathComponent("/api/v3/klines"), resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "interval", value: interval),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components?.url else {
            throw ExchangeError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ExchangeError.networkError(URLError(.badServerResponse))
        }
        
        let klines = try JSONDecoder().decode([[String]].self, from: data)
        return try klines.map { kline in
            guard kline.count >= 6,
                  let time = Double(kline[0]),
                  let open = Double(kline[1]),
                  let high = Double(kline[2]),
                  let low = Double(kline[3]),
                  let close = Double(kline[4]),
                  let volume = Double(kline[5]) else {
                throw ExchangeError.invalidResponse
            }
            
            return Candle(
                openTime: Date(timeIntervalSince1970: time / 1000),
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
        }
    }
    
    // MARK: - Trading
    
    func createOrder(_ req: OrderRequest) async throws -> OrderFill {
        // TODO: Implement live trading with API keys and signatures
        // For MVP, only support MARKET orders when credentials are present
        guard let apiKey = try? await KeychainStore.shared.getAPIKey(for: .binance),
              let apiSecret = try? await KeychainStore.shared.getAPISecret(for: .binance) else {
            throw ExchangeError.missingCredentials
        }
        
        let timestamp = String(Int64(Date().timeIntervalSince1970 * 1000))
        let params = [
            "symbol": req.symbol.raw,
            "side": req.side == .buy ? "BUY" : "SELL",
            "type": "MARKET",
            "quantity": String(format: "%.8f", req.quantity),
            "timestamp": timestamp
        ]
        
        let signature = sign(params: params, secret: apiSecret)
        var components = URLComponents(url: baseURL.appendingPathComponent("/api/v3/order"), resolvingAgainstBaseURL: true)
        components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        components?.queryItems?.append(URLQueryItem(name: "signature", value: signature))
        
        guard let url = components?.url else {
            throw ExchangeError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-MBX-APIKEY")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExchangeError.networkError(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200:
            let fill = try JSONDecoder().decode(BinanceOrderResponse.self, from: data)
            return OrderFill(
                id: UUID(),
                symbol: req.symbol,
                side: req.side,
                quantity: Double(fill.executedQty) ?? 0,
                price: Double(fill.avgPrice) ?? 0,
                timestamp: Date(timeIntervalSince1970: Double(fill.transactTime) / 1000)
            )
        case 401:
            throw ExchangeError.missingCredentials
        case 429:
            throw ExchangeError.rateLimitExceeded
        default:
            throw ExchangeError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    func account() async throws -> Account {
        // TODO: Implement account info fetching with API keys
        throw ExchangeError.missingCredentials
    }
    
    func supportsPaperTrading() -> Bool {
        false
    }
    
    // MARK: - Private Methods
    
    private func sign(params: [String: String], secret: String) -> String {
        let sortedParams = params.sorted { $0.key < $1.key }
        let queryString = sortedParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        
        let key = SymmetricKey(data: secret.data(using: .utf8)!)
        let signature = HMAC<SHA256>.authenticationCode(
            for: queryString.data(using: .utf8)!,
            using: key
        )
        return Data(signature).map { String(format: "%02hhx", $0) }.joined()
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

// MARK: - API Models

private struct BinanceTrade: Codable {
    let price: String
    let time: Int64
}

private struct BinanceOrderResponse: Codable {
    let orderId: String
    let executedQty: String
    let avgPrice: String
    let transactTime: Int64
}