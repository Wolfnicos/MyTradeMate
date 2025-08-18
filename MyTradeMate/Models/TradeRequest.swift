import Foundation

// MARK: - Trade Request
public struct TradeRequest: Codable, Identifiable {
    public let id: UUID
    public let symbol: String
    public let side: TradeSide
    public let amount: Double
    public let price: Double
    public let type: OrderType
    public let timeInForce: TimeInForce
    public let timestamp: Date
    
    // NEW - Enhanced properties for complete integration
    public let tradingPair: TradingPair
    public let amountMode: AmountMode
    public let quoteCurrency: QuoteCurrency
    
    // Legacy initializer for compatibility
    public init(symbol: String, side: TradeSide, amount: Double, price: Double, type: OrderType, timeInForce: TimeInForce, id: UUID = UUID()) {
        self.id = id
        self.symbol = symbol
        self.side = side
        self.amount = amount
        self.price = price
        self.type = type
        self.timeInForce = timeInForce
        self.timestamp = Date()
        
        // Default values for new properties
        self.tradingPair = TradingPair.btcUsdt
        self.amountMode = .fixedNotional
        self.quoteCurrency = .USD
    }
    
    // NEW - Enhanced initializer for complete integration
    public init(side: OrderSide, tradingPair: TradingPair, amountMode: AmountMode, amount: Double, price: Double, quoteCurrency: QuoteCurrency, type: OrderType = .market, timeInForce: TimeInForce = .goodTillCanceled, id: UUID = UUID()) {
        self.id = id
        self.symbol = tradingPair.symbol
        self.side = TradeSide(from: side)
        self.amount = amount
        self.price = price
        self.type = type
        self.timeInForce = timeInForce
        self.timestamp = Date()
        
        self.tradingPair = tradingPair
        self.amountMode = amountMode
        self.quoteCurrency = quoteCurrency
    }
    
    public var displayAmount: String {
        String(format: "%.6f", amount)
    }
    
    public var displayPrice: String {
        String(format: "%.2f", price)
    }
    
    public var estimatedValue: Double {
        amount * price
    }
    
    public var displayValue: String {
        String(format: "%.2f", estimatedValue)
    }
}

// MARK: - Trade Side
public enum TradeSide: String, Codable, CaseIterable {
    case buy = "BUY"
    case sell = "SELL"
    
    // NEW - Initialize from OrderSide
    public init(from orderSide: OrderSide) {
        switch orderSide {
        case .buy:
            self = .buy
        case .sell:
            self = .sell
        }
    }
    
    public var displayName: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        }
    }
    
    public var color: Color {
        switch self {
        case .buy: return .green
        case .sell: return .red
        }
    }
}

// MARK: - Order Type
public enum OrderType: String, Codable, CaseIterable {
    case market = "MARKET"
    case limit = "LIMIT"
    case stopLoss = "STOP_LOSS"
    case stopLossLimit = "STOP_LOSS_LIMIT"
    case takeProfit = "TAKE_PROFIT"
    case takeProfitLimit = "TAKE_PROFIT_LIMIT"
    
    public var displayName: String {
        switch self {
        case .market: return "Market"
        case .limit: return "Limit"
        case .stopLoss: return "Stop Loss"
        case .stopLossLimit: return "Stop Loss Limit"
        case .takeProfit: return "Take Profit"
        case .takeProfitLimit: return "Take Profit Limit"
        }
    }
}

// MARK: - Time In Force
public enum TimeInForce: String, Codable, CaseIterable {
    case goodTillCanceled = "GTC"
    case immediateOrCancel = "IOC"
    case fillOrKill = "FOK"
    
    public var displayName: String {
        switch self {
        case .goodTillCanceled: return "Good Till Canceled"
        case .immediateOrCancel: return "Immediate or Cancel"
        case .fillOrKill: return "Fill or Kill"
        }
    }
}

import SwiftUI

// MARK: - TradeSide to OrderSide Conversion
extension TradeSide {
    public var toOrderSide: OrderSide {
        switch self {
        case .buy: return .buy
        case .sell: return .sell
        }
    }
}