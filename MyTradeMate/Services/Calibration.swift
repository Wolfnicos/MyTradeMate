import Foundation

public protocol CalibrationEvaluator {
    /// Returns calibrated probability in [0,1] for a raw model score.
    func calibrate(raw: Double, timeframe: Timeframe) -> Double
}

/// Minimal temperature-scaling fallback. Replace with learned T/isotonic later.
public final class SimpleCalibrationEvaluator: CalibrationEvaluator {
    public var temperature: [Timeframe: Double] = [.m5: 2.0, .h1: 2.0, .h4: 2.0]
    
    public init() {}
    
    public func calibrate(raw: Double, timeframe: Timeframe) -> Double {
        let T = max(0.5, temperature[timeframe] ?? 2.0)
        let x = raw / T
        let p = 1.0 / (1.0 + exp(-x))
        // UI band clamp 0.50...0.90 happens elsewhere; return true prob here.
        return min(max(p, 0.0), 1.0)
    }
}