import Foundation

public struct MetaConfidenceResult: Sendable {
    public let confidence: Double // 0.50 ... 0.90
    
    public init(confidence: Double) { 
        self.confidence = confidence 
    }
}

public protocol MetaConfidenceCalculator {
    func meta(for frames: [PerTFSignal], finalSide: TradeSide) -> MetaConfidenceResult
}

public final class SimpleMetaConfidenceCalculator: MetaConfidenceCalculator {
    public init() {}
    
    public func meta(for frames: [PerTFSignal], finalSide: TradeSide) -> MetaConfidenceResult {
        guard finalSide != .hold else { 
            return .init(confidence: 0.50) 
        }
        
        // weights 0.30 / 0.40 / 0.30
        func w(_ tf: Timeframe) -> Double { 
            tf == .m5 ? 0.30 : (tf == .h1 ? 0.40 : 0.30) 
        }
        
        var agg = 0.0, uSum = 0.0, wSum = 0.0
        for f in frames {
            let sign = (f.side == finalSide ? 1.0 : (f.side == .hold ? 0.0 : -1.0))
            let wi = w(f.timeframe)
            agg += wi * sign * f.pUI
            uSum += f.uncertainty
            wSum += wi
        }
        
        let agreement = tanh(abs(agg / max(wSum, 1e-9)))
        let uAvg = frames.isEmpty ? 0.0 : uSum / Double(frames.count)
        let uncPenalty = min(0.30, 0.50 * uAvg)
        let meta = min(0.90, max(0.50, 0.50 + 0.40 * agreement - uncPenalty))
        
        return .init(confidence: meta)
    }
}