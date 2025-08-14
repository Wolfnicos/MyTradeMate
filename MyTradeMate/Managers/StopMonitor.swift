import Foundation

public actor StopMonitor {
    public static let shared = StopMonitor()
    private var task: Task<Void, Never>?
    private var pollingMs: Int = 600 // used only if no WS tick arrives
    
    public func start() {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(pollingMs) * 1_000_000)
                await self.evaluate()
            }
        }
    }
    
    public func stop() { task?.cancel(); task = nil }
    
    /// Called by MarketDataService on every tick for instant reaction
    public func onTick(_ price: Double) async {
        await evaluate(currentPrice: price)
    }
    
    private func evaluate(currentPrice: Double? = nil) async {
        let pos = await TradeManager.shared.position
        guard let p = pos, p.quantity > 0 else { return }
        
        // Prefer latest tick pushed; else compute mid
        let lastPrice = currentPrice ?? await MarketPriceCache.shared.lastPrice
        
        // Read current SL/TP from RiskManager
        let risk = await RiskManager.shared.params
        let sl = p.avgPrice * (1.0 - risk.defaultSLPercent/100.0)
        let tp = p.avgPrice * (1.0 + risk.defaultTPPercent/100.0)
        
        if lastPrice <= sl {
            await TradeManager.shared.close(reason: .stopLoss, execPrice: lastPrice)
        } else if lastPrice >= tp {
            await TradeManager.shared.close(reason: .takeProfit, execPrice: lastPrice)
        }
    }
}
