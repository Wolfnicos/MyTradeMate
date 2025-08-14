import Foundation

struct Ticker: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let price: Double
    let time: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Ticker, rhs: Ticker) -> Bool {
        lhs.id == rhs.id
    }
}