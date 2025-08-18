import Foundation

public class PredictionLogger {
    public static let shared = PredictionLogger()
    
    private let fileManager = FileManager.default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var logsURL: URL {
        documentsURL.appendingPathComponent("logs")
    }
    
    private init() {
        createLogsDirectoryIfNeeded()
    }
    
    private func createLogsDirectoryIfNeeded() {
        try? fileManager.createDirectory(at: logsURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Prediction Logging
    
    public func logPrediction(_ result: PredictionResult, mode: String, strategies: String? = nil) {
        let csvData = formatPredictionCSV(result, mode: mode, strategies: strategies)
        let jsonData = formatPredictionJSON(result, mode: mode, strategies: strategies)
        
        appendToFile(csvData, fileName: "predictions.csv")
        appendToFile(jsonData, fileName: "predictions.json")
    }
    
    private func formatPredictionCSV(_ result: PredictionResult, mode: String, strategies: String?) -> String {
        let timestamp = ISO8601DateFormatter().string(from: result.timestamp)
        let model = result.modelName
        let signal = result.signal
        let confidence = String(format: "%.4f", result.confidence)
        let strategiesStr = strategies ?? ""
        
        // Create header if file doesn't exist
        let csvFile = logsURL.appendingPathComponent("predictions.csv")
        let needsHeader = !fileManager.fileExists(atPath: csvFile.path)
        
        var csvLine = ""
        if needsHeader {
            csvLine += "timestamp,model,signal,confidence,mode,strategies\n"
        }
        csvLine += "\(timestamp),\(model),\(signal),\(confidence),\(mode),\"\(strategiesStr)\"\n"
        
        return csvLine
    }
    
    private func formatPredictionJSON(_ result: PredictionResult, mode: String, strategies: String?) -> String {
        let logEntry: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: result.timestamp),
            "model": result.modelName,
            "signal": result.signal,
            "confidence": result.confidence,
            "mode": mode,
            "strategies": strategies ?? ""
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: logEntry, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString + "\n"
        }
        return ""
    }
    
    // MARK: - Trade Logging
    
    public func logTrade(_ fill: OrderFill) {
        let csvData = formatTradeCSV(fill)
        appendToFile(csvData, fileName: "trades.csv")
    }
    
    private func formatTradeCSV(_ fill: OrderFill) -> String {
        let csvFile = logsURL.appendingPathComponent("trades.csv")
        let needsHeader = !fileManager.fileExists(atPath: csvFile.path)
        
        var csvLine = ""
        if needsHeader {
            csvLine += "timestamp,symbol,side,quantity,price,notional\n"
        }
        
        let timestamp = ISO8601DateFormatter().string(from: fill.timestamp)
        let symbol = fill.pair.symbol
        let side = fill.side.rawValue
        let qty = String(format: "%.8f", fill.quantity)
        let price = String(format: "%.8f", fill.price)
        let notional = String(format: "%.8f", fill.quantity * fill.price)
        
        csvLine += "\(timestamp),\(symbol),\(side),\(qty),\(price),\(notional)\n"
        return csvLine
    }
    
    // MARK: - File Operations
    
    private func appendToFile(_ content: String, fileName: String) {
        guard !content.isEmpty else { return }
        
        let fileURL = logsURL.appendingPathComponent(fileName)
        
        if let data = content.data(using: .utf8) {
            if fileManager.fileExists(atPath: fileURL.path) {
                // Append to existing file
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                // Create new file
                try? data.write(to: fileURL)
            }
        }
    }
    
    // MARK: - Export Support
    
    public func getLogFiles() -> [URL] {
        let predictionCSV = logsURL.appendingPathComponent("predictions.csv")
        let predictionJSON = logsURL.appendingPathComponent("predictions.json")
        let tradesCSV = logsURL.appendingPathComponent("trades.csv")
        
        return [predictionCSV, predictionJSON, tradesCSV].filter { 
            fileManager.fileExists(atPath: $0.path) 
        }
    }
    
    public func exportLogsToShare() -> [URL] {
        return getLogFiles()
    }
}