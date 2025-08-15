import Foundation

public enum CSVExporter {
    public static func exportFills(_ fills: [OrderFill], fileName: String = "trades") async throws -> URL {
        guard !fills.isEmpty else {
            throw ExportError.noData
        }
        
        let header = "timestamp,symbol,side,qty,price,notional,fee,pnl,note\n"
        let rows = fills.map { f in
            let ts = ISO8601DateFormatter().string(from: f.timestamp)
            let sym = escapeCSV(f.symbol.raw)
            let side = f.side.rawValue
            let qty = f8(f.quantity)
            let price = f8(f.price)
            let notional = f8(f.quantity * f.price)
            let fee: String = {
                if let fee = (f as AnyObject).value(forKey: "fee") as? Double { return f8(fee) }
                return "0.0"
            }()
            let pnl: String = {
                if let pnl = (f as AnyObject).value(forKey: "pnl") as? Double { return f8(pnl) }
                return "0.0"
            }()
            let note = ""  // Optional: add note field to OrderFill if needed
            return "\(ts),\(sym),\(side),\(qty),\(price),\(notional),\(fee),\(pnl),\(note)"
        }.joined(separator: "\n")
        
        let csv = header + rows + "\n"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName)_\(Int(Date().timeIntervalSince1970)).csv")
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        try data.write(to: url, options: .atomic)
        return url
    }
    
    private static func f8(_ d: Double) -> String { String(format: "%.8f", d) }
    
    private static func escapeCSV(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return text
    }
}

public enum ExportError: LocalizedError {
    case noData
    case encodingFailed
    case writeFailed
    
    public var errorDescription: String? {
        switch self {
        case .noData:
            return "No data to export"
        case .encodingFailed:
            return "Failed to encode data"
        case .writeFailed:
            return "Failed to write file"
        }
    }
}