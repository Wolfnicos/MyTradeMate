import Foundation
import SwiftUI

// MARK: - Signal Info
public struct SignalInfo {
    public let direction: String  // "BUY", "SELL", "HOLD"
    public let confidence: Double // 0-1 (0-100%)
    public let reason: String
    public let timestamp: Date
    
    public init(direction: String, confidence: Double, reason: String, timestamp: Date = Date()) {
        self.direction = direction
        self.confidence = confidence
        self.reason = reason
        self.timestamp = timestamp
    }
}

// MARK: - Signal Direction Enum
public enum SignalDirection: String, CaseIterable {
    case buy = "BUY"
    case sell = "SELL"
    case hold = "HOLD"
    
    public var displayName: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        case .hold: return "Hold"
        }
    }
    
    public var color: Color {
        switch self {
        case .buy: return .green
        case .sell: return .red
        case .hold: return .secondary
        }
    }
}

// MARK: - Signal Strength Enum
public enum SignalStrength: String, CaseIterable {
    case veryWeak = "Very Weak"
    case weak = "Weak"
    case moderate = "Moderate"
    case strong = "Strong"
    case veryStrong = "Very Strong"
    
    public static func from(confidence: Double) -> SignalStrength {
        if confidence >= 0.8 {
            return .veryStrong
        } else if confidence >= 0.6 {
            return .strong
        } else if confidence >= 0.4 {
            return .moderate
        } else if confidence >= 0.2 {
            return .weak
        } else {
            return .veryWeak
        }
    }
    
    public var color: Color {
        switch self {
        case .veryStrong, .strong:
            return .green
        case .moderate:
            return .orange
        case .weak, .veryWeak:
            return .red
        }
    }
}