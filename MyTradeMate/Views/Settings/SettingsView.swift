import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Trading Section
                Section {
                    // Enhanced trading mode display
                    HStack {
                        Text("Current Mode")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(settings.demoMode ? .orange : .green)
                                .frame(width: 8, height: 8)
                            
                            Text(settings.demoMode ? "DEMO MODE" : "LIVE MODE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(settings.demoMode ? .orange : .green)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill((settings.demoMode ? Color.orange : Color.green).opacity(0.15))
                        )
                    }
                    .padding(.vertical, 4)
                    
                    Toggle("Demo Mode", isOn: $settings.demoMode)
                        .help("Use simulated trading for testing")
                    
                    Toggle("Auto Trading", isOn: $settings.autoTrading)
                        .help("Allow AI strategies to place trades automatically when conditions are met")
                    
                    Toggle("Confirm Trades", isOn: $settings.confirmTrades)
                        .help("Show confirmation dialog before placing trades")
                    
                    Toggle("Paper Trading", isOn: $settings.paperTrading)
                        .help("Simulate trades without real money")
                        .disabled(settings.demoMode)
                    
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
                    
                    NavigationLink("Strategy Configuration") {
                        List {
                            Section {
                                Text("Strategy configuration will be implemented in a future update")
                                    .foregroundColor(.secondary)
                            } header: {
                                Text("Available Strategies")
                            }
                        }
                        .navigationTitle("Strategy Configuration")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                } header: {
                    Label("Trading", systemImage: "chart.line.uptrend.xyaxis")
                } footer: {
                    Text("Configure trading behavior, market data sources, and strategy settings.")
                }
                
                // MARK: - Security Section
                Section {
                    Button("Manage API Keys") {
                        navigationCoordinator.navigate(to: .exchangeKeys, in: .settings)
                    }
                    .foregroundColor(.primary)
                    
                    NavigationLink("Binance Configuration") {
                        BinanceKeysView()
                    }
                    
                    NavigationLink("Kraken Configuration") {
                        KrakenKeysView()
                    }
                    
                    Toggle("Dark Mode", isOn: $settings.darkMode)
                        .help("Use dark color scheme")
                    
                    Toggle("Haptic Feedback", isOn: $settings.haptics)
                        .help("Enable tactile feedback for interactions")
                } header: {
                    Label("Security", systemImage: "key")
                } footer: {
                    Text("Manage exchange API credentials and app security settings.")
                }
                
                // MARK: - Diagnostics Section
                Section {
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
                    
                    Toggle("AI Debug Mode", isOn: $settings.aiDebugMode)
                        .help("Enable additional AI diagnostics")
                    
                    Toggle("Verbose AI Logs", isOn: $settings.verboseAILogs)
                        .help("Show detailed AI processing logs")
                    
                    Toggle("PnL Demo Mode", isOn: $settings.pnlDemoMode)
                        .help("Use synthetic PnL data for testing")
                    
                    Button("Export Logs") {
                        exportDiagnosticLogs()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Run System Check") {
                        runSystemDiagnostics()
                    }
                    .foregroundColor(.blue)
                } header: {
                    Label("Diagnostics", systemImage: "stethoscope")
                } footer: {
                    Text("Debug settings, system information, and diagnostic tools for troubleshooting.")
                }
            }
            .navigationTitle("Settings")
        }
        .preferredColorScheme(settings.darkMode ? .dark : .light)
    }
    
    // MARK: - Helper Methods
    private func exportDiagnosticLogs() {
        // Export functionality will be implemented in a separate task
        print("Export diagnostic logs requested")
    }
    
    private func runSystemDiagnostics() {
        // System diagnostics functionality
        print("System diagnostics requested")
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