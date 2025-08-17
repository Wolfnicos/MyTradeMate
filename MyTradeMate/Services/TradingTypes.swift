import Foundation

public enum Timeframe: String, CaseIterable {
    case m5 = "5m", h1 = "1h", h4 = "4h"
}

public enum TradeSide: String { 
    case buy = "BUY", sell = "SELL", hold = "HOLD" 
}

public struct PerTFSignal: Sendable {
    public let timeframe: Timeframe
    public let side: TradeSide
    public let pUI: Double          // 0.50 ... 0.90 (already clamped)
    public let uncertainty: Double  // 0 ... 1
    public let gatePass: Bool
    
    public init(timeframe: Timeframe, side: TradeSide, pUI: Double, uncertainty: Double, gatePass: Bool) {
        self.timeframe = timeframe
        self.side = side
        self.pUI = pUI
        self.uncertainty = uncertainty
        self.gatePass = gatePass
    }
}

