import Foundation

public struct ConformalResult: Sendable {
    public let q05: Double
    public let q95: Double
    public let pass: Bool
    
    public init(q05: Double, q95: Double, pass: Bool) {
        self.q05 = q05
        self.q95 = q95
        self.pass = pass
    }
}

public protocol ConformalGate {
    /// Returns interval and pass/fail given fees & slippage (as fraction of price move).
    func check(timeframe: Timeframe, fees: Double, slippage: Double) -> ConformalResult
}

/// Placeholder: symmetric tiny interval; always pass if interval beats costs.
public final class SimpleConformalGate: ConformalGate {
    public init() {}
    
    public func check(timeframe: Timeframe, fees: Double, slippage: Double) -> ConformalResult {
        let cost = max(0.0005, fees + slippage) // ~5bps default
        // Dummy interval width by timeframe
        let w: Double = (timeframe == .m5 ? 0.002 : timeframe == .h1 ? 0.004 : 0.006)
        let q05 = -w/2, q95 = +w/2
        let pass = (q95 > cost) || (q05 < -cost)
        return ConformalResult(q05: q05, q95: q95, pass: pass)
    }
}