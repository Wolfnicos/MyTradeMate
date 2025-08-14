import Foundation

actor SignalEngine {
    static let shared = SignalEngine()
    
    private init() {}
    
    // MARK: - Scoring Methods
    
    func score5m(candles: [Candle]) -> Double {
        // Placeholder model: Simple moving average slope
        guard candles.count >= 20 else { return 0 }
        
        let ma5 = sma(candles.suffix(5).map(\.close))
        let ma20 = sma(candles.suffix(20).map(\.close))
        
        // Normalize to -1..+1 range
        let diff = ma5 - ma20
        let normalizedDiff = min(max(diff / ma20, -1), 1)
        
        return normalizedDiff
    }
    
    func score1h(candles: [Candle]) -> Double {
        // Similar to 5m but with different parameters
        guard candles.count >= 50 else { return 0 }
        
        let ma10 = sma(candles.suffix(10).map(\.close))
        let ma50 = sma(candles.suffix(50).map(\.close))
        
        let diff = ma10 - ma50
        let normalizedDiff = min(max(diff / ma50, -1), 1)
        
        return normalizedDiff
    }
    
    func score4h(candles: [Candle]) -> Double {
        // Similar to 1h but with longer lookback
        guard candles.count >= 100 else { return 0 }
        
        let ma20 = sma(candles.suffix(20).map(\.close))
        let ma100 = sma(candles.suffix(100).map(\.close))
        
        let diff = ma20 - ma100
        let normalizedDiff = min(max(diff / ma100, -1), 1)
        
        return normalizedDiff
    }
    
    func makeSignal(c5m: Double, c1h: Double, c4h: Double) -> Signal {
        // Ensemble weights: 4h 50%, 1h 35%, 5m 15%
        let scores = [
            ModelScore(timeframe: "5m", score: c5m),
            ModelScore(timeframe: "1h", score: c1h),
            ModelScore(timeframe: "4h", score: c4h)
        ]
        
        // Require 4h and 1h to agree
        let isStrongBull = c4h > 0.2 && c1h > 0.2
        let isStrongBear = c4h < -0.2 && c1h < -0.2
        
        // Calculate weighted score
        let weightedScore = (c4h * 0.5) + (c1h * 0.35) + (c5m * 0.15)
        
        // Determine action and confidence
        let action: SignalAction
        let confidence: Double
        
        if isStrongBull {
            action = .buy
            confidence = min(abs(weightedScore), 1)
        } else if isStrongBear {
            action = .sell
            confidence = min(abs(weightedScore), 1)
        } else {
            action = .hold
            confidence = 0.5
        }
        
        return Signal(
            scores: scores,
            confidence: confidence,
            action: action
        )
    }
    
    // MARK: - Private Methods
    
    private func sma(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}

// MARK: - ML Model Protocol (for future use)

protocol TradingModel {
    func predict(candles: [Candle]) -> Double
}

// Example CoreML model adapter (to be implemented)
/*
class CoreMLTradingModel: TradingModel {
    func predict(candles: [Candle]) -> Double {
        // TODO: Implement CoreML model prediction
        return 0
    }
}
*/