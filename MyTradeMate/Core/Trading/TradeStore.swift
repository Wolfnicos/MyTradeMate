import Foundation

struct Trade: Sendable, Identifiable, Equatable {
    enum Side: String, Sendable { case buy, sell }
    let id: UUID
    let date: Date
    let symbol: String
    let side: Side
    let qty: Double
    let price: Double
    let pnl: Double
}

actor TradeStore {
    private var all: [Trade] = []
    
    func append(_ trade: Trade) {
        all.insert(trade, at: 0) // newest first
    }
    
    func fetchTrades(offset: Int, limit: Int) -> [Trade] {
        guard offset < all.count else { return [] }
        let end = min(offset + limit, all.count)
        return Array(all[offset..<end])
    }
}
