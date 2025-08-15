import Foundation

public enum TradingMode: String, CaseIterable, Codable, Sendable {
    case manual
    case auto
    
    // Legacy compatibility for the old paper/live cases
    public static let paper = TradingMode.manual
    public static let live = TradingMode.auto
}

public extension TradingMode {
    var title: String { self == .manual ? "Manual" : "Auto" }
}
