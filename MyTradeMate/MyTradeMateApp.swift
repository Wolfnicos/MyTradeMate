import SwiftUI

@main
struct MyTradeMateApp: App {
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var market = MarketDataService.shared
    @StateObject private var trade  = TradeManager.shared
    @StateObject private var risk   = RiskManager.shared
    @StateObject private var ai     = AIModelManager.shared
    @StateObject private var theme  = ThemeManager.shared
    
    init() {
        // Global appearance setup
        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.font: UIFont.systemFont(ofSize: 34, weight: .bold)]
        appearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
    }
    
    var body: some Scene {
        WindowGroup {
            RootTabs()
                .environmentObject(appSettings)
                .environmentObject(market)
                .environmentObject(trade)
                .environmentObject(risk)
                .environmentObject(ai)
                .environmentObject(theme)
                .preferredColorScheme(theme.colorScheme)
                .onAppear {
                    // Initialize market data based on settings
                    market.setLiveEnabled(appSettings.liveMarketData)
                    
                    if appSettings.shouldShowAIDebug {
                        print("🧪 Demo Mode: \(appSettings.demoMode ? "ON" : "OFF")")
                        print("📊 PnL Demo Mode: \(appSettings.pnlDemoMode ? "ON" : "OFF")")
                        
                        // Run CoreML model sanity check when AI debug is enabled
                        runModelSanityCheck()
                    }
                    
                    // RUN DIAGNOSTIC AUDIT
                    Task {
                        await Audit.run()
                    }
                }
                .onDisappear {
                    appSettings.saveSettings()
                }
        }
    }
}

