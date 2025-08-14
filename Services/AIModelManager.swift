import Foundation

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

public actor AIModelManager {
    public static let shared = AIModelManager()
    
    public enum Mode: String, Codable, Sendable { case normal, precision }
    
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
}