import Foundation

public enum ExchangeError: Error, Sendable {
    case invalidResponse
    case networkError(Error)
    case missingCredentials
    case rateLimitExceeded
    case serverError(String)
}

public protocol ExchangeClient: Sendable {
    var exchange: Exchange { get }
    nonisolated func normalized(symbol: Symbol) -> String
    func bestPrice(for symbol: Symbol) async throws -> Double
    func placeMarketOrder(_ req: OrderRequest) async throws -> OrderFill
}
