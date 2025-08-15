import Foundation
import Combine
import OSLog

private let logger = Logger(subsystem: "com.mytrademate", category: "MarketData")

@MainActor
final class MarketDataService: ObservableObject {
    static let shared = MarketDataService()
    
    @Published var latestPrice: Double = 0
    @Published var candles: [String: [Candle]] = [:] // Key: "symbol-timeframe"
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    func fetchCandles(symbol: String, timeframe: Timeframe) async throws -> [Candle] {
        let key = "\(symbol)-\(timeframe.rawValue)"
        
        // Return cached candles if available
        if let cached = candles[key], !cached.isEmpty {
            return cached
        }
        
        // In demo mode, generate mock data
        if AppSettings.shared.demoMode {
            let mockCandles = generateMockCandles(symbol: symbol, timeframe: timeframe)
            candles[key] = mockCandles
            return mockCandles
        }
        
        // TODO: Implement real market data fetching
        throw MarketDataError.notImplemented
    }
    
    private func generateMockCandles(symbol: String, timeframe: Timeframe) -> [Candle] {
        let basePrice: Double = symbol.contains("BTC") ? 45000 : 2500
        let count = 200
        var result: [Candle] = []
        
        let intervalSeconds: Double
        switch timeframe {
        case .m5: intervalSeconds = 300
        case .h1: intervalSeconds = 3600
        case .h4: intervalSeconds = 14400
        }
        
        for i in 0..<count {
            let timestamp = Date().addingTimeInterval(-Double(i) * intervalSeconds)
            let volatility = basePrice * 0.005
            let trend = sin(Double(i) * 0.05) * volatility
            
            let open = basePrice + trend + Double.random(in: -volatility...volatility)
            let close = open + Double.random(in: -volatility/2...volatility/2)
            let high = max(open, close) + Double.random(in: 0...volatility/4)
            let low = min(open, close) - Double.random(in: 0...volatility/4)
            let volume = Double.random(in: 100...1000)
            
            result.append(Candle(
                openTime: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
        }
        
        return result.reversed()
    }
    
    enum MarketDataError: LocalizedError {
        case notImplemented
        case invalidSymbol
        case networkError(String)
        
        var errorDescription: String? {
            switch self {
            case .notImplemented:
                return "Live market data not yet implemented"
            case .invalidSymbol:
                return "Invalid symbol"
            case .networkError(let message):
                return "Network error: \(message)"
            }
        }
    }
}