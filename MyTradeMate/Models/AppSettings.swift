import SwiftUI

@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    private init() {}
    
    // Market Data
    @AppStorage("liveMarketDataEnabled") public var liveMarketDataEnabled = true
    
    // AI & Trading
    @AppStorage("aiDebugMode") public var aiDebugMode = false
    @AppStorage("demoMode") public var demoMode = false
    @AppStorage("verboseAILogs") public var verboseAILogs = false
    @AppStorage("pnlDemoMode") public var pnlDemoMode = false
    @AppStorage("autoTrading") public var autoTrading = false
    
    // Experience
    @AppStorage("hapticsEnabled") public var hapticsEnabled = true
    @AppStorage("darkMode") public var darkMode = false
    @AppStorage("confirmTrades") public var confirmTrades = true
    @AppStorage("defaultTimeframe") public var defaultTimeframe: String = "5m"
    
    // Helpers
    public var isDemoAI: Bool { demoMode }
    public var isDemoPnL: Bool { pnlDemoMode }
    
    // Computed timeframe
    public var timeframe: Timeframe {
        switch defaultTimeframe {
        case "1h": return .h1
        case "4h": return .h4
        default: return .m5
        }
    }
}