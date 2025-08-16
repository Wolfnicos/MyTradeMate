import Foundation
import WidgetKit
import BackgroundTasks
import OSLog

// MARK: - Signal Strength Helper

private enum SignalStrength: String, CaseIterable {
    case veryWeak = "Very Weak"
    case weak = "Weak"
    case moderate = "Moderate"
    case strong = "Strong"
    case veryStrong = "Very Strong"
    
    static func from(confidence: Double) -> SignalStrength {
        if confidence >= 0.8 {
            return .veryStrong
        } else if confidence >= 0.6 {
            return .strong
        } else if confidence >= 0.4 {
            return .moderate
        } else if confidence >= 0.2 {
            return .weak
        } else {
            return .veryWeak
        }
    }
}

// MARK: - Widget Configuration

public struct WidgetConfiguration: Codable {
    public let displayMode: String
    public let primarySymbol: String
    public let showDemoMode: Bool
    public let colorTheme: String
    public let updateFrequency: String
    
    public static let `default` = WidgetConfiguration(
        displayMode: "balanced",
        primarySymbol: "AUTO",
        showDemoMode: true,
        colorTheme: "standard",
        updateFrequency: "normal"
    )
    
    public init(displayMode: String, primarySymbol: String, showDemoMode: Bool, colorTheme: String, updateFrequency: String) {
        self.displayMode = displayMode
        self.primarySymbol = primarySymbol
        self.showDemoMode = showDemoMode
        self.colorTheme = colorTheme
        self.updateFrequency = updateFrequency
    }
    
    public var updateInterval: TimeInterval {
        switch updateFrequency {
        case "fast": return 60
        case "normal": return 120
        case "slow": return 300
        case "manual": return 3600
        default: return 120
        }
    }
    
    public var shouldShowDemoMode: Bool {
        return showDemoMode
    }
    
    public var effectiveSymbol: String {
        return primarySymbol == "AUTO" ? "BTC/USDT" : primarySymbol
    }
}

// MARK: - Shared Widget Data Models

public struct PnLDataPoint: Codable, Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let value: Double
    public let percentage: Double
    
    public init(timestamp: Date, value: Double, percentage: Double) {
        self.timestamp = timestamp
        self.value = value
        self.percentage = percentage
    }
    
    private enum CodingKeys: String, CodingKey {
        case timestamp, value, percentage
    }
}

public struct WidgetData: Codable {
    public let pnl: Double
    public let pnlPercentage: Double
    public let todayPnL: Double
    public let unrealizedPnL: Double
    public let equity: Double
    public let openPositions: Int
    public let lastPrice: Double
    public let priceChange: Double
    public let isDemoMode: Bool
    public let connectionStatus: String
    public let lastUpdated: Date
    public let symbol: String
    
    // AI Signal data
    public let signalDirection: String?
    public let signalConfidence: Double?
    public let signalReason: String?
    public let signalTimestamp: Date?
    public let signalModelName: String?
    
    // P&L Chart data
    public let pnlHistory: [PnLDataPoint]?
    
    public init(
        pnl: Double,
        pnlPercentage: Double,
        todayPnL: Double,
        unrealizedPnL: Double,
        equity: Double,
        openPositions: Int,
        lastPrice: Double,
        priceChange: Double,
        isDemoMode: Bool,
        connectionStatus: String,
        lastUpdated: Date,
        symbol: String,
        signalDirection: String? = nil,
        signalConfidence: Double? = nil,
        signalReason: String? = nil,
        signalTimestamp: Date? = nil,
        signalModelName: String? = nil,
        pnlHistory: [PnLDataPoint]? = nil
    ) {
        self.pnl = pnl
        self.pnlPercentage = pnlPercentage
        self.todayPnL = todayPnL
        self.unrealizedPnL = unrealizedPnL
        self.equity = equity
        self.openPositions = openPositions
        self.lastPrice = lastPrice
        self.priceChange = priceChange
        self.isDemoMode = isDemoMode
        self.connectionStatus = connectionStatus
        self.lastUpdated = lastUpdated
        self.symbol = symbol
        self.signalDirection = signalDirection
        self.signalConfidence = signalConfidence
        self.signalReason = signalReason
        self.signalTimestamp = signalTimestamp
        self.signalModelName = signalModelName
        self.pnlHistory = pnlHistory
    }
    
    public static let `default` = WidgetData(
        pnl: 0,
        pnlPercentage: 0,
        todayPnL: 0,
        unrealizedPnL: 0,
        equity: 10000,
        openPositions: 0,
        lastPrice: 45000,
        priceChange: 0,
        isDemoMode: true,
        connectionStatus: "disconnected",
        lastUpdated: Date(),
        symbol: "BTC/USDT",
        signalDirection: nil,
        signalConfidence: nil,
        signalReason: nil,
        signalTimestamp: nil,
        signalModelName: nil,
        pnlHistory: nil
    )
}

// MARK: - Widget Refresh Status

public enum WidgetRefreshStatus {
    case idle
    case refreshing
    case success(Date)
    case failed(Error)
    
    public var isRefreshing: Bool {
        if case .refreshing = self { return true }
        return false
    }
    
    public var lastSuccessDate: Date? {
        if case .success(let date) = self { return date }
        return nil
    }
}

// MARK: - Widget Data Manager

public class WidgetDataManager {
    public static let shared = WidgetDataManager()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.mytrademate.app")
    private let widgetDataKey = "widget_trading_data"
    private let widgetConfigKey = "widget_configuration"
    private let refreshStatusKey = "widget_refresh_status"
    private let lastRefreshKey = "widget_last_refresh"
    
    // Refresh management
    private var refreshStatus: WidgetRefreshStatus = .idle
    private var lastRefreshTime: Date = Date.distantPast
    private let minimumRefreshInterval: TimeInterval = 30 // 30 seconds minimum between refreshes
    private var refreshTimer: Timer?
    
    // Background refresh
    private let backgroundRefreshIdentifier = "com.mytrademate.widget.refresh"
    
    private init() {
        setupBackgroundRefresh()
        loadRefreshStatus()
    }
    
    /// Save widget data and trigger widget refresh
    public func updateWidgetData(_ data: WidgetData) {
        saveWidgetData(data)
        refreshWidgets()
    }
    
    /// Save widget data to shared UserDefaults
    public func saveWidgetData(_ data: WidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else {
            os.Logger(subsystem: "com.mytrademate", category: "Widget").error("Failed to encode widget data")
            return
        }
        userDefaults?.set(encoded, forKey: widgetDataKey)
        os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Widget data saved successfully")
    }
    
    /// Load widget data from shared UserDefaults
    public func loadWidgetData() -> WidgetData {
        guard let data = userDefaults?.data(forKey: widgetDataKey),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Using default widget data")
            return WidgetData.default
        }
        return decoded
    }
    
    /// Trigger widget refresh with rate limiting and status tracking
    public func refreshWidgets(force: Bool = false) {
        // Check rate limiting unless forced
        if !force && Date().timeIntervalSince(lastRefreshTime) < minimumRefreshInterval {
            os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Widget refresh skipped due to rate limiting")
            return
        }
        
        // Update status
        refreshStatus = .refreshing
        lastRefreshTime = Date()
        
        // Perform refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "TradingWidget")
        
        // Update status to success
        refreshStatus = .success(Date())
        saveRefreshStatus()
        
        os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Widget refresh triggered successfully")
    }
    
    /// Manual refresh triggered by user action
    public func manualRefresh() {
        os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Manual widget refresh requested")
        refreshWidgets(force: true)
    }
    
    /// Get current refresh status
    public func getRefreshStatus() -> WidgetRefreshStatus {
        return refreshStatus
    }
    
    /// Check if widgets can be refreshed (not rate limited)
    public func canRefresh() -> Bool {
        return Date().timeIntervalSince(lastRefreshTime) >= minimumRefreshInterval
    }
    
    /// Schedule automatic refresh based on configuration
    public func scheduleAutomaticRefresh() {
        // Cancel existing timer
        refreshTimer?.invalidate()
        
        let config = loadWidgetConfiguration()
        
        // Don't schedule for manual mode
        guard config.updateFrequency != "manual" else {
            os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Automatic refresh disabled for manual mode")
            return
        }
        
        let interval = config.updateInterval
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refreshWidgets()
        }
        
        os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Automatic widget refresh scheduled every \(interval) seconds")
    }
    
    /// Stop automatic refresh
    public func stopAutomaticRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Automatic widget refresh stopped")
    }
    
    /// Save widget configuration
    public func saveWidgetConfiguration(_ config: WidgetConfiguration) {
        guard let encoded = try? JSONEncoder().encode(config) else {
            os.Logger(subsystem: "com.mytrademate", category: "Widget").error("Failed to encode widget configuration")
            return
        }
        userDefaults?.set(encoded, forKey: widgetConfigKey)
        os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Widget configuration saved successfully")
        
        // Reschedule automatic refresh with new configuration
        scheduleAutomaticRefresh()
        
        // Refresh widgets immediately when configuration changes
        refreshWidgets(force: true)
    }
    
    /// Load widget configuration
    public func loadWidgetConfiguration() -> WidgetConfiguration {
        guard let data = userDefaults?.data(forKey: widgetConfigKey),
              let decoded = try? JSONDecoder().decode(WidgetConfiguration.self, from: data) else {
            os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Using default widget configuration")
            return WidgetConfiguration.default
        }
        return decoded
    }
    
    /// Create widget data with provided values
    public func createWidgetData(
        pnl: Double,
        pnlPercentage: Double,
        todayPnL: Double,
        unrealizedPnL: Double,
        equity: Double,
        openPositions: Int,
        marketPrice: Double,
        priceChange: Double,
        isDemoMode: Bool,
        isConnected: Bool,
        signalDirection: String? = nil,
        signalConfidence: Double? = nil,
        signalReason: String? = nil,
        signalTimestamp: Date? = nil,
        signalModelName: String? = nil,
        pnlHistory: [PnLDataPoint]? = nil
    ) -> WidgetData {
        let connectionStatus = isConnected ? "connected" : "disconnected"
        
        return WidgetData(
            pnl: pnl,
            pnlPercentage: pnlPercentage,
            todayPnL: todayPnL,
            unrealizedPnL: unrealizedPnL,
            equity: equity,
            openPositions: openPositions,
            lastPrice: marketPrice,
            priceChange: priceChange,
            isDemoMode: isDemoMode,
            connectionStatus: connectionStatus,
            lastUpdated: Date(),
            symbol: "BTC/USDT", // Could be made dynamic based on selected symbol
            signalDirection: signalDirection,
            signalConfidence: signalConfidence,
            signalReason: signalReason,
            signalTimestamp: signalTimestamp,
            signalModelName: signalModelName,
            pnlHistory: pnlHistory
        )
    }
}

// MARK: - Extensions for Integration
// Extensions can be added here when the required types are available

// MARK: - Private Methods

extension WidgetDataManager {
    
    /// Setup background refresh capability
    private func setupBackgroundRefresh() {
        // Register background task for widget refresh
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundRefreshIdentifier, using: nil) { [weak self] task in
            self?.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    /// Handle background refresh task
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Background widget refresh started")
        
        // Schedule next background refresh
        scheduleBackgroundRefresh()
        
        // Create operation for refresh
        let operation = BlockOperation {
            // Refresh widgets in background
            DispatchQueue.main.async { [weak self] in
                self?.refreshWidgets()
            }
        }
        
        // Handle task completion
        task.expirationHandler = {
            operation.cancel()
            os.Logger(subsystem: "com.mytrademate", category: "Widget").warning("Background widget refresh expired")
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
            os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Background widget refresh completed")
        }
        
        // Execute operation
        OperationQueue().addOperation(operation)
    }
    
    /// Schedule background refresh
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Background widget refresh scheduled")
        } catch {
            os.Logger(subsystem: "com.mytrademate", category: "Widget").error("Failed to schedule background widget refresh: \(error)")
        }
    }
    
    /// Save refresh status to UserDefaults
    private func saveRefreshStatus() {
        let statusData: [String: Any] = [
            "lastRefresh": lastRefreshTime,
            "status": refreshStatusString()
        ]
        userDefaults?.set(statusData, forKey: refreshStatusKey)
    }
    
    /// Load refresh status from UserDefaults
    private func loadRefreshStatus() {
        guard let statusData = userDefaults?.dictionary(forKey: refreshStatusKey),
              let lastRefresh = statusData["lastRefresh"] as? Date else {
            return
        }
        
        lastRefreshTime = lastRefresh
        
        // Set status to idle on app launch (don't persist complex status)
        refreshStatus = .idle
    }
    
    /// Convert refresh status to string for persistence
    private func refreshStatusString() -> String {
        switch refreshStatus {
        case .idle: return "idle"
        case .refreshing: return "refreshing"
        case .success: return "success"
        case .failed: return "failed"
        }
    }
}

// MARK: - Public Refresh Control Methods

extension WidgetDataManager {
    
    /// Start automatic refresh based on current configuration
    public func startAutomaticRefresh() {
        scheduleAutomaticRefresh()
        scheduleBackgroundRefresh()
    }
    
    /// Stop all automatic refresh activities
    public func stopAllRefresh() {
        stopAutomaticRefresh()
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundRefreshIdentifier)
    }
    
    /// Get refresh statistics
    public func getRefreshStats() -> (lastRefresh: Date?, canRefresh: Bool, status: WidgetRefreshStatus) {
        return (
            lastRefresh: lastRefreshTime == Date.distantPast ? nil : lastRefreshTime,
            canRefresh: canRefresh(),
            status: refreshStatus
        )
    }
    
    /// Force refresh all widget data from current app state
    public func forceFullRefresh() {
        os.Logger(subsystem: "com.mytrademate", category: "Widget").info("Force full widget refresh requested")
        
        // Update widget data from current app state if available
        Task { @MainActor in
            // Just refresh with existing data for now
            // Integration with PnLVM can be added later when dependencies are resolved
            refreshWidgets(force: true)
        }
    }
}