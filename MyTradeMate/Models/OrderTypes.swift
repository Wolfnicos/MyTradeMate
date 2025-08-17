import Foundation

/// Amount mode for trade sizing
public enum AmountMode: String, CaseIterable, Codable {
    case fixedNotional = "fixed_notional"    // Fixed dollar/euro amount
    case percentOfEquity = "percent_equity"  // Percentage of account equity
    case riskPercent = "risk_percent"        // Risk-based sizing with stop distance
    
    public var displayName: String {
        switch self {
        case .fixedNotional: return "Fixed"
        case .percentOfEquity: return "% Equity"
        case .riskPercent: return "Risk %"
        }
    }
    
    public var shortName: String {
        switch self {
        case .fixedNotional: return "$"
        case .percentOfEquity: return "%"
        case .riskPercent: return "R%"
        }
    }
    
    public var description: String {
        switch self {
        case .fixedNotional: return "Fixed dollar amount per trade"
        case .percentOfEquity: return "Percentage of account equity"
        case .riskPercent: return "Risk percentage with stop loss"
        }
    }
}

public struct OrderRequest: Codable, Sendable {
    public let symbol: Symbol
    public let side: OrderSide
    public let quantity: Double
    public let limitPrice: Double? // nil = market
    public let stopLoss: Double?
    public let takeProfit: Double?
    
    public init(symbol: Symbol, side: OrderSide, quantity: Double, limitPrice: Double? = nil, stopLoss: Double? = nil, takeProfit: Double? = nil) {
        self.symbol = symbol
        self.side = side
        self.quantity = quantity
        self.limitPrice = limitPrice
        self.stopLoss = stopLoss
        self.takeProfit = takeProfit
    }
}

public struct OrderFill: Identifiable, Codable, Sendable {
    public let id: UUID
    public let symbol: Symbol
    public let side: OrderSide
    public let quantity: Double
    public let price: Double
    public let timestamp: Date
    
    public init(id: UUID = UUID(), symbol: Symbol, side: OrderSide, quantity: Double, price: Double, timestamp: Date) {
        self.id = id
        self.symbol = symbol
        self.side = side
        self.quantity = quantity
        self.price = price
        self.timestamp = timestamp
    }
}
