import Foundation
import OSLog
import UIKit

/// Utility for exporting diagnostic logs from the app
public enum LogExporter {
    
    /// Export diagnostic logs to a temporary file
    /// - Returns: URL of the exported log file
    public static func exportDiagnosticLogs() async throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = "MyTradeMate_Logs_\(timestamp.replacingOccurrences(of: ":", with: "-")).txt"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var logContent = ""
        
        // Add header information
        logContent += "MyTradeMate Diagnostic Logs\n"
        logContent += "Generated: \(timestamp)\n"
        logContent += "App Version: \(Bundle.main.appVersion)\n"
        logContent += "Build Number: \(Bundle.main.buildNumber)\n"
        logContent += "iOS Version: \(UIDevice.current.systemVersion)\n"
        logContent += "Device Model: \(UIDevice.current.model)\n"
        logContent += "Device Name: \(UIDevice.current.name)\n"
        logContent += String(repeating: "=", count: 50) + "\n\n"
        
        // Collect logs from OSLog
        do {
            let logs = try await collectOSLogs()
            logContent += logs
        } catch {
            logContent += "Error collecting system logs: \(error.localizedDescription)\n\n"
        }
        
        // Add app-specific diagnostic information
        logContent += await collectAppDiagnostics()
        
        // Add prediction and trade logs
        logContent += collectPredictionAndTradeLogs()
        
        // Write to file
        guard let data = logContent.data(using: .utf8) else {
            throw LogExportError.encodingFailed
        }
        
        try data.write(to: url, options: .atomic)
        return url
    }
    
    /// Collect logs from OSLog system
    private static func collectOSLogs() async throws -> String {
        var logContent = "SYSTEM LOGS\n"
        logContent += String(repeating: "-", count: 20) + "\n"
        
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let subsystem = Bundle.main.bundleIdentifier ?? "com.mytrademate"
        
        // Get logs from the last 24 hours
        let oneDayAgo = Date().addingTimeInterval(-24 * 60 * 60)
        let predicate = NSPredicate(format: "subsystem == %@", subsystem)
        
        let entries = try store.getEntries(
            at: store.position(date: oneDayAgo),
            matching: predicate
        )
        
        var logEntries: [String] = []
        
        for entry in entries {
            if let logEntry = entry as? OSLogEntryLog {
                let timestamp = ISO8601DateFormatter().string(from: logEntry.date)
                let level = logLevelString(logEntry.level)
                let category = logEntry.category
                let message = logEntry.composedMessage
                
                let logLine = "[\(timestamp)] [\(level)] [\(category)] \(message)"
                logEntries.append(logLine)
            }
        }
        
        // Limit to last 1000 entries to prevent huge files
        let recentEntries = Array(logEntries.suffix(1000))
        logContent += recentEntries.joined(separator: "\n")
        logContent += "\n\n"
        
        return logContent
    }
    
    /// Collect app-specific diagnostic information
    private static func collectAppDiagnostics() async -> String {
        var diagnostics = "APP DIAGNOSTICS\n"
        diagnostics += String(repeating: "-", count: 20) + "\n"
        
        // Memory usage
        let memoryUsage = getMemoryUsage()
        diagnostics += "Memory Usage: \(String(format: "%.2f MB", memoryUsage / 1024 / 1024))\n"
        
        // App settings
        await MainActor.run {
            let settings = AppSettings.shared
            diagnostics += "Demo Mode: \(settings.demoMode)\n"
            diagnostics += "Auto Trading: \(settings.autoTrading)\n"
            diagnostics += "Live Market Data: \(settings.liveMarketData)\n"
            diagnostics += "AI Debug Mode: \(settings.aiDebugMode)\n"
            diagnostics += "Verbose AI Logs: \(settings.verboseAILogs)\n"
            diagnostics += "Default Symbol: \(settings.defaultSymbol)\n"
            diagnostics += "Default Timeframe: \(settings.defaultTimeframe)\n"
        }
        
        // Device information
        diagnostics += "Available Storage: \(getAvailableStorage())\n"
        diagnostics += "Battery Level: \(getBatteryLevel())\n"
        diagnostics += "Low Power Mode: \(ProcessInfo.processInfo.isLowPowerModeEnabled)\n"
        
        // Network status
        diagnostics += "Network Status: \(getNetworkStatus())\n"
        
        diagnostics += "\n"
        return diagnostics
    }
    
    /// Convert OSLogEntryLog.Level to string
    private static func logLevelString(_ level: OSLogEntryLog.Level) -> String {
        switch level {
        case .undefined:
            return "UNDEFINED"
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .notice:
            return "NOTICE"
        case .error:
            return "ERROR"
        case .fault:
            return "FAULT"
        @unknown default:
            return "UNKNOWN"
        }
    }
    
    /// Get current memory usage in bytes
    private static func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    /// Get available storage space
    private static func getAvailableStorage() -> String {
        do {
            let fileURL = URL(fileURLWithPath: NSHomeDirectory())
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            if let capacity = values.volumeAvailableCapacity {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useGB, .useMB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: Int64(capacity))
            }
        } catch {
            return "Unknown"
        }
        return "Unknown"
    }
    
    /// Get battery level
    private static func getBatteryLevel() -> String {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        UIDevice.current.isBatteryMonitoringEnabled = false
        
        if batteryLevel < 0 {
            return "Unknown"
        } else {
            return String(format: "%.0f%%", batteryLevel * 100)
        }
    }
    
    /// Get network status (simplified)
    private static func getNetworkStatus() -> String {
        // This is a simplified check - in a real app you might want to use Network framework
        return "Available" // Placeholder - could be enhanced with actual network checking
    }
    
    /// Collect prediction and trade logs from PredictionLogger
    private static func collectPredictionAndTradeLogs() -> String {
        var content = "PREDICTION AND TRADE LOGS\n"
        content += String(repeating: "-", count: 30) + "\n"
        
        let logFiles = PredictionLogger.shared.getLogFiles()
        
        if logFiles.isEmpty {
            content += "No prediction or trade logs found.\n\n"
            return content
        }
        
        for logFile in logFiles {
            content += "\n=== \(logFile.lastPathComponent) ===\n"
            
            if let logData = try? Data(contentsOf: logFile),
               let logContent = String(data: logData, encoding: .utf8) {
                
                // Include last 100 lines to avoid huge files
                let lines = logContent.components(separatedBy: .newlines)
                let lastLines = Array(lines.suffix(100))
                
                if lines.count > 100 {
                    content += "... (showing last 100 lines of \(lines.count) total)\n"
                }
                
                content += lastLines.joined(separator: "\n")
                content += "\n\n"
            } else {
                content += "Unable to read log file.\n\n"
            }
        }
        
        return content
    }
}

/// Errors that can occur during log export
public enum LogExportError: LocalizedError {
    case encodingFailed
    case writeFailed
    case logCollectionFailed
    
    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode log data"
        case .writeFailed:
            return "Failed to write log file"
        case .logCollectionFailed:
            return "Failed to collect system logs"
        }
    }
}

// MARK: - Bundle Extension
extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}