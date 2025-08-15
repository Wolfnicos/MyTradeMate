import Foundation
import Combine

@MainActor
final class BinanceExchangeClient: ObservableObject {
    @Published var isConnected = false
    @Published var lastPrice: Double = 0.0
    @Published var priceChange: Double = 0.0
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    
    func connect(to stream: String) async {
        guard let url = URL(string: "wss://stream.binance.com:9443/ws/\(stream)") else {
            return
        }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Subscribe to stream
        let subscribeMessage = """
        {
            "method": "SUBSCRIBE",
            "params": ["\(stream)"],
            "id": 1
        }
        """
        
        do {
            try await webSocketTask?.send(.string(subscribeMessage))
            isConnected = true
            
            // Start receiving messages
            receiveMessages()
            
            print("✅ Connected to Binance WebSocket: \(stream)")
        } catch {
            print("❌ Failed to connect to Binance WebSocket: \(error.localizedDescription)")
        }
    }
    
    private func receiveMessages() {
        guard let webSocketTask = webSocketTask else { return }
        
        webSocketTask.receive { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    self?.handleMessage(message)
                case .failure(let error):
                    print("❌ WebSocket receive error: \(error.localizedDescription)")
                    self?.isConnected = false
                }
            }
            
            // Continue receiving messages
            self?.receiveMessages()
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                if let price = json["p"] as? String,
                   let priceDouble = Double(price) {
                    let oldPrice = lastPrice
                    lastPrice = priceDouble
                    priceChange = lastPrice - oldPrice
                    
                    print("📊 Price update: \(priceDouble)")
                }
            }
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                print("📦 Received data: \(text)")
            }
        @unknown default:
            break
        }
    }
    
    func disconnect() async {
        webSocketTask?.cancel()
        webSocketTask = nil
        isConnected = false
        print("🔌 Disconnected from Binance WebSocket")
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