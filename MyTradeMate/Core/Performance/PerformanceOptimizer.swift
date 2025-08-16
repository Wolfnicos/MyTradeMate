import Foundation
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.mytrademate", category: "PerformanceOptimizer")

/// Central performance optimization coordinator that manages all performance-related systems
@MainActor
final class PerformanceOptimizer: ObservableObject {
    static let shared = PerformanceOptimizer()
    
    @Published var isOptimizationEnabled = true
    @Published var currentOptimizationLevel: OptimizationLevel = .balanced
    @Published var performanceMetrics = PerformanceMetrics()
    
    private var metricsUpdateTimer: Timer?
    private var optimizationTimer: Timer?
    
    enum OptimizationLevel {
        case performance    // Prioritize performance over battery
        case balanced      // Balance performance and battery
        case battery       // Prioritize battery over performance
        case aggressive    // Maximum battery savings
        
        var description: String {
            switch self {
            case .performance: return "Performance"
            case .balanced: return "Balanced"
            case .battery: return "Battery Saver"
            case .aggressive: return "Aggressive Saver"
            }
        }
    }
    
    private init() {
        setupOptimization()
        startMetricsCollection()
    }
    
    deinit {
        metricsUpdateTimer?.invalidate()
        optimizationTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupOptimization() {
        // Start optimization monitoring
        optimizationTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.performOptimizationCheck()
            }
        }
        
        // Listen for system state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateChanged),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelChanged),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
    }
    
    private func startMetricsCollection() {
        metricsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePerformanceMetrics()
            }
        }
    }
    
    // MARK: - Optimization Logic
    
    private func performOptimizationCheck() {
        guard isOptimizationEnabled else { return }
        
        let batteryLevel = getBatteryLevel()
        let thermalState = ProcessInfo.processInfo.thermalState
        let memoryPressure = MemoryPressureManager.shared.memoryPressureLevel
        let networkStatus = ConnectionManager.shared.networkStatus
        
        let recommendedLevel = calculateOptimalLevel(
            batteryLevel: batteryLevel,
            thermalState: thermalState,
            memoryPressure: memoryPressure,
            networkStatus: networkStatus
        )
        
        if recommendedLevel != currentOptimizationLevel {
            logger.info("Optimization level changed: \(currentOptimizationLevel.description) -> \(recommendedLevel.description)")
            applyOptimizationLevel(recommendedLevel)
        }
    }
    
    private func calculateOptimalLevel(
        batteryLevel: Float,
        thermalState: ProcessInfo.ThermalState,
        memoryPressure: MemoryPressureManager.MemoryPressureLevel,
        networkStatus: ConnectionManager.NetworkStatus
    ) -> OptimizationLevel {
        var score = 0
        
        // Battery level factor
        if batteryLevel < 0.1 {
            score += 4 // Critical battery
        } else if batteryLevel < 0.2 {
            score += 3 // Very low battery
        } else if batteryLevel < 0.5 {
            score += 1 // Low battery
        }
        
        // Thermal state factor
        switch thermalState {
        case .critical:
            score += 4
        case .serious:
            score += 3
        case .fair:
            score += 1
        case .nominal:
            score += 0
        @unknown default:
            score += 0
        }
        
        // Memory pressure factor
        switch memoryPressure {
        case .critical:
            score += 3
        case .warning:
            score += 2
        case .normal:
            score += 0
        }
        
        // Network factor
        if networkStatus.isExpensive {
            score += 2
        }
        
        // Determine optimization level
        switch score {
        case 0...1:
            return .performance
        case 2...4:
            return .balanced
        case 5...7:
            return .battery
        default:
            return .aggressive
        }
    }
    
    private func applyOptimizationLevel(_ level: OptimizationLevel) {
        currentOptimizationLevel = level
        
        // Apply inference throttling
        let throttleLevel: InferenceThrottler.ThrottleLevel
        switch level {
        case .performance:
            throttleLevel = .responsive
        case .balanced:
            throttleLevel = .normal
        case .battery:
            throttleLevel = .conservative
        case .aggressive:
            throttleLevel = .aggressive
        }
        
        InferenceThrottler.shared.setThrottleLevel(throttleLevel)
        
        // Apply connection management
        let intelligentMode = level != .performance
        ConnectionManager.shared.setIntelligentMode(intelligentMode)
        
        // Apply memory management
        if level == .aggressive || level == .battery {
            MemoryPressureManager.shared.requestMemoryCleanup()
        }
        
        logger.info("Applied optimization level: \(level.description)")
    }
    
    // MARK: - Metrics Collection
    
    private func updatePerformanceMetrics() {
        let memoryUsage = MemoryPressureManager.shared.getCurrentMemoryUsage()
        
        let throttleStatus = InferenceThrottler.shared.getThrottleStatus()
        let connectionStatus = ConnectionManager.shared.getConnectionStatus()
        let cacheStats = DataCacheManager.shared.cacheStats
        
        performanceMetrics = PerformanceMetrics(
            memoryUsageMB: memoryUsage.usedMemoryMB,
            memoryUsagePercent: memoryUsage.usagePercentage,
            inferenceRate: throttleStatus.inferenceRate,
            activeConnections: connectionStatus.activeConnections,
            cacheMemoryMB: cacheStats.totalMemoryMB,
            batteryLevel: getBatteryLevel(),
            thermalState: ProcessInfo.processInfo.thermalState.description
        )
    }
    
    @objc private func batteryStateChanged() {
        Task { @MainActor in
            performOptimizationCheck()
        }
    }
    
    @objc private func batteryLevelChanged() {
        Task { @MainActor in
            performOptimizationCheck()
        }
    }
    
    private func getBatteryLevel() -> Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        UIDevice.current.isBatteryMonitoringEnabled = false
        return level >= 0 ? level : 1.0
    }
    
    // MARK: - Public Interface
    
    func setOptimizationLevel(_ level: OptimizationLevel) {
        logger.info("Manual optimization level set to: \(level.description)")
        applyOptimizationLevel(level)
    }
    
    func enableOptimization(_ enabled: Bool) {
        isOptimizationEnabled = enabled
        logger.info("Performance optimization \(enabled ? "enabled" : "disabled")")
        
        if enabled {
            performOptimizationCheck()
        }
    }
    
    func forceOptimizationCheck() {
        performOptimizationCheck()
    }
    
    func getDetailedMetrics() -> DetailedPerformanceMetrics {
        let memoryUsage = MemoryPressureManager.shared.getCurrentMemoryUsage()
        let throttleStatus = InferenceThrottler.shared.getThrottleStatus()
        let connectionStatus = ConnectionManager.shared.getConnectionStatus()
        let cacheInfo = DataCacheManager.shared.getCacheInfo()
        
        return DetailedPerformanceMetrics(
            memoryUsage: memoryUsage,
            throttleStatus: throttleStatus,
            connectionStatus: connectionStatus,
            cacheInfo: cacheInfo,
            optimizationLevel: currentOptimizationLevel,
            isOptimizationEnabled: isOptimizationEnabled
        )
    }
}

// MARK: - Supporting Types

struct PerformanceMetrics {
    let memoryUsageMB: Double
    let memoryUsagePercent: Double
    let inferenceRate: Double
    let activeConnections: Int
    let cacheMemoryMB: Double
    let batteryLevel: Float
    let thermalState: String
    
    init(memoryUsageMB: Double = 0, memoryUsagePercent: Double = 0, inferenceRate: Double = 0, activeConnections: Int = 0, cacheMemoryMB: Double = 0, batteryLevel: Float = 1.0, thermalState: String = "Unknown") {
        self.memoryUsageMB = memoryUsageMB
        self.memoryUsagePercent = memoryUsagePercent
        self.inferenceRate = inferenceRate
        self.activeConnections = activeConnections
        self.cacheMemoryMB = cacheMemoryMB
        self.batteryLevel = batteryLevel
        self.thermalState = thermalState
    }
}

struct DetailedPerformanceMetrics {
    let memoryUsage: MemoryUsage
    let throttleStatus: ThrottleStatus
    let connectionStatus: ConnectionStatus
    let cacheInfo: [CacheInfo]
    let optimizationLevel: PerformanceOptimizer.OptimizationLevel
    let isOptimizationEnabled: Bool
}

// MARK: - Extensions

extension ProcessInfo.ThermalState {
    var description: String {
        switch self {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
}