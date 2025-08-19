import Foundation
import Combine
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "TradingManager")

// MARK: - Trading Manager
@MainActor
final class TradingManager: ObservableObject {
    // MARK: - Dependencies
    private let errorManager = ErrorManager.shared
    
    // MARK: - Published Properties
    @Published var tradingMode: TradingMode = .demo
    @Published var openPositions: [Position] = []
    @Published var isConnected: Bool = false
    @Published var connectionStatus: String = "Connecting..."
    
    // MARK: - Private Properties
    private var lastAutoTradeTime: Date = .distantPast
    private let autoTradeCooldown: TimeInterval = 60.0 // 60 seconds
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Observe trading mode changes
        $tradingMode
            .removeDuplicates()
            .sink { mode in
                Log.trade.info("Trading mode changed to \(mode.rawValue)")
            }
            .store(in: &cancellables)
        
        // Observe connection status
        NotificationCenter.default.publisher(for: .init("WebSocketStatusChanged"))
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                if let status = notification.object as? Bool {
                    self?.isConnected = status
                    self?.connectionStatus = status ? "Connected" : "Disconnected"
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Trading Actions
    func executeBuy() {
        guard !AppSettings.shared.autoTrading else { 
            Log.trade.warning("Manual buy blocked - auto trading is enabled")
            return 
        }
        
        // Haptics.impact(.medium)
        
        if AppSettings.shared.confirmTrades {
            // Show confirmation dialog
            logger.info("Buy order confirmation required")
        } else {
            // Execute immediately
            logger.info("Executing buy order")
            Task {
                await performBuyOrder()
            }
        }
    }
    
    func executeSell() {
        guard !AppSettings.shared.autoTrading else { 
            Log.trade.warning("Manual sell blocked - auto trading is enabled")
            return 
        }
        
        // Haptics.impact(.medium)
        
        if AppSettings.shared.confirmTrades {
            // Show confirmation dialog
            logger.info("Sell order confirmation required")
        } else {
            // Execute immediately
            logger.info("Executing sell order")
            Task {
                await performSellOrder()
            }
        }
    }
    
    /// Execute a trade order with proper error handling
    func executeTradeOrder(_ request: TradeRequest) async {
        do {
            // Convert TradeRequest to OrderRequest
            let orderRequest = OrderRequest(
                pair: TradingPair(base: Asset.bitcoin, quote: QuoteCurrency.USD), // Convert from symbol later
                side: request.side == .buy ? .buy : .sell,
                amountMode: .fixedNotional,
                amountValue: request.amount
            )
            
            // Execute the order through TradeManager
            let fill = try await TradeManager.shared.manualOrder(orderRequest)
            
            // Show success toast
            await MainActor.run {
                if let toastManager = getToastManager() {
                    toastManager.showTradeExecuted(
                        symbol: request.symbol,
                        side: request.side.rawValue
                    )
                }
            }
            
            Log.trade.info("✅ Order executed successfully: \(request.side.rawValue) \(request.amount) \(request.symbol)")
            
        } catch let error as AppError {
            // Handle AppError with proper error message
            await MainActor.run {
                errorManager.handle(error, context: "Trade execution")
                
                if let toastManager = getToastManager() {
                    toastManager.showTradeExecutionFailed(error: error.localizedDescription)
                }
            }
            
            Log.trade.error("❌ Order execution failed: \(error.localizedDescription)")
            
        } catch {
            // Handle any other errors
            let appError = AppError.tradeExecutionFailed(details: error.localizedDescription)
            await MainActor.run {
                errorManager.handle(appError, context: "Trade execution")
                
                if let toastManager = getToastManager() {
                    toastManager.showTradeExecutionFailed(error: error.localizedDescription)
                }
            }
            
            Log.trade.error("❌ Order execution failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    /// Get toast manager from environment (this would be injected in real implementation)
    private func getToastManager() -> ToastManager? {
        // In a real implementation, this would be injected via dependency injection
        // For now, we'll create a new instance or use a shared one
        return ToastManager()
    }
    
    func handleAutoTrading(signal: SignalInfo, currentPrice: Double) {
        guard AppSettings.shared.autoTrading else { return }
        // Auto trading is already gated by AppSettings.shared.autoTrading check above
        
        // Cooldown check
        let timeSinceLastTrade = Date().timeIntervalSince(lastAutoTradeTime)
        guard timeSinceLastTrade >= autoTradeCooldown else {
            Log.ai.info("Auto trading on cooldown: \(String(format: "%.1f", timeSinceLastTrade))s / \(autoTradeCooldown)s")
            return
        }
        
        // Only act on strong signals
        guard signal.confidence > 0.7 else {
            Log.ai.info("Auto trading: Signal confidence too low (\(String(format: "%.1f", signal.confidence)))")
            return
        }
        
        // Paper trading simulation
        if AppSettings.shared.confirmTrades { // Using confirmTrades as paper trading toggle
            simulatePaperTrade(signal: signal, price: currentPrice)
        } else {
            Log.ai.info("❌ Live trading disabled for safety")
        }
    }
    
    // MARK: - Private Methods
    private func performBuyOrder() async {
        let tradeRequest = TradeRequest(
            symbol: AppSettings.shared.defaultSymbol,
            side: .buy,
            amount: 0.01, // Default amount - should be configurable
            price: 0.0, // Market order
            type: .market,
            timeInForce: .goodTillCanceled
        )
        
        if AppSettings.shared.demoMode {
            simulateDemoTrade(direction: "BUY")
        } else {
            await executeTradeOrder(tradeRequest)
        }
    }
    
    private func performSellOrder() async {
        let tradeRequest = TradeRequest(
            symbol: AppSettings.shared.defaultSymbol,
            side: .sell,
            amount: 0.01, // Default amount - should be configurable
            price: 0.0, // Market order
            type: .market,
            timeInForce: .goodTillCanceled
        )
        
        if AppSettings.shared.demoMode {
            simulateDemoTrade(direction: "SELL")
        } else {
            await executeTradeOrder(tradeRequest)
        }
    }
    
    private func simulateDemoTrade(direction: String) {
        Log.trade.info("🎮 Demo Trade: \(direction)")
        
        // Generate mock position
        let mockPosition = Position(
            pair: TradingPair(base: Asset.bitcoin, quote: QuoteCurrency.USD),
            quantity: 0.01,
            averagePrice: 45000.0 + Double.random(in: -100...100)
        )
        
        openPositions.append(mockPosition)
    }
    
    private func simulatePaperTrade(signal: SignalInfo, price: Double) {
        lastAutoTradeTime = Date()
        
        let orderType = signal.direction
        let confidence = String(format: "%.1f%%", signal.confidence * 100)
        
        Log.ai.info("📝 Paper Trade Simulated: \(orderType) @ \(price) (confidence: \(confidence))")
        Log.ai.info("↳ Reason: \(signal.reason)")
        
        // Generate mock position for paper trading
        let mockPosition = Position(
            pair: TradingPair(base: Asset.bitcoin, quote: QuoteCurrency.USD),
            quantity: orderType == "BUY" ? 0.01 : -0.01,
            averagePrice: price
        )
        
        openPositions.append(mockPosition)
    }
    
    // MARK: - Position Management
    func closePosition(_ position: Position) {
        openPositions.removeAll { $0.pair.symbol == position.pair.symbol }
        Log.trade.info("Closed position: \(position.pair.symbol)")
    }
    
    func closeAllPositions() {
        let count = openPositions.count
        openPositions.removeAll()
        Log.trade.info("Closed all positions (\(count) positions)")
    }
    
    func updatePositionPnL(currentPrice: Double) {
        for i in openPositions.indices {
            let position = openPositions[i]
            let priceDiff = currentPrice - position.averagePrice
            let pnl = priceDiff * position.quantity
            
            // Update position with new price
            openPositions[i] = Position(
                pair: position.pair,
                quantity: position.quantity,
                averagePrice: position.averagePrice
            )
        }
    }
}

// Position extension removed - using Position from Models/Trading/OrderModels.swift