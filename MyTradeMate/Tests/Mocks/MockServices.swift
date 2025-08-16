import Foundation
import Combine

// MARK: - Mock Services for Testing

final class MockKeychainStore: KeychainStoreProtocol {
    private var storage: [String: String] = [:]
    
    func saveAPIKey(_ key: String, for exchange: Exchange) throws {
        storage["apiKey.\(exchange.rawValue)"] = key
    }
    
    func saveAPISecret(_ secret: String, for exchange: Exchange) throws {
        storage["apiSecret.\(exchange.rawValue)"] = secret
    }
    
    func getAPIKey(for exchange: Exchange) throws -> String {
        guard let key = storage["apiKey.\(exchange.rawValue)"] else {
            throw KeychainStore.KeychainError.itemNotFound
        }
        return key
    }
    
    func getAPISecret(for exchange: Exchange) throws -> String {
        guard let secret = storage["apiSecret.\(exchange.rawValue)"] else {
            throw KeychainStore.KeychainError.itemNotFound
        }
        return secret
    }
    
    func deleteCredentials(for exchange: Exchange) throws {
        storage.removeValue(forKey: "apiKey.\(exchange.rawValue)")
        storage.removeValue(forKey: "apiSecret.\(exchange.rawValue)")
    }
    
    func hasCredentials(for exchange: Exchange) async -> Bool {
        return storage["apiKey.\(exchange.rawValue)"] != nil && 
               storage["apiSecret.\(exchange.rawValue)"] != nil
    }
    
    func getExchangeCredentials(for exchange: Exchange) async throws -> ExchangeCredentials {
        let apiKey = try getAPIKey(for: exchange)
        let apiSecret = try getAPISecret(for: exchange)
        return ExchangeCredentials(apiKey: apiKey, apiSecret: apiSecret)
    }
    
    func saveExchangeCredentials(apiKey: String, apiSecret: String, for exchange: Exchange) async throws {
        try saveAPIKey(apiKey, for: exchange)
        try saveAPISecret(apiSecret, for: exchange)
    }
}

@MainActor
final class MockErrorManager: ErrorManagerProtocol {
    @Published var currentError: AppError?
    @Published var errorHistory: [ErrorRecord] = []
    @Published var showErrorAlert = false
    
    func handle(_ error: Error, context: String = "") {
        let appError = AppError.from(error, context: context)
        handle(appError, context: context)
    }
    
    func handle(_ error: AppError, context: String = "") {
        currentError = error
        showErrorAlert = true
        errorHistory.append(ErrorRecord(error: error, context: context))
    }
    
    func clearError() {
        currentError = nil
        showErrorAlert = false
    }
    
    func clearHistory() {
        errorHistory.removeAll()
    }
}

@MainActor
final class MockAppSettings: AppSettingsProtocol {
    @Published var demoMode = true
    @Published var liveMarketData = false
    @Published var defaultSymbol = "BTC/USDT"
    @Published var defaultTimeframe = "5m"
    @Published var darkMode = false
    @Published var verboseAILogs = false
    @Published var autoTrading = false
    @Published var confirmTrades = true
    
    var isDemoPnL: Bool { demoMode }
}

final class MockMarketDataService: MarketDataServiceProtocol {
    func fetchCandles(symbol: String, timeframe: Timeframe) async throws -> [Candle] {
        // Return mock candles
        return generateMockCandles(count: 100)
    }
    
    func fetchTicker(symbol: String) async throws -> Ticker {
        return Ticker(
            symbol: symbol,
            price: 45000.0,
            change: 500.0,
            changePercent: 1.12,
            volume: 1000.0,
            timestamp: Date()
        )
    }
    
    func subscribeToTickers(symbols: [String]) -> AsyncStream<Ticker> {
        return AsyncStream { continuation in
            // Mock ticker stream
            Task {
                for symbol in symbols {
                    let ticker = Ticker(
                        symbol: symbol,
                        price: Double.random(in: 40000...50000),
                        change: Double.random(in: -1000...1000),
                        changePercent: Double.random(in: -5...5),
                        volume: Double.random(in: 100...2000),
                        timestamp: Date()
                    )
                    continuation.yield(ticker)
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                }
                continuation.finish()
            }
        }
    }
    
    private func generateMockCandles(count: Int) -> [Candle] {
        var candles: [Candle] = []
        let basePrice = 45000.0
        
        for i in 0..<count {
            let timestamp = Date().addingTimeInterval(-Double(i * 300))
            let volatility = basePrice * 0.01
            
            let open = basePrice + Double.random(in: -volatility...volatility)
            let close = open + Double.random(in: -volatility/2...volatility/2)
            let high = max(open, close) + Double.random(in: 0...volatility/4)
            let low = min(open, close) - Double.random(in: 0...volatility/4)
            let volume = Double.random(in: 100...1000)
            
            candles.append(Candle(
                openTime: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
        }
        
        return candles.reversed()
    }
}

final class MockAIModelManager: AIModelManagerProtocol {
    var models: [ModelKind: Any] = [:]
    
    func validateModels() async throws {
        // Mock validation - always succeeds
    }
    
    func predictSafely(timeframe: Timeframe, candles: [Candle], mode: TradingMode) async -> PredictionResult? {
        // Mock prediction
        let signals = ["BUY", "SELL", "HOLD"]
        let signal = signals.randomElement() ?? "HOLD"
        let confidence = Double.random(in: 0.5...0.95)
        
        return PredictionResult(
            signal: signal,
            confidence: confidence,
            modelName: "MockModel",
            timestamp: Date()
        )
    }
}

final class MockStrategyManager: StrategyManagerProtocol {
    private var strategies: [TradingStrategy] = []
    
    var availableStrategies: [TradingStrategy] {
        return strategies
    }
    
    var activeStrategies: [TradingStrategy] {
        return strategies.filter { $0.isEnabled }
    }
    
    func addStrategy(_ strategy: TradingStrategy) {
        strategies.append(strategy)
    }
    
    func removeStrategy(withId id: String) {
        strategies.removeAll { $0.id == id }
    }
    
    func enableStrategy(withId id: String) {
        if let index = strategies.firstIndex(where: { $0.id == id }) {
            strategies[index].isEnabled = true
        }
    }
    
    func disableStrategy(withId id: String) {
        if let index = strategies.firstIndex(where: { $0.id == id }) {
            strategies[index].isEnabled = false
        }
    }
    
    func generateSignals(for candles: [Candle]) async -> [StrategySignal] {
        return activeStrategies.compactMap { strategy in
            let directions: [SignalDirection] = [.buy, .sell, .hold]
            let direction = directions.randomElement() ?? .hold
            let confidence = Double.random(in: 0.3...0.9)
            
            return StrategySignal(
                strategyId: strategy.id,
                direction: direction,
                confidence: confidence,
                reason: "Mock signal from \(strategy.name)",
                timestamp: Date()
            )
        }
    }
}

// MARK: - Mock Trading Strategy
struct MockTradingStrategy: TradingStrategy {
    let id: String
    let name: String
    var isEnabled: Bool
    let parameters: [StrategyParameter]
    
    init(id: String = UUID().uuidString, name: String, isEnabled: Bool = false) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.parameters = [
            StrategyParameter(
                id: "period",
                name: "Period",
                type: .integer,
                currentValue: 14,
                defaultValue: 14,
                range: 5...50
            )
        ]
    }
    
    func generateSignal(from candles: [Candle]) async -> StrategySignal {
        let directions: [SignalDirection] = [.buy, .sell, .hold]
        let direction = directions.randomElement() ?? .hold
        let confidence = Double.random(in: 0.3...0.9)
        
        return StrategySignal(
            strategyId: id,
            direction: direction,
            confidence: confidence,
            reason: "Mock signal from \(name)",
            timestamp: Date()
        )
    }
    
    func updateParameter(_ parameter: StrategyParameter, value: Any) throws {
        // Mock parameter update
    }
}