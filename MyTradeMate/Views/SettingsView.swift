import SwiftUI

struct SettingsView: View {
    @State private var liveMarketDataEnabled = true
    @State private var aiDebugMode = false
    @State private var demoMode = false
    @State private var verboseAILogs = false
    @State private var pnlDemoMode = false
    @State private var hapticsEnabled = true
    @State private var darkMode = false
    @State private var confirmTrades = true
    @State private var defaultTimeframe: Timeframe = .m5
    
    var body: some View {
        NavigationView {
            Form {
                Section("Market Data") {
                    Toggle("Live Market Data", isOn: $liveMarketDataEnabled)
                    Toggle("Demo Mode", isOn: $demoMode)
                }
                
                Section("AI Settings") {
                    Toggle("AI Debug Mode", isOn: $aiDebugMode)
                    Toggle("Verbose AI Logs", isOn: $verboseAILogs)
                }
                
                Section("Trading") {
                    Toggle("Confirm Trades", isOn: $confirmTrades)
                    Toggle("PnL Demo Mode", isOn: $pnlDemoMode)
                }
                
                Section("Interface") {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                    Toggle("Dark Mode", isOn: $darkMode)
                    
                    Picker("Default Timeframe", selection: $defaultTimeframe) {
                        Text("5m").tag(Timeframe.m5)
                        Text("1h").tag(Timeframe.h1)
                        Text("4h").tag(Timeframe.h4)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Bundle Extension
extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(nil)
}