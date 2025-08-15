import Foundation
import Combine

@MainActor
final class DashboardVM: ObservableObject {
    @Published var exchange: Exchange = .binance
    @Published var symbol: Symbol = Symbol("BTCUSDT", exchange: .binance)
    @Published var price: Double = 0
    @Published var priceUp: Bool = true
    @Published var lastSignal: Signal?
    @Published var timeframe: Timeframe = .m5
    @Published var aiMode: AIModelManager.Mode = .normal
    @Published var autoTrading: Bool = false
    @Published var pnl: PnLSnapshot = .init(equity: 10_000, realizedToday: 0, unrealized: 0, ts: .init())
    
    private var prev: Double = 0
    
    func onAppear() {
        Task { await MarketDataService.shared.subscribe { [weak self] tick in
            Task { @MainActor in
                guard let self, tick.symbol == self.symbol else { return }
                self.priceUp = tick.price >= self.prev
                self.prev = tick.price
                self.price = tick.price
                
                // Update PnL
                let pos = await TradeManager.shared.position
                let eq = await TradeManager.shared.equity
                await PnLManager.shared.resetIfNeeded()
                let snap = await PnLManager.shared.snapshot(price: tick.price, position: pos, equity: eq)
                await MainActor.run { self.pnl = snap }
            }
        }}
        Task { await MarketDataService.shared.start(symbol: symbol) }
    }
    
    func changeExchange(_ ex: Exchange) {
        exchange = ex
        symbol = Symbol(symbol.raw, exchange: ex)
        Task {
            await MarketDataService.shared.stop()
            await TradeManager.shared.setExchange(ex)
            await MarketDataService.shared.start(symbol: symbol)
        }
    }
    
    func generateSignal() {
        Task {
            let sig = await AIModelManager.shared.generateSignal(
                symbol: symbol, mark: price, timeframe: timeframe, mode: aiMode
            )
            await MainActor.run { self.lastSignal = sig }
        }
    }
    
    func buy(_ qty: Double = 0.01) {
        Task {
            if await ThemeManager.shared.isHapticsEnabled {
                Haptics.buyFeedback()
            }
            let req = OrderRequest(symbol: symbol, side: .buy, quantity: qty, limitPrice: nil, stopLoss: nil, takeProfit: nil)
            _ = try? await TradeManager.shared.manualOrder(req)
        }
    }
    
    func sell(_ qty: Double = 0.01) {
        Task {
            if await ThemeManager.shared.isHapticsEnabled {
                Haptics.sellFeedback()
            }
            let req = OrderRequest(symbol: symbol, side: .sell, quantity: qty, limitPrice: nil, stopLoss: nil, takeProfit: nil)
            _ = try? await TradeManager.shared.manualOrder(req)
        }
    }
}