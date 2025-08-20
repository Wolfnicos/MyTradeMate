import Foundation

/// AI system state enumeration
/// Represents all possible states of the AI prediction engine
public enum AIState: Equatable {
    case running(confidence: Double)
    case paused
    case updating 
    case error(message: String)
    
    // MARK: - Display Properties
    
    var displayName: String {
        switch self {
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .updating:
            return "Updating"
        case .error:
            return "Error"
        }
    }
    
    var systemIconName: String {
        switch self {
        case .running:
            return "brain.head.profile"
        case .paused:
            return "pause.circle"
        case .updating:
            return "arrow.triangle.2.circlepath"
        case .error:
            return "exclamationmark.triangle"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .running:
            return .green
        case .paused:
            return .orange
        case .updating:
            return .blue
        case .error:
            return .red
        }
    }
    
    var confidence: Double? {
        switch self {
        case .running(let confidence):
            return confidence
        default:
            return nil
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .error(let message):
            return message
        default:
            return nil
        }
    }
    
    var isInteractive: Bool {
        switch self {
        case .error:
            return true // Can retry
        default:
            return false
        }
    }
}

/// Complete AI system status
/// Contains state, timing information, and metadata
public struct AIStatus: Equatable {
    public let state: AIState
    public let lastUpdate: Date?
    public let nextRefresh: Date?
    
    public init(
        state: AIState,
        lastUpdate: Date? = nil,
        nextRefresh: Date? = nil
    ) {
        self.state = state
        self.lastUpdate = lastUpdate
        self.nextRefresh = nextRefresh
    }
    
    // MARK: - Computed Properties
    
    /// Time since last update in human readable format
    var lastUpdateString: String {
        guard let lastUpdate = lastUpdate else {
            return "Never updated"
        }
        
        let interval = Date().timeIntervalSince(lastUpdate)
        
        if interval < 5 {
            return "Just now"
        } else if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        }
    }
    
    /// Time until next refresh in human readable format
    var nextRefreshString: String? {
        guard let nextRefresh = nextRefresh else {
            return nil
        }
        
        let interval = nextRefresh.timeIntervalSince(Date())
        
        if interval <= 0 {
            return "Refreshing soon"
        } else if interval < 60 {
            return "in \(Int(interval))s"
        } else {
            let minutes = Int(interval / 60)
            return "in \(minutes)m"
        }
    }
    
    /// Accessibility description for VoiceOver
    var accessibilityDescription: String {
        var description = "AI \(state.displayName.lowercased())"
        
        if let confidence = state.confidence {
            let percentage = Int(confidence * 100)
            description += ". Confidence \(percentage) percent"
        }
        
        if let lastUpdate = lastUpdate {
            let timeAgo = lastUpdateString.replacingOccurrences(of: "ago", with="")
            description += ". Updated \(timeAgo)"
        }
        
        if let errorMessage = state.errorMessage {
            description += ". Error: \(errorMessage)"
        }
        
        return description
    }
}

// MARK: - Convenience Initializers

public extension AIStatus {
    
    /// Create running status with confidence
    static func running(confidence: Double, lastUpdate: Date = Date()) -> AIStatus {
        return AIStatus(
            state: .running(confidence: confidence),
            lastUpdate: lastUpdate,
            nextRefresh: Calendar.current.date(byAdding: .second, value: 30, to: Date())
        )
    }
    
    /// Create paused status
    static func paused(lastUpdate: Date? = nil) -> AIStatus {
        return AIStatus(
            state: .paused,
            lastUpdate: lastUpdate
        )
    }
    
    /// Create updating status
    static func updating() -> AIStatus {
        return AIStatus(
            state: .updating,
            lastUpdate: Date()
        )
    }
    
    /// Create error status with message
    static func error(_ message: String, lastUpdate: Date? = nil) -> AIStatus {
        return AIStatus(
            state: .error(message: message),
            lastUpdate: lastUpdate
        )
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

extension Color {
    /// Status colors for AI states
    static let aiRunning = Color.green
    static let aiPaused = Color.orange
    static let aiUpdating = Color.blue
    static let aiError = Color.red
}