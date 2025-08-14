import Foundation

public struct Symbol: Hashable, Codable, Sendable {
    public let raw: String
    public let exchange: Exchange
    
    public init(_ raw: String, exchange: Exchange) {
        self.raw = raw.uppercased()
        self.exchange = exchange
    }
    
    public var display: String { raw }
}
