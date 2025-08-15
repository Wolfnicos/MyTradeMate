import Foundation
import Combine

@MainActor
final class PnLVM: ObservableObject {
    @Published var today: Double = 0
    @Published var unrealized: Double = 0
    @Published var equity: Double = 10_000
    @Published var history: [(Date, Double)] = []
    @Published var timeframe: Timeframe = .hour1
    
    private var timer: AnyCancellable?
    private var rawHistory: [(Date, Double)] = []
    
    enum Timeframe: String, CaseIterable {
        case minute1 = "1m"
        case minute5 = "5m"
        case hour1 = "1h"
        case day1 = "1D"
        
        var seconds: TimeInterval {
            switch self {
            case .minute1: return 60
            case .minute5: return 300
            case .hour1: return 3600
            case .day1: return 86400
            }
        }
        
        var maxPoints: Int {
            switch self {
            case .minute1: return 120  // 2 hours
            case .minute5: return 288  // 24 hours
            case .hour1: return 168    // 1 week
            case .day1: return 90      // 3 months
            }
        }
    }
    
    var timeframeHours: Int {
        max(1, Int(timeframe.seconds / 3600))
    }
    
    func start() {
        timer?.cancel()
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refresh() }
    }
    
    func stop() { timer?.cancel(); timer = nil }
    
    func setTimeframe(_ tf: Timeframe) {
        timeframe = tf
        aggregateHistory()
    }
    
    private func refresh() {
        Task {
            let pos = await TradeManager.shared.position
            let eq = await TradeManager.shared.equity
            let lp = await MarketPriceCache.shared.lastPrice
            await PnLManager.shared.resetIfNeeded()
            let snap = await PnLManager.shared.snapshot(price: lp, position: pos, equity: eq)
            await MainActor.run {
                self.today = snap.realizedToday
                self.unrealized = snap.unrealized
                self.equity = snap.equity
                
                // Add to raw history
                self.rawHistory.append((snap.ts, self.equity))
                
                // Keep raw history reasonable size
                if self.rawHistory.count > 3600 { // 1 hour at 1s intervals
                    self.rawHistory.removeFirst(self.rawHistory.count - 3600)
                }
                
                // Update aggregated history
                self.aggregateHistory()
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
