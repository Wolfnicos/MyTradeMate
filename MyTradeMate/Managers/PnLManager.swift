import Foundation
import Combine

@MainActor
final class PnLManager: ObservableObject {
    static let shared = PnLManager()
    
    @Published var dailyPnL: Double = 0.0
    @Published var totalPnL: Double = 0.0
    
    private var startOfDayEquity: Double = 10000.0
    private let settings: AppSettings
    
    init(settings: AppSettings = AppSettings.shared) {
        self.settings = settings
    }
    
    // NEW - Enhanced getCurrentSnapshot method for complete integration
    func getCurrentSnapshot() async throws -> PnLSnapshot {
        let tradeManager = TradeManager.shared
        let currentEquity = await tradeManager.getCurrentEquity()
        let position = await tradeManager.getCurrentPosition()
        let currentPrice = 45500.0 // Would get from market data service in production
        
        return await snapshot(price: currentPrice, position: position, equity: currentEquity)
    }
    
    func snapshot(price: Double, position: TradingPosition?, equity: Double) async -> PnLSnapshot {
        let unrealizedPnL = position?.unrealizedPnL ?? 0.0
        let realizedToday = equity - startOfDayEquity
        
        return PnLSnapshot(
            equity: equity,
            realizedToday: realizedToday,
            unrealized: unrealizedPnL
        )
    }
    
    func resetDailyTracking() {
        // This would typically be called at market open or start of day
        startOfDayEquity = TradeManager.shared.equity
        dailyPnL = 0.0
    }
    
    func recordTrade(pnl: Double) {
        dailyPnL += pnl
        totalPnL += pnl
    }
    
    func resetIfNeeded() async {
        // Check if we need to reset daily tracking (e.g., new day)
        let calendar = Calendar.current
        let now = Date()
        
        // This is a simplified version - in production you'd want to track the last reset date
        // and reset at market open or start of trading day
        if calendar.isDate(now, inSameDayAs: Date()) {
            // Same day, no reset needed
            return
        }
        
        // New day, reset daily tracking
        resetDailyTracking()
    }
}