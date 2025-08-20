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
    
    private init() {
        loadStoredData()
        setupObservers()
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
