import Foundation
import Combine
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "TradingManager")

// MARK: - Trading Manager
@MainActor
final class TradingManager: ObservableObject {
    // MARK: - Injected Dependencies
    @Injected private var settings: AppSettingsProtocol
    @Injected private var errorManager: ErrorManagerProtocol
    
    // MARK: - Published Properties
    @Published var tradingMode: TradingMode = .manual
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
        guard !settings.autoTrading else { 
            Log.trade.warning("Manual buy blocked - auto trading is enabled")
            return 
        }
        
        // Haptics.impact(.medium)
        
        if settings.confirmTrades {
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
        guard !settings.autoTrading else { 
            Log.trade.warning("Manual sell blocked - auto trading is enabled")
            return 
        }
        
        // Haptics.impact(.medium)
        
        if settings.confirmTrades {
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
                symbol: Symbol(raw: request.symbol),
                side: request.side,
                quantity: request.amount
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
        guard settings.autoTrading else { return }
        guard tradingMode == .auto else { return }
        
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
        if settings.confirmTrades { // Using confirmTrades as paper trading toggle
            simulatePaperTrade(signal: signal, price: currentPrice)
        } else {
            Log.ai.info("❌ Live trading disabled for safety")
        }
    }
    
    // MARK: - Private Methods
    private func performBuyOrder() async {
        let tradeRequest = TradeRequest(
            symbol: settings.defaultSymbol,
            side: .buy,
            amount: 0.01, // Default amount - should be configurable
            price: 0.0, // Market order
            mode: tradingMode,
            isDemo: settings.demoMode
        )
        
        if settings.demoMode {
            simulateDemoTrade(direction: "BUY")
        } else {
            await executeTradeOrder(tradeRequest)
        }
    }
    
    private func performSellOrder() async {
        let tradeRequest = TradeRequest(
            symbol: settings.defaultSymbol,
            side: .sell,
            amount: 0.01, // Default amount - should be configurable
            price: 0.0, // Market order
            mode: tradingMode,
            isDemo: settings.demoMode
        )
        
        if settings.demoMode {
            simulateDemoTrade(direction: "SELL")
        } else {
            await executeTradeOrder(tradeRequest)
        }
    }
    
    private func simulateDemoTrade(direction: String) {
        Log.trade.info("🎮 Demo Trade: \(direction)")
        
        // Generate mock position
        let mockPosition = Position(
            id: UUID().uuidString,
            symbol: settings.defaultSymbol,
            side: direction == "BUY" ? .buy : .sell,
            quantity: 0.01,
            entryPrice: 45000.0 + Double.random(in: -100...100),
            currentPrice: 45000.0,
            pnl: Double.random(in: -50...50),
            pnlPercent: Double.random(in: -1...1),
            timestamp: Date()
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
            id: UUID().uuidString,
            symbol: settings.defaultSymbol,
            side: orderType == "BUY" ? .buy : .sell,
            quantity: 0.01,
            entryPrice: price,
            currentPrice: price,
            pnl: 0.0,
            pnlPercent: 0.0,
            timestamp: Date()
        )
        
        openPositions.append(mockPosition)
    }
    
    // MARK: - Position Management
    func closePosition(_ position: Position) {
        openPositions.removeAll { $0.id == position.id }
        Log.trade.info("Closed position: \(position.symbol) \(position.side.rawValue)")
    }
    
    func closeAllPositions() {
        let count = openPositions.count
        openPositions.removeAll()
        Log.trade.info("Closed all positions (\(count) positions)")
    }
    
    func updatePositionPnL(currentPrice: Double) {
        for i in openPositions.indices {
            let position = openPositions[i]
            let priceDiff = currentPrice - position.entryPrice
            let pnl = position.side == .buy ? priceDiff : -priceDiff
            let pnlPercent = (pnl / position.entryPrice) * 100
            
            openPositions[i] = Position(
                id: position.id,
                symbol: position.symbol,
                side: position.side,
                quantity: position.quantity,
                entryPrice: position.entryPrice,
                currentPrice: currentPrice,
                pnl: pnl * position.quantity,
                pnlPercent: pnlPercent,
                timestamp: position.timestamp
            )
        }
    }
}

// MARK: - Position Model Extension
extension Position {
    init(id: String, symbol: String, side: OrderSide, quantity: Double, entryPrice: Double, currentPrice: Double, pnl: Double, pnlPercent: Double, timestamp: Date) {
        self.init(
            id: id,
            symbol: symbol,
            side: side,
            quantity: quantity,
            entryPrice: entryPrice,
            currentPrice: currentPrice,
            pnl: pnl,
            pnlPercent: pnlPercent,
            timestamp: timestamp
        )
    }
}