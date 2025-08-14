import Foundation
import Combine

@MainActor
final class PnLVM: ObservableObject {
    @Published var today: Double = 0
    @Published var unrealized: Double = 0
    @Published var equity: Double = 10_000
    @Published var history: [(Date, Double)] = []
    
    private var timer: AnyCancellable?
    
    func start() {
        timer?.cancel()
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refresh() }
    }
    
    func stop() { timer?.cancel(); timer = nil }
    
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
                self.history.append((snap.ts, self.equity))
                if self.history.count > 600 { self.history.removeFirst(self.history.count - 600) }
            }
        }
    }
}
