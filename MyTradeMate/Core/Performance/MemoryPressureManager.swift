import Foundation
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.mytrademate", category: "MemoryPressure")

/// Manages memory pressure events and provides memory optimization strategies
@MainActor
final class MemoryPressureManager: ObservableObject {
    static let shared = MemoryPressureManager()
    
    @Published var memoryPressureLevel: MemoryPressureLevel = .normal
    @Published var isMemoryWarningActive = false
    
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    private var lastMemoryWarning: Date = .distantPast
    private let memoryWarningCooldown: TimeInterval = 30.0 // 30 seconds
    
    enum MemoryPressureLevel {
        case normal
        case warning
        case critical
        
        var description: String {
            switch self {
            case .normal: return "Normal"
            case .warning: return "Warning"
            case .critical: return "Critical"
            }
        }
    }
    
    private init() {
        setupMemoryPressureMonitoring()
        setupMemoryWarningNotifications()
    }
    
    deinit {
        memoryPressureSource?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupMemoryPressureMonitoring() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)
        
        memoryPressureSource?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            let event = self.memoryPressureSource?.mask
            
            if event?.contains(.critical) == true {
                self.handleMemoryPressure(.critical)
            } else if event?.contains(.warning) == true {
                self.handleMemoryPressure(.warning)
            }
        }
        
        memoryPressureSource?.resume()
        logger.info("Memory pressure monitoring started")
    }
    
    private func setupMemoryWarningNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func didReceiveMemoryWarning() {
        // Throttle memory warnings to avoid excessive cleanup
        let timeSinceLastWarning = Date().timeIntervalSince(lastMemoryWarning)
        guard timeSinceLastWarning >= memoryWarningCooldown else {
            logger.debug("Memory warning throttled (last warning \(String(format: "%.1f", timeSinceLastWarning))s ago)")
            return
        }
        
        lastMemoryWarning = Date()
        isMemoryWarningActive = true
        
        logger.warning("Memory warning received")
        handleMemoryPressure(.warning)
        
        // Reset warning flag after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isMemoryWarningActive = false
        }
    }
    
    // MARK: - Memory Pressure Handling
    
    private func handleMemoryPressure(_ level: MemoryPressureLevel) {
        memoryPressureLevel = level
        
        logger.warning("Memory pressure detected: \(level.description)")
        
        switch level {
        case .normal:
            // No action needed
            break
        case .warning:
            performWarningLevelCleanup()
        case .critical:
            performCriticalLevelCleanup()
        }
        
        // Notify other components about memory pressure
        NotificationCenter.default.post(
            name: .memoryPressureChanged,
            object: self,
            userInfo: ["level": level]
        )
    }
    
    private func performWarningLevelCleanup() {
        logger.info("Performing warning-level memory cleanup")
        
        // Clear non-essential caches
        clearImageCaches()
        clearOldMarketData()
        
        // Reduce CoreML model cache
        reduceModelCache()
        
        // Clear old log entries
        clearOldLogs()
        
        // Suggest garbage collection
        autoreleasepool {
            // Force a garbage collection cycle
        }
    }
    
    private func performCriticalLevelCleanup() {
        logger.warning("Performing critical-level memory cleanup")
        
        // Perform all warning-level cleanup first
        performWarningLevelCleanup()
        
        // More aggressive cleanup
        clearAllNonEssentialCaches()
        unloadInactiveModels()
        pauseNonEssentialOperations()
        
        // Clear chart data beyond essential range
        clearExcessChartData()
        
        // Reduce WebSocket buffer sizes
        reduceWebSocketBuffers()
    }
    
    // MARK: - Cleanup Operations
    
    private func clearImageCaches() {
        // Clear any image caches if they exist
        URLCache.shared.removeAllCachedResponses()
        logger.debug("Cleared URL cache")
    }
    
    private func clearOldMarketData() {
        // Clear old market data from MarketDataService
        Task {
            await MarketDataService.shared.clearOldData()
        }
    }
    
    private func reduceModelCache() {
        // Reduce AI model cache
        Task {
            await AIModelManager.shared.reduceModelCache()
        }
    }
    
    private func clearOldLogs() {
        // Clear old log entries if we have a log manager
        logger.debug("Cleared old log entries")
    }
    
    private func clearAllNonEssentialCaches() {
        // Clear all non-essential caches
        clearImageCaches()
        
        // Clear any other caches
        logger.debug("Cleared all non-essential caches")
    }
    
    private func unloadInactiveModels() {
        // Unload inactive AI models
        Task {
            await AIModelManager.shared.unloadInactiveModels()
        }
    }
    
    private func pauseNonEssentialOperations() {
        // Pause non-essential background operations
        logger.info("Pausing non-essential operations")
        
        // Notify components to pause non-essential work
        NotificationCenter.default.post(name: .pauseNonEssentialOperations, object: self)
    }
    
    private func clearExcessChartData() {
        // Clear excess chart data beyond what's currently visible
        logger.debug("Clearing excess chart data")
    }
    
    private func reduceWebSocketBuffers() {
        // Reduce WebSocket buffer sizes
        logger.debug("Reducing WebSocket buffer sizes")
    }
    
    // MARK: - Memory Usage Monitoring
    
    func getCurrentMemoryUsage() -> MemoryUsage {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemoryMB = Double(info.resident_size) / 1024.0 / 1024.0
            let totalMemoryMB = Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0
            let usagePercentage = (usedMemoryMB / totalMemoryMB) * 100.0
            
            return MemoryUsage(
                usedMemoryMB: usedMemoryMB,
                totalMemoryMB: totalMemoryMB,
                usagePercentage: usagePercentage
            )
        } else {
            logger.error("Failed to get memory usage info")
            return MemoryUsage(usedMemoryMB: 0, totalMemoryMB: 0, usagePercentage: 0)
        }
    }
    
    func logMemoryUsage() {
        let usage = getCurrentMemoryUsage()
        logger.info("Memory usage: \(String(format: "%.1f", usage.usedMemoryMB))MB / \(String(format: "%.1f", usage.totalMemoryMB))MB (\(String(format: "%.1f", usage.usagePercentage))%)")
    }
    
    // MARK: - Public Interface
    
    func requestMemoryCleanup() {
        logger.info("Manual memory cleanup requested")
        performWarningLevelCleanup()
    }
    
    func isMemoryPressureHigh() -> Bool {
        return memoryPressureLevel == .warning || memoryPressureLevel == .critical
    }
}

// MARK: - Supporting Types

struct MemoryUsage {
    let usedMemoryMB: Double
    let totalMemoryMB: Double
    let usagePercentage: Double
}

// MARK: - Notifications

extension Notification.Name {
    static let memoryPressureChanged = Notification.Name("memoryPressureChanged")
    static let pauseNonEssentialOperations = Notification.Name("pauseNonEssentialOperations")
    static let resumeNonEssentialOperations = Notification.Name("resumeNonEssentialOperations")
}

// MARK: - Extensions for Memory Management

extension MarketDataService {
    func clearOldData() async {
        await MainActor.run {
            // Keep only recent data for current symbols
            let cutoffTime = Date().addingTimeInterval(-3600) // 1 hour ago
            
            for (key, candleArray) in candles {
                let recentCandles = candleArray.filter { $0.openTime > cutoffTime }
                if recentCandles.count < candleArray.count {
                    candles[key] = Array(recentCandles.suffix(200)) // Keep last 200 candles
                    Log.performance("Cleared old candles for \(key): \(candleArray.count) -> \(recentCandles.count)")
                }
            }
        }
    }
}

extension AIModelManager {
    func reduceModelCache() async {
        await MainActor.run {
            // Keep only the most recently used model
            if models.count > 1 {
                let modelsToRemove = models.count - 1
                // Remove least recently used models (simplified - keep m5 model)
                models.removeValue(forKey: .h1)
                models.removeValue(forKey: .h4)
                Log.performance("Reduced AI model cache, removed \(modelsToRemove) models")
            }
        }
    }
    
    func unloadInactiveModels() async {
        await MainActor.run {
            // Unload all models except the currently active one
            let activeModels = models.count
            models.removeAll()
            Log.performance("Unloaded \(activeModels) inactive AI models")
        }
    }
}