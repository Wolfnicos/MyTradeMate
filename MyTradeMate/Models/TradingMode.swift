import Foundation

public enum TradingMode: String, CaseIterable, Codable, Sendable {
    case demo       // Simulated data and orders
    case paper      // Real market data, simulated orders  
    case live       // Real market data and orders
    
    // For UI display
    var title: String {
        switch self {
        case .demo: return "Demo"
        case .paper: return "Paper"
        case .live: return "Live"
        }
    }
    
    var description: String {
        switch self {
        case .demo: return "Synthetic data & simulated trading"
        case .paper: return "Live data & simulated trading"
        case .live: return "Live data & real trading"
        }
    }
    
    var requiresAPIKeys: Bool {
        return self == .live
    }
    
    var allowsRealTrading: Bool {
        return self == .live
    }
}
