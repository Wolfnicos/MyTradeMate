// Temporarily disabled for build fix
// Original backed up to .backup file
// TODO: Fix and re-enable

import Foundation
import Combine

@MainActor
class TradesVM: ObservableObject {
    @Published var trades: [TradeViewModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tradeStore = TradeStore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            await loadTrades()
        }
    }
    
    func loadTrades() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let allTrades = await tradeStore.fetchTrades(offset: 0, limit: 100)
            trades = allTrades.map { trade in
                TradeViewModel(
                    id: trade.id.uuidString,
                    symbol: trade.symbol,
                    side: trade.side == .buy ? OrderSide.buy : OrderSide.sell,
                    qty: trade.qty,
                    price: trade.price,
                    pnl: trade.pnl,
                    date: trade.date
                )
            }
        } catch {
            errorMessage = "Failed to load trades: \(error.localizedDescription)"
        }
    }
}

struct TradeViewModel: Identifiable {
    let id: String
    let symbol: String
    let side: OrderSide
    let qty: Double
    let price: Double
    let pnl: Double
    let date: Date
}
