import Foundation

public enum Timeframe: String, Codable, CaseIterable, Sendable {
    case m1  = "m1"   // NEW - 1 minute
    case m5  = "m5"
    case m15 = "m15"  // NEW - 15 minutes
    case h1  = "h1"
    case h4  = "h4"
    case d1  = "d1"   // NEW - 1 day
    
    var seconds: TimeInterval {
        switch self {
        case .m1: return 1 * 60      // NEW
        case .m5: return 5 * 60
        case .m15: return 15 * 60    // NEW
        case .h1: return 60 * 60
        case .h4: return 4 * 60 * 60
        case .d1: return 24 * 60 * 60 // NEW
        }
    }
    
    var maxPoints: Int {
        switch self {
        case .m1: return 200    // NEW - More points for shorter timeframe
        case .m5: return 100
        case .m15: return 100   // NEW
        case .h1: return 100  
        case .h4: return 100
        case .d1: return 100    // NEW
        }
    }
    
    var displayName: String {
        switch self {
        case .m1: return "1m"   // NEW
        case .m5: return "5m"
        case .m15: return "15m" // NEW
        case .h1: return "1h"
        case .h4: return "4h"
        case .d1: return "1d"   // NEW
        }
    }
}
