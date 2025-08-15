import Foundation

public enum Timeframe: String, Codable, CaseIterable, Sendable {
    case m5  = "5m"
    case h1  = "1h"
    case h4  = "4h"
    
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
}
