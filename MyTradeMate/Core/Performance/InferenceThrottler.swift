import Foundation
import OSLog

private let logger = Logger(subsystem: "com.mytrademate", category: "InferenceThrottler")

/// Manages CoreML inference frequency to optimize performance and battery life
@MainActor
final class InferenceThrottler: ObservableObject {
    static let shared = InferenceThrottler()
    
    @Published var currentThrottleLevel: ThrottleLevel = .normal
    @Published var inferenceCount: Int = 0
    @Published var lastInferenceTime: Date = .distantPast
    
    private var inferenceHistory: [Date] = []
    private let maxHistorySize = 100
    private var adaptiveThrottleTimer: Timer?
    
    enum ThrottleLevel {
        case aggressive  // 10+ seconds between inferences
        case conservative // 5-10 seconds between inferences  
        case normal      // 2-5 seconds between inferences
        case responsive  // 0.5-2 seconds between inferences
        case realtime    // No throttling (< 0.5 seconds)
        
        var minimumInterval: TimeInterval {
            switch self {
            case .aggressive: return 10.0
            case .conservative: return 5.0
            case .normal: return 2.0
            case .responsive: return 0.5
            case .realtime: return 0.1
            }
        }
        
        var description: String {
            switch self {
            case .aggressive: return "Aggressive (10s+)"
            case .conservative: return "Conservative (5-10s)"
            case .normal: return "Normal (2-5s)"
            case .responsive: return "Responsive (0.5-2s)"
            case .realtime: return "Real-time (<0.5s)"
            }
        }
    }
    
    private init() {
        setupAdaptiveThrottling()
        setupMemoryPressureObserver()
    }
    
    deinit {
        adaptiveThrottleTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupAdaptiveThrottling() {
        // Periodically adjust throttle level based on system conditions
        adaptiveThrottleTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.adjustThrottleLevelAdaptively()
            }
        }
    }
    
    private func setupMemoryPressureObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(memoryPressureChanged),
            name: .memoryPressureChanged,
            object: nil
        )
    }
    
    @objc private func memoryPressureChanged(_ notification: Notification) {
        guard let level = notification.userInfo?["level"] as? MemoryPressureManager.MemoryPressureLevel else { return }
        
        switch level {
        case .normal:
            // Allow normal throttling
            break
        case .warning:
            // Increase throttling
            if currentThrottleLevel.minimumInterval < 5.0 {
                currentThrottleLevel = .conservative
                logger.info("Increased inference throttling due to memory pressure")
            }
        case .critical:
            // Aggressive throttling
            currentThrottleLevel = .aggressive
            logger.warning("Set aggressive inference throttling due to critical memory pressure")
        }
    }
    
    // MARK: - Throttling Logic
    
    func shouldAllowInference() -> Bool {
        let timeSinceLastInference = Date().timeIntervalSince(lastInferenceTime)
        let minimumInterval = currentThrottleLevel.minimumInterval
        
        let shouldAllow = timeSinceLastInference >= minimumInterval
        
        if !shouldAllow {
            let remainingTime = minimumInterval - timeSinceLastInference
            logger.debug("Inference throttled: \(String(format: "%.1f", remainingTime))s remaining")
        }
        
        return shouldAllow
    }
    
    func recordInference() {
        lastInferenceTime = Date()
        inferenceCount += 1
        
        // Add to history
        inferenceHistory.append(lastInferenceTime)
        
        // Trim history to max size
        if inferenceHistory.count > maxHistorySize {
            inferenceHistory.removeFirst(inferenceHistory.count - maxHistorySize)
        }
        
        logger.debug("Inference recorded (total: \(inferenceCount))")
    }
    
    func getInferenceRate() -> Double {
        guard inferenceHistory.count >= 2 else { return 0.0 }
        
        let timeWindow: TimeInterval = 60.0 // 1 minute
        let cutoffTime = Date().addingTimeInterval(-timeWindow)
        
        let recentInferences = inferenceHistory.filter { $0 > cutoffTime }
        return Double(recentInferences.count) / timeWindow * 60.0 // inferences per minute
    }
    
    // MARK: - Adaptive Throttling
    
    private func adjustThrottleLevelAdaptively() {
        let batteryLevel = getBatteryLevel()
        let thermalState = getThermalState()
        let memoryPressure = MemoryPressureManager.shared.memoryPressureLevel
        let inferenceRate = getInferenceRate()
        
        let newLevel = calculateOptimalThrottleLevel(
            batteryLevel: batteryLevel,
            thermalState: thermalState,
            memoryPressure: memoryPressure,
            inferenceRate: inferenceRate
        )
        
        if newLevel != currentThrottleLevel {
            logger.info("Adaptive throttling: \(currentThrottleLevel.description) -> \(newLevel.description)")
            currentThrottleLevel = newLevel
        }
    }
    
    private func calculateOptimalThrottleLevel(
        batteryLevel: Float,
        thermalState: ProcessInfo.ThermalState,
        memoryPressure: MemoryPressureManager.MemoryPressureLevel,
        inferenceRate: Double
    ) -> ThrottleLevel {
        var score = 0
        
        // Battery level factor
        if batteryLevel < 0.2 {
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
        
        // Inference rate factor (too many inferences)
        if inferenceRate > 30 { // More than 30 per minute
            score += 2
        } else if inferenceRate > 15 {
            score += 1
        }
        
        // Determine throttle level based on score
        switch score {
        case 0...1:
            return .realtime
        case 2...3:
            return .responsive
        case 4...5:
            return .normal
        case 6...7:
            return .conservative
        default:
            return .aggressive
        }
    }
    
    private func getBatteryLevel() -> Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        UIDevice.current.isBatteryMonitoringEnabled = false
        return level >= 0 ? level : 1.0 // Return 1.0 if battery level is unknown
    }
    
    private func getThermalState() -> ProcessInfo.ThermalState {
        return ProcessInfo.processInfo.thermalState
    }
    
    // MARK: - Public Interface
    
    func setThrottleLevel(_ level: ThrottleLevel) {
        currentThrottleLevel = level
        logger.info("Manual throttle level set to: \(level.description)")
    }
    
    func getThrottleStatus() -> ThrottleStatus {
        let timeSinceLastInference = Date().timeIntervalSince(lastInferenceTime)
        let nextInferenceIn = max(0, currentThrottleLevel.minimumInterval - timeSinceLastInference)
        
        return ThrottleStatus(
            level: currentThrottleLevel,
            inferenceCount: inferenceCount,
            inferenceRate: getInferenceRate(),
            nextInferenceIn: nextInferenceIn,
            canInferNow: shouldAllowInference()
        )
    }
    
    func resetStatistics() {
        inferenceCount = 0
        inferenceHistory.removeAll()
        lastInferenceTime = .distantPast
        logger.info("Inference statistics reset")
    }
}

// MARK: - Supporting Types

struct ThrottleStatus {
    let level: InferenceThrottler.ThrottleLevel
    let inferenceCount: Int
    let inferenceRate: Double
    let nextInferenceIn: TimeInterval
    let canInferNow: Bool
}

// MARK: - UIDevice Extension

import UIKit

extension UIDevice {
    var thermalStateString: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
}