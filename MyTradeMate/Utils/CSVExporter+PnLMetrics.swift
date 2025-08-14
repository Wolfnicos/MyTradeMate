import Foundation

public enum PnLMetricsCSVExporter {
    public static func export(_ m: PnLMetrics, fileName: String = "pnl_metrics") throws -> URL {
        var csv = "trades,wins,losses,win_rate,avg_trade,avg_win,avg_loss,gross_profit,gross_loss,net_pnl,max_drawdown\n"
        csv += "\(m.trades),\(m.wins),\(m.losses),\(f4(m.winRate)),\(f8(m.avgTradePnL)),\(f8(m.avgWin)),\(f8(m.avgLoss)),\(f8(m.grossProfit)),\(f8(m.grossLoss)),\(f8(m.netPnL)),\(f8(m.maxDrawdown))\n"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName)_\(Int(Date().timeIntervalSince1970)).csv")
        try csv.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }
    
    private static func f4(_ d: Double) -> String { String(format: "%.4f", d) }
    private static func f8(_ d: Double) -> String { String(format: "%.8f", d) }
}
