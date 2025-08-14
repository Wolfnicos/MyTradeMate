import Foundation

public struct PnLMetrics: Codable, Hashable {
    public let trades: Int
    public let wins: Int
    public let losses: Int
    public let winRate: Double       // 0...1
    public let avgTradePnL: Double
    public let avgWin: Double
    public let avgLoss: Double
    public let grossProfit: Double
    public let grossLoss: Double
    public let netPnL: Double
    public let maxDrawdown: Double   // negative number (e.g. -123.45)
}

public enum PnLMetricsAggregator {
    /// Expects fills where `pnl` (realized) is present. If not, treat as 0.
    public static func compute(from fills: [OrderFill]) -> PnLMetrics {
        var wins = 0, losses = 0
        var grossProfit = 0.0, grossLoss = 0.0
        var equity = 0.0
        var peak = 0.0
        var maxDD = 0.0
        
        let pnls = fills.compactMap { ($0 as AnyObject).value(forKey: "pnl") as? Double ?? 0 }
        for p in pnls {
            if p > 0 { wins += 1; grossProfit += p }
            else if p < 0 { losses += 1; grossLoss += p } // negative sum
            equity += p
            peak = max(peak, equity)
            maxDD = min(maxDD, equity - peak) // negative
        }
        
        let trades = pnls.count
        let avgTrade = trades > 0 ? pnls.reduce(0,+)/Double(trades) : 0
        let avgWin = wins > 0 ? grossProfit/Double(wins) : 0
        let avgLoss = losses > 0 ? grossLoss/Double(losses) : 0 // negative
        let winRate = trades > 0 ? Double(wins)/Double(trades) : 0
        let net = grossProfit + grossLoss
        
        return PnLMetrics(
            trades: trades,
            wins: wins,
            losses: losses,
            winRate: winRate,
            avgTradePnL: avgTrade,
            avgWin: avgWin,
            avgLoss: avgLoss,
            grossProfit: grossProfit,
            grossLoss: grossLoss,
            netPnL: net,
            maxDrawdown: maxDD
        )
    }
}
