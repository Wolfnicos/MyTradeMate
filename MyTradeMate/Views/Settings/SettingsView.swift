import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack {
            List {
                Section("Market Data") {
                    Toggle("Live Market Data", isOn: $settings.liveMarketData)
                        .help("Connect to live exchange data")
                    
                    HStack {
                        Text("Default Symbol")
                        Spacer()
                        Text(settings.defaultSymbol)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Default Timeframe")
                        Spacer()
                        Text(settings.defaultTimeframe)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("AI Settings") {
                    Toggle("Demo Mode", isOn: $settings.demoMode)
                        .help("Use simulated AI predictions for testing")
                    
                    Toggle("AI Debug Mode", isOn: $settings.aiDebugMode)
                        .help("Enable additional AI diagnostics")
                    
                    Toggle("Verbose AI Logs", isOn: $settings.verboseAILogs)
                        .help("Show detailed AI processing logs")
                    
                    Toggle("PnL Demo Mode", isOn: $settings.pnlDemoMode)
                        .help("Use synthetic PnL data for testing")
                }
                
                Section("Trading") {
                    Toggle("Confirm Trades", isOn: $settings.confirmTrades)
                        .help("Show confirmation dialog before placing trades")
                    
                    Toggle("Paper Trading", isOn: $settings.paperTrading)
                        .help("Simulate trades without real money")
                    
                    Toggle("Auto Trading", isOn: $settings.autoTrading)
                        .help("Enable automated trading based on signals")
                        .disabled(!settings.confirmTrades)
                }
                
                Section("Strategies") {
                    NavigationLink("RSI Strategy") {
                        Text("RSI Configuration")
                            .navigationTitle("RSI Strategy")
                    }
                    
                    NavigationLink("EMA Strategy") {
                        Text("EMA Configuration")
                            .navigationTitle("EMA Strategy")
                    }
                    
                    NavigationLink("ATR Strategy") {
                        Text("ATR Configuration")
                            .navigationTitle("ATR Strategy")
                    }
                }
                
                Section("Exchanges") {
                    Button("Manage API Keys") {
                        navigationCoordinator.navigate(to: .exchangeKeys, in: .settings)
                    }
                    .foregroundColor(.primary)
                    
                    NavigationLink("Binance") {
                        Text("Binance Configuration")
                            .navigationTitle("Binance")
                    }
                    
                    NavigationLink("Kraken") {
                        Text("Kraken Configuration")
                            .navigationTitle("Kraken")
                    }
                }
                
                Section("Interface") {
                    Toggle("Dark Mode", isOn: $settings.darkMode)
                        .help("Use dark color scheme")
                    
                    Toggle("Haptic Feedback", isOn: $settings.haptics)
                        .help("Enable tactile feedback for interactions")
                }
                
                Section("Diagnostics") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build Number")
                        Spacer()
                        Text(Bundle.main.buildNumber)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Export Diagnostics") {
                        // Export functionality
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Settings")
        }
        .preferredColorScheme(settings.darkMode ? .dark : .light)
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