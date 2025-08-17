import Foundation

public struct UncertaintyResult: Sendable {
    public let meanProb: Double   // calibrated mean probability
    public let uncertainty: Double // 0..1 (entropy/ensemble variance normalized)
    
    public init(meanProb: Double, uncertainty: Double) {
        self.meanProb = meanProb
        self.uncertainty = uncertainty
    }
}

public protocol UncertaintyModule {
    func evaluate(calibratedProb p: Double, timeframe: Timeframe) -> UncertaintyResult
}

/// Placeholder: returns given prob and a conservative uncertainty.
public final class SimpleUncertaintyModule: UncertaintyModule {
    public init() {}
    
    public func evaluate(calibratedProb p: Double, timeframe: Timeframe) -> UncertaintyResult {
        // If close to 0.5 → higher uncertainty; farther → lower.
        let u = min(1.0, max(0.0, 2.0 * (0.5 - abs(p - 0.5))))
        return UncertaintyResult(meanProb: p, uncertainty: u)
    }
}