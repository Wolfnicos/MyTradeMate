import Foundation
import SwiftUI

// MARK: - AI Core Data Models

public struct SignalDecision: Codable, Sendable {
    public let signal: SignalType
    public let confidence: Double  // 0.0 to 1.0
    public let reasoning: String?
    public let timestamp: Date
    
    public init(signal: SignalType, confidence: Double, reasoning: String? = nil, timestamp: Date = Date()) {
        self.signal = signal
        self.confidence = confidence
        self.reasoning = reasoning
        self.timestamp = timestamp
    }
}

public struct PositionPlan: Codable, Sendable {
    public let quantity: Decimal
    public let stopLoss: Decimal?
    public let takeProfit: Decimal?
    public let maxRisk: Decimal
    public let estimatedCost: Decimal
    public let riskPercentage: Decimal
    
    public init(quantity: Decimal, stopLoss: Decimal? = nil, takeProfit: Decimal? = nil, maxRisk: Decimal, estimatedCost: Decimal, riskPercentage: Decimal) {
        self.quantity = quantity
        self.stopLoss = stopLoss
        self.takeProfit = takeProfit
        self.maxRisk = maxRisk
        self.estimatedCost = estimatedCost
        self.riskPercentage = riskPercentage
    }
}

public struct AIOrderRequest: Codable, Sendable {
    public let symbol: String
    public let side: OrderSide
    public let quantity: Decimal
    public let orderType: RequestOrderType
    public let price: Decimal?
    public let stopLoss: Decimal?
    public let takeProfit: Decimal?
    public let timeInForce: String?
    
    public init(symbol: String, side: OrderSide, quantity: Decimal, orderType: RequestOrderType = .market, price: Decimal? = nil, stopLoss: Decimal? = nil, takeProfit: Decimal? = nil, timeInForce: String? = nil) {
        self.symbol = symbol
        self.side = side
        self.quantity = quantity
        self.orderType = orderType
        self.price = price
        self.stopLoss = stopLoss
        self.takeProfit = takeProfit
        self.timeInForce = timeInForce
    }
}

public enum RequestOrderType: String, Codable, Sendable {
    case market = "MARKET"
    case limit = "LIMIT"
    case stopLoss = "STOP_LOSS"
    case takeProfit = "TAKE_PROFIT"
}

// MARK: - AI Core Protocols

@MainActor
public protocol SignalCore {
    func inferSignal(symbol: String, timeframe: Timeframe, candles: [Candle]) async throws -> SignalDecision
}

@MainActor
public protocol RiskCore {
    func sizePosition(equity: Decimal, price: Decimal, riskPct: Decimal, symbol: String) -> PositionPlan
}

@MainActor
public protocol ExecCore {
    func buildOrder(from plan: PositionPlan, side: OrderSide, symbol: String, price: Decimal) -> AIOrderRequest
}

// MARK: - Mock Implementations

public struct MockSignalCore: SignalCore {
    public static let shared = MockSignalCore()
    public init() {}
    
    public func inferSignal(symbol: String, timeframe: Timeframe, candles: [Candle]) async throws -> SignalDecision {
        // Deterministic mock based on timeframe and recent candle data
        let confidence: Double
        let signal: SignalType
        
        if candles.isEmpty {
            return SignalDecision(signal: .hold, confidence: 0.5, reasoning: "No candle data available")
        }
        
        let recentCandle = candles.last!
        let priceChange = recentCandle.close - recentCandle.open
        
        // Simple mock logic based on timeframe and price movement
        switch timeframe {
        case .m5:
            confidence = min(0.85, abs(priceChange / recentCandle.open) * 100 + 0.3)
            signal = priceChange > 0 ? .buy : (priceChange < 0 ? .sell : .hold)
            
        case .h1:
            confidence = min(0.80, abs(priceChange / recentCandle.open) * 50 + 0.4)
            signal = priceChange > recentCandle.open * 0.01 ? .buy : (priceChange < -recentCandle.open * 0.01 ? .sell : .hold)
            
        case .h4:
            confidence = min(0.75, abs(priceChange / recentCandle.open) * 25 + 0.5)
            signal = priceChange > recentCandle.open * 0.02 ? .buy : (priceChange < -recentCandle.open * 0.02 ? .sell : .hold)
        }
        
        return SignalDecision(
            signal: signal,
            confidence: confidence,
            reasoning: "Mock analysis: \(timeframe.rawValue) timeframe, price change: \(String(format: "%.4f", priceChange))"
        )
    }
}

public struct MockRiskCore: RiskCore {
    public static let shared = MockRiskCore()
    public init() {}
    
    public func sizePosition(equity: Decimal, price: Decimal, riskPct: Decimal, symbol: String) -> PositionPlan {
        let maxRisk = equity * (riskPct / 100)
        let quantity = maxRisk / price * 0.95 // Conservative 95% of max risk
        
        // Simple SL/TP based on 2% and 4% moves
        let stopLoss = price * 0.98
        let takeProfit = price * 1.04
        let estimatedCost = quantity * price
        
        return PositionPlan(
            quantity: quantity,
            stopLoss: stopLoss,
            takeProfit: takeProfit,
            maxRisk: maxRisk,
            estimatedCost: estimatedCost,
            riskPercentage: riskPct
        )
    }
}

public struct MockExecCore: ExecCore {
    public static let shared = MockExecCore()
    public init() {}
    
    public func buildOrder(from plan: PositionPlan, side: OrderSide, symbol: String, price: Decimal) -> AIOrderRequest {
        return AIOrderRequest(
            symbol: symbol,
            side: side,
            quantity: plan.quantity,
            orderType: .market,
            price: nil, // Market order, no price needed
            stopLoss: plan.stopLoss,
            takeProfit: plan.takeProfit,
            timeInForce: "GTC"
        )
    }
}

// MARK: - Legacy Signal Models

public protocol TradingSignalModel: Sendable {
    func signal(symbol: Symbol, mark: Double) async -> Signal
}

public actor M5Model: TradingSignalModel {
    public static let shared = M5Model()
    public func signal(symbol: Symbol, mark: Double) async -> Signal {
        // placeholder heuristic
        let conf = min(0.9, abs(sin(mark/1000)))
        return Signal(
            symbol: symbol,
            timeframe: .m5,
            type: conf > 0.5 ? .buy : .hold,
            confidence: conf,
            modelName: "M5",
            timestamp: Date()
        )
    }
}

public actor H1Model: TradingSignalModel {
    public static let shared = H1Model()
    public func signal(symbol: Symbol, mark: Double) async -> Signal {
        let conf = min(0.9, abs(cos(mark/2000)))
        return Signal(
            symbol: symbol,
            timeframe: .h1,
            type: conf > 0.5 ? .sell : .hold,
            confidence: conf,
            modelName: "H1",
            timestamp: Date()
        )
    }
}

public actor H4Model: TradingSignalModel {
    public static let shared = H4Model()
    public func signal(symbol: Symbol, mark: Double) async -> Signal {
        let conf = min(0.9, abs(sin(mark/3000)))
        return Signal(
            symbol: symbol,
            timeframe: .h4,
            type: conf > 0.6 ? .buy : .sell,
            confidence: conf,
            modelName: "H4",
            timestamp: Date()
        )
    }
}

@MainActor
public final class AIModelManager: ObservableObject {
    public static let shared = AIModelManager()
    
    public enum Mode: String, Codable, Sendable { case normal, precision }
    
    // AI Cores
    private let signalCore: MockSignalCore = MockSignalCore.shared
    private let riskCore: MockRiskCore = MockRiskCore.shared
    private let execCore: MockExecCore = MockExecCore.shared
    
    public func preloadModels() async {
        // Preload all models by accessing their shared instances
        _ = M5Model.shared
        _ = H1Model.shared
        _ = H4Model.shared
    }
    
    public func generateSignal(symbol: Symbol, mark: Double, timeframe: Timeframe, mode: Mode) async -> Signal {
        switch mode {
        case .normal:
            return await model(for: timeframe).signal(symbol: symbol, mark: mark)
        case .precision:
            // Always combine the three horizons
            async let s1 = model(for: .m5).signal(symbol: symbol, mark: mark)
            async let s2 = model(for: .h1).signal(symbol: symbol, mark: mark)
            async let s3 = model(for: .h4).signal(symbol: symbol, mark: mark)
            let signals = await [s1, s2, s3]
            // majority vote; confidence = average of agreeing models
            let buys = signals.filter { $0.type == .buy }
            let sells = signals.filter { $0.type == .sell }
            if buys.count >= 2 {
                let conf = buys.map(\.confidence).reduce(0,+) / Double(buys.count)
                return Signal(
                    symbol: symbol,
                    timeframe: timeframe,
                    type: .buy,
                    confidence: conf,
                    modelName: "Consensus(2/3)",
                    timestamp: Date()
                )
            } else if sells.count >= 2 {
                let conf = sells.map(\.confidence).reduce(0,+) / Double(sells.count)
                return Signal(
                    symbol: symbol,
                    timeframe: timeframe,
                    type: .sell,
                    confidence: conf,
                    modelName: "Consensus(2/3)",
                    timestamp: Date()
                )
            } else {
                return Signal(
                    symbol: symbol,
                    timeframe: timeframe,
                    type: .hold,
                    confidence: 0.5,
                    modelName: "Consensus(2/3)",
                    timestamp: Date()
                )
            }
        }
    }
    
    private func model(for tf: Timeframe) -> any TradingSignalModel {
        switch tf {
        case .m5: return M5Model.shared
        case .h1: return H1Model.shared
        case .h4: return H4Model.shared
        }
    }
    
    // MARK: - AI Core Integration
    
    public func makeDecision(symbol: Symbol, timeframe: Timeframe, candles: [Candle] = []) async throws -> SignalDecision {
        print("📊 AIModelManager: Making decision for \(symbol.raw) on \(timeframe.rawValue)")
        return try await signalCore.inferSignal(symbol: symbol.raw, timeframe: timeframe, candles: candles)
    }
    
    public func planPosition(equity: Decimal, price: Decimal, side: OrderSide, riskPct: Decimal, symbol: Symbol) -> PositionPlan {
        print("⚖️ AIModelManager: Planning position for \(symbol.raw), risk: \(riskPct)%")
        return riskCore.sizePosition(equity: equity, price: price, riskPct: riskPct, symbol: symbol.raw)
    }
    
    public func requestOrder(plan: PositionPlan, side: OrderSide, symbol: Symbol, price: Decimal) -> AIOrderRequest {
        print("📋 AIModelManager: Building order request for \(symbol.raw)")
        return execCore.buildOrder(from: plan, side: side, symbol: symbol.raw, price: price)
    }
}