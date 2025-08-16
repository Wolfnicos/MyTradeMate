import Foundation
import Combine

enum PnLDateFilter: String, CaseIterable, Identifiable {
    case all = "All Time"
    case today = "Today"
    case week = "7 Days"
    case month = "30 Days"
    case quarter = "90 Days"
    
    var id: String { rawValue }
    
    var dateRange: (Date?, Date?) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .all:
            return (nil, nil)
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)
        case .week:
            return (calendar.date(byAdding: .day, value: -7, to: now), now)
        case .month:
            return (calendar.date(byAdding: .day, value: -30, to: now), now)
        case .quarter:
            return (calendar.date(byAdding: .day, value: -90, to: now), now)
        }
    }
}

@MainActor
final class PnLVM: ObservableObject {
    @Published var today: Double = 0
    @Published var unrealized: Double = 0
    @Published var equity: Double = 10_000
    @Published var history: [(Date, Double)] = []
    @Published var timeframe: Timeframe = .h1
    @Published var isLoading: Bool = false
    @Published var performanceMetrics: PnLMetrics?
    @Published var dateFilter: PnLDateFilter = .all
    @Published var symbolFilter: String = "All"
    @Published var availableSymbols: [String] = ["All"]
    
    private var timer: AnyCancellable?
    private var rawHistory: [(Date, Double)] = []
    
    var timeframeHours: Int {
        max(1, Int(timeframe.seconds / 3600))
    }
    
    func start() {
        timer?.cancel()
        
        // Show loading state initially
        isLoading = true
        
        // Initialize with some baseline data if history is empty
        if rawHistory.isEmpty {
            let now = Date()
            let baseEquity = 10000.0
            // Add 20 data points going back in time for initial display
            for i in (0..<20).reversed() {
                let timestamp = now.addingTimeInterval(-Double(i * 60)) // 1 minute intervals
                rawHistory.append((timestamp, baseEquity))
            }
            aggregateHistory()
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
            
            let pos = await TradeManager.shared.position
            let eq = await TradeManager.shared.equity
            let lp = await MarketPriceCache.shared.lastPrice
            await PnLManager.shared.resetIfNeeded()
            let snap = await PnLManager.shared.snapshot(price: lp, position: pos, equity: eq)
            
            // Get fills and calculate performance metrics with filters applied
            let fills = await TradeManager.shared.fillsSnapshot()
            let filteredFills = self.applyFilters(to: fills)
            let metrics = PnLMetricsAggregator.compute(from: filteredFills)
            
            // Update available symbols
            let symbols = Set(fills.map { $0.symbol.raw }).sorted()
            
            await MainActor.run {
                self.today = snap.realizedToday
                self.unrealized = snap.unrealized
                self.equity = snap.equity
                self.performanceMetrics = metrics
                self.availableSymbols = ["All"] + symbols
                
                // Add to raw history
                self.rawHistory.append((snap.ts, self.equity))
                
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
    }
    
    private func applyFilters(to fills: [OrderFill]) -> [OrderFill] {
        var filtered = fills
        
        // Apply date filter
        let (startDate, endDate) = dateFilter.dateRange
        if let start = startDate {
            filtered = filtered.filter { $0.timestamp >= start }
        }
        if let end = endDate {
            filtered = filtered.filter { $0.timestamp <= end }
        }
        
        // Apply symbol filter
        if symbolFilter != "All" {
            filtered = filtered.filter { $0.symbol.raw == symbolFilter }
        }
        
        return filtered
    }
    
    func updateDateFilter(_ newFilter: PnLDateFilter) {
        dateFilter = newFilter
        isLoading = true
        refresh()
    }
    
    func updateSymbolFilter(_ newSymbol: String) {
        symbolFilter = newSymbol
        isLoading = true
        refresh()
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
            
            let widgetData = WidgetDataManager.shared.createWidgetData(
                from: self,
                tradeManager: TradeManager.shared,
                marketPrice: marketPrice,
                priceChange: priceChange,
                isDemoMode: isDemoMode,
                isConnected: isConnected
            )
            
            WidgetDataManager.shared.updateWidgetData(widgetData)
        }
    }
}
