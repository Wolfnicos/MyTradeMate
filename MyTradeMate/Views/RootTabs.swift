import SwiftUI

struct RootTabs: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis") }
            
            NavigationStack { TradeHistoryView() }
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}