import Foundation

public struct Ticker: Sendable, Equatable {
    public let symbol: String
    public let price: Double
    public let ts: Date
}

public protocol ExchangeClient: Sendable {
    var name: String { get }
    var supportsWebSocket: Bool { get }
    func connectTickers(symbols: [String]) async throws
    func disconnectTickers() async
    var tickerStream: AsyncStream<Ticker> { get }
}