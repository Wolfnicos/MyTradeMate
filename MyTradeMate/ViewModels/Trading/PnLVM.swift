import Foundation
import Combine
import SwiftUI



@MainActor
final class PnLVM: ObservableObject {
    @Published var today: Double = 0
    @Published var unrealized: Double = 0
    @Published var equity: Double = 0
    @Published var history: [(Date, Double)] = []
    @Published var timeframe: Timeframe = .h1
    @Published var isLoading: Bool = false
    @Published var performanceMetrics: PnLMetrics?
    @Published var symbolFilter: String = "All"
    @Published var availableSymbols: [String] = ["All"]
    
    private var timer: AnyCancellable?
    private var rawHistory: [(Date, Double)] = []
    private let settings = AppSettings.shared
    private var cancellables = Set<AnyCancellable>()
    
    var timeframeHours: Int {
        max(1, Int(timeframe.seconds / 3600))
    }
    
    func start() {
        timer?.cancel()
        
        // Show loading state initially
        isLoading = true
        
        // Subscribe to trading events
        subscribeToTradingEvents()
        
        // Initialize with some baseline data if history is empty
        if rawHistory.isEmpty {
            Task {
                let baseEquity = await TradeManager.shared.equity
                await MainActor.run {
                    let now = Date()
                    // Add 20 data points going back in time for initial display
                    for i in (0..<20).reversed() {
                        let timestamp = now.addingTimeInterval(-Double(i * 60)) // 1 minute intervals
                        self.rawHistory.append((timestamp, baseEquity))
                    }
                    self.aggregateHistory()
                }
            }
        }
        
        // Initial refresh to load data
        refresh()
        
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refresh() }
    }
    
    func stop() { timer?.cancel(); timer = nil }
    
    func setTimeframe(_ tf: Timeframe) {
        isLoading = true
        timeframe = tf
        aggregateHistory()
        isLoading = false
    }
    
    private func refresh() {
        Task {
            // Show loading state for initial load or when recalculating
            await MainActor.run {
                if self.rawHistory.isEmpty || self.isLoading {
                    self.isLoading = true
                }
            }
            
            // Use proper trading mode from AppSettings
            switch settings.tradingMode {
            case .demo:
                await refreshDemoData()
            case .paper:
                await refreshPaperData()
            case .live:
                await refreshLiveData()
            }
        }
    }
    
    private func refreshDemoData() async {
        // Use current equity from TradeManager as base, not hardcoded 10k
        let baseEquity = await TradeManager.shared.getCurrentEquity()
        
        // Generate synthetic PnL data with smaller, more realistic fluctuations
        let now = Date()
        let timeInterval = now.timeIntervalSince1970
        
        // Create realistic demo fluctuations (±2% of base equity)
        let maxVariation = baseEquity * 0.02
        let variation = sin(timeInterval / 300) * maxVariation * 0.6 + cos(timeInterval / 600) * maxVariation * 0.4
        let demoEquity = baseEquity + variation
        
        let demoToday = variation * 0.3
        let demoUnrealized = variation * 0.2
        
        await MainActor.run {
            self.today = demoToday
            self.unrealized = demoUnrealized
            self.equity = demoEquity
            self.performanceMetrics = self.generateDemoMetrics()
            self.availableSymbols = ["All", "BTC/USDT", "ETH/USDT"]
            
            // Add to raw history
            self.rawHistory.append((now, self.equity))
            
            // Keep raw history reasonable size
            if self.rawHistory.count > 3600 { // 1 hour at 1s intervals
                self.rawHistory.removeFirst(self.rawHistory.count - 3600)
            }
            
            // Update aggregated history
            self.aggregateHistory()
            
            // Update widget data
            self.updateWidgetData()
            
            // Hide loading state after calculations are complete
            self.isLoading = false
        }
    }
    
    private func refreshPaperData() async {
        // Paper trading: use simulated trades with real market data
        let pos = await TradeManager.shared.getCurrentPosition()
        let eq = await TradeManager.shared.getCurrentEquity()
        let lp = await MarketPriceCache.shared.lastPrice
        await PnLManager.shared.resetIfNeeded()
        let snap = await PnLManager.shared.snapshot(price: lp, position: pos, equity: eq)
        
        // Get fills (TradeManager will return appropriate data based on current mode)
        let fills = await TradeManager.shared.fillsSnapshot()
        let filteredFills = applySymbolFilter(to: fills)
        let metrics = PnLMetricsAggregator.compute(from: filteredFills)
        
        // Update available symbols
        let symbols = Set(fills.map { $0.pair.symbol }).sorted()
        
        await MainActor.run {
            self.today = snap.realizedToday
            self.unrealized = snap.unrealized
            self.equity = snap.equity
            self.performanceMetrics = metrics
            self.availableSymbols = ["All"] + symbols
            
            // Add current equity to history for paper mode
            let now = Date()
            self.rawHistory.append((now, snap.equity))
            
            // Keep only last 500 points to prevent memory issues
            if self.rawHistory.count > 500 {
                self.rawHistory.removeFirst(self.rawHistory.count - 500)
            }
            
            self.aggregateHistory()
            self.isLoading = false
        }
    }
    
    private func refreshLiveData() async {
        let pos = await TradeManager.shared.getCurrentPosition()
        let eq = await TradeManager.shared.getCurrentEquity()
        let lp = await MarketPriceCache.shared.lastPrice
        await PnLManager.shared.resetIfNeeded()
        let snap = await PnLManager.shared.snapshot(price: lp, position: pos, equity: eq)
        
        // Get fills and calculate performance metrics with filters applied
        let fills = await TradeManager.shared.fillsSnapshot()
        let filteredFills = applySymbolFilter(to: fills)
        let metrics = PnLMetricsAggregator.compute(from: filteredFills)
        
        // Update available symbols
        let symbols = Set(fills.map { $0.pair.symbol }).sorted()
        
        await MainActor.run {
            self.today = snap.realizedToday
            self.unrealized = snap.unrealized
            self.equity = snap.equity
            self.performanceMetrics = metrics
            self.availableSymbols = ["All"] + symbols
            
            // Add to raw history
            self.rawHistory.append((Date(), self.equity))
            
            // Keep raw history reasonable size
            if self.rawHistory.count > 3600 { // 1 hour at 1s intervals
                self.rawHistory.removeFirst(self.rawHistory.count - 3600)
            }
            
            // Update aggregated history
            self.aggregateHistory()
            
            // Update widget data
            self.updateWidgetData()
            
            // Hide loading state after calculations are complete
            self.isLoading = false
        }
    }
    
    private func generateDemoMetrics() -> PnLMetrics {
        // Generate realistic demo performance metrics based on actual equity
        let initialEquity = 10000.0 // Starting amount
        let netPnL = equity - initialEquity
        return PnLMetrics(
            trades: 24,
            wins: 16,
            losses: 8,
            winRate: 0.655, // 65.5% as decimal
            avgTradePnL: netPnL / 24.0,
            avgWin: 145.60,
            avgLoss: -89.30,
            grossProfit: 16 * 145.60,
            grossLoss: 8 * -89.30,
            netPnL: netPnL,
            maxDrawdown: -285.50
        )
    }
    

    
    func updateSymbolFilter(_ newSymbol: String) {
        symbolFilter = newSymbol
        isLoading = true
        refresh()
    }
    
    private func applySymbolFilter(to fills: [OrderFill]) -> [OrderFill] {
        guard symbolFilter != "All" else { return fills }
        return fills.filter { $0.pair.symbol == symbolFilter }
    }
    
    private func aggregateHistory() {
        guard !rawHistory.isEmpty else {
            history = []
            return
        }
        
        let interval = timeframe.seconds
        let maxPoints = timeframe.maxPoints
        
        // Group data points by time intervals
        var aggregated: [Date: Double] = [:]
        
        for (timestamp, value) in rawHistory {
            let bucketTime = Date(timeIntervalSince1970: 
                floor(timestamp.timeIntervalSince1970 / interval) * interval)
            aggregated[bucketTime] = value // Use latest value in bucket
        }
        
        // Convert to sorted array and limit to maxPoints
        var sortedHistory = aggregated.map { ($0.key, $0.value) }
            .sorted { $0.0 < $1.0 }
        
        if sortedHistory.count > maxPoints {
            sortedHistory = Array(sortedHistory.suffix(maxPoints))
        }
        
        history = sortedHistory
    }
    
    /// Update widget data when P&L changes
    private func updateWidgetData() {
        Task {
            // Get current market data
            let marketPrice = await MarketPriceCache.shared.lastPrice
            let priceChange = 0.0 // This would need to be calculated from 24h data
            
            // Get trading mode and connection status
            let isDemoMode = AppSettings.shared.tradingMode == .demo
            let isConnected = true // This would come from connection manager
            
            let netPnL = self.equity - 10000.0 // Assuming initial equity of 10k
            let pnlPercentage = netPnL / 10000.0 * 100
            
            let widgetData = WidgetDataManager.shared.createWidgetData(
                pnl: netPnL,
                pnlPercentage: pnlPercentage,
                todayPnL: self.today,
                unrealizedPnL: self.unrealized,
                equity: self.equity,
                openPositions: 1, // Placeholder
                marketPrice: marketPrice,
                priceChange: priceChange,
                isDemoMode: isDemoMode,
                isConnected: isConnected
            )
            
            WidgetDataManager.shared.updateWidgetData(widgetData)
        }
    }
    
    // MARK: - Event Subscriptions
    
    private func subscribeToTradingEvents() {
        // Subscribe to order filled events
        NotificationCenter.default.publisher(for: .orderFilled)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                // Refresh PnL when an order is filled
                self?.refresh()
            }
            .store(in: &cancellables)
        
        // Subscribe to position updated events
        NotificationCenter.default.publisher(for: .positionUpdated)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                // Refresh PnL when position changes
                self?.refresh()
            }
            .store(in: &cancellables)
        
        // Subscribe to PnL updated events
        NotificationCenter.default.publisher(for: .pnlUpdated)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                // Refresh display when PnL is updated
                self?.refresh()
            }
            .store(in: &cancellables)
        
        // Subscribe to trade executed events
        NotificationCenter.default.publisher(for: .tradeExecuted)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                // Update available symbols if needed
                if let userInfo = notification.userInfo,
                   let symbol = userInfo["symbol"] as? String {
                    if !(self?.availableSymbols.contains(symbol) ?? true) {
                        self?.availableSymbols.append(symbol)
                    }
                }
                self?.refresh()
            }
            .store(in: &cancellables)
    }
}
