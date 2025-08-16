import Foundation
import Combine
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "MarketData")

@MainActor
final class MarketDataService: ObservableObject {
    static let shared = MarketDataService()
    
    @Published var latestPrice: Double = 0
    @Published var candles: [String: [Candle]] = [:] // Key: "symbol-timeframe"
    
    private var cancellables = Set<AnyCancellable>()
    
    // Efficient caching
    private var candleCache: [String: [Candle]] = [:]
    private var priceCache: [String: Double] = [:]
    
    // Performance tracking
    private var lastDataFetch: Date = .distantPast
    private var fetchCount = 0
    
    private init() {
        // TODO: Re-enable when MemoryPressureManager is available
        // Listen for memory pressure notifications
        // NotificationCenter.default.addObserver(
        //     self,
        //     selector: #selector(handleMemoryPressure),
        //     name: .memoryPressureChanged,
        //     object: nil
        // )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // TODO: Re-enable when MemoryPressureManager is available
    // @objc private func handleMemoryPressure(_ notification: Notification) {
    //     guard let level = notification.userInfo?["level"] as? MemoryPressureManager.MemoryPressureLevel else { return }
        
    //     Task { @MainActor in
    //         switch level {
    //         case .warning:
    //             await clearOldData()
    //         case .critical:
    //             await clearOldData()
    //             // Clear more aggressively
    //             let keysToRemove = candles.keys.filter { key in
    //                 !key.contains("BTCUSDT") // Keep only BTC data
    //             }
    //             for key in keysToRemove {
    //                 candles.removeValue(forKey: key)
    //                 candleCache.removeValue(forKey: key)
    //             }
    //             Log.performance("Cleared non-essential market data due to critical memory pressure")
    //         case .normal:
    //             break
    //         }
    //     }
    // }
    
    func fetchCandles(symbol: String, timeframe: Timeframe) async throws -> [Candle] {
        let key = "\(symbol)-\(timeframe.rawValue)"
        let startTime = Date()
        
        // Performance tracking
        fetchCount += 1
        lastDataFetch = startTime
        
        // Check efficient cache first
        if let cached = candleCache[key], !cached.isEmpty,
           let lastCandle = cached.last,
           Date().timeIntervalSince(lastCandle.openTime) < getCacheTimeout(for: timeframe) {
            logger.debug("Returning cached candles for \(key)")
            candles[key] = cached // Update in-memory cache for UI binding
            Log.performance("Market data cache hit for \(key)")
            return cached
        }
        
        // TODO: Re-enable when ConnectionManager is available
        // Check if we should throttle requests based on network conditions
        // let networkStatus = ConnectionManager.shared.networkStatus
        // if networkStatus.isExpensive && Date().timeIntervalSince(lastDataFetch) < 30.0 {
        //     logger.debug("Throttling market data request on expensive network")
        //     // Return cached data even if slightly stale
        //     if let cached = candleCache[key], !cached.isEmpty {
        //         candles[key] = cached
        //         return cached
        //     }
        // }
        
        // In demo mode, generate mock data
        if AppSettings.shared.demoMode {
            let mockCandles = generateMockCandles(symbol: symbol, timeframe: timeframe)
            candles[key] = mockCandles
            candleCache[key] = mockCandles // Cache efficiently
            logger.info("Generated mock candles for \(key) in demo mode")
            Log.performance("Mock data generation", duration: Date().timeIntervalSince(startTime))
            return mockCandles
        }
        
        // Fetch real market data
        do {
            let realCandles = try await fetchRealMarketData(symbol: symbol, timeframe: timeframe)
            candles[key] = realCandles
            candleCache[key] = realCandles // Cache efficiently
            logger.info("Fetched \(realCandles.count) real candles for \(key)")
            Log.performance("Real market data fetch", duration: Date().timeIntervalSince(startTime))
            return realCandles
        } catch {
            logger.error("Failed to fetch real market data for \(key): \(error.localizedDescription)")
            
            // Fallback to mock data if real data fails
            let mockCandles = generateMockCandles(symbol: symbol, timeframe: timeframe)
            candles[key] = mockCandles
            candleCache[key] = mockCandles // Cache efficiently
            logger.info("Fallback to mock candles for \(key)")
            Log.performance("Fallback data generation", duration: Date().timeIntervalSince(startTime))
            return mockCandles
        }
    }
    
    private func fetchRealMarketData(symbol: String, timeframe: Timeframe) async throws -> [Candle] {
        // Determine which exchange to use based on symbol format
        let exchange = determineExchange(for: symbol)
        
        switch exchange {
        case .binance:
            return try await fetchBinanceCandles(symbol: symbol, timeframe: timeframe)
        case .kraken:
            return try await fetchKrakenCandles(symbol: symbol, timeframe: timeframe)
        }
    }
    
    private func determineExchange(for symbol: String) -> Exchange {
        // Default to Binance for most symbols, could be made configurable
        return .binance
    }
    
    private func fetchBinanceCandles(symbol: String, timeframe: Timeframe) async throws -> [Candle] {
        let interval = mapTimeframeToBinanceInterval(timeframe)
        let limit = 500 // Maximum allowed by Binance
        
        guard let url = URL(string: "https://api.binance.com/api/v3/klines?symbol=\(symbol)&interval=\(interval)&limit=\(limit)") else {
            throw MarketDataError.invalidSymbol
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MarketDataError.networkError("HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[Any]] else {
            throw MarketDataError.networkError("Invalid JSON response")
        }
        
        let candles = try jsonArray.compactMap { klineData -> Candle? in
            guard klineData.count >= 11,
                  let openTimeMs = klineData[0] as? Double,
                  let openStr = klineData[1] as? String,
                  let highStr = klineData[2] as? String,
                  let lowStr = klineData[3] as? String,
                  let closeStr = klineData[4] as? String,
                  let volumeStr = klineData[5] as? String,
                  let open = Double(openStr),
                  let high = Double(highStr),
                  let low = Double(lowStr),
                  let close = Double(closeStr),
                  let volume = Double(volumeStr) else {
                return nil
            }
            
            let openTime = Date(timeIntervalSince1970: openTimeMs / 1000)
            
            return Candle(
                openTime: openTime,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
        }
        
        return candles
    }
    
    private func fetchKrakenCandles(symbol: String, timeframe: Timeframe) async throws -> [Candle] {
        let interval = mapTimeframeToKrakenInterval(timeframe)
        let krakenSymbol = mapSymbolToKraken(symbol)
        
        guard let url = URL(string: "https://api.kraken.com/0/public/OHLC?pair=\(krakenSymbol)&interval=\(interval)") else {
            throw MarketDataError.invalidSymbol
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MarketDataError.networkError("HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any] else {
            throw MarketDataError.networkError("Invalid JSON response")
        }
        
        // Kraken returns data with dynamic pair names
        guard let pairData = result.values.first(where: { $0 is [[Any]] }) as? [[Any]] else {
            throw MarketDataError.networkError("No OHLC data found")
        }
        
        let candles = try pairData.compactMap { ohlcData -> Candle? in
            guard ohlcData.count >= 7,
                  let timestamp = ohlcData[0] as? Double,
                  let openStr = ohlcData[1] as? String,
                  let highStr = ohlcData[2] as? String,
                  let lowStr = ohlcData[3] as? String,
                  let closeStr = ohlcData[4] as? String,
                  let volumeStr = ohlcData[6] as? String,
                  let open = Double(openStr),
                  let high = Double(highStr),
                  let low = Double(lowStr),
                  let close = Double(closeStr),
                  let volume = Double(volumeStr) else {
                return nil
            }
            
            let openTime = Date(timeIntervalSince1970: timestamp)
            
            return Candle(
                openTime: openTime,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
        }
        
        return candles
    }
    
    private func mapTimeframeToBinanceInterval(_ timeframe: Timeframe) -> String {
        switch timeframe {
        case .m5: return "5m"
        case .h1: return "1h"
        case .h4: return "4h"
        }
    }
    
    private func mapTimeframeToKrakenInterval(_ timeframe: Timeframe) -> Int {
        switch timeframe {
        case .m5: return 5
        case .h1: return 60
        case .h4: return 240
        }
    }
    
    private func mapSymbolToKraken(_ symbol: String) -> String {
        // Convert common symbols to Kraken format
        let symbol = symbol.uppercased()
        if symbol.hasPrefix("BTC") {
            return "XBT" + String(symbol.dropFirst(3))
        }
        return symbol
    }
    
    private func getCacheTimeout(for timeframe: Timeframe) -> TimeInterval {
        switch timeframe {
        case .m5: return 300 // 5 minutes
        case .h1: return 3600 // 1 hour
        case .h4: return 14400 // 4 hours
        }
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
    
    // MARK: - Memory Management
    
    func clearOldData() async {
        await MainActor.run {
            // Keep only recent data for current symbols
            let cutoffTime = Date().addingTimeInterval(-3600) // 1 hour ago
            var clearedCount = 0
            
            for (key, candleArray) in candles {
                let recentCandles = candleArray.filter { $0.openTime > cutoffTime }
                if recentCandles.count < candleArray.count {
                    candles[key] = Array(recentCandles.suffix(200)) // Keep last 200 candles
                    candleCache[key] = candles[key] // Update cache
                    clearedCount += (candleArray.count - recentCandles.count)
                }
            }
            
            if clearedCount > 0 {
                Log.performance("Cleared \(clearedCount) old candles from market data")
            }
        }
    }
    
    func getPerformanceMetrics() -> MarketDataMetrics {
        return MarketDataMetrics(
            fetchCount: fetchCount,
            lastFetchTime: lastDataFetch,
            cachedSymbols: candles.keys.count,
            totalCandles: candles.values.reduce(0) { $0 + $1.count }
        )
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

// MARK: - Supporting Types

struct MarketDataMetrics {
    let fetchCount: Int
    let lastFetchTime: Date
    let cachedSymbols: Int
    let totalCandles: Int
}