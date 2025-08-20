import Foundation

public enum JSONExporter {
    public static func export<T: Encodable>(_ value: T, fileName: String) async throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(value)
        
        guard !data.isEmpty else {
            throw ExportError.noData
        }
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName)_\(Int(Date().timeIntervalSince1970)).json")
        
        try data.write(to: url, options: .atomic)
        return url
    }
    
    public static func exportFills(_ fills: [OrderFill], fileName: String = "trades") async throws -> URL {
        guard !fills.isEmpty else {
            throw ExportError.noData
        }
        
        return try await export(fills, fileName: fileName)
    }
}
