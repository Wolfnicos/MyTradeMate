import Foundation
import Combine

@MainActor
final class TradeManager: ObservableObject {
    static let shared = TradeManager()
    
    @Published var equity: Double = 10000.0
    @Published var currentPosition: TradingPosition?
    @Published var isExecutingTrade = false
    
    private let settings = AppSettings.shared
    
    private init() {}
    
    func executeTrade(_ request: TradeRequest) async throws -> TradeResult {
        isExecutingTrade = true
        defer { isExecutingTrade = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Simulate trade execution based on mode
        if settings.demoMode {
            return try await executeDemoTrade(request)
        } else if settings.paperTrading {
            return try await executePaperTrade(request)
        } else {
            return try await executeLiveTrade(request)
        }
    }
    
    private func executeDemoTrade(_ request: TradeRequest) async throws -> TradeResult {
        // Demo mode - always succeeds with simulated data
        let orderId = "DEMO_\(UUID().uuidString.prefix(8))"
        let executedPrice = request.price + Double.random(in: -10...10) // Small price variation
        let executedAmount = request.amount
        
        // Update demo position
        updateDemoPosition(request: request, executedPrice: executedPrice, executedAmount: executedAmount)
        
        return TradeResult(
            orderId: orderId,
            symbol: request.symbol,
            side: request.side,
            executedAmount: executedAmount,
            executedPrice: executedPrice,
            status: .filled,
            timestamp: Date()
        )
    }
    
    private func executePaperTrade(_ request: TradeRequest) async throws -> TradeResult {
        // Paper trading - uses real market data but simulated execution
        let orderId = "PAPER_\(UUID().uuidString.prefix(8))"
        let executedPrice = request.price // Use current market price
        let executedAmount = request.amount
        
        // Update paper position
        updatePaperPosition(request: request, executedPrice: executedPrice, executedAmount: executedAmount)
        
        return TradeResult(
            orderId: orderId,
            symbol: request.symbol,
            side: request.side,
            executedAmount: executedAmount,
            executedPrice: executedPrice,
            status: .filled,
            timestamp: Date()
        )
    }
    
    private func executeLiveTrade(_ request: TradeRequest) async throws -> TradeResult {
        // Live trading - would connect to actual exchange API
        // For now, throw an error as live trading is not fully implemented
        throw TradeError.liveTradeNotImplemented
    }
    
    private func updateDemoPosition(request: TradeRequest, executedPrice: Double, executedAmount: Double) {
        let positionChange = request.side == .buy ? executedAmount : -executedAmount
        
        if let existingPosition = currentPosition {
            let newQuantity = existingPosition.quantity + positionChange
            
            if abs(newQuantity) < 0.000001 { // Close to zero
                currentPosition = nil
            } else {
                // Update average price for the position
                let totalValue = existingPosition.quantity * existingPosition.averagePrice + positionChange * executedPrice
                let averagePrice = totalValue / newQuantity
                
                currentPosition = TradingPosition(
                    id: existingPosition.id,
                    symbol: request.symbol,
                    quantity: newQuantity,
                    averagePrice: averagePrice,
                    currentPrice: executedPrice,
                    timestamp: Date()
                )
            }
        } else {
            // Create new position
            currentPosition = TradingPosition(
                id: UUID().uuidString,
                symbol: request.symbol,
                quantity: positionChange,
                averagePrice: executedPrice,
                currentPrice: executedPrice,
                timestamp: Date()
            )
        }
        
        // Update equity (subtract fees, etc.)
        let tradingFee = executedAmount * executedPrice * 0.001 // 0.1% fee
        equity -= tradingFee
    }
    
    private func updatePaperPosition(request: TradeRequest, executedPrice: Double, executedAmount: Double) {
        // Same logic as demo but with real market prices
        updateDemoPosition(request: request, executedPrice: executedPrice, executedAmount: executedAmount)
    }
    
    func getCurrentPosition() async -> TradingPosition? {
        return currentPosition
    }
    
    func getCurrentEquity() async -> Double {
        return equity
    }
    
    func close(reason: CloseReason, execPrice: Double) async throws {
        guard let position = currentPosition else {
            throw TradeError.invalidAmount // No position to close
        }
        
        // Create a trade request to close the position
        let closeRequest = TradeRequest(
            symbol: position.symbol,
            side: position.quantity > 0 ? .sell : .buy, // Opposite side to close
            amount: abs(position.quantity),
            price: execPrice,
            type: .market,
            timeInForce: .goodTillCanceled
        )
        
        // Execute the closing trade
        _ = try await executeTrade(closeRequest)
        
        Log.trade.info("Position closed due to \(reason.rawValue) at price \(execPrice)")
    }
    
    func fillsSnapshot() async -> [OrderFill] {
        // Return empty array for now - in production this would return actual fills
        return []
    }
    
    func manualOrder(_ orderRequest: OrderRequest) async throws -> OrderFill {
        // Convert OrderRequest to TradeRequest for internal processing
        let tradeRequest = TradeRequest(
            symbol: orderRequest.symbol.raw,
            side: orderRequest.side == .buy ? .buy : .sell,
            amount: orderRequest.quantity,
            price: orderRequest.limitPrice ?? 0.0, // Use limit price or 0 for market
            type: orderRequest.limitPrice != nil ? .limit : .market,
            timeInForce: .goodTillCanceled
        )
        
        // Execute the trade
        let result = try await executeTrade(tradeRequest)
        
        // Convert result to OrderFill
        return OrderFill(
            id: UUID(),
            symbol: orderRequest.symbol,
            side: orderRequest.side,
            quantity: orderRequest.quantity,
            price: result.executedPrice,
            timestamp: result.timestamp
        )
    }
}

// MARK: - Supporting Types

public struct TradeResult: Codable {
    let orderId: String
    let symbol: String
    let side: TradeSide
    let executedAmount: Double
    let executedPrice: Double
    let status: OrderStatus
    let timestamp: Date
}

public enum OrderStatus: String, Codable {
    case pending = "PENDING"
    case partiallyFilled = "PARTIALLY_FILLED"
    case filled = "FILLED"
    case canceled = "CANCELED"
    case rejected = "REJECTED"
}



public struct TradingPosition: Codable, Identifiable {
    public let id: String
    public let symbol: String
    public let quantity: Double // Positive = long, negative = short
    public let averagePrice: Double
    public let currentPrice: Double
    public let timestamp: Date
    
    public var unrealizedPnL: Double {
        quantity * (currentPrice - averagePrice)
    }
    
    public var unrealizedPnLPercent: Double {
        guard averagePrice > 0 else { return 0 }
        return (unrealizedPnL / (abs(quantity) * averagePrice)) * 100
    }
    
    public var side: String {
        quantity > 0 ? "LONG" : "SHORT"
    }
    
    public var displayQuantity: String {
        String(format: "%.6f", abs(quantity))
    }
    
    public var displayPnL: String {
        let sign = unrealizedPnL >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", unrealizedPnL))"
    }
    
    public var displayPnLPercent: String {
        let sign = unrealizedPnLPercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", unrealizedPnLPercent))%"
    }
}

public enum CloseReason: String, Codable {
    case stopLoss = "stop_loss"
    case takeProfit = "take_profit"
    case manual = "manual"
    case liquidation = "liquidation"
}

public enum TradeError: LocalizedError {
    case liveTradeNotImplemented
    case insufficientBalance
    case invalidAmount
    case marketClosed
    case apiError(String)
    
    public var errorDescription: String? {
        switch self {
        case .liveTradeNotImplemented:
            return "Live trading is not yet implemented"
        case .insufficientBalance:
            return "Insufficient balance for this trade"
        case .invalidAmount:
            return "Invalid trade amount"
        case .marketClosed:
            return "Market is currently closed"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}