import Foundation

public enum PredictionMode { 
    case normal, precision 
}

public struct ModeProcessingResult: Sendable {
    public let finalSide: TradeSide
    public let notes: [String]
    
    public init(finalSide: TradeSide, notes: [String] = []) {
        self.finalSide = finalSide
        self.notes = notes
    }
}

public protocol ModeEngine {
    func combine(frames: [PerTFSignal], mode: PredictionMode) -> ModeProcessingResult
}

/// Implements the consensus/thresholds from the mega spec (simplified but safe).
public final class SimpleModeEngine: ModeEngine {
    public init() {}
    
    public func combine(frames: [PerTFSignal], mode: PredictionMode) -> ModeProcessingResult {
        let pMin = (mode == .precision ? 0.70 : 0.60)
        let uMax = (mode == .precision ? 0.40 : 0.60)
        
        // Filter to eligible frames (pass gate, prob >= pMin, uncertainty <= uMax)
        let eligible = frames.filter { $0.gatePass && $0.pUI >= pMin && $0.uncertainty <= uMax }
        
        guard !eligible.isEmpty else { 
            return ModeProcessingResult(finalSide: .hold, notes: ["no eligible frames"]) 
        }
        
        // Votes
        func vote(_ s: TradeSide) -> Int { 
            s == .buy ? 1 : (s == .sell ? -1 : 0) 
        }
        let sum = eligible.reduce(0) { $0 + vote($1.side) }
        
        if mode == .precision {
            // Require 5m & 1h agreement; 4h can be HOLD or same side
            let m5 = eligible.first { $0.timeframe == .m5 }?.side ?? .hold
            let h1 = eligible.first { $0.timeframe == .h1 }?.side ?? .hold
            let h4 = eligible.first { $0.timeframe == .h4 }?.side ?? .hold
            
            if m5 == .buy && h1 == .buy && h4 != .sell { 
                return .init(finalSide: .buy) 
            }
            if m5 == .sell && h1 == .sell && h4 != .buy { 
                return .init(finalSide: .sell) 
            }
            return .init(finalSide: .hold, notes: ["no consensus"])
        } else {
            // Normal: majority vote among eligible
            if sum > 0 { return .init(finalSide: .buy) }
            if sum < 0 { return .init(finalSide: .sell) }
            return .init(finalSide: .hold, notes: ["tie"])
        }
    }
}