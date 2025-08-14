import Foundation

public struct DailyPnLRow: Codable, Hashable {
    public let day: Date      // startOfDay (UTC for consistency with exchange data)
    public var realized: Double
    public var fees: Double
    public var trades: Int
}

public enum PnLAggregator {
    /// Aggregate fills into daily realized PnL (and fees), based on `timestamp`
    public static func aggregateDaily(fills: [OrderFill], in calendar: Calendar = .current) -> [DailyPnLRow] {
        var rows: [Date: DailyPnLRow] = [:]
        for f in fills {
            let day = calendar.startOfDay(for: f.timestamp)
            var row = rows[day] ?? DailyPnLRow(day: day, realized: 0, fees: 0, trades: 0)
            
            // Realized PnL (if your Fill already has pnl, use that; otherwise compute elsewhere)
            if let pnl = (f as AnyObject).value(forKey: "pnl") as? Double {
                row.realized += pnl
            }
            if let fee = (f as AnyObject).value(forKey: "fee") as? Double {
                row.fees += fee
            }
            row.trades += 1
            rows[day] = row
        }
        
        return rows.values.sorted { $0.day < $1.day }
    }
}
