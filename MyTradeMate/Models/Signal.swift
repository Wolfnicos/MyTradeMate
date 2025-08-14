import Foundation

public enum SignalType: String, Codable, Sendable {
    case buy, sell, hold
}

public struct Signal: Codable, Sendable {
    public let symbol: Symbol
    public let timeframe: Timeframe
    public let type: SignalType
    public let confidence: Double   // 0..1
    public let modelName: String    // e.g., "AI-5m", "AI-1h", "AI-4h"
    public let timestamp: Date
}