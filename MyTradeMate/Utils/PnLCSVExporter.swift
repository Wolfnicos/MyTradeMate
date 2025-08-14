import Foundation

public enum PnLCSVExporter {
    public static func exportDaily(_ rows: [DailyPnLRow], fileName: String = "daily_pnl") throws -> URL {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        
        var csv = "day,realized,fees,trades\n"
        for r in rows {
            let dayStr = fmt.string(from: r.day)
            csv += "\(dayStr),\(f8(r.realized)),\(f8(r.fees)),\(r.trades)\n"
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName)_\(Int(Date().timeIntervalSince1970)).csv")
        try csv.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }
    
    private static func f8(_ d: Double) -> String { String(format: "%.8f", d) }
}
