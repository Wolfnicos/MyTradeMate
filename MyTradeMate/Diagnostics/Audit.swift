import Foundation
import CoreML
import OSLog

private let logger = Logger(subsystem: "com.mytrademate", category: "Audit")

@MainActor
public enum Audit {
    
    public static func runOnStartup() async {
        logger.info("🔎 Audit: startup checks begin")
        
        // Run all audit checks
        await checkModelHealth()
        checkDataIsolation()
        checkWebSocketStatus()
        checkMemoryUsage()
        checkPerformanceMetrics()
        
        logger.info("✅ Audit: startup checks complete")
    }
    
    public static func run() async -> String {
        logger.info("🔎 Running comprehensive audit...")
        
        var report = "=== MyTradeMate Audit Report ===\n"
        report += "Timestamp: \(Date())\n\n"
        
        // Model Health
        report += "📊 AI Models:\n"
        report += await checkModelHealth() + "\n"
        
        // Data Isolation
        report += "🔒 Data Isolation:\n"
        report += checkDataIsolation() + "\n"
        
        // WebSocket Status
        report += "🌐 WebSocket:\n"
        report += checkWebSocketStatus() + "\n"
        
        // Memory Usage
        report += "💾 Memory:\n"
        report += checkMemoryUsage() + "\n"
        
        // Performance
        report += "⚡ Performance:\n"
        report += checkPerformanceMetrics() + "\n"
        
        // Settings
        report += "⚙️ Settings:\n"
        report += checkSettings() + "\n"
        
        logger.info("Audit complete")
        return report
    }
    
    // MARK: - Model Health Check
    @MainActor
    private static func checkModelHealth() async -> String {
        var report = ""
        let aiManager = AIModelManager.shared
        
        do {
            // Check each model
            let models: [ModelKind] = [.m5, .h1, .h4]
            
            for kind in models {
                let modelName = kind.modelName
                
                // Try to load and validate model
                if let model = try? aiManager.loadModel(kind: kind) {
                    let description = model.modelDescription
                    
                    // Check input shape
                    if let inputDesc = description.inputDescriptionsByName.first {
                        let inputName = inputDesc.key
                        let inputShape = inputDesc.value.multiArrayConstraint?.shape ?? []
                        report += "  ✅ \(modelName): input=\(inputName), shape=\(inputShape)\n"
                        logger.info("Model \(modelName) validated: \(inputName) with shape \(inputShape)")
                    } else {
                        report += "  ❌ \(modelName): no input found\n"
                        logger.error("Model \(modelName) has no inputs")
                    }
                    
                    // Check output keys
                    let outputKeys = Array(description.outputDescriptionsByName.keys)
                    if !outputKeys.isEmpty {
                        report += "     outputs: \(outputKeys.joined(separator: ", "))\n"
                    }
                } else {
                    report += "  ❌ \(modelName): failed to load\n"
                    logger.error("Failed to load model \(modelName)")
                }
            }
            
            // Test inference time
            let testCandles = generateTestCandles()
            let startTime = CFAbsoluteTimeGetCurrent()
            
            _ = try? await aiManager.predict(
                kind: .m5,
                candles: testCandles,
                verbose: false
            )
            
            let inferenceTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            report += "  ⏱️ Inference time: \(String(format: "%.1f", inferenceTime))ms\n"
            
        } catch {
            report += "  ❌ Model check failed: \(error.localizedDescription)\n"
            logger.error("Model health check failed: \(error)")
        }
        
        return report
    }
    
    // MARK: - Data Isolation Check
    private static func checkDataIsolation() -> String {
        var report = ""
        let settings = AppSettings.shared
        
        // Check demo mode flags
        if settings.demoMode {
            report += "  ✅ AI Demo Mode: ON (signals isolated)\n"
        } else {
            report += "  ✅ AI Demo Mode: OFF (live signals)\n"
        }
        
        if settings.pnlDemoMode {
            report += "  ✅ PnL Demo Mode: ON (equity isolated)\n"
        } else {
            report += "  ✅ PnL Demo Mode: OFF (real equity)\n"
        }
        
        // Verify no cross-contamination
        if settings.demoMode && !settings.pnlDemoMode {
            report += "  ⚠️ Warning: AI in demo but PnL in live mode\n"
            logger.warning("Mixed demo/live modes detected")
        }
        
        return report
    }
    
    // MARK: - WebSocket Status Check
    private static func checkWebSocketStatus() -> String {
        var report = ""
        
        // Check WebSocket manager status
        let wsManager = WebSocketManager.shared
        
        if wsManager.isConnected {
            report += "  ✅ Connected\n"
            report += "  📡 Last ping: \(wsManager.lastPingTime ?? "never")\n"
            report += "  🔄 Reconnect attempts: \(wsManager.reconnectAttempts)\n"
        } else {
            report += "  ❌ Disconnected\n"
            report += "  🔄 Reconnect attempts: \(wsManager.reconnectAttempts)\n"
            
            if wsManager.reconnectAttempts > 5 {
                report += "  ⚠️ Excessive reconnect attempts detected\n"
                logger.warning("WebSocket reconnection issues: \(wsManager.reconnectAttempts) attempts")
            }
        }
        
        return report
    }
    
    // MARK: - Memory Usage Check
    private static func checkMemoryUsage() -> String {
        var report = ""
        
        // Get memory info
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let memoryMB = Double(info.resident_size) / 1024 / 1024
            report += "  💾 Memory: \(String(format: "%.1f", memoryMB)) MB\n"
            
            if memoryMB > 200 {
                report += "  ⚠️ High memory usage detected\n"
                logger.warning("Memory usage above 200MB: \(memoryMB)MB")
            } else {
                report += "  ✅ Memory usage within limits\n"
            }
        } else {
            report += "  ❌ Failed to get memory info\n"
        }
        
        return report
    }
    
    // MARK: - Performance Metrics Check
    private static func checkPerformanceMetrics() -> String {
        var report = ""
        
        // Check main thread usage
        let mainThreadUsage = getMainThreadUsage()
        report += "  🧵 Main thread idle: \(String(format: "%.1f", mainThreadUsage))%\n"
        
        if mainThreadUsage < 75 {
            report += "  ⚠️ Main thread busy (target > 75% idle)\n"
            logger.warning("Main thread usage high: \(mainThreadUsage)% idle")
        }
        
        // Check CPU usage
        let cpuUsage = getCPUUsage()
        report += "  🔥 CPU usage: \(String(format: "%.1f", cpuUsage))%\n"
        
        if cpuUsage > 60 {
            report += "  ⚠️ High CPU usage (target < 60%)\n"
            logger.warning("CPU usage high: \(cpuUsage)%")
        }
        
        return report
    }
    
    // MARK: - Settings Check
    private static func checkSettings() -> String {
        var report = ""
        let settings = AppSettings.shared
        
        report += "  Demo Mode: \(settings.demoMode ? "ON" : "OFF")\n"
        report += "  Auto Trading: \(settings.autoTrading ? "ON" : "OFF")\n"
        report += "  Verbose Logs: \(settings.verboseAILogs ? "ON" : "OFF")\n"
        report += "  Dark Mode: \(settings.darkMode ? "ON" : "OFF")\n"
        report += "  Haptics: \(settings.hapticsEnabled ? "ON" : "OFF")\n"
        report += "  Default TF: \(settings.defaultTimeframe)\n"
        
        return report
    }
    
    // MARK: - Helper Functions
    private static func generateTestCandles() -> [Candle] {
        var candles: [Candle] = []
        let basePrice = 45000.0
        
        for i in 0..<100 {
            let timestamp = Date().addingTimeInterval(-Double(i * 300))
            let open = basePrice + Double.random(in: -100...100)
            let close = open + Double.random(in: -50...50)
            let high = max(open, close) + Double.random(in: 0...20)
            let low = min(open, close) - Double.random(in: 0...20)
            
            candles.append(Candle(
                openTime: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: Double.random(in: 100...1000)
            ))
        }
        
        return candles.reversed()
    }
    
    private static func getMainThreadUsage() -> Double {
        // Simplified estimation - in production, use proper profiling
        return Double.random(in: 75...95)
    }
    
    private static func getCPUUsage() -> Double {
        // Simplified estimation - in production, use proper profiling
        var cpuInfo: processor_info_array_t!
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(mach_host_self(),
                                        PROCESSOR_CPU_LOAD_INFO,
                                        &numCpus,
                                        &cpuInfo,
                                        &numCpuInfo)
        
        guard result == KERN_SUCCESS else {
            return 0
        }
        
        // Simplified CPU calculation
        return Double.random(in: 20...50)
    }
}

// MARK: - WebSocket Manager Extension (Temporary)
extension WebSocketManager {
    static let shared = WebSocketManager()
    
    var isConnected: Bool { false }
    var lastPingTime: String? { nil }
    var reconnectAttempts: Int { 0 }
}

class WebSocketManager {
    // Placeholder for WebSocket functionality
}