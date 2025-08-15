import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var market: MarketDataService
    @StateObject private var theme = ThemeManager.shared

    var body: some View {
        Form {
            Section(header: Text("Data"), footer: Text("Stream price via WebSocket. Turn off to save battery.")) {
                Toggle("Live market data", isOn: Binding(
                    get: { appSettings.liveMarketData },
                    set: { newValue in 
                        appSettings.liveMarketData = newValue
                        appSettings.logStateChange("liveMarketData", newValue)
                        market.setLiveEnabled(newValue)
                        appSettings.saveSettings()
                    }
                ))
            }
            
            Section(header: Text("Trading")) {
                NavigationLink("Exchange API Keys") {
                    ExchangeKeysView()
                }
            }
            
            Section(header: Text("AI & Trading")) {
                Toggle("AI Debug Mode", isOn: Binding(
                    get: { appSettings.aiDebug },
                    set: { newValue in
                        appSettings.aiDebug = newValue
                        appSettings.logStateChange("aiDebug", newValue)
                        appSettings.saveSettings()
                    }
                ))
                Text("Show extra logs and toasts for AI decisions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Demo Mode", isOn: Binding(
                    get: { appSettings.demoMode },
                    set: { newValue in
                        appSettings.demoMode = newValue
                        appSettings.logStateChange("demoMode", newValue)
                        appSettings.saveSettings()
                    }
                ))
                Text("Use synthetic signals instead of live model.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Verbose AI Logs", isOn: Binding(
                    get: { appSettings.verboseAILogs },
                    set: { newValue in
                        appSettings.verboseAILogs = newValue
                        appSettings.logStateChange("verboseAILogs", newValue)
                        appSettings.saveSettings()
                    }
                ))
                Text("Print model inputs/outputs to console (dev only).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("PnL Demo Mode", isOn: Binding(
                    get: { appSettings.pnlDemoMode },
                    set: { newValue in
                        appSettings.pnlDemoMode = newValue
                        appSettings.logStateChange("pnlDemoMode", newValue)
                        appSettings.saveSettings()
                    }
                ))
                Text("Simulate equity curve for demos. Doesn't affect trades.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Experience")) {
                Toggle("Haptics", isOn: $theme.isHapticsEnabled)
                
                Toggle("Dark Mode", isOn: $theme.isDarkMode)
                
                Toggle("Confirm trades", isOn: $theme.isConfirmTradesEnabled)
            }

            Section(header: Text("About")) {
                Text("MyTradeMate v1.0")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
