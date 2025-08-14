import Foundation

public struct PnLSnapshot: Sendable {
    public let equity: Double
    public let realizedToday: Double
    public let unrealized: Double
    public let ts: Date
}

public actor PnLManager {
    public static let shared = PnLManager()
    
    private var realizedToday: Double = 0
    private var startOfDay = Calendar.current.startOfDay(for: Date())
    
    public func resetIfNeeded() {
        let sod = Calendar.current.startOfDay(for: Date())
        if sod > startOfDay {
            startOfDay = sod
            realizedToday = 0
        }
    }
    
    public func addRealized(_ v: Double) { realizedToday += v }
    
    public func snapshot(price: Double, position: Position?, equity: Double) -> PnLSnapshot {
        let unrealized: Double
        if let p = position, p.quantity > 0 {
            unrealized = (price - p.avgPrice) * p.quantity
        } else { unrealized = 0 }
        return .init(equity: equity + unrealized,
                    realizedToday: realizedToday,
                    unrealized: unrealized,
                    ts: Date())
    }
}
