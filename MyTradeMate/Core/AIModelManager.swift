import Foundation

enum Signal: String, Sendable { case buy, hold, sell }

actor AIModelManager {
    private var isLoaded = false
    
    func preloadModels() async {
        guard !isLoaded else { return }
        // Load ML models/files from bundle or warm up pipelines here
        try? await Task.sleep(nanoseconds: 300_000_000) // simulate load
        isLoaded = true
    }
    
    func signal(for symbol: String, price: Double, timeframe: TimeInterval) -> Signal {
        // Replace with real models. This is just a placeholder.
        // e.g. 5m = 300s, 1h = 3600s, 4h = 14400s
        return [.buy, .hold, .sell].randomElement()!
    }
    
    func consensusSignal(symbol: String, price: Double) -> Signal {
        let s5 = signal(for: symbol, price: price, timeframe: 300)
        let s1h = signal(for: symbol, price: price, timeframe: 3600)
        let s4h = signal(for: symbol, price: price, timeframe: 14400)
        let votes = [s5, s1h, s4h]
        let buy = votes.filter { $0 == .buy }.count
        let sell = votes.filter { $0 == .sell }.count
        if buy >= 2 { return .buy }
        if sell >= 2 { return .sell }
        return .hold
    }
}
