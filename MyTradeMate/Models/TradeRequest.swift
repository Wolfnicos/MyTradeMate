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
            case .demo:
                return "Demo"
            case .paper:
                return "Paper"
            case .live:
                return "Live"
            }
        }
    }
    
    public var modeColor: Color {
        if isDemo {
            return .orange
        } else {
            switch mode {
            case .demo:
                return .orange
            case .paper:
                return .blue
            case .live:
                return .green
            }
        }
    }
}