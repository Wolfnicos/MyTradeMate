import Foundation
import SwiftUI
import Combine

/// Main trading engine facade that provides a clean interface for all trading operations
@MainActor
public final class TradingEngine: ObservableObject {
    public static let shared = TradingEngine()
    
    // MARK: - Published Properties
    @Published public private(set) var currentMode: TradingMode
    @Published public private(set) var isExecutingTrade = false
    @Published public private(set) var activeOrders: [Order] = []
    
    // MARK: - Dependencies
    private let tradeManager = TradeManager.shared
    private let settings: AppSettings
    private let orderTracker = OrderStatusTracker.shared
    
    // MARK: - Configuration
    public struct TradingConfig {
        let feeBps: Double // Basis points (0.1% = 10 bps)
        let slippageBps: Double
        let maxSlippageAmount: Double
        
        static let defaultPaper = TradingConfig(
            feeBps: 10.0, // 0.1% fee
            slippageBps: 5.0, // 0.05% slippage
            maxSlippageAmount: 50.0 // Max $50 slippage per trade
        )
        
        static let defaultLive = TradingConfig(
            feeBps: 10.0,
            slippageBps: 2.0, // Lower slippage for live trading
            maxSlippageAmount: 100.0
        )
    }
    
    private var config: TradingConfig {
        switch currentMode {
        case .demo, .paper:
            return .defaultPaper
        case .live:
            return .defaultLive
        }
    }
    
    private init() {
        self.settings = AppSettings.shared
        self.currentMode = settings.tradingMode
        
        // Observe trading mode changes
        NotificationCenter.default.addObserver(
            forName: .tradingModeChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let newMode = notification.object as? TradingMode {
                self?.currentMode = newMode
            }
        }
    }
    
    // MARK: - Order Management
    
    /// Place a market order using OrderRequest with AmountMode calculation
    public func placeOrder(_ request: OrderRequest) async throws -> OrderFill {
        
        guard !isExecutingTrade else {
            throw AppError.tradeExecutionFailed(details: "Another trade is already in progress")
        }
        
        isExecutingTrade = true
        defer { isExecutingTrade = false }
        
        // Calculate quantity based on AmountMode
        let currentPrice = await MarketPriceCache.shared.lastPrice
        let currentEquity = await tradeManager.equity
        let stopDistance = currentPrice * 0.02 // 2% ATR approximation for risk-based sizing
        
        let quantity = request.calculateQuantity(
            currentPrice: currentPrice,
            equity: currentEquity,
            stopDistance: stopDistance
        )
        
        Log.trading.info("[TRADING] Placing \(request.side.rawValue) order: \(String(format: "%.6f", quantity)) \(request.pair.symbol) (\(request.amountMode.displayName): \(String(format: "%.2f", request.amountValue)))")
        
        do {
            let orderRequest = OrderRequest(
                symbol: Symbol(raw: request.pair.symbol),
                side: request.side,
                quantity: quantity,
                type: .market,
                price: nil
            )
            
            // Apply fees and slippage for paper/demo mode
            let adjustedFill = try await executeWithFeesAndSlippage(orderRequest)
            
            Log.trading.info("[TRADING] Order filled: \(adjustedFill.side.rawValue) \(String(format: "%.6f", adjustedFill.quantity)) at $\(String(format: "%.2f", adjustedFill.price))")
            
            return adjustedFill
            
        } catch {
            Log.trading.error("[TRADING] Order failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Place a market order with proper fee and slippage calculation (legacy method)
    public func placeOrder(
        symbol: Symbol,
        side: OrderSide,
        quantity: Double,
        type: OrderType = .market,
        price: Double? = nil
    ) async throws -> OrderFill {
        
        guard !isExecutingTrade else {
            throw AppError.tradeExecutionFailed(details: "Another trade is already in progress")
        }
        
        isExecutingTrade = true
        defer { isExecutingTrade = false }
        
        Log.trading.info("🔄 Placing \(side.rawValue) order: \(quantity) \(symbol.raw)")
        
        do {
            let orderRequest = OrderRequest(
                symbol: symbol,
                side: side,
                quantity: quantity,
                type: type,
                price: price
            )
            
            // Apply fees and slippage for paper/demo mode
            let adjustedFill = try await executeWithFeesAndSlippage(orderRequest)
            
            Log.trading.info("✅ Order filled: \(adjustedFill.side.rawValue) \(adjustedFill.quantity) at \(adjustedFill.price)")
            
            return adjustedFill
            
        } catch {
            Log.trading.error("❌ Order failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Cancel an active order
    public func cancelOrder(id: UUID) async throws {
        Log.trading.info("🔄 Cancelling order: \(id)")
        
        // Find the order
        guard let order = activeOrders.first(where: { $0.id == id }) else {
            throw AppError.orderNotFound(id: id.uuidString)
        }
        
        // Update order status
        await orderTracker.updateOrderStatus(id, .cancelled)
        
        // Remove from active orders
        activeOrders.removeAll { $0.id == id }
        
        Log.trading.info("✅ Order cancelled: \(id)")
    }
    
    /// Get current positions for a symbol
    public func positionsFor(symbol: Symbol) async -> Position? {
        let currentPosition = await tradeManager.position
        
        if let position = currentPosition, position.symbol.raw == symbol.raw {
            return position
        }
        
        return nil
    }
    
    /// Get current account equity
    public var equity: Double {
        get async {
            await tradeManager.equity
        }
    }
    
    /// Get unrealized P&L for current position
    public func unrealizedPnL(marketPrice: Double) async -> Double {
        if let position = await tradeManager.position {
            return position.unrealizedPnL(mark: marketPrice)
        }
        return 0.0
    }
    
    // MARK: - Private Implementation
    
    private func executeWithFeesAndSlippage(_ request: OrderRequest) async throws -> OrderFill {
        switch currentMode {
        case .demo:
            return try await executeDemoOrder(request)
        case .paper:
            return try await executePaperOrder(request)
        case .live:
            return try await executeLiveOrder(request)
        }
    }
    
    private func executeDemoOrder(_ request: OrderRequest) async throws -> OrderFill {
        // Demo mode: simulate realistic execution with delays
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...800_000_000)) // 0.2-0.8s
        
        let basePrice = await MarketPriceCache.shared.lastPrice
        let slippage = calculateSlippage(basePrice: basePrice, quantity: request.quantity)
        let fee = calculateFee(quantity: request.quantity, price: basePrice)
        
        let executionPrice = applySlippage(basePrice: basePrice, side: request.side, slippage: slippage)
        
        Log.trading.debug("📊 Demo execution: base=\(basePrice), slippage=\(slippage), fee=\(fee)")
        
        return OrderFill(
            symbol: request.symbol,
            side: request.side,
            quantity: request.quantity,
            price: executionPrice,
            timestamp: Date()
        )
    }
    
    private func executePaperOrder(_ request: OrderRequest) async throws -> OrderFill {
        // Use real TradeManager for paper trading
        let fill = try await tradeManager.manualOrder(request)
        
        // Apply our fee/slippage model on top
        let adjustedPrice = applyFeeAndSlippage(originalPrice: fill.price, side: request.side, quantity: request.quantity)
        
        return OrderFill(
            id: fill.id,
            symbol: fill.symbol,
            side: fill.side,
            quantity: fill.quantity,
            price: adjustedPrice,
            timestamp: fill.timestamp
        )
    }
    
    private func executeLiveOrder(_ request: OrderRequest) async throws -> OrderFill {
        // Live trading - use exchange client directly
        // For now, this is disabled for safety
        throw AppError.featureNotImplemented(feature: "Live trading is disabled for safety")
    }
    
    private func calculateSlippage(basePrice: Double, quantity: Double) -> Double {
        let slippageBps = config.slippageBps
        let maxSlippage = config.maxSlippageAmount
        
        // Slippage increases with order size
        let volumeMultiplier = min(1.0 + (quantity / 1000.0), 3.0) // Cap at 3x
        let slippageAmount = (basePrice * slippageBps / 10000.0) * volumeMultiplier
        
        return min(slippageAmount, maxSlippage)
    }
    
    private func calculateFee(quantity: Double, price: Double) -> Double {
        let feeBps = config.feeBps
        return (quantity * price * feeBps) / 10000.0
    }
    
    private func applySlippage(basePrice: Double, side: OrderSide, slippage: Double) -> Double {
        switch side {
        case .buy:
            return basePrice + slippage // Pay more when buying
        case .sell:
            return basePrice - slippage // Receive less when selling
        }
    }
    
    private func applyFeeAndSlippage(originalPrice: Double, side: OrderSide, quantity: Double) -> Double {
        let slippage = calculateSlippage(basePrice: originalPrice, quantity: quantity)
        return applySlippage(basePrice: originalPrice, side: side, slippage: slippage)
    }
    
    // MARK: - Account Management
    
    /// Reset paper account to initial state
    public func resetPaperAccount() async {
        guard currentMode != .live else {
            Log.trading.warning("⚠️ Cannot reset live account")
            return
        }
        
        Log.trading.info("🔄 Resetting paper account")
        
        await tradeManager.resetPaperAccount()
        activeOrders.removeAll()
        
        Log.trading.info("✅ Paper account reset complete")
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let tradingModeChanged = Notification.Name("TradingModeChanged")
}

extension AppError {
    static func orderNotFound(id: String) -> AppError {
        .tradeExecutionFailed(details: "Order not found: \(id)")
    }
    
    static func featureNotImplemented(feature: String) -> AppError {
        .invalidConfiguration(component: "\(feature) is not yet implemented")
    }
}

// MARK: - Logging
// Using Log.trading from main Log enum