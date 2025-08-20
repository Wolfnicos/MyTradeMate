import Foundation
import Combine
import OSLog

// MARK: - Analytics Service

@MainActor
public final class AnalyticsService: ObservableObject {
    public static let shared = AnalyticsService()
    
    @Published public var tradingStats: TradingStats = TradingStats()
    @Published public var signalPerformanceMetrics: SignalPerformanceMetrics = SignalPerformanceMetrics()
    
    private let logger = os.Logger(subsystem: "com.mytrademate", category: "Analytics")
    private var cancellables = Set<AnyCancellable>()
    
    // Data storage
    private var trades: [TradeRecord] = []
    private var dailyStats: [Date: DailyStats] = [:]
    
    // ✅ ADD: Telemetry event tracking
    private var telemetryEvents: [TelemetryEvent] = []
    private let maxTelemetryEvents = 1000
    private let isEnabled: Bool
    
    // ✅ ADD: Rate limiting for telemetry events
    private var lastEventTime: [String: Date] = [:]
    private let rateLimitInterval: TimeInterval = 2.0 // Max 1 event per category per 2 seconds
    
    private init() {
        // ✅ ADD: Initialize telemetry based on settings
        self.isEnabled = !AppSettings.shared.demoMode // Disable in demo mode for privacy
        
        loadStoredData()
        setupObservers()
        
        if isEnabled {
            logger.info("📊 AnalyticsService initialized - telemetry enabled")
        } else {
            logger.info("📊 AnalyticsService initialized - telemetry disabled (demo mode)")
        }
    }
    
    // MARK: - Trade Tracking
    
    public func recordTrade(symbol: String, side: OrderSide, amount: Double, price: Double, pnl: Double) {
        let trade = TradeRecord(
            id: UUID().uuidString,
            symbol: symbol,
            side: side,
            amount: amount,
            price: price,
            pnl: pnl,
            timestamp: Date()
        )
        
        trades.append(trade)
        updateTradingStats()
        updateDailyStats(for: trade)
        saveData()
        
        logger.info("Trade recorded: \(side.rawValue) \(amount) \(symbol) at \(price)")
    }
    
    public func recordSignalAccuracy(predicted: String, actual: String, confidence: Double) {
        let isCorrect = predicted == actual
        
        signalPerformanceMetrics.totalSignals += 1
        if isCorrect {
            signalPerformanceMetrics.correctSignals += 1
        }
        
        signalPerformanceMetrics.accuracy = Double(signalPerformanceMetrics.correctSignals) / Double(signalPerformanceMetrics.totalSignals)
        signalPerformanceMetrics.averageConfidence = (signalPerformanceMetrics.averageConfidence + confidence) / 2.0
        
        logger
            .info(
                "Signal accuracy updated: \(String(format: "%.1f", self.signalPerformanceMetrics.accuracy * 100))%"
            )
    }
    
    // MARK: - ✅ ADD: Telemetry Event Tracking
    
    /// Track a telemetry event with properties (rate limited)
    public func track(_ event: String, properties: [String: Any] = [:]) {
        guard isEnabled else {
            // Still log to console for development even if telemetry disabled
            logger.debug("📊 Telemetry (disabled): \(event) - \(properties)")
            return
        }
        
        // ✅ RATE LIMITING: Check if we should throttle this event
        let eventCategory = (properties["category"] as? String) ?? "default"
        let now = Date()
        
        if let lastTime = lastEventTime[eventCategory],
           now.timeIntervalSince(lastTime) < rateLimitInterval {
            // Rate limited - log but don't persist
            logger.debug("📊 Telemetry (rate limited): \(event) - \(eventCategory)")
            return
        }
        
        // Update last event time for this category
        lastEventTime[eventCategory] = now
        
        let telemetryEvent = TelemetryEvent(
            name: event,
            properties: properties,
            timestamp: now
        )
        
        // Add to cache
        telemetryEvents.append(telemetryEvent)
        
        // Log to console for immediate visibility
        logger.info("📊 Telemetry: \(event) - \(properties)")
        
        // Maintain cache size
        if telemetryEvents.count > maxTelemetryEvents {
            telemetryEvents.removeFirst(telemetryEvents.count - maxTelemetryEvents)
        }
        
        // Save to persistent storage
        saveTelemetryData()
    }
    
    /// Track AI-related events with standardized properties
    public func trackAI(_ event: String, timeframe: String? = nil, confidence: Double? = nil, latency: Int? = nil, metadata: [String: Any] = [:]) {
        var properties = metadata
        properties["category"] = "ai"
        
        if let timeframe = timeframe {
            properties["timeframe"] = timeframe
        }
        
        if let confidence = confidence {
            properties["confidence"] = confidence
        }
        
        if let latency = latency {
            properties["latency_ms"] = latency
        }
        
        track(event, properties: properties)
    }
    
    /// Track strategy-related events
    public func trackStrategy(_ event: String, strategyName: String, confidence: Double? = nil, metadata: [String: Any] = [:]) {
        var properties = metadata
        properties["category"] = "strategy"
        properties["strategy_name"] = strategyName
        
        if let confidence = confidence {
            properties["confidence"] = confidence
        }
        
        track(event, properties: properties)
    }
    
    /// Track performance metrics
    public func trackPerformance(_ event: String, duration: TimeInterval, metadata: [String: Any] = [:]) {
        var properties = metadata
        properties["category"] = "performance"
        properties["duration_ms"] = Int(duration * 1000)
        
        track(event, properties: properties)
    }
    
    /// Track errors with context
    public func trackError(_ event: String, error: Error, context: String? = nil, metadata: [String: Any] = [:]) {
        var properties = metadata
        properties["category"] = "error"
        properties["error_message"] = error.localizedDescription
        properties["error_type"] = String(describing: type(of: error))
        
        if let context = context {
            properties["context"] = context
        }
        
        track(event, properties: properties)
    }
    
    /// Get telemetry summary for debugging
    public func getTelemetrySummary() -> TelemetrySummary {
        let last24Hours = telemetryEvents.filter { $0.timestamp > Date().addingTimeInterval(-24 * 60 * 60) }
        
        return TelemetrySummary(
            totalEvents: telemetryEvents.count,
            eventsLast24Hours: last24Hours.count,
            categories: Dictionary(grouping: telemetryEvents) { 
                ($0.properties["category"] as? String) ?? "unknown" 
            }.mapValues { $0.count },
            oldestEvent: telemetryEvents.first?.timestamp,
            newestEvent: telemetryEvents.last?.timestamp
        )
    }
    
    // MARK: - Statistics Calculation
    
    private func updateTradingStats() {
        guard !trades.isEmpty else { return }
        
        let totalTrades = trades.count
        let winningTrades = trades.filter { $0.pnl > 0 }
        let losingTrades = trades.filter { $0.pnl < 0 }
        
        tradingStats.totalTrades = totalTrades
        tradingStats.winningTrades = winningTrades.count
        tradingStats.losingTrades = losingTrades.count
        tradingStats.winRate = Double(winningTrades.count) / Double(totalTrades)
        
        tradingStats.totalPnL = trades.reduce(0) { $0 + $1.pnl }
        tradingStats.averagePnL = tradingStats.totalPnL / Double(totalTrades)
        
        if !winningTrades.isEmpty {
            tradingStats.averageWin = winningTrades.reduce(0) { $0 + $1.pnl } / Double(winningTrades.count)
        }
        
        if !losingTrades.isEmpty {
            tradingStats.averageLoss = losingTrades.reduce(0) { $0 + $1.pnl } / Double(losingTrades.count)
        }
        
        // Calculate profit factor
        let grossProfit = winningTrades.reduce(0) { $0 + $1.pnl }
        let grossLoss = abs(losingTrades.reduce(0) { $0 + $1.pnl })
        tradingStats.profitFactor = grossLoss > 0 ? grossProfit / grossLoss : 0
        
        // Calculate max drawdown
        calculateMaxDrawdown()
    }
    
    private func calculateMaxDrawdown() {
        var runningPnL: Double = 0
        var peak: Double = 0
        var maxDrawdown: Double = 0
        
        for trade in trades.sorted(by: { $0.timestamp < $1.timestamp }) {
            runningPnL += trade.pnl
            peak = max(peak, runningPnL)
            let drawdown = peak - runningPnL
            maxDrawdown = max(maxDrawdown, drawdown)
        }
        
        tradingStats.maxDrawdown = maxDrawdown
    }
    
    private func updateDailyStats(for trade: TradeRecord) {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: trade.timestamp)
        
        if dailyStats[day] == nil {
            dailyStats[day] = DailyStats(date: day)
        }
        
        dailyStats[day]?.trades += 1
        dailyStats[day]?.pnl += trade.pnl
        
        if trade.pnl > 0 {
            dailyStats[day]?.wins += 1
        } else if trade.pnl < 0 {
            dailyStats[day]?.losses += 1
        }
    }
    
    // MARK: - Performance Analysis
    
    public func getWeeklyPerformance() -> [WeeklyStats] {
        let calendar = Calendar.current
        let now = Date()
        var weeklyStats: [WeeklyStats] = []
        
        for weekOffset in 0..<12 { // Last 12 weeks
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                  let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { continue }
            
            let weekTrades = trades.filter { trade in
                trade.timestamp >= weekStart && trade.timestamp <= weekEnd
            }
            
            let weekPnL = weekTrades.reduce(0) { $0 + $1.pnl }
            let weekWins = weekTrades.filter { $0.pnl > 0 }.count
            
            let stats = WeeklyStats(
                weekStart: weekStart,
                trades: weekTrades.count,
                pnl: weekPnL,
                wins: weekWins,
                winRate: weekTrades.isEmpty ? 0 : Double(weekWins) / Double(weekTrades.count)
            )
            
            weeklyStats.append(stats)
        }
        
        return weeklyStats.reversed()
    }
    
    public func getSymbolPerformance() -> [SymbolStats] {
        let symbolGroups = Dictionary(grouping: trades, by: { $0.symbol })
        
        return symbolGroups.map { symbol, trades in
            let totalPnL = trades.reduce(0) { $0 + $1.pnl }
            let wins = trades.filter { $0.pnl > 0 }.count
            let winRate = Double(wins) / Double(trades.count)
            
            return SymbolStats(
                symbol: symbol,
                trades: trades.count,
                pnl: totalPnL,
                winRate: winRate
            )
        }.sorted { $0.pnl > $1.pnl }
    }
    
    // MARK: - Data Persistence
    
    private func saveData() {
        // Save to UserDefaults for demo (in production, use Core Data or similar)
        if let tradesData = try? JSONEncoder().encode(trades) {
            UserDefaults.standard.set(tradesData, forKey: "analytics_trades")
        }
        
        if let statsData = try? JSONEncoder().encode(tradingStats) {
            UserDefaults.standard.set(statsData, forKey: "analytics_stats")
        }
    }
    
    // ✅ ADD: Telemetry data persistence
    private func saveTelemetryData() {
        if let telemetryData = try? JSONEncoder().encode(telemetryEvents) {
            UserDefaults.standard.set(telemetryData, forKey: "analytics_telemetry")
        }
    }
    
    private func loadStoredData() {
        // Load from UserDefaults
        if let tradesData = UserDefaults.standard.data(forKey: "analytics_trades"),
           let loadedTrades = try? JSONDecoder().decode([TradeRecord].self, from: tradesData) {
            trades = loadedTrades
        }
        
        if let statsData = UserDefaults.standard.data(forKey: "analytics_stats"),
           let loadedStats = try? JSONDecoder().decode(TradingStats.self, from: statsData) {
            tradingStats = loadedStats
        }
        
        // ✅ ADD: Load telemetry events
        if let telemetryData = UserDefaults.standard.data(forKey: "analytics_telemetry"),
           let loadedTelemetry = try? JSONDecoder().decode([TelemetryEvent].self, from: telemetryData) {
            telemetryEvents = loadedTelemetry
        }
        
        // Recalculate stats to ensure consistency
        updateTradingStats()
    }
    
    // MARK: - Observers
    
    private func setupObservers() {
        // Listen for trade executions
        NotificationCenter.default.publisher(for: .tradeExecuted)
            .sink { [weak self] notification in
                self?.handleTradeExecution(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleTradeExecution(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let symbol = userInfo["symbol"] as? String,
              let sideString = userInfo["side"] as? String,
              let side = OrderSide(rawValue: sideString),
              let amount = userInfo["amount"] as? Double,
              let price = userInfo["price"] as? Double,
              let pnl = userInfo["pnl"] as? Double else { return }
        
        recordTrade(symbol: symbol, side: side, amount: amount, price: price, pnl: pnl)
    }
}

// MARK: - Supporting Types

public struct TradingStats: Codable {
    public var totalTrades: Int = 0
    public var winningTrades: Int = 0
    public var losingTrades: Int = 0
    public var winRate: Double = 0
    public var totalPnL: Double = 0
    public var averagePnL: Double = 0
    public var averageWin: Double = 0
    public var averageLoss: Double = 0
    public var profitFactor: Double = 0
    public var maxDrawdown: Double = 0
    
    public init() {}
}

public struct SignalPerformanceMetrics: Codable {
    public var totalSignals: Int = 0
    public var correctSignals: Int = 0
    public var accuracy: Double = 0
    public var averageConfidence: Double = 0
    
    public init() {}
}

public struct TradeRecord: Identifiable, Codable {
    public let id: String
    public let symbol: String
    public let side: OrderSide
    public let amount: Double
    public let price: Double
    public let pnl: Double
    public let timestamp: Date
    
    public init(id: String, symbol: String, side: OrderSide, amount: Double, price: Double, pnl: Double, timestamp: Date) {
        self.id = id
        self.symbol = symbol
        self.side = side
        self.amount = amount
        self.price = price
        self.pnl = pnl
        self.timestamp = timestamp
    }
}

public struct DailyStats {
    public let date: Date
    public var trades: Int = 0
    public var wins: Int = 0
    public var losses: Int = 0
    public var pnl: Double = 0
    
    public init(date: Date) {
        self.date = date
    }
}

public struct WeeklyStats {
    public let weekStart: Date
    public let trades: Int
    public let pnl: Double
    public let wins: Int
    public let winRate: Double
    
    public init(weekStart: Date, trades: Int, pnl: Double, wins: Int, winRate: Double) {
        self.weekStart = weekStart
        self.trades = trades
        self.pnl = pnl
        self.wins = wins
        self.winRate = winRate
    }
}

public struct SymbolStats {
    public let symbol: String
    public let trades: Int
    public let pnl: Double
    public let winRate: Double
    
    public init(symbol: String, trades: Int, pnl: Double, winRate: Double) {
        self.symbol = symbol
        self.trades = trades
        self.pnl = pnl
        self.winRate = winRate
    }
}

// ✅ ADD: Telemetry supporting types
public struct TelemetryEvent: Codable {
    public let name: String
    public let properties: [String: AnyCodable]
    public let timestamp: Date
    
    public init(name: String, properties: [String: Any], timestamp: Date) {
        self.name = name
        self.properties = properties.mapValues { AnyCodable($0) }
        self.timestamp = timestamp
    }
}

public struct TelemetrySummary {
    public let totalEvents: Int
    public let eventsLast24Hours: Int
    public let categories: [String: Int]
    public let oldestEvent: Date?
    public let newestEvent: Date?
}

// Helper for encoding Any values in telemetry
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let value = value as? String {
            try container.encode(value)
        } else if let value = value as? Int {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? Bool {
            try container.encode(value)
        } else {
            try container.encode(String(describing: value))
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }
}
