import Foundation

struct RiskParams {
    var maxPositionPct: Double
    var defaultSL: Double
    var defaultTP: Double
    var dailyLossBreaker: Double
    
    static let `default` = RiskParams(
        maxPositionPct: 0.15,  // 15% max position
        defaultSL: 0.008,      // 0.8% stop loss
        defaultTP: 0.016,      // 1.6% take profit
        dailyLossBreaker: 0.05 // 5% daily loss limit
    )
}

actor RiskManager {
    var params: RiskParams
    
    init(params: RiskParams = .default) {
        self.params = params
    }
    
    func positionSize(equity: Double, price: Double) -> Double {
        guard price > 0 else { return 0 }
        
        let maxPositionValue = equity * params.maxPositionPct
        return maxPositionValue / price
    }
    
    func circuitBreakerHit(todayPnlPct: Double) -> Bool {
        abs(todayPnlPct) >= params.dailyLossBreaker
    }
    
    func calculateStopLoss(entryPrice: Double, side: OrderSide) -> Double {
        switch side {
        case .buy:
            return entryPrice * (1 - params.defaultSL)
        case .sell:
            return entryPrice * (1 + params.defaultSL)
        }
    }
    
    func calculateTakeProfit(entryPrice: Double, side: OrderSide) -> Double {
        switch side {
        case .buy:
            return entryPrice * (1 + params.defaultTP)
        case .sell:
            return entryPrice * (1 - params.defaultTP)
        }
    }
    
    func validatePosition(size: Double, equity: Double, price: Double) -> Bool {
        let positionValue = size * price
        return positionValue <= (equity * params.maxPositionPct)
    }
    
    func updateParams(_ newParams: RiskParams) {
        // Validate and clamp parameters to safe ranges
        params = RiskParams(
            maxPositionPct: min(max(newParams.maxPositionPct, 0.01), 1.0),
            defaultSL: min(max(newParams.defaultSL, 0.001), 0.1),
            defaultTP: min(max(newParams.defaultTP, 0.001), 0.2),
            dailyLossBreaker: min(max(newParams.dailyLossBreaker, 0.01), 0.2)
        )
    }
}