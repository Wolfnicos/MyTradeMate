import Foundation
import SwiftUI

public enum CloseReason: String, Sendable { case manual, stopLoss, takeProfit }

@MainActor
public final class TradeManager: ObservableObject {
    public static let shared = TradeManager()

    public private(set) var mode: TradingMode = .paper
    public private(set) var equity: Double = 10_000
    public private(set) var position: Position?
    public private(set) var fills: [OrderFill] = []
    
    private var exchangeClient: ExchangeClient = PaperExchangeClient(exchange: .binance)
    private let risk = RiskManager.shared
    
    public func setMode(_ newMode: TradingMode) {
        mode = newMode
        // For now paper only; wire live client later
    }
    
    public func setExchange(_ ex: Exchange) async {
        exchangeClient = PaperExchangeClient(exchange: ex)
        await MarketDataService.shared.setPaperExchange(ex)
    }
    
        public func manualOrder(_ req: OrderRequest) async throws -> OrderFill {
        guard await risk.canTrade(equity: equity) else {
            throw NSError(domain: "TradeManager", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Daily loss limit reached"])
        }

        let fill = try await exchangeClient.placeMarketOrder(req)
        fills.append(fill)

        var pos = position ?? Position(symbol: req.symbol, quantity: 0, avgPrice: 0)
        switch req.side {
        case .buy:
            let totalCost = pos.avgPrice * pos.quantity + fill.price * fill.quantity
            pos.quantity += fill.quantity
            pos.avgPrice = pos.quantity > 0 ? totalCost / pos.quantity : 0
        case .sell:
            let qtyToClose = min(pos.quantity, fill.quantity)
            let average = pos.avgPrice
            // realized pnl for the closed portion
            let realized = (fill.price - average) * qtyToClose
            equity += realized
            await risk.record(realizedPnL: realized, equity: equity)
            await PnLManager.shared.addRealized(realized)

            pos.quantity -= fill.quantity
            if pos.quantity <= 0 { pos.quantity = 0; pos.avgPrice = 0 }
        }
        position = pos
        return fill
    }
    
    public func close(reason: CloseReason, execPrice: Double) async {
        guard var p = position, p.quantity > 0 else { return }
        let realized = (execPrice - p.avgPrice) * p.quantity
        equity += realized
        await PnLManager.shared.addRealized(realized)
        fills.append(OrderFill(
            id: UUID(),
            symbol: p.symbol,
            side: .sell,
            quantity: p.quantity,
            price: execPrice,
            timestamp: Date()
        ))
        position = nil
    }
    
    public func fillsSnapshot() async -> [OrderFill] {
        fills
    }
}
