import Foundation

public enum Timeframe: String, Codable, CaseIterable, Sendable {
    case m5  = "m5"
    case h1  = "h1"
    case h4  = "h4"
    
    var seconds: TimeInterval {
        switch self {
        case .m5: return 5 * 60
        case .h1: return 60 * 60
        case .h4: return 4 * 60 * 60
        }
    }
    
    var maxPoints: Int {
        switch self {
        case .m5: return 100
        case .h1: return 100  
        case .h4: return 100
        }
    }
    
    var displayName: String {
        switch self {
        case .m5: return "5m"
        case .h1: return "1h"
        case .h4: return "4h"
        }
    }
}
