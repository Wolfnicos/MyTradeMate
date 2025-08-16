import Foundation
import SwiftUI

// MARK: - Trade Request Model
public struct TradeRequest {
    public let symbol: String
    public let side: OrderSide
    public let amount: Double
    public let price: Double
    public let mode: TradingMode
    public let isDemo: Bool
    
    public init(
        symbol: String,
        side: OrderSide,
        amount: Double,
        price: Double,
        mode: TradingMode,
        isDemo: Bool
    ) {
        self.symbol = symbol
        self.side = side
        self.amount = amount
        self.price = price
        self.mode = mode
        self.isDemo = isDemo
    }
    
    public var displayMode: String {
        if isDemo {
            return "Demo"
        } else {
            switch mode {
            case .manual:
                return "Manual"
            case .auto:
                return "Auto"
            case .demo:
                return "Demo"
            }
        }
    }
    
    public var modeColor: Color {
        if isDemo {
            return .orange
        } else {
            switch mode {
            case .manual:
                return .blue
            case .auto:
                return .green
            case .demo:
                return .orange
            }
        }
    }
}