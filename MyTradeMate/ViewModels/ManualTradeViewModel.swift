import Foundation

@MainActor
final class ManualTradeViewModel: ObservableObject {
    enum Side { case buy, sell }
    @Published var symbol: String = ""
    @Published var quantity: Double = 0
    @Published var side: Side = .buy
    @Published var status: String?

    var canSubmit: Bool { !symbol.isEmpty && quantity > 0 }

    func placeOrder() async {
        status = "Submitting..."
        // TODO: call OrderManager.shared.place(symbol:side:qty:)
        try? await Task.sleep(nanoseconds: 400_000_000)
        status = "Order submitted (simulated)"
    }
}
