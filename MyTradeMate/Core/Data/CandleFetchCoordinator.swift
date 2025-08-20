import Foundation
import Combine
import OSLog

/// Coordinates candle data fetching across multiple sources to prevent cache inconsistencies
/// Implements single-flight pattern and standardized cache keys
@MainActor
final class CandleFetchCoordinator: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CandleFetchCoordinator()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "MyTradeMate", category: "CandleFetchCoordinator")
    private var inflightRequests: [String: Task<[Candle], Error>] = [:]
    private var lastFetchTimes: [String: Date] = [:]
    private let debounceInterval: TimeInterval = 0.5
    
    // MARK: - Cache Key Standardization
    
    /// Generate standardized cache key: "SYMBOL:TIMEFRAME"
    static func cacheKey(symbol: String, timeframe: Timeframe) -> String {
        let normalizedSymbol = symbol.uppercased().replacingOccurrences(of: "/", with: "")
        return "\(normalizedSymbol):\(timeframe.rawValue.uppercased())"
    }
    
    /// Parse cache key back to symbol and timeframe
    static func parseCacheKey(_ key: String) -> (symbol: String, timeframe: String)? {
        let components = key.split(separator: ":")
        guard components.count == 2 else { return nil }
        return (symbol: String(components[0]), timeframe: String(components[1]))
    }
    
    // MARK: - Coordinated Fetching
    
    /// Coordinate candle fetch with debouncing and single-flight pattern
    func fetchCandles(
        symbol: String, 
        timeframe: Timeframe,
        source: CandleFetchSource = .marketData
    ) async throws -> [Candle] {
        let key = Self.cacheKey(symbol: symbol, timeframe: timeframe)
        
        // Check debounce - prevent rapid successive requests
        if let lastFetch = lastFetchTimes[key],
           Date().timeIntervalSince(lastFetch) < debounceInterval {
            logger.debug("⏱️ Debouncing fetch request for \(key)")
            
            // If there's an inflight request, await it
            if let existingTask = inflightRequests[key] {
                return try await existingTask.value
            }
            throw CandleFetchError.rateLimited
        }
        
        // Check for existing inflight request (single-flight pattern)
        if let existingTask = inflightRequests[key] {
            logger.debug("🔄 Joining existing fetch for \(key)")
            return try await existingTask.value
        }
        
        // Create new fetch task
        let fetchTask = Task<[Candle], Error> {
            defer {
                inflightRequests.removeValue(forKey: key)
                lastFetchTimes[key] = Date()
            }
            
            logger.info("📊 Coordinated fetch: \(key) from \(source.rawValue)")
            
            switch source {
            case .marketData:
                return try await MarketDataService.shared.fetchCandles(symbol: symbol, timeframe: timeframe)
            case .widget:
                return try await fetchCandlesForWidget(symbol: symbol, timeframe: timeframe)
            case .appForeground:
                return try await fetchCandlesForForeground(symbol: symbol, timeframe: timeframe)
            }
        }
        
        inflightRequests[key] = fetchTask
        
        do {
            return try await fetchTask.value
        } catch {
            // Remove failed task from inflight requests
            inflightRequests.removeValue(forKey: key)
            throw error
        }
    }
    
    // MARK: - Source-Specific Fetching
    
    private func fetchCandlesForWidget(symbol: String, timeframe: Timeframe) async throws -> [Candle] {
        // Widget requests might need different caching strategy (longer TTL)
        return try await MarketDataService.shared.fetchCandles(symbol: symbol, timeframe: timeframe)
    }
    
    private func fetchCandlesForForeground(symbol: String, timeframe: Timeframe) async throws -> [Candle] {
        // Foreground requests might need fresher data
        return try await MarketDataService.shared.fetchCandles(symbol: symbol, timeframe: timeframe)
    }
    
    // MARK: - Cache Management
    
    /// Clear inflight requests (useful for memory pressure or app backgrounding)
    func clearInflightRequests() {
        logger.info("🧹 Clearing \(inflightRequests.count) inflight requests")
        for (_, task) in inflightRequests {
            task.cancel()
        }
        inflightRequests.removeAll()
    }
    
    /// Get fetch statistics for debugging
    func getFetchStatistics() -> CandleFetchStatistics {
        return CandleFetchStatistics(
            inflightRequestCount: inflightRequests.count,
            cachedKeyCount: lastFetchTimes.count,
            oldestCacheEntry: lastFetchTimes.values.min(),
            newestCacheEntry: lastFetchTimes.values.max()
        )
    }
    
    deinit {
        clearInflightRequests()
    }
}

// MARK: - Supporting Types

enum CandleFetchSource: String, CaseIterable {
    case marketData = "MarketData"
    case widget = "Widget" 
    case appForeground = "AppForeground"
}

enum CandleFetchError: LocalizedError {
    case rateLimited
    case sourceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .rateLimited:
            return "Fetch request rate limited"
        case .sourceUnavailable:
            return "Data source unavailable"
        }
    }
}

struct CandleFetchStatistics {
    let inflightRequestCount: Int
    let cachedKeyCount: Int
    let oldestCacheEntry: Date?
    let newestCacheEntry: Date?
    
    var description: String {
        return """
        Fetch Statistics:
        - Inflight: \(inflightRequestCount)
        - Cached keys: \(cachedKeyCount)
        - Cache age: \(oldestCacheEntry?.timeIntervalSinceNow ?? 0)s to \(newestCacheEntry?.timeIntervalSinceNow ?? 0)s
        """
    }
}