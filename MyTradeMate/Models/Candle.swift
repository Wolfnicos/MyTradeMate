import Foundation

struct Candle: Identifiable, Hashable {
    let id = UUID()
    let openTime: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Candle, rhs: Candle) -> Bool {
        lhs.id == rhs.id
    }
}