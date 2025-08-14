import Foundation

@MainActor
final class SettingsVM: ObservableObject {
    @Published var mode: TradingMode = .paper
    @Published var selectedExchange: Exchange = .binance
    @Published var risk = RiskManager.Params()
    @Published var trial = TrialState()
    
    func applyMode(_ m: TradingMode) { mode = m; Task { await TradeManager.shared.setMode(m) } }
    func applyExchange(_ ex: Exchange) { selectedExchange = ex; Task { await TradeManager.shared.setExchange(ex) } }
    
    func saveRisk() {
        Task { await RiskManager.shared.params = risk }
    }
}