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
        // await MarketDataService.shared.setPaperExchange(ex)
    }
    
        public func manualOrder(_ req: OrderRequest) async throws -> OrderFill {
        guard await risk.canTrade(equity: equity) else {
            throw AppError.riskLimitExceeded(limit: "Daily loss limit reached")
        }

        do {
            let fill = try await exchangeClient.placeMarketOrder(req)
            fills.append(fill)

            var pos = position ?? Position(symbol: req.symbol, quantity: 0, avgPrice: 0)
            let (newPos, realized) = applyFill(fill: fill, to: pos)
            
            if realized != 0 {
                equity += realized
                await risk.record(realizedPnL: realized, equity: equity)
                await PnLManager.shared.addRealized(realized)
            }
            
            position = newPos.isFlat ? nil : newPos
            return fill
        } catch let error as ExchangeError {
            // Convert ExchangeError to AppError for consistent error handling
            let appError = convertExchangeError(error, for: req)
            throw appError
        } catch {
            // Handle any other errors
            throw AppError.tradeExecutionFailed(details: error.localizedDescription)
        }
    }
    
    /// Convert ExchangeError to AppError with appropriate context
    private func convertExchangeError(_ error: ExchangeError, for request: OrderRequest) -> AppError {
        switch error {
        case .invalidResponse:
            return .tradeExecutionFailed(details: "Invalid response from exchange")
        case .networkError(let underlying):
            return .tradeExecutionFailed(details: "Network error: \(underlying.localizedDescription)")
        case .missingCredentials:
            return .credentialsNotFound(exchange: exchangeClient.exchange.rawValue)
        case .rateLimitExceeded:
            return .tradeExecutionFailed(details: "Rate limit exceeded. Please wait before placing another order")
        case .serverError(let message):
            return .tradeExecutionFailed(details: "Exchange server error: \(message)")
        case .invalidConfiguration:
            return .invalidConfiguration(component: "Exchange client")
        case .securityValidationFailed:
            return .networkSecurityFailed(reason: "Exchange security validation failed")
        }
    }
    
    /// Apply a fill to a position, correctly handling both long and short positions
    private func applyFill(fill: OrderFill, to position: Position) -> (Position, Double) {
        var pos = position
        var realizedPnL = 0.0
        
        let fillValue = fill.quantity * fill.price
        
        switch fill.side {
        case .buy:
            if pos.quantity >= 0 {
                // Long position: add to position
                let totalCost = pos.avgPrice * pos.quantity + fillValue
                pos.quantity += fill.quantity
                pos.avgPrice = pos.quantity > 0 ? totalCost / pos.quantity : 0
            } else {
                // Short position: buying to cover
                let qtyToCover = min(abs(pos.quantity), fill.quantity)
                realizedPnL = (pos.avgPrice - fill.price) * qtyToCover
                
                pos.quantity += qtyToCover
                let remainingFillQty = fill.quantity - qtyToCover
                
                if remainingFillQty > 0 {
                    // Flip to long position
                    pos.quantity = remainingFillQty
                    pos.avgPrice = fill.price
                } else if pos.quantity == 0 {
                    pos.avgPrice = 0
                }
            }
            
        case .sell:
            if pos.quantity > 0 {
                // Long position: selling to close or flip short
                let qtyToClose = min(pos.quantity, fill.quantity)
                realizedPnL = (fill.price - pos.avgPrice) * qtyToClose
                
                pos.quantity -= qtyToClose
                let remainingFillQty = fill.quantity - qtyToClose
                
                if remainingFillQty > 0 {
                    // Flip to short position
                    pos.quantity = -remainingFillQty
                    pos.avgPrice = fill.price
                } else if pos.quantity == 0 {
                    pos.avgPrice = 0
                }
            } else {
                // Short position: add to short position
                let totalValue = abs(pos.quantity) * pos.avgPrice + fillValue
                pos.quantity -= fill.quantity
                pos.avgPrice = pos.quantity < 0 ? totalValue / abs(pos.quantity) : 0
            }
        }
        
        return (pos, realizedPnL)
    }
    
    public func close(reason: CloseReason, execPrice: Double) async {
        guard let p = position, !p.isFlat else { return }
        
        let (side, quantity, realized) = if p.quantity > 0 {
            // Close long position by selling
            (OrderSide.sell, p.quantity, (execPrice - p.avgPrice) * p.quantity)
        } else {
            // Close short position by buying
            (OrderSide.buy, abs(p.quantity), (p.avgPrice - execPrice) * abs(p.quantity))
        }
        
        equity += realized
        await PnLManager.shared.addRealized(realized)
        fills.append(OrderFill(
            id: UUID(),
            symbol: p.symbol,
            side: side,
            quantity: quantity,
            price: execPrice,
            timestamp: Date()
        ))
        position = nil
    }
    
    public func fillsSnapshot() async -> [OrderFill] {
        fills
    }
}
