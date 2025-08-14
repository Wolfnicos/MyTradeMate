import Foundation

@MainActor
final class TradingDashboardViewModel: ObservableObject {
    struct Position: Identifiable {
        let id = UUID()
        let symbol: String
        let qty: Double
        let avgPrice: Double
    }
    @Published var positions: [Position] = []
    func refreshTickers() async {
        // TODO: hook real API
        try? await Task.sleep(nanoseconds: 300_000_000)
        positions = [
            .init(symbol: "BTCUSDT", qty: 0.01, avgPrice: 65000),
            .init(symbol: "ETHUSDT", qty: 0.2,  avgPrice: 3500)
        ]
    }
}
