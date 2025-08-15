import SwiftUI

@main
struct MyTradeMateApp: App {
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
                .environmentObject(market)
                .environmentObject(trade)
                .environmentObject(risk)
                .environmentObject(ai)
                .environmentObject(theme)
                .preferredColorScheme(theme.colorScheme)
                .onAppear {
                    // Preload ai models if you have such a method
                    // ai.preload() // ✅ ensure method exists (or comment if not)
                    market.setLiveEnabled(false) // ✅ start on paper
                }
        }
    }
}

