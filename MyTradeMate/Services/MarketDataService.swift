import Foundation
import SwiftUI

@MainActor
public final class MarketDataService: ObservableObject {
    public static let shared = MarketDataService()
    
    @Published public var selectedSymbol: String = "BTCUSDT"
    @Published public var lastTick: PriceTick?
    @Published public var isLiveEnabled: Bool = false  // ✅ starts disabled
    @Published public var isConnected: Bool = false    // ✅ connection state
    
    private var task: URLSessionWebSocketTask?
    private var symbol: Symbol?
    private var onTick: ((PriceTick) -> Void)?
    private var isConnecting = false
    private var shouldReconnect = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private var pingTimer: Timer?
    private var healthCheckTimer: Timer?
    private var lastMessageTime: Date = Date()
    private let healthCheckInterval: TimeInterval = 30.0
    private let maxSilenceDuration: TimeInterval = 60.0
    
    public func subscribe(_ handler: @escaping (PriceTick) -> Void) {
        onTick = handler
    }
    
    public func startLiveIfNeeded() {
        guard isLiveEnabled else { 
            Task { await stopLive() }
            return 
        }
        Task { await connect() }
    }
    
    public func setLiveEnabled(_ enabled: Bool) {
        isLiveEnabled = enabled
        if enabled { 
            startLiveIfNeeded() 
        } else { 
            Task { await stopLive() }
        }
    }
    
    public func start(symbol: Symbol) async {
        await stop()
        self.symbol = symbol
        shouldReconnect = true
        reconnectAttempts = 0
        await connect()
    }
    
    public func stop() async {
        shouldReconnect = false
        stopPingTimer()
        stopHealthCheckTimer()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        symbol = nil
        isConnecting = false
        isConnected = false
    }
    
    public func stopLive() async {
        shouldReconnect = false
        stopPingTimer()
        stopHealthCheckTimer()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        isConnected = false
    }
    
    public func disconnect() async {
        shouldReconnect = false
        stopPingTimer()
        stopHealthCheckTimer()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        isConnected = false
        reconnectAttempts = 0
    }
    
    private func connect() async {
        guard isLiveEnabled else { return }
        guard let symbol = symbol, !isConnecting else { return }
        
        // Prevent double connections - cancel existing task first
        if let existingTask = task {
            existingTask.cancel(with: .goingAway, reason: nil)
            task = nil
            stopPingTimer()
            stopHealthCheckTimer()
        }
        
        isConnecting = true
        let (url, subscribeMessage) = wsSpec(for: symbol)
        
        // URL sanity check
        guard url.scheme == "wss", url.host != nil else {
            print("❌ Invalid WebSocket URL: \(url)")
            isConnecting = false
            return
        }
        
        let session = URLSession(configuration: .default)
        let newTask = session.webSocketTask(with: url)
        task = newTask // Keep strong reference
        
        newTask.resume() // CRITICAL: Must call resume()
        
        // Send subscription message if needed
        if !subscribeMessage.isEmpty,
           let msgData = try? JSONSerialization.data(withJSONObject: subscribeMessage),
           let txt = String(data: msgData, encoding: .utf8) {
            send(.string(txt))
        }
        
        isConnecting = false
        isConnected = true
        reconnectAttempts = 0
        lastMessageTime = Date()
        startPingTimer()
        startHealthCheckTimer()
        
        print("✅ WebSocket connected successfully to \(url)")
        
        // Start async receive loop
        Task {
            await receiveLoop()
        }
    }
    
    private func receiveLoop() async {
        guard let task = task else { return }
        
        do {
            let message = try await task.receive()
            await MainActor.run {
                self.lastMessageTime = Date()
                self.handle(message: message)
            }
            
            // Continue receiving if still connected
            if self.task === task && shouldReconnect {
                Task {
                    await self.receiveLoop()
                }
            }
        } catch {
            // Connection lost - attempt reconnect if should reconnect
            if shouldReconnect {
                await handleConnectionLoss(error: error)
            }
        }
    }
    
    private func handleConnectionLoss(error: Error) async {
        isConnected = false
        print("🔌 WebSocket connection lost: \(error.localizedDescription)")
        
        // Guard: Don't reconnect if Live WS is disabled or max attempts reached
        guard isLiveEnabled && shouldReconnect && reconnectAttempts < maxReconnectAttempts else {
            if !isLiveEnabled {
                print("ℹ️ Live WebSocket disabled - not reconnecting")
            } else {
                print("❌ Max reconnection attempts reached")
            }
            return
        }
        
        reconnectAttempts += 1
        
        // Exponential backoff with jitter: start at 3s, double each attempt, cap at 60s
        let baseDelay = min(pow(2.0, Double(reconnectAttempts)) + 1.0, 60.0)
        
        // Add jitter (±30%) to reduce thundering herd
        let jitter = Double.random(in: 0.7...1.3)
        let delay = baseDelay * jitter
        
        // Reduce log spam - only log every few attempts or longer delays
        if reconnectAttempts <= 3 || reconnectAttempts % 3 == 0 || delay > 20 {
            print("🔄 Reconnecting in \(String(format: "%.1f", delay))s (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
        }
        
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // Double-check isLiveEnabled after delay
        if isLiveEnabled && shouldReconnect {
            stopPingTimer()
            stopHealthCheckTimer()
            task?.cancel(with: .abnormalClosure, reason: nil)
            task = nil
            await connect()
        }
    }
    
    private func startPingTimer() {
        stopPingTimer()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.sendPing()
            }
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func startHealthCheckTimer() {
        stopHealthCheckTimer()
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: healthCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performHealthCheck()
            }
        }
    }
    
    private func stopHealthCheckTimer() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }
    
    private func performHealthCheck() async {
        let timeSinceLastMessage = Date().timeIntervalSince(lastMessageTime)
        
        if timeSinceLastMessage > maxSilenceDuration {
            print("🩺 Health check failed: No messages received for \(String(format: "%.1f", timeSinceLastMessage))s")
            
            if shouldReconnect && isLiveEnabled {
                let healthError = NSError(domain: "MarketDataService", code: 1001, userInfo: [
                    NSLocalizedDescriptionKey: "Connection health check failed - no data received"
                ])
                await handleConnectionLoss(error: healthError)
            }
        }
    }
    
    private func sendPing() async {
        guard let task = task else { return }
        
        task.sendPing { [weak self] error in
            if let error = error {
                // Only log ping failures if verbose logging enabled
                if AIModelManager.shared.verboseAILogs {
                    print("🏓 Ping failed: \(error.localizedDescription)")
                }
                Task {
                    await self?.handleConnectionLoss(error: error)
                }
            }
        }
    }
    
    private func handle(message: URLSessionWebSocketTask.Message) {
        guard case let .string(text) = message,
              let data = text.data(using: .utf8) ?? text.replacingOccurrences(of: "\n", with: "").data(using: .utf8)
        else { 
            if AIModelManager.shared.verboseAILogs {
                print("📨 Received non-string WebSocket message")
            }
            return 
        }
        
        if AIModelManager.shared.verboseAILogs {
            print("📨 WS message: \(text.prefix(200))")
        }
        
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
                    lastTick = tick
                    Task {
                        await MarketPriceCache.shared.update(price)
                        await StopMonitor.shared.onTick(price)
                    }
                    onTick?(tick)
                    
                    if AIModelManager.shared.verboseAILogs {
                        print("💰 Price update: \(sym.raw) = $\(price)")
                    }
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
                    lastTick = tick
                    Task {
                        await MarketPriceCache.shared.update(price)
                        await StopMonitor.shared.onTick(price)
                    }
                    onTick?(tick)
                    
                    if AIModelManager.shared.verboseAILogs {
                        print("💰 Price update: \(sym.raw) = $\(price)")
                    }
                }
            }
        }
    }
    
    private func send(_ message: URLSessionWebSocketTask.Message) {
        task?.send(message) { _ in }
    }
    
    private func wsSpec(for symbol: Symbol) -> (URL, [String: Any]) {
        switch symbol.exchange {
        case .binance:
            // miniTicker for single symbol
            let stream = symbol.raw.lowercased() + "@miniTicker"
            guard let url = URL(string: "wss://stream.binance.com:9443/ws/\(stream)") else {
                fatalError("Invalid Binance WebSocket URL")
            }
            // no subscribe needed for direct /ws/stream
            return (url, [:])
        case .kraken:
            // needs subscribe message
            guard let url = URL(string: "wss://ws.kraken.com/") else {
                fatalError("Invalid Kraken WebSocket URL")
            }
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
    
    public func setPaperExchange(_ exchange: Exchange) async {
        // For paper trading, we can switch data sources
        // Implementation can be expanded based on needs
    }
}