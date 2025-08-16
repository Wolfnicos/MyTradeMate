import Foundation
import Combine
import SwiftUI

@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    // MARK: - @AppStorage Properties
    @AppStorage("liveMarketData") public var liveMarketData = true
    @AppStorage("demoMode") public var demoMode = true
    @AppStorage("paperTrading") public var paperTrading = true
    @AppStorage("autoTrading") public var autoTrading = false
    @AppStorage("aiDebug") public var aiDebug = true
    @AppStorage("aiVerbose") public var aiVerbose = true
    @AppStorage("pnlDemoMode") public var pnlDemoMode = true
    @AppStorage("defaultSymbol") public var defaultSymbol = "BTC/USDT"
    @AppStorage("defaultTimeframe") public var defaultTimeframe = "m5"
    @AppStorage("themeDark") public var themeDark = false
    @AppStorage("haptics") public var haptics = true
    @AppStorage("confirmTrades") public var confirmTrades = true
    
    // MARK: - Trading Mode
    @AppStorage("tradingMode") private var tradingModeRaw = "demo"
    
    public var tradingMode: TradingMode {
        get {
            TradingMode(rawValue: tradingModeRaw) ?? .demo
        }
        set {
            tradingModeRaw = newValue.rawValue
        }
    }
    
    // MARK: - Computed Helpers
    public var timeframe: Timeframe { 
        Timeframe(rawValue: defaultTimeframe) ?? .m5 
    }
    
    public var isLiveTradingEnabled: Bool { 
        liveMarketData && !demoMode && !paperTrading && autoTrading 
    }
    
    // MARK: - Legacy Compatibility
    public var aiDebugMode: Bool {
        get { aiDebug }
        set { aiDebug = newValue }
    }
    
    public var verboseAILogs: Bool {
        get { aiVerbose }
        set { aiVerbose = newValue }
    }
    
    public var darkMode: Bool {
        get { themeDark }
        set { themeDark = newValue }
    }
    
    public var isDemoAI: Bool { demoMode }
    public var isDemoPnL: Bool { pnlDemoMode }
    
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
    
    private init() {}
}