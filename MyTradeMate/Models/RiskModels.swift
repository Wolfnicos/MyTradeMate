import Foundation

public struct RiskParams: Codable, Sendable {
    public var maxRiskPercentPerTrade: Double = 1.0   // % of equity
    public var maxDailyLossPercent: Double    = 5.0   // % of equity
    public var defaultSLPercent: Double       = 1.0
    public var defaultTPPercent: Double       = 1.5
    
    public init() {}
}

public struct TrialState: Codable, Sendable {
    public let startDate: Date
    public var days: Int = 3
    
    public init(startDate: Date = Date(), days: Int = 3) {
        self.startDate = startDate
        self.days = days
    }
    
    public var daysRemaining: Int {
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, diff)
    }
    
    public var endDate: Date {
        Calendar.current.date(byAdding: .day, value: days, to: startDate) ?? startDate
    }
    
    public var isActive: Bool {
        Date() < endDate
    }
}
