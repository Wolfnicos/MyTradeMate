import Foundation

public enum JSONExporter {
    public static func export<T: Encodable>(_ value: T, fileName: String) throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(value)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName)_\(Int(Date().timeIntervalSince1970)).json")
        try data.write(to: url, options: .atomic)
        return url
    }
}
