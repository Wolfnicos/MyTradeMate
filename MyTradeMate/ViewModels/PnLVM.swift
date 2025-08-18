import Foundation
import Combine

@MainActor
final class PnLVM: ObservableObject {
    @Published var today: Double = 0
    @Published var unrealized: Double = 0
    @Published var equity: Double = 10_000
    @Published var history: [(Date, Double)] = []
    @Published var timeframe: Timeframe = .h1
    @Published var isLoading: Bool = false
    @Published var performanceMetrics: PnLMetrics?
    
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
            
            let pos = await TradeManager.shared.getCurrentPosition()
            let eq = await TradeManager.shared.getCurrentEquity()
            let lp = 45000.0 // Mock price - in production this would come from market data
            await PnLManager.shared.resetIfNeeded()
            let snap = await PnLManager.shared.snapshot(price: lp, position: pos, equity: eq)
            
            // Get fills and calculate performance metrics
            let fills = await TradeManager.shared.fillsSnapshot()
            let metrics = PnLMetricsAggregator.compute(from: fills)
            
            await MainActor.run {
                self.today = snap.realizedToday
                self.unrealized = snap.unrealized
                self.equity = snap.equity
                self.performanceMetrics = metrics
                
                // Add to raw history
                self.rawHistory.append((snap.timestamp, self.equity))
                
                // Keep raw history reasonable size
                if self.rawHistory.count > 3600 { // 1 hour at 1s intervals
                    self.rawHistory.removeFirst(self.rawHistory.count - 3600)
                }
                
                // Update aggregated history
                self.aggregateHistory()
                
                // Hide loading state after calculations are complete
                self.isLoading = false
            }
        }
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
}
