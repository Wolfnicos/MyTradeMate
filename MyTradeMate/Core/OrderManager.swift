import Foundation

actor OrderManager {
    static let shared = OrderManager()
    enum Side { case buy, sell }
    struct Result { let orderId: String }
    func place(symbol: String, side: Side, qty: Double) async throws -> Result {
        // TODO: integrate real exchange manager
        try await Task.sleep(nanoseconds: 300_000_000)
        return .init(orderId: UUID().uuidString)
    }
}
