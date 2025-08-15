import SwiftUI

struct RootTabs: View {
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        TabView {
            NavigationView {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
            }
            
            NavigationView {
                TradesView()
            }
            .tabItem {
                Label("Trades", systemImage: "arrow.left.arrow.right")
            }
            
            NavigationView {
                PnLDetailView()
            }
            .tabItem {
                Label("P&L", systemImage: "chart.bar.fill")
            }
            
            NavigationView {
                StrategiesView()
            }
            .tabItem {
                Label("Strategies", systemImage: "brain")
            }
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .environmentObject(settings)
        .preferredColorScheme(settings.darkMode ? .dark : .light)
    }
}

struct RootTabs_Previews: PreviewProvider {
    static var previews: some View {
        RootTabs()
    }
}