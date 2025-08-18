import Foundation
import Combine
import SwiftUI

// MARK: - Trade Error
enum TradeError: Error {
    case liveTradeNotImplemented
    case invalidAmount
}

// MARK: - Trade Result
public struct TradeResult: Codable {
    let orderId: String
    let symbol: String
    let side: TradeSide
    let executedAmount: Double
    let executedPrice: Double
    let status: Order.Status
    let timestamp: Date
    
    public init(orderId: String, symbol: String, side: TradeSide, executedAmount: Double, executedPrice: Double, status: Order.Status, timestamp: Date) {
        self.orderId = orderId
        self.symbol = symbol
        self.side = side
        self.executedAmount = executedAmount
        self.executedPrice = executedPrice
        self.status = status
        self.timestamp = timestamp
    }
}

@MainActor
final class TradeManager: ObservableObject {
    static let shared = TradeManager()
    
    @Published var equity: Double = 10000.0
    @Published var currentPosition: TradingPosition?
    @Published var isExecutingTrade = false
    
    private let settings: AppSettings
    
    init(settings: AppSettings = AppSettings.shared) {
        self.settings = settings
    }
    
    // NEW - Enhanced executeOrder method for complete integration
    func executeOrder(_ request: TradeRequest, tradingMode: TradingMode) async throws -> OrderFill {
        isExecutingTrade = true
        defer { isExecutingTrade = false }
        
        // Validate request
        guard request.amount > 0 else {
            throw TradeError.invalidAmount
        }
        
        // Simulate network delay for realism
        try await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...2_000_000_000)) // 0.5-2 seconds
        
        let executedPrice = calculateExecutionPrice(request: request, tradingMode: tradingMode)
        let fee = calculateTradingFee(amount: request.amount, price: executedPrice)
        let executedQuantity = request.amount / executedPrice // Convert notional to quantity
        
        let orderFill = OrderFill(
            id: UUID(),
            pair: request.tradingPair,
            side: request.side.toOrderSide,
            quantity: executedQuantity,
            price: executedPrice,
            fee: fee,
            timestamp: Date(),
            orderType: request.type
        )
        
        // Update position and equity based on trading mode
        await updatePositionAfterTrade(orderFill: orderFill, tradingMode: tradingMode)
        
        return orderFill
    }
    
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
            status: Order.Status.filled,
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
            status: Order.Status.filled,
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
        // Return demo position when in demo mode
        if settings.demoMode {
            return generateDemoPosition()
        }
        return currentPosition
    }
    
    private func generateDemoPosition() -> TradingPosition {
        return TradingPosition(
            id: "DEMO_POSITION_001",
            symbol: "BTC/USDT",
            quantity: 0.15, // Long position
            averagePrice: 45000.0,
            currentPrice: 45500.0, // Slightly higher for profit
            timestamp: Date()
        )
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
        // Return demo fills when in demo mode
        if settings.demoMode {
            return generateDemoFills()
        }
        // Return empty array for now - in production this would return actual fills
        return []
    }
    
    private func generateDemoFills() -> [OrderFill] {
        let now = Date()
        return [
            OrderFill(
                pair: .btcUsdt,
                side: .buy,
                quantity: 0.1,
                price: 45000.0,
                fee: 0.0,
                timestamp: now.addingTimeInterval(-2 * 3600),
                orderType: .market,
                originalRequest: OrderRequest(
                    pair: .btcUsdt,
                    side: .buy,
                    type: .market,
                    amountMode: .fixedNotional,
                    amountValue: 4500.0,
                    leverage: nil,
                    limitPrice: nil,
                    stopPrice: nil,
                    timeInForce: .goodTillCanceled
                )
            ),
            OrderFill(
                pair: .btcUsdt,
                side: .sell,
                quantity: 0.05,
                price: 46000.0,
                fee: 0.0,
                timestamp: now.addingTimeInterval(-1 * 3600),
                orderType: .market,
                originalRequest: OrderRequest(
                    pair: .btcUsdt,
                    side: .sell,
                    type: .market,
                    amountMode: .fixedNotional,
                    amountValue: 2300.0,
                    leverage: nil,
                    limitPrice: nil,
                    stopPrice: nil,
                    timeInForce: .goodTillCanceled
                )
            ),
            OrderFill(
                pair: .btcUsdt,
                side: .buy,
                quantity: 0.2,
                price: 44000.0,
                fee: 0.0,
                timestamp: now.addingTimeInterval(-30 * 60),
                orderType: .market,
                originalRequest: OrderRequest(
                    pair: .btcUsdt,
                    side: .buy,
                    type: .market,
                    amountMode: .fixedNotional,
                    amountValue: 8800.0,
                    leverage: nil,
                    limitPrice: nil,
                    stopPrice: nil,
                    timeInForce: .goodTillCanceled
                )
            )
        ]
    }
    
    func manualOrder(_ orderRequest: OrderRequest) async throws -> OrderFill {
        // Convert OrderRequest to TradeRequest for internal processing
        // Calculate quantity from the order request
        let quantity = orderRequest.calculateQuantity(
            currentPrice: 50000.0, // Default price for calculation
            equity: 10000.0, // Default equity
            stopDistance: nil
        )
        
        let tradeRequest = TradeRequest(
            symbol: orderRequest.pair.symbol,
            side: orderRequest.side == .buy ? .buy : .sell,
            amount: quantity,
            price: orderRequest.limitPrice ?? 0.0, // Use limit price or 0 for market
            type: orderRequest.limitPrice != nil ? .limit : .market,
            timeInForce: .goodTillCanceled
        )
        
        // Execute the trade
        let result = try await executeTrade(tradeRequest)
        
        // Convert result to OrderFill
        return OrderFill(
            pair: orderRequest.pair,
            side: orderRequest.side,
            quantity: quantity,
            price: result.executedPrice,
            orderType: orderRequest.type,
            originalRequest: orderRequest
        )
    }
}

// MARK: - Supporting Types

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

// MARK: - Helper Methods for Enhanced Integration
extension TradeManager {
    
    // Calculate execution price with realistic spread simulation
    private func calculateExecutionPrice(request: TradeRequest, tradingMode: TradingMode) -> Double {
        let basePrice = request.price
        
        switch tradingMode {
        case .demo:
            // Demo mode: Add some random variation for realism
            return basePrice + Double.random(in: -basePrice * 0.001...basePrice * 0.001) // ±0.1% variation
        case .paper:
            // Paper trading: Use market price with minimal spread
            let spread = basePrice * 0.0005 // 0.05% spread
            return request.side == .buy ? basePrice + spread : basePrice - spread
        case .live:
            // Live trading: Would use actual exchange prices
            let spread = basePrice * 0.001 // 0.1% spread
            return request.side == .buy ? basePrice + spread : basePrice - spread
        }
    }
    
    // Calculate trading fee based on trading mode
    private func calculateTradingFee(amount: Double, price: Double) -> Double {
        let notionalValue = amount * price
        
        switch settings.demoMode {
        case true:
            return notionalValue * 0.001 // 0.1% demo fee
        case false:
            if settings.paperTrading {
                return notionalValue * 0.001 // 0.1% paper trading fee
            } else {
                return notionalValue * 0.002 // 0.2% live trading fee
            }
        }
    }
    
    // Update position after trade execution
    private func updatePositionAfterTrade(orderFill: OrderFill, tradingMode: TradingMode) async {
        let positionChange = orderFill.side == .buy ? orderFill.quantity : -orderFill.quantity
        
        if let existingPosition = currentPosition {
            let newQuantity = existingPosition.quantity + positionChange
            
            if abs(newQuantity) < 0.000001 { // Close to zero - position closed
                currentPosition = nil
            } else {
                // Update average price calculation
                let totalValue = existingPosition.quantity * existingPosition.averagePrice + positionChange * orderFill.price
                let averagePrice = newQuantity != 0 ? totalValue / newQuantity : orderFill.price
                
                currentPosition = TradingPosition(
                    id: existingPosition.id,
                    symbol: orderFill.pair.symbol,
                    quantity: newQuantity,
                    averagePrice: averagePrice,
                    currentPrice: orderFill.price,
                    timestamp: Date()
                )
            }
        } else if positionChange != 0 {
            // Create new position
            currentPosition = TradingPosition(
                id: UUID().uuidString,
                symbol: orderFill.pair.symbol,
                quantity: positionChange,
                averagePrice: orderFill.price,
                currentPrice: orderFill.price,
                timestamp: Date()
            )
        }
        
        // Update equity by subtracting fees
        equity -= orderFill.fee
        
        // Ensure equity doesn't go negative in demo mode
        if tradingMode == .demo && equity < 0 {
            equity = 100.0 // Reset to minimum demo balance
        }
    }
}