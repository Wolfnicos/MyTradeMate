import Foundation
import CryptoKit

final class KrakenExchangeClient: ExchangeClient {
    let id: Exchange = .kraken
    let exchange: Exchange = .kraken
    private let baseURL = URL(string: "https://api.kraken.com")
    private let wsURL = URL(string: "wss://ws.kraken.com")
    
    private var continuation: AsyncStream<Ticker>.Continuation?
    
    lazy var liveTickerStream: AsyncStream<Ticker> = {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }()
    
    // MARK: - WebSocket Methods
    
    func wsConnect(symbol: String) async {
        // Disconnect any existing connection
        await wsDisconnect()
        
        // Convert symbol to Kraken format (e.g., BTCUSDT -> XBT/USDT)
        let krakenSymbol = krakenPairName(symbol)
        
        // Subscribe message for ticker
        let subscribeMessage = """
        {
            "event": "subscribe",
            "pair": ["\(krakenSymbol)"],
            "subscription": {
                "name": "ticker"
            }
        }
        """
        
        // TODO: Implement WebSocket connection when WebSocketManager is available
        print("🔌 Kraken WebSocket connection requested for \(symbol)")
    }
    
    func wsDisconnect() async {
        continuation?.finish()
    }
    
    @MainActor
    private func handleWebSocketMessage(_ message: String, symbol: String) async {
        guard let data = message.data(using: .utf8) else { return }
        
        do {
            // Parse Kraken ticker message format: [channelID, {"c":["67890.1", ...]}, "ticker", "XBT/USDT"]
            if let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
               array.count >= 4,
               let tickerData = array[1] as? [String: Any],
               let cArray = tickerData["c"] as? [String],
               let lastPriceStr = cArray.first,
               let price = Double(lastPriceStr) {
                
                let ticker = Ticker(
                    id: UUID(),
                    symbol: symbol,
                    price: price,
                    time: Date()
                )
                continuation?.yield(ticker)
                
                if SettingsVM.shared.verboseAILogs {
                    print("💰 Kraken ticker update: \(symbol) = $\(price)")
                }
            }
        } catch {
                            if SettingsVM.shared.verboseAILogs {
                print("⚠️ Failed to parse Kraken message: \(error)")
            }
        }
    }
    
    private func krakenPairName(_ symbol: String) -> String {
        // Convert BTCUSDT -> XBT/USDT, ETHUSDT -> ETH/USDT etc.
        let upperSymbol = symbol.uppercased()
        if upperSymbol.hasPrefix("BTC") { 
            return "XBT/\(upperSymbol.suffix(4))" 
        }
        if upperSymbol.count >= 6 {
            let base = String(upperSymbol.prefix(upperSymbol.count - 4))
            let quote = String(upperSymbol.suffix(4))
            return "\(base)/\(quote)"
        }
        return "XBT/USDT"
    }
    
    // MARK: - Market Data
    
    func fetchCandles(symbol: String, interval: String, limit: Int) async throws -> [Candle] {
        guard let baseURL = baseURL else {
            throw ExchangeError.invalidConfiguration
        }
        
        var components = URLComponents(url: baseURL.appendingPathComponent("/0/public/OHLC"), resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "pair", value: symbol),
            URLQueryItem(name: "interval", value: interval)
        ]
        
        guard let url = components?.url else {
            throw ExchangeError.invalidResponse
        }
        
        // Validate HTTPS security
        try NetworkSecurityManager.shared.validateHTTPS(for: url)
        
        let session = NetworkSecurityManager.shared.createSecureSession(for: .kraken)
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ExchangeError.networkError(URLError(.badServerResponse))
        }
        
        let result = try JSONDecoder().decode(KrakenOHLCResponse.self, from: data)
        guard let ohlc = result.result[symbol] else {
            throw ExchangeError.invalidResponse
        }
        
        return ohlc.prefix(limit).map { item in
            Candle(
                openTime: Date(timeIntervalSince1970: item[0]),
                open: item[1],
                high: item[2],
                low: item[3],
                close: item[4],
                volume: item[6]
            )
        }
    }
    
    // MARK: - Trading
    
    func createOrder(_ req: OrderRequest) async throws -> OrderFill {
        // TODO: Implement live trading with API keys and signatures
        // For MVP, only support MARKET orders when credentials are present
        guard let apiKey = try? await KeychainStore.shared.getAPIKey(for: .kraken),
              let apiSecret = try? await KeychainStore.shared.getAPISecret(for: .kraken) else {
            throw ExchangeError.missingCredentials
        }
        
        let nonce = String(Int64(Date().timeIntervalSince1970 * 1000))
        let params: [String: String] = [
            "pair": req.symbol.raw,
            "type": req.side == .buy ? "buy" : "sell",
            "ordertype": "market",
            "volume": String(format: "%.8f", req.quantity),
            "nonce": nonce
        ]
        
        let signature = sign(path: "/0/private/AddOrder", params: params, secret: apiSecret)
        guard let url = baseURL?.appendingPathComponent("/0/private/AddOrder") else {
            throw ExchangeError.invalidConfiguration
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "API-Key")
        request.setValue(signature, forHTTPHeaderField: "API-Sign")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = body.data(using: String.Encoding.utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExchangeError.networkError(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200:
            let result = try JSONDecoder().decode(KrakenOrderResponse.self, from: data)
            guard let orderId = result.result.txid.first else {
                throw ExchangeError.invalidResponse
            }
            
            // For MVP, assume immediate fill at market price
            return OrderFill(
                id: UUID(),
                symbol: req.symbol,
                side: req.side,
                quantity: req.quantity,
                price: req.limitPrice ?? 0,
                timestamp: Date()
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
    
    private func sign(path: String, params: [String: String], secret: String) -> String {
        let postData = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let nonce = params["nonce"] ?? ""
        let message = nonce + postData
        
        let sha256 = SHA256.hash(data: message.data(using: .utf8)!)
        let sha256Data = Data(sha256)
        
        guard let secretData = Data(base64Encoded: secret),
              let pathData = path.data(using: .utf8) else {
            return ""
        }
        
        let key = SymmetricKey(data: secretData)
        let signature = HMAC<SHA512>.authenticationCode(
            for: pathData + sha256Data,
            using: key
        )
        return Data(signature).base64EncodedString()
    }
    
    // MARK: - ExchangeClient Protocol
    
    func normalized(symbol: Symbol) -> String {
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

// MARK: - API Models

private struct KrakenTicker: Codable {
    let c: [String] // Last trade closed array
}

private struct KrakenOHLCResponse: Codable {
    let result: [String: [[Double]]]
}

private struct KrakenOrderResponse: Codable {
    struct Result: Codable {
        let txid: [String]
    }
    let result: Result
}