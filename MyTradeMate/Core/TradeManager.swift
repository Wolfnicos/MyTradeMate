import Foundation

actor TradeManager {
    private let exchange: ExchangeClient
    private let riskManager: RiskManager
    private let trialManager: TrialManager
    
    private var account: Account
    private var todayPnL: Double = 0
    private var position: Position?
    private var isAutoTradingEnabled = false
    private var dayStartEquity: Double = 0
    private var lastResetDate = Date()
    
    init(exchange: ExchangeClient, risk: RiskManager) {
        self.exchange = exchange
        self.riskManager = risk
        self.trialManager = .shared
        self.account = Account(equity: 0, cash: 0, positions: [])
        
        // Start daily reset timer
        Task {
            await resetDailyMetrics()
            await startDailyResetTimer()
        }
    }
    
    // MARK: - Public API
    
    func toggleAutoTrading(_ on: Bool) {
        isAutoTradingEnabled = on
    }
    
    func manualBuy(symbol: String) async throws {
        try await validateAndExecute(
            symbol: symbol,
            side: .buy,
            isAuto: false
        )
    }
    
    func manualSell(symbol: String) async throws {
        try await validateAndExecute(
            symbol: symbol,
            side: .sell,
            isAuto: false
        )
    }
    
    func onSignal(_ signal: Signal, symbol: String) async {
        guard isAutoTradingEnabled,
              await trialManager.canUseAutoTrading(),
              !await riskManager.circuitBreakerHit(todayPnlPct: todayPnLPercent) else {
            return
        }
        
        do {
            switch signal.action {
            case .buy:
                try await validateAndExecute(
                    symbol: symbol,
                    side: .buy,
                    isAuto: true
                )
                
            case .sell:
                try await validateAndExecute(
                    symbol: symbol,
                    side: .sell,
                    isAuto: true
                )
                
            case .hold:
                break
            }
        } catch {
            print("Auto trading error: \(error)")
        }
    }
    
    func loadAccount() async throws -> Account {
        account = try await exchange.account()
        if dayStartEquity == 0 {
            dayStartEquity = account.equity
        }
        return account
    }
    
    // MARK: - Private Methods
    
    private func validateAndExecute(symbol: String, side: OrderSide, isAuto: Bool) async throws {
        // Load latest account state
        account = try await exchange.account()
        
        // Calculate position size
        let size = await riskManager.positionSize(
            equity: account.equity,
            price: try await getCurrentPrice(symbol)
        )
        
        // Validate position
        guard let price = try? await getCurrentPrice(symbol),
              await riskManager.validatePosition(
                size: size,
                equity: account.equity,
                price: price
              ) else {
            throw TradeError.invalidPosition
        }
        
        // Create and execute order
        let request = OrderRequest(
            symbol: symbol,
            qty: size,
            side: side,
            price: nil // Market order
        )
        
        let fill = try await exchange.createOrder(request)
        
        // Update position tracking
        updatePosition(
            symbol: symbol,
            side: side,
            qty: fill.executedQty,
            price: fill.avgPrice
        )
        
        // Place stop loss and take profit orders if supported
        if exchange.supportsPaperTrading() {
            try await placeStopLoss(
                symbol: symbol,
                entryPrice: fill.avgPrice,
                qty: fill.executedQty,
                side: side
            )
            
            try await placeTakeProfit(
                symbol: symbol,
                entryPrice: fill.avgPrice,
                qty: fill.executedQty,
                side: side
            )
        }
        
        // Update P&L
        await updatePnL(fill)
    }
    
    private func getCurrentPrice(_ symbol: String) async throws -> Double {
        // TODO: Get from MarketDataService
        // For now, return placeholder
        return 30000.0
    }
    
    private func updatePosition(symbol: String, side: OrderSide, qty: Double, price: Double) {
        if let existingPosition = position {
            if existingPosition.symbol == symbol {
                let newQty = side == .buy ? 
                    existingPosition.qty + qty :
                    existingPosition.qty - qty
                
                if newQty > 0 {
                    position = Position(
                        symbol: symbol,
                        qty: newQty,
                        avgPrice: price
                    )
                } else {
                    position = nil
                }
            }
        } else if side == .buy {
            position = Position(
                symbol: symbol,
                qty: qty,
                avgPrice: price
            )
        }
    }
    
    private func placeStopLoss(symbol: String, entryPrice: Double, qty: Double, side: OrderSide) async throws {
        let stopPrice = await riskManager.calculateStopLoss(
            entryPrice: entryPrice,
            side: side
        )
        
        let request = OrderRequest(
            symbol: symbol,
            qty: qty,
            side: side == .buy ? .sell : .buy,
            price: stopPrice
        )
        
        _ = try await exchange.createOrder(request)
    }
    
    private func placeTakeProfit(symbol: String, entryPrice: Double, qty: Double, side: OrderSide) async throws {
        let takeProfitPrice = await riskManager.calculateTakeProfit(
            entryPrice: entryPrice,
            side: side
        )
        
        let request = OrderRequest(
            symbol: symbol,
            qty: qty,
            side: side == .buy ? .sell : .buy,
            price: takeProfitPrice
        )
        
        _ = try await exchange.createOrder(request)
    }
    
    private func updatePnL(_ fill: OrderFill) async {
        let pnl = calculatePnL(fill)
        todayPnL += pnl
        
        // Check circuit breaker
        if await riskManager.circuitBreakerHit(todayPnlPct: todayPnLPercent) {
            isAutoTradingEnabled = false
        }
    }
    
    private func calculatePnL(_ fill: OrderFill) -> Double {
        // TODO: Implement P&L calculation
        return 0
    }
    
    private var todayPnLPercent: Double {
        guard dayStartEquity > 0 else { return 0 }
        return todayPnL / dayStartEquity
    }
    
    private func resetDailyMetrics() async {
        todayPnL = 0
        dayStartEquity = try? await loadAccount().equity ?? 0
        lastResetDate = Date()
    }
    
    private func startDailyResetTimer() async {
        // Reset metrics at midnight
        while true {
            let now = Date()
            if !Calendar.current.isDate(lastResetDate, inSameDayAs: now) {
                await resetDailyMetrics()
            }
            try? await Task.sleep(nanoseconds: 60 * NSEC_PER_SEC) // Check every minute
        }
    }
}

// MARK: - Supporting Types

extension TradeManager {
    enum TradeError: Error {
        case invalidPosition
        case insufficientFunds
        case circuitBreakerTriggered
        case exchangeError(Error)
    }
}