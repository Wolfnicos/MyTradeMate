import Foundation

/// Global app configuration and constants
@globalActor actor AppConfig {
    static let shared = AppConfig()
    
    // MARK: - Default Symbols
    
    let defaultSymbols: [ExchangeID: String] = [
        .binance: "BTCUSDT",
        .kraken: "XBTUSDT"  // Falls back to XBTUSD if USDT pair not available
    ]
    
    // MARK: - Risk Parameters
    
    let maxPositionPct: Double = 0.15     // 15% max position size
    let defaultSL: Double = 0.008         // 0.8% stop loss
    let defaultTP: Double = 0.016         // 1.6% take profit
    let dailyLossBreaker: Double = 0.05   // 5% daily loss limit
    
    // MARK: - Runtime State
    
    private(set) var environment: Environment = .production
    private(set) var isDemoMode = true
    
    private init() {}
    
    // MARK: - Configuration Methods
    
    func setEnvironment(_ env: Environment) {
        environment = env
    }
    
    func setDemoMode(_ isDemo: Bool) {
        isDemoMode = isDemo
    }
}

// MARK: - Supporting Types

extension AppConfig {
    enum Environment {
        case development
        case staging
        case production
    }
}