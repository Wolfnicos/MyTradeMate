import Foundation
import OSLog

/// Structured logging system with subsystem categorization
actor Logger {
    static let shared = Logger()
    private let logger: os.Logger
    
    private init() {
        self.logger = os.Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.mytrademate",
            category: "default"
        )
    }
    
    // MARK: - Logging Methods
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.debug("\(message, privacy: .public) [\(file):\(line)]")
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.info("\(message, privacy: .public) [\(file):\(line)]")
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.warning("\(message, privacy: .public) [\(file):\(line)]")
    }
    
    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        if let error = error {
            logger.error("\(message, privacy: .public) - Error: \(error.localizedDescription, privacy: .public) [\(file):\(line)]")
        } else {
            logger.error("\(message, privacy: .public) [\(file):\(line)]")
        }
    }
    
    // MARK: - Trading Specific Logging
    
    func logTrade(symbol: String, action: String, price: Decimal, quantity: Decimal) {
        logger.info("TRADE: \(symbol, privacy: .public) \(action, privacy: .public) - Price: \(price, privacy: .public) Qty: \(quantity, privacy: .public)")
    }
    
    func logSignal(symbol: String, type: String, confidence: Double) {
        logger.info("SIGNAL: \(symbol, privacy: .public) \(type, privacy: .public) - Confidence: \(confidence, privacy: .public)")
    }
    
    func logMarketData(symbol: String, event: String, data: String) {
        logger.debug("MARKET: \(symbol, privacy: .public) \(event, privacy: .public) - \(data, privacy: .public)")
    }
}
