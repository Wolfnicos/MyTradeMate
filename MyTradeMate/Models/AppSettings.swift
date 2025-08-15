import Foundation
import Combine
import SwiftUI

// Centralized, shared settings object backed by UserDefaults.
// Works in ViewModels and Views (no @AppStorage required).
@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    private let ud = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    // MARK: Keys
    private struct K {
        static let liveMarketData   = "live_market_data"
        static let demoMode         = "demo_mode"
        static let aiDebugMode      = "ai_debug_mode"
        static let verboseAILogs    = "verbose_ai_logs"
        static let confirmTrades    = "confirm_trades"
        static let pnlDemoMode      = "pnl_demo_mode"
        static let paperTrading     = "paper_trading"       // "auto trading (paper)"
        static let haptics          = "haptics_enabled"
        static let darkMode         = "dark_mode"
        static let defaultTimeframe = "default_timeframe"
        static let defaultSymbol    = "default_symbol"
        static let autoTrading      = "auto_trading"
    }

    // MARK: Published settings (read/write)
    @Published public var liveMarketData: Bool {
        didSet { ud.set(liveMarketData, forKey: K.liveMarketData) }
    }
    @Published public var demoMode: Bool {
        didSet { ud.set(demoMode, forKey: K.demoMode) }
    }
    @Published public var aiDebugMode: Bool {
        didSet { ud.set(aiDebugMode, forKey: K.aiDebugMode) }
    }
    @Published public var verboseAILogs: Bool {
        didSet { ud.set(verboseAILogs, forKey: K.verboseAILogs) }
    }
    @Published public var confirmTrades: Bool {
        didSet { ud.set(confirmTrades, forKey: K.confirmTrades) }
    }
    @Published public var pnlDemoMode: Bool {
        didSet { ud.set(pnlDemoMode, forKey: K.pnlDemoMode) }
    }
    @Published public var paperTrading: Bool {
        didSet { ud.set(paperTrading, forKey: K.paperTrading) }
    }
    @Published public var haptics: Bool {
        didSet { ud.set(haptics, forKey: K.haptics) }
    }
    @Published public var darkMode: Bool {
        didSet { ud.set(darkMode, forKey: K.darkMode) }
    }
    @Published public var defaultTimeframe: String {
        didSet { ud.set(defaultTimeframe, forKey: K.defaultTimeframe) }
    }
    @Published public var defaultSymbol: String {
        didSet { ud.set(defaultSymbol, forKey: K.defaultSymbol) }
    }
    @Published public var autoTrading: Bool {
        didSet { ud.set(autoTrading, forKey: K.autoTrading) }
    }

    // MARK: Computed helpers
    public var isDemoAI: Bool { demoMode }
    public var isDemoPnL: Bool { pnlDemoMode }
    
    // Legacy compatibility properties
    public var liveMarketDataEnabled: Bool {
        get { liveMarketData }
        set { liveMarketData = newValue }
    }
    public var hapticsEnabled: Bool {
        get { haptics }
        set { haptics = newValue }
    }

    // Convert persisted string to enum safely (does not crash if enum changes)
    public func resolvedTimeframe<Fallback: RawRepresentable>(as _: Fallback.Type, fallback: Fallback) -> Fallback where Fallback.RawValue == String {
        Fallback(rawValue: defaultTimeframe) ?? fallback
    }

    private init() {
        liveMarketData   = ud.object(forKey: K.liveMarketData)   as? Bool ?? true
        demoMode         = ud.object(forKey: K.demoMode)         as? Bool ?? true
        aiDebugMode      = ud.object(forKey: K.aiDebugMode)      as? Bool ?? false
        verboseAILogs    = ud.object(forKey: K.verboseAILogs)    as? Bool ?? true
        confirmTrades    = ud.object(forKey: K.confirmTrades)    as? Bool ?? true
        pnlDemoMode      = ud.object(forKey: K.pnlDemoMode)      as? Bool ?? true
        paperTrading     = ud.object(forKey: K.paperTrading)     as? Bool ?? true
        haptics          = ud.object(forKey: K.haptics)          as? Bool ?? true
        darkMode         = ud.object(forKey: K.darkMode)         as? Bool ?? false
        defaultTimeframe = ud.string(forKey: K.defaultTimeframe) ?? "m5"
        defaultSymbol    = ud.string(forKey: K.defaultSymbol)    ?? "BTC/USDT"
        autoTrading      = ud.object(forKey: K.autoTrading)      as? Bool ?? false
    }
}