import Foundation

public enum CSVExporter {
    public static func exportFills(_ fills: [OrderFill], fileName: String = "trades") async throws -> URL {
        let header = "timestamp,symbol,side,qty,price,notional,fee,pnl,note\n"
        var rows = fills.map { f in
            let ts = ISO8601DateFormatter().string(from: f.timestamp)
            let sym = f.symbol.raw
            let side = f.side.rawValue
            let qty = Self.f8(f.quantity)
            let price = Self.f8(f.price)
            let notional = Self.f8(f.quantity * f.price)
            let fee: String = {
                if let fee = (f as AnyObject).value(forKey: "fee") as? Double { return Self.f8(fee) }
                return ""
            }()
            let pnl: String = {
                if let pnl = (f as AnyObject).value(forKey: "pnl") as? Double { return Self.f8(pnl) }
                return ""
            }()
            let note = ""  // Optional: add note field to OrderFill if needed
            return "\(ts),\(sym),\(side),\(qty),\(price),\(notional),\(fee),\(pnl),\(note)"
        }.joined(separator: "\n")
        
        let csv = header + rows + (rows.isEmpty ? "" : "\n")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName)_\(Int(Date().timeIntervalSince1970)).csv")
        try csv.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }
    
    private static func f8(_ d: Double) -> String { String(format: "%.8f", d) }
}