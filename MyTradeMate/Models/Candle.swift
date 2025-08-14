import Foundation

public struct Candle: Identifiable, Hashable, Codable, Sendable {
    public let id = UUID()
    public let openTime: Date
    public let open: Double
    public let high: Double
    public let low: Double
    public let close: Double
    public let volume: Double
    
    public init(openTime: Date, open: Double, high: Double, low: Double, close: Double, volume: Double) {
        self.openTime = openTime
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Candle, rhs: Candle) -> Bool {
        lhs.id == rhs.id
    }
}