import SwiftUI

struct RootTabs: View {
    @StateObject private var market = MarketDataService.shared

    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis") }
            
            NavigationStack { TradeHistoryView() }
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .environmentObject(market)
    }
}