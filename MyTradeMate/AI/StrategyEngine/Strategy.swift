import Foundation

// MARK: - Strategy Protocol
public protocol Strategy {
    var name: String { get }
    var description: String { get }
    var isEnabled: Bool { get set }
    var weight: Double { get set }
    
    func signal(candles: [Candle]) -> StrategySignal
    func requiredCandles() -> Int
}

// MARK: - Strategy Signal
public struct StrategySignal {
    public enum Direction {
        case buy, sell, hold
    }
    
    public let direction: Direction
    public let confidence: Double // 0.0 to 1.0
    public let reason: String
    public let timestamp: Date
    public let strategyName: String
    
    public init(direction: Direction, confidence: Double, reason: String, strategyName: String) {
        self.direction = direction
        self.confidence = max(0, min(1, confidence))
        self.reason = reason
        self.timestamp = Date()
        self.strategyName = strategyName
    }
}

// MARK: - Base Strategy
public class BaseStrategy: Strategy {
    public var name: String
    public var description: String
    public var isEnabled: Bool = true
    public var weight: Double = 1.0
    
    public init(name: String, description: String) {
        self.name = name
        self.description = description
    }
    
    public func signal(candles: [Candle]) -> StrategySignal {
        fatalError("Subclasses must implement signal()")
    }
    
    public func requiredCandles() -> Int {
        return 50 // Default minimum
    }
}
