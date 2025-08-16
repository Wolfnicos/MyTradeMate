import Foundation

public enum ExchangeError: Error, Sendable {
    case invalidResponse
    case networkError(Error)
    case missingCredentials
    case rateLimitExceeded
    case serverError(String)
    case invalidConfiguration
    case securityValidationFailed
}

public protocol ExchangeClient {
    var exchange: Exchange { get }
    func normalized(symbol: Symbol) -> String
    func bestPrice(for symbol: Symbol) async throws -> Double
    func placeMarketOrder(_ req: OrderRequest) async throws -> OrderFill
}
