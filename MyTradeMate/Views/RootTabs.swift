import SwiftUI

struct RootTabs: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis") }
            
            NavigationStack { TradeHistoryView() }
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            
            NavigationStack { 
                List {
                    Section("General") {
                        Toggle("Haptics", isOn: .constant(true))
                        Toggle("Dark Mode", isOn: .constant(false))
                    }
                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Settings")
            }
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}