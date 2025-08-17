import Foundation
import Combine
import OSLog

// MARK: - WebSocket Service

@MainActor
public final class WebSocketService: ObservableObject {
    public static let shared = WebSocketService()
    
    @Published public var isConnected = false
    @Published public var connectionStatus: String = "Disconnected"
    @Published public var latestPrice: Double = 0
    @Published public var priceUpdates: [String: Double] = [:]
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.mytrademate", category: "WebSocket")
    
    private let reconnectDelay: TimeInterval = 5.0
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    private init() {
        setupReconnectionTimer()
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Connection Management
    
    public func connect(to symbol: String = "BTCUSDT") {
        guard !isConnected else { return }
        
        logger.info("Connecting to WebSocket for \(symbol)")
        connectionStatus = "Connecting..."
        
        // Binance WebSocket URL for price updates
        let urlString = "wss://stream.binance.com:9443/ws/\(symbol.lowercased())@ticker"
        guard let url = URL(string: urlString) else {
            logger.error("Invalid WebSocket URL")
            return
        }
        
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start listening for messages
        receiveMessage()
        
        // Simulate connection success for demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isConnected = true
            self.connectionStatus = "Connected"
            self.reconnectAttempts = 0
            self.logger.info("WebSocket connected successfully")
            
            // Start price simulation for demo
            self.startPriceSimulation(for: symbol)
        }
    }
    
    public func disconnect() {
        logger.info("Disconnecting WebSocket")
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        isConnected = false
        connectionStatus = "Disconnected"
    }
    
    // MARK: - Message Handling
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage() // Continue listening
                
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseTickerData(text)
            
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseTickerData(text)
            }
            
        @unknown default:
            logger.warning("Unknown message type received")
        }
    }
    
    private func parseTickerData(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let symbol = json["s"] as? String,
               let priceString = json["c"] as? String,
               let price = Double(priceString) {
                
                Task { @MainActor in
                    self.priceUpdates[symbol] = price
                    if symbol == "BTCUSDT" {
                        self.latestPrice = price
                    }
                    
                    // Notify other services
                    NotificationCenter.default.post(
                        name: .priceUpdate,
                        object: nil,
                        userInfo: ["symbol": symbol, "price": price]
                    )
                }
            }
        } catch {
            logger.error("Failed to parse ticker data: \(error)")
        }
    }
    
    // MARK: - Error Handling & Reconnection
    
    private func handleError(_ error: Error) {
        Task { @MainActor in
            self.logger.error("WebSocket error: \(error)")
            self.isConnected = false
            self.connectionStatus = "Error: \(error.localizedDescription)"
            
            // Attempt reconnection
            if self.reconnectAttempts < self.maxReconnectAttempts {
                self.reconnectAttempts += 1
                self.connectionStatus = "Reconnecting... (\(self.reconnectAttempts)/\(self.maxReconnectAttempts))"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + self.reconnectDelay) {
                    self.connect()
                }
            } else {
                self.connectionStatus = "Connection failed"
            }
        }
    }
    
    private func setupReconnectionTimer() {
        // Check connection health every 30 seconds
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkConnectionHealth()
            }
            .store(in: &cancellables)
    }
    
    private func checkConnectionHealth() {
        guard isConnected else { return }
        
        // Send ping to check if connection is alive
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                self?.logger.warning("Ping failed: \(error)")
                Task { @MainActor in
                    self?.handleError(error)
                }
            }
        }
    }
    
    // MARK: - Demo Price Simulation
    
    private func startPriceSimulation(for symbol: String) {
        // Simulate realistic price movements for demo
        Timer.publish(every: 2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.simulatePriceUpdate(for: symbol)
            }
            .store(in: &cancellables)
    }
    
    private func simulatePriceUpdate(for symbol: String) {
        let basePrice = 45000.0 // Base BTC price
        let variation = Double.random(in: -500...500)
        let newPrice = basePrice + variation
        
        priceUpdates[symbol] = newPrice
        if symbol == "BTCUSDT" {
            latestPrice = newPrice
        }
        
        // Notify other services
        NotificationCenter.default.post(
            name: .priceUpdate,
            object: nil,
            userInfo: ["symbol": symbol, "price": newPrice]
        )
        
        // Update trading service positions
        TradingService.shared.updatePositionPrices(symbol: symbol, currentPrice: newPrice)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let priceUpdate = Notification.Name("priceUpdate")
    static let webSocketStatusChanged = Notification.Name("webSocketStatusChanged")
}