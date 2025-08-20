import Foundation

// MARK: - Core Service Protocols

protocol KeychainStoreProtocol {
    func saveAPIKey(_ key: String, for exchange: Exchange) async throws
    func saveAPISecret(_ secret: String, for exchange: Exchange) async throws
    func getAPIKey(for exchange: Exchange) async throws -> String
    func getAPISecret(for exchange: Exchange) async throws -> String
    func deleteCredentials(for exchange: Exchange) async throws
    func hasCredentials(for exchange: Exchange) async -> Bool
    func getExchangeCredentials(for exchange: Exchange) async throws -> ExchangeCredentials
    func saveExchangeCredentials(apiKey: String, apiSecret: String, for exchange: Exchange) async throws
}

@MainActor
protocol ErrorManagerProtocol: ObservableObject {
    var currentError: AppError? { get set }
    var errorHistory: [ErrorRecord] { get set }
    var showErrorAlert: Bool { get set }
    
    func handle(_ error: Error, context: String)
    func handle(_ error: AppError, context: String)
    func clearError()
    func clearHistory()
}

@MainActor
protocol AppSettingsProtocol: ObservableObject {
    var demoMode: Bool { get set }
    var liveMarketData: Bool { get set }
    var defaultSymbol: String { get set }
    var defaultTimeframe: String { get set }
    var darkMode: Bool { get set }
    var verboseAILogs: Bool { get set }
    var autoTrading: Bool { get set }
    var confirmTrades: Bool { get set }
    var isDemoPnL: Bool { get }
}

// MARK: - Market Data Service Protocols

protocol MarketDataServiceProtocol {
    func fetchCandles(symbol: String, timeframe: Timeframe) async throws -> [Candle]
    func fetchTicker(symbol: String) async throws -> Ticker
    func subscribeToTickers(symbols: [String]) -> AsyncStream<Ticker>
}


// MARK: - Exchange Client Protocols

protocol ExchangeClientProtocol {
    var name: String { get }
    var supportsWebSocket: Bool { get }
    var exchange: Exchange { get }
    var tickerStream: AsyncStream<Ticker> { get }
    
    func connectTickers(symbols: [String]) async throws
    func disconnectTickers() async throws
    func placeOrder(symbol: String, side: OrderSide, quantity: Double, price: Double?) async throws -> Order
    func getAccountInfo() async throws -> Account
    func getOpenOrders(symbol: String?) async throws -> [Order]
    func cancelOrder(orderId: String, symbol: String) async throws
}

protocol BinanceClientProtocol: ExchangeClientProtocol {}
protocol KrakenClientProtocol: ExchangeClientProtocol {}

// MARK: - Strategy Service Protocols

protocol StrategyManagerProtocol {
    var availableStrategies: [any TradingStrategy] { get async }
    var activeStrategies: [any TradingStrategy] { get async }
    
    func addStrategy(_ strategy: any TradingStrategy) async
    func removeStrategy(withId id: String) async
    func enableStrategy(withId id: String) async
    func disableStrategy(withId id: String) async
    func generateSignals(for candles: [Candle]) async -> [StrategySignal]
}

protocol TradingStrategy {
    var id: String { get }
    var name: String { get }
    var isEnabled: Bool { get set }
    var parameters: [StrategyParameter] { get }
    
    func generateSignal(from candles: [Candle]) async -> StrategySignal
    func updateParameter(_ parameter: StrategyParameter, value: Any) throws
}

// MARK: - WebSocket Service Protocol

protocol WebSocketManagerProtocol {
    var isConnected: Bool { get }
    var connectionStatus: String { get }
    
    func connect(to url: URL) async throws
    func disconnect() async
    func send(_ message: String) async throws
    func messageStream() -> AsyncStream<String>
}

// MARK: - Trade Store Protocol

protocol TradeStoreProtocol {
    func saveTrade(_ trade: Trade) async throws
    func getTrades(limit: Int?) async throws -> [Trade]
    func getTradeById(_ id: String) async throws -> Trade?
    func deleteTrade(_ id: String) async throws
    func getTradeHistory(from: Date, to: Date) async throws -> [Trade]
}

// MARK: - Supporting Types

// struct ExchangeCredentials {
//     let apiKey: String
//     let apiSecret: String
// }

// MARK: - StrategySignal (Ambiguous)

// Ambiguous type, definition moved to AI/StrategyEngine/Strategy.swift
//
// struct StrategySignal {
//     enum Direction {
//         case buy, sell, hold
//     }
//     
//     let direction: Direction
//     let confidence: Double // 0.0 to 1.0
//     let reason: String
//     let timestamp: Date
// }

// struct StrategyParameter {
//     let id: String
//     let name: String
//     let type: ParameterType
//     let currentValue: Any
//     let defaultValue: Any
//     let range: ClosedRange<Double>?
//     
//     enum ParameterType {
//         case integer
//         case double
//         case boolean
//         case string
//     }
// }


// struct ErrorRecord {
//     let error: AppError
//     let context: String?
//     let timestamp: Date
//     
//     init(error: AppError, context: String? = nil) {
//         self.error = error
//         self.context = context
//         self.timestamp = Date()
//     }
// }