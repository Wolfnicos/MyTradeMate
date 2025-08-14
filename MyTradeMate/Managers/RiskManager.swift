import Foundation
import SwiftUI

@MainActor
public final class RiskManager: ObservableObject {
    public static let shared = RiskManager()
    
    public struct Params: Codable, Sendable {
        public var maxRiskPercentPerTrade: Double = 1.0   // % of equity
        public var maxDailyLossPercent: Double = 5.0      // % of equity
        public var defaultSLPercent: Double = 1.0
        public var defaultTPPercent: Double = 1.5
        public init() {}
    }
    
    public var params = Params()
    private var dailyLossAcc: Double = 0
    
    public func resetDay() { dailyLossAcc = 0 }
    
    public func canTrade(equity: Double) -> Bool {
        dailyLossAcc < (params.maxDailyLossPercent / 100.0 * equity)
    }
    
    public func record(realizedPnL: Double, equity: Double) {
        if realizedPnL < 0 { dailyLossAcc += abs(realizedPnL) }
    }
    
    public func positionSize(equity: Double, entry: Double, stop: Double) -> Double {
        let riskCash = equity * (params.maxRiskPercentPerTrade / 100.0)
        let perUnitRisk = max(0.0001, abs(entry - stop))
        return max(0, riskCash / perUnitRisk)
    }
    
    public func defaultSL(entry: Double, side: OrderSide) -> Double {
        let p = params.defaultSLPercent / 100.0
        return side == .buy ? entry * (1 - p) : entry * (1 + p)
    }
    
    public func defaultTP(entry: Double, side: OrderSide) -> Double {
        let p = params.defaultTPPercent / 100.0
        return side == .buy ? entry * (1 + p) : entry * (1 - p)
    }
}
