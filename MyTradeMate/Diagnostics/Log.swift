import Foundation
import os.log

/// Unified logging system for MyTradeMate
enum Log {
    // MARK: - Core Loggers
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.mytrademate"
    
    static let ai = OSLog(subsystem: subsystem, category: "AI")
    static let ws = OSLog(subsystem: subsystem, category: "WebSocket")
    static let pnl = OSLog(subsystem: subsystem, category: "PnL")
    static let app = OSLog(subsystem: subsystem, category: "App")
    static let trade = OSLog(subsystem: subsystem, category: "Trade")
    static let network = OSLog(subsystem: subsystem, category: "Network")
    static let security = OSLog(subsystem: subsystem, category: "Security")
    static let error = OSLog(subsystem: subsystem, category: "Error")
    static let data = OSLog(subsystem: subsystem, category: "Data")
    static let ui = OSLog(subsystem: subsystem, category: "UI")
    static let strategy = OSLog(subsystem: subsystem, category: "Strategy")
    
    // MARK: - Production-grade standardized loggers
    static let routing = OSLog(subsystem: subsystem, category: "ROUTING")
    static let trading = OSLog(subsystem: subsystem, category: "TRADING")
    static let settings = OSLog(subsystem: subsystem, category: "SETTINGS")
    static let health = OSLog(subsystem: subsystem, category: "HEALTH")
    
    // MARK: - Convenience Methods
    
    /// Log a message with automatic category detection based on context
    static func log(_ message: String, level: OSLogType = .default, category: LogCategory = .app) {
        let logger = loggerFor(category: category)
        os_log("%{public}@", log: logger, type: level, message)
    }
    
    /// Log an error with full context
    static func error(_ error: Error, context: String = "", category: LogCategory = .error) {
        let logger = loggerFor(category: category)
        let message = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
        os_log("%{public}@", log: logger, type: .error, message)
        
        // Also log to error manager if it's not a logging error
        if category != .error {
            Task { @MainActor in
                ErrorManager.shared.handle(error, context: context)
            }
        }
    }
    
    /// Log sensitive information (filtered in production)
    static func sensitive(_ message: String, category: LogCategory = .security) {
        #if DEBUG
        let logger = loggerFor(category: category)
        os_log("🔒 [SENSITIVE] %{public}@", log: logger, type: .debug, message)
        #else
        // In production, log only that sensitive data was accessed
        let logger = loggerFor(category: category)
        os_log("🔒 Sensitive data accessed", log: logger, type: .info)
        #endif
    }
    
    /// Log performance metrics
    static func performance(_ message: String, duration: TimeInterval? = nil) {
        let durationText = duration.map { String(format: " (%.3fs)", $0) } ?? ""
        os_log("⚡ %{public}@%{public}@", log: app, type: .info, message, durationText)
    }
    
    /// Log user actions for analytics
    static func userAction(_ action: String, parameters: [String: Any] = [:]) {
        let params = parameters.isEmpty ? "" : " \(parameters)"
        os_log("👤 %{public}@%{public}@", log: ui, type: .info, action, params)
    }
    
    // MARK: - Private Helpers
    
    private static func loggerFor(category: LogCategory) -> OSLog {
        switch category {
        case .ai: return ai
        case .webSocket: return ws
        case .pnl: return pnl
        case .app: return app
        case .trade: return trade
        case .network: return network
        case .security: return security
        case .error: return error
        case .data: return data
        case .ui: return ui
        case .strategy: return strategy
        }
    }
}

// MARK: - Log Categories

enum LogCategory {
    case ai
    case webSocket
    case pnl
    case app
    case trade
    case network
    case security
    case error
    case data
    case ui
    case strategy
}

// MARK: - Logging Extensions

extension OSLog {
    /// Log with emoji prefix for better readability
    func success(_ message: String) {
        os_log("✅ %{public}@", log: self, type: .info, message)
    }
    
    func warning(_ message: String) {
        os_log("⚠️ %{public}@", log: self, type: .default, message)
    }
    
    func failure(_ message: String) {
        os_log("❌ %{public}@", log: self, type: .error, message)
    }
    
    func debug(_ message: String) {
        os_log("🐛 %{public}@", log: self, type: .debug, message)
    }
    
    func info(_ message: String) {
        os_log("%{public}@", log: self, type: .info, message)
    }
    
    func error(_ message: String) {
        os_log("%{public}@", log: self, type: .error, message)
    }
}

// MARK: - Performance Logging

struct PerformanceLogger {
    private let startTime: CFAbsoluteTime
    private let operation: String
    private let category: LogCategory
    
    init(_ operation: String, category: LogCategory = .app) {
        self.operation = operation
        self.category = category
        self.startTime = CFAbsoluteTimeGetCurrent()
        Log.log("Started: \(operation)", category: category)
    }
    
    func finish() {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        Log.performance("Completed: \(operation)", duration: duration)
    }
}

// MARK: - Conditional Logging

extension Log {
    /// Log only if verbose logging is enabled
    static func verbose(_ message: String, category: LogCategory = .app) {
        Task { @MainActor in
            guard AppSettings.shared.verboseAILogs else { return }
            log("🔍 \(message)", level: .debug, category: category)
        }
    }
    
    /// Log only in debug mode
    static func debug(_ message: String, category: LogCategory = .app) {
        #if DEBUG
        log("🐛 \(message)", level: .debug, category: category)
        #endif
    }
    
    /// Log only if AI debug mode is enabled
    static func aiDebug(_ message: String) {
        Task { @MainActor in
            guard AppSettings.shared.aiDebugMode else { return }
            os_log("🤖 %{public}@", log: ai, type: .debug, message)
        }
    }
    
    /// Log a warning message
    static func warning(_ message: String, category: LogCategory = .app) {
        let logger = loggerFor(category: category)
        os_log("⚠️ %{public}@", log: logger, type: .default, message)
    }
}