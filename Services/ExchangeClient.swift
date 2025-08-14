import Foundation

public protocol ExchangeClient: Sendable {
    var exchange: Exchange { get }
    func normalized(symbol: Symbol) -> String
    func bestPrice(for symbol: Symbol) async throws -> Double
    func placeMarketOrder(_ req: OrderRequest) async throws -> OrderFill
}
