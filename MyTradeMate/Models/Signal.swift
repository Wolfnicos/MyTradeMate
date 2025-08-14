import Foundation

public enum SignalType: String, Codable, Sendable {
    case buy, sell, hold
}

public enum SignalAction: String, Codable, Sendable {
    case buy, sell, hold
}

public struct ModelScore: Codable, Sendable {
    public let timeframe: String
    public let score: Double
    
    public init(timeframe: String, score: Double) {
        self.timeframe = timeframe
        self.score = score
    }
}

public struct Signal: Codable, Sendable {
    public let symbol: Symbol?
    public let timeframe: Timeframe?
    public let type: SignalType?
    public let confidence: Double   // 0..1
    public let modelName: String?    // e.g., "AI-5m", "AI-1h", "AI-4h"
    public let timestamp: Date?
    public let scores: [ModelScore]?
    public let action: SignalAction?
    
    public init(symbol: Symbol? = nil, timeframe: Timeframe? = nil, type: SignalType? = nil, confidence: Double, modelName: String? = nil, timestamp: Date? = nil, scores: [ModelScore]? = nil, action: SignalAction? = nil) {
        self.symbol = symbol
        self.timeframe = timeframe
        self.type = type
        self.confidence = confidence
        self.modelName = modelName
        self.timestamp = timestamp
        self.scores = scores
        self.action = action
    }
}