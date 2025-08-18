import Foundation
import OSLog

private let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "MyTradeMate", category: "DataCacheManager")

/// Manages efficient data caching with memory pressure awareness and intelligent eviction
@MainActor
final class DataCacheManager: ObservableObject {
    static let shared = DataCacheManager()
    
    @Published var cacheStats: CacheStatistics = CacheStatistics()
    
    private var caches: [String: AnyCache] = [:]
    private var cacheAccessTimes: [String: Date] = [:]
    private var memoryPressureObserver: NSObjectProtocol?
    private var cleanupTimer: Timer?
    
    // Cache configuration
    private let maxTotalMemoryMB: Double = 50.0 // 50MB total cache limit
    private let cleanupInterval: TimeInterval = 300.0 // 5 minutes
    private let maxCacheAge: TimeInterval = 3600.0 // 1 hour
    
    private init() {
        setupMemoryPressureObserver()
        startPeriodicCleanup()
    }
    
    deinit {
        cleanupTimer?.invalidate()
        if let observer = memoryPressureObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Setup
    
    private func setupMemoryPressureObserver() {
        memoryPressureObserver = NotificationCenter.default.addObserver(
            forName: .memoryPressureChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let level = notification.userInfo?["level"] as? MemoryPressureManager.MemoryPressureLevel else { return }
            self?.handleMemoryPressure(level)
        }
    }
    
    private func startPeriodicCleanup() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.performPeriodicCleanup()
            }
        }
    }
    
    // MARK: - Cache Management
    
    func getCache<T: Codable>(for key: String, type: T.Type) -> DataCache<T> {
        if let existingCache = caches[key] as? DataCache<T> {
            cacheAccessTimes[key] = Date()
            return existingCache
        }
        
        let newCache = DataCache<T>(
            name: key,
            maxSize: calculateMaxSizeForCache(key),
            maxAge: maxCacheAge
        )
        
        caches[key] = AnyCache(newCache)
        cacheAccessTimes[key] = Date()
        
        logger.info("Created new cache: \(key)")
        updateCacheStatistics()
        
        return newCache
    }
    
    private func calculateMaxSizeForCache(_ key: String) -> Int {
        // Allocate cache size based on cache type and priority
        switch key {
        case "market_data":
            return 200 // 200 items for market data
        case "candles":
            return 100 // 100 candle arrays
        case "predictions":
            return 50 // 50 prediction results
        case "user_settings":
            return 20 // 20 settings objects
        default:
            return 50 // Default size
        }
    }
    
    // MARK: - Memory Pressure Handling
    
    private func handleMemoryPressure(_ level: MemoryPressureManager.MemoryPressureLevel) {
        logger.info("Handling memory pressure: \(level.description)")
        
        switch level {
        case .normal:
            // No action needed
            break
        case .warning:
            performWarningLevelCacheCleanup()
        case .critical:
            performCriticalLevelCacheCleanup()
        }
        
        updateCacheStatistics()
    }
    
    private func performWarningLevelCacheCleanup() {
        logger.info("Performing warning-level cache cleanup")
        
        // Remove least recently used caches
        let sortedCaches = cacheAccessTimes.sorted { $0.value < $1.value }
        let cachesToRemove = sortedCaches.prefix(caches.count / 3) // Remove 1/3 of caches
        
        for (cacheKey, _) in cachesToRemove {
            if let cache = caches[cacheKey] {
                cache.clearHalf()
                logger.debug("Cleared half of cache: \(cacheKey)")
            }
        }
    }
    
    private func performCriticalLevelCacheCleanup() {
        logger.warning("Performing critical-level cache cleanup")
        
        // Keep only essential caches
        let essentialCaches = ["user_settings", "market_data"]
        
        for (cacheKey, cache) in caches {
            if essentialCaches.contains(cacheKey) {
                cache.clearHalf()
            } else {
                cache.clearAll()
                caches.removeValue(forKey: cacheKey)
                cacheAccessTimes.removeValue(forKey: cacheKey)
                logger.debug("Removed non-essential cache: \(cacheKey)")
            }
        }
    }
    
    // MARK: - Periodic Cleanup
    
    private func performPeriodicCleanup() {
        logger.debug("Performing periodic cache cleanup")
        
        let now = Date()
        var removedCaches = 0
        var cleanedItems = 0
        
        // Remove expired items from all caches
        for (_, cache) in caches {
            let removedCount = cache.removeExpiredItems()
            cleanedItems += removedCount
        }
        
        // Remove unused caches
        let unusedThreshold = now.addingTimeInterval(-maxCacheAge)
        let unusedCaches = cacheAccessTimes.compactMap { (key, lastAccess) in
            lastAccess < unusedThreshold ? key : nil
        }
        
        for cacheKey in unusedCaches {
            caches.removeValue(forKey: cacheKey)
            cacheAccessTimes.removeValue(forKey: cacheKey)
            removedCaches += 1
        }
        
        if removedCaches > 0 || cleanedItems > 0 {
            logger.info("Periodic cleanup: removed \(removedCaches) caches, \(cleanedItems) expired items")
        }
        
        updateCacheStatistics()
    }
    
    // MARK: - Statistics
    
    private func updateCacheStatistics() {
        let totalItems = caches.values.reduce(0) { $0 + $1.count }
        let totalMemoryMB = caches.values.reduce(0.0) { $0 + $1.estimatedMemoryUsageMB }
        
        cacheStats = CacheStatistics(
            totalCaches: caches.count,
            totalItems: totalItems,
            totalMemoryMB: totalMemoryMB,
            memoryUsagePercent: (totalMemoryMB / maxTotalMemoryMB) * 100
        )
    }
    
    // MARK: - Public Interface
    
    func clearAllCaches() {
        logger.info("Clearing all caches")
        
        for (_, cache) in caches {
            cache.clearAll()
        }
        
        caches.removeAll()
        cacheAccessTimes.removeAll()
        updateCacheStatistics()
    }
    
    func clearCache(named name: String) {
        if let cache = caches[name] {
            cache.clearAll()
            caches.removeValue(forKey: name)
            cacheAccessTimes.removeValue(forKey: name)
            logger.info("Cleared cache: \(name)")
            updateCacheStatistics()
        }
    }
    
    func getCacheInfo() -> [CacheInfo] {
        return caches.map { (key, cache) in
            CacheInfo(
                name: key,
                itemCount: cache.count,
                memoryUsageMB: cache.estimatedMemoryUsageMB,
                lastAccessed: cacheAccessTimes[key] ?? Date.distantPast
            )
        }.sorted { $0.lastAccessed > $1.lastAccessed }
    }
}

// MARK: - Data Cache Implementation

final class DataCache<T: Codable> {
    private var storage: [String: CacheItem<T>] = [:]
    private let name: String
    private let maxSize: Int
    private let maxAge: TimeInterval
    private let accessQueue = DispatchQueue(label: "DataCache", attributes: .concurrent)
    
    init(name: String, maxSize: Int, maxAge: TimeInterval) {
        self.name = name
        self.maxSize = maxSize
        self.maxAge = maxAge
    }
    
    func get(_ key: String) -> T? {
        return accessQueue.sync {
            guard let item = storage[key] else { return nil }
            
            // Check if item has expired
            if Date().timeIntervalSince(item.timestamp) > maxAge {
                storage.removeValue(forKey: key)
                return nil
            }
            
            // Update access time
            storage[key] = CacheItem(
                value: item.value,
                timestamp: item.timestamp,
                lastAccessed: Date()
            )
            
            return item.value
        }
    }
    
    func set(_ key: String, value: T) {
        accessQueue.async(flags: .barrier) {
            // Remove oldest items if at capacity
            if self.storage.count >= self.maxSize {
                self.evictOldestItems()
            }
            
            self.storage[key] = CacheItem(
                value: value,
                timestamp: Date(),
                lastAccessed: Date()
            )
        }
    }
    
    func remove(_ key: String) {
        accessQueue.async(flags: .barrier) {
            self.storage.removeValue(forKey: key)
        }
    }
    
    private func evictOldestItems() {
        let itemsToRemove = max(1, maxSize / 4) // Remove 25% of items
        let sortedItems = storage.sorted { $0.value.lastAccessed < $1.value.lastAccessed }
        
        for (key, _) in sortedItems.prefix(itemsToRemove) {
            storage.removeValue(forKey: key)
        }
    }
}

// MARK: - Type Erasure for Cache Storage

private class AnyCache {
    private let _count: () -> Int
    private let _estimatedMemoryUsageMB: () -> Double
    private let _clearAll: () -> Void
    private let _clearHalf: () -> Void
    private let _removeExpiredItems: () -> Int
    
    init<T: Codable>(_ cache: DataCache<T>) {
        _count = { cache.count }
        _estimatedMemoryUsageMB = { cache.estimatedMemoryUsageMB }
        _clearAll = { cache.clearAll() }
        _clearHalf = { cache.clearHalf() }
        _removeExpiredItems = { cache.removeExpiredItems() }
    }
    
    var count: Int { _count() }
    var estimatedMemoryUsageMB: Double { _estimatedMemoryUsageMB() }
    func clearAll() { _clearAll() }
    func clearHalf() { _clearHalf() }
    func removeExpiredItems() -> Int { _removeExpiredItems() }
}

// MARK: - Cache Extensions

extension DataCache {
    var count: Int {
        return accessQueue.sync { storage.count }
    }
    
    var estimatedMemoryUsageMB: Double {
        return accessQueue.sync {
            // Rough estimation: 1KB per item on average
            return Double(storage.count) * 0.001
        }
    }
    
    func clearAll() {
        accessQueue.async(flags: .barrier) {
            self.storage.removeAll()
        }
    }
    
    func clearHalf() {
        accessQueue.async(flags: .barrier) {
            let itemsToKeep = self.storage.count / 2
            let sortedItems = self.storage.sorted { $0.value.lastAccessed > $1.value.lastAccessed }
            
            self.storage.removeAll()
            
            for (key, item) in sortedItems.prefix(itemsToKeep) {
                self.storage[key] = item
            }
        }
    }
    
    func removeExpiredItems() -> Int {
        return accessQueue.sync(flags: .barrier) {
            let now = Date()
            let initialCount = storage.count
            
            storage = storage.filter { (_, item) in
                now.timeIntervalSince(item.timestamp) <= maxAge
            }
            
            return initialCount - storage.count
        }
    }
}

// MARK: - Supporting Types

private struct CacheItem<T: Codable> {
    let value: T
    let timestamp: Date
    let lastAccessed: Date
}

struct CacheStatistics {
    let totalCaches: Int
    let totalItems: Int
    let totalMemoryMB: Double
    let memoryUsagePercent: Double
    
    init(totalCaches: Int = 0, totalItems: Int = 0, totalMemoryMB: Double = 0, memoryUsagePercent: Double = 0) {
        self.totalCaches = totalCaches
        self.totalItems = totalItems
        self.totalMemoryMB = totalMemoryMB
        self.memoryUsagePercent = memoryUsagePercent
    }
}

struct CacheInfo {
    let name: String
    let itemCount: Int
    let memoryUsageMB: Double
    let lastAccessed: Date
}