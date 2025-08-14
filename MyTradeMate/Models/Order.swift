import Foundation

enum OrderSide {
    case buy
    case sell
}

struct OrderRequest {
    let symbol: String
    let qty: Double
    let side: OrderSide
    let price: Double?
}

struct OrderFill {
    let orderId: String
    let executedQty: Double
    let avgPrice: Double
    let time: Date
}