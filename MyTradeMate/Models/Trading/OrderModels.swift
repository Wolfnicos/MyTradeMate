import Foundation

/// Order side enumeration
public enum OrderSide: String, CaseIterable, Codable {
    case buy = "buy"
    case sell = "sell"
    
    public var displayName: String {
        return rawValue.uppercased()
    }
    
    public var multiplier: Double {
        switch self {
        case .buy: return 1.0
        case .sell: return -1.0
        }
    }
}

/// Order type enumeration
public enum OrderType: String, CaseIterable, Codable {
    case market = "market"
    case limit = "limit"
    case stop = "stop"
    case stopLimit = "stop_limit"
    
    public var displayName: String {
        switch self {
        case .market: return "Market"
        case .limit: return "Limit"
        case .stop: return "Stop"
        case .stopLimit: return "Stop Limit"
        }
    }
}

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

/// Time in force for orders
public enum TimeInForce: String, CaseIterable, Codable {
    case gtc = "GTC"    // Good Till Canceled
    case ioc = "IOC"    // Immediate Or Cancel
    case fok = "FOK"    // Fill Or Kill
    case day = "DAY"    // Day order
    
    public var displayName: String {
        switch self {
        case .gtc: return "Good Till Canceled"
        case .ioc: return "Immediate Or Cancel"
        case .fok: return "Fill Or Kill"
        case .day: return "Day Order"
        }
    }
}

/// Comprehensive order request with multi-asset support
public struct OrderRequest: Codable {
    public let pair: TradingPair
    public let side: OrderSide
    public let type: OrderType
    public let amountMode: AmountMode
    public let amountValue: Double       // Interpreted based on amountMode
    public let leverage: Double?         // Optional leverage (paper only for now)
    public let limitPrice: Double?       // Required for limit orders
    public let stopPrice: Double?        // Required for stop orders
    public let timeInForce: TimeInForce
    public let timestamp: Date
    
    public init(
        pair: TradingPair,
        side: OrderSide,
        type: OrderType = .market,
        amountMode: AmountMode,
        amountValue: Double,
        leverage: Double? = nil,
        limitPrice: Double? = nil,
        stopPrice: Double? = nil,
        timeInForce: TimeInForce = .gtc
    ) {
        self.pair = pair
        self.side = side
        self.type = type
        self.amountMode = amountMode
        self.amountValue = amountValue
        self.leverage = leverage
        self.limitPrice = limitPrice
        self.stopPrice = stopPrice
        self.timeInForce = timeInForce
        self.timestamp = Date()
    }
    
    /// Calculate order quantity based on amount mode, equity, and current price
    public func calculateQuantity(
        currentPrice: Double,
        equity: Double,
        stopDistance: Double? = nil
    ) -> Double {
        let notional: Double
        
        switch amountMode {
        case .fixedNotional:
            // Direct notional amount in quote currency
            notional = amountValue
            
        case .percentOfEquity:
            // Percentage of current equity
            notional = equity * (amountValue / 100.0)
            
        case .riskPercent:
            // Risk-based sizing: qty = (equity * risk%) / stopDistance
            guard let stopDistance = stopDistance, stopDistance > 0 else {
                // Fallback to 1% of equity if no stop distance
                notional = equity * 0.01
                break
            }
            let riskAmount = equity * (amountValue / 100.0)
            let quantity = riskAmount / stopDistance
            return pair.base.roundQuantity(quantity)
        }
        
        // Convert notional to quantity
        let quantity = notional / currentPrice
        return pair.base.roundQuantity(quantity)
    }
    
    /// Get display string for amount
    public func displayAmount(quote: QuoteCurrency) -> String {
        switch amountMode {
        case .fixedNotional:
            return "\(quote.symbol)\(String(format: "%.2f", amountValue))"
        case .percentOfEquity:
            return "\(String(format: "%.1f", amountValue))%"
        case .riskPercent:
            return "\(String(format: "%.1f", amountValue))% risk"
        }
    }
    
    /// Validate order request
    public func validate() -> OrderValidationResult {
        var errors: [String] = []
        
        // Validate amount
        if amountValue <= 0 {
            errors.append("Amount must be greater than zero")
        }
        
        switch amountMode {
        case .fixedNotional:
            if amountValue < pair.base.minNotional {
                errors.append("Amount below minimum \(pair.formatNotional(pair.base.minNotional))")
            }
        case .percentOfEquity:
            if amountValue > 100 {
                errors.append("Equity percentage cannot exceed 100%")
            }
        case .riskPercent:
            if amountValue > 10 {
                errors.append("Risk percentage should not exceed 10%")
            }
        }
        
        // Validate prices for limit/stop orders
        if type == .limit || type == .stopLimit {
            guard let limitPrice = limitPrice, limitPrice > 0 else {
                errors.append("Limit price required for limit orders")
                return .invalid(errors)
            }
        }
        
        if type == .stop || type == .stopLimit {
            guard let stopPrice = stopPrice, stopPrice > 0 else {
                errors.append("Stop price required for stop orders")
                return .invalid(errors)
            }
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

/// Order validation result
public enum OrderValidationResult {
    case valid
    case invalid([String])
    
    public var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    public var errors: [String] {
        switch self {
        case .valid: return []
        case .invalid(let errors): return errors
        }
    }
}

/// Enhanced order fill with multi-asset support
public struct OrderFill: Codable, Identifiable {
    public let id: UUID
    public let pair: TradingPair
    public let side: OrderSide
    public let quantity: Double
    public let price: Double
    public let fee: Double
    public let timestamp: Date
    public let orderType: OrderType
    public let originalRequest: OrderRequest?
    
    public init(
        id: UUID = UUID(),
        pair: TradingPair,
        side: OrderSide,
        quantity: Double,
        price: Double,
        fee: Double = 0.0,
        timestamp: Date = Date(),
        orderType: OrderType = .market,
        originalRequest: OrderRequest? = nil
    ) {
        self.id = id
        self.pair = pair
        self.side = side
        self.quantity = quantity
        self.price = price
        self.fee = fee
        self.timestamp = timestamp
        self.orderType = orderType
        self.originalRequest = originalRequest
    }
    
    /// Notional value of the fill
    public var notional: Double {
        return quantity * price
    }
    
    /// Signed quantity (negative for sells)
    public var signedQuantity: Double {
        return quantity * side.multiplier
    }
    
    /// Display string for the fill
    public var displayString: String {
        return "\(side.displayName) \(pair.formatQuantity(quantity)) @ \(pair.formatPrice(price))"
    }
}

/// Position for a specific trading pair
public struct Position: Codable, Identifiable {
    public let id: UUID
    public let pair: TradingPair
    public var quantity: Double
    public var averagePrice: Double
    public let openedAt: Date
    public var lastUpdated: Date
    
    public init(
        id: UUID = UUID(),
        pair: TradingPair,
        quantity: Double,
        averagePrice: Double,
        openedAt: Date = Date()
    ) {
        self.id = id
        self.pair = pair
        self.quantity = quantity
        self.averagePrice = averagePrice
        self.openedAt = openedAt
        self.lastUpdated = Date()
    }
    
    /// Whether this is a flat position
    public var isFlat: Bool {
        return abs(quantity) < 0.000001 // Considering precision
    }
    
    /// Whether this is a long position
    public var isLong: Bool {
        return quantity > 0
    }
    
    /// Whether this is a short position
    public var isShort: Bool {
        return quantity < 0
    }
    
    /// Current market value at given price
    public func marketValue(at currentPrice: Double) -> Double {
        return abs(quantity) * currentPrice
    }
    
    /// Unrealized P&L at current price
    public func unrealizedPnL(at currentPrice: Double) -> Double {
        return quantity * (currentPrice - averagePrice)
    }
    
    /// Display string for position
    public var displayString: String {
        let side = isLong ? "LONG" : (isShort ? "SHORT" : "FLAT")
        return "\(side) \(pair.formatQuantity(abs(quantity))) @ \(pair.formatPrice(averagePrice))"
    }
}