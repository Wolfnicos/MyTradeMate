import Foundation

public struct SimpleUIDisplayResult: Sendable {
    public let headline: String   // e.g., "SELL (77%)" or "HOLD / Neutral"
    public let detail: String     // compact breakdown line
    
    public init(headline: String, detail: String) {
        self.headline = headline
        self.detail = detail
    }
}

public protocol SimpleUIAdapterProtocol {
    func render(final: TradeSide, meta: Double, frames: [PerTFSignal]) -> SimpleUIDisplayResult
}

public final class SimpleUIAdapter: SimpleUIAdapterProtocol {
    public init() {}
    
    public func render(final: TradeSide, meta: Double, frames: [PerTFSignal]) -> SimpleUIDisplayResult {
        let headline: String
        if final == .hold { 
            headline = "HOLD / Neutral" 
        } else { 
            headline = "\(final.rawValue) (\(Int(round(meta * 100)))%)" 
        }
        
        func fmt(_ f: PerTFSignal) -> String {
            let pct = Int(round(f.pUI * 100))
            let p = f.side == .hold ? "—" : "\(pct)%"
            return "\(f.timeframe.rawValue): \(f.side.rawValue) (\(p))"
        }
        
        let parts = Timeframe.allCases.compactMap { tf in 
            frames.first { $0.timeframe == tf }.map(fmt) 
        }
        let detail = "Models: " + parts.joined(separator: ", ")
        
        return SimpleUIDisplayResult(headline: headline, detail: detail)
    }
}