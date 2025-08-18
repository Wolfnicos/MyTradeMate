import SwiftUI
import Foundation

// Exchange model is defined in Models/Exchange.swift

// NavigationCoordinator, NavigationDestination and AppTab are defined in RootTabs.swift

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
                    
                    StandardToggleRow(
                        title: "Demo Mode",
                        description: "Use simulated trading environment for testing strategies without real money. All trades will be virtual.",
                        isOn: $settings.demoMode,
                        style: .warning
                    )
                    
                    StandardToggleRow(
                        title: "Auto Trading",
                        description: "Allow AI strategies to automatically place trades when conditions are met. Requires valid API keys and live mode.",
                        isOn: $settings.autoTrading,
                        style: .success
                    )
                    
                    StandardToggleRow(
                        title: "Confirm Trades",
                        description: "Show confirmation dialog before placing any trade. Recommended for beginners and live trading.",
                        isOn: $settings.confirmTrades,
                        style: .default
                    )
                    
                    StandardToggleRow(
                        title: "Paper Trading",
                        description: "Simulate trades with real market data but without actual money. Disabled when Demo Mode is active.",
                        isOn: $settings.paperTrading,
                        style: .prominent,
                        isDisabled: settings.demoMode
                    )
                    
                    StandardToggleRow(
                        title: "Live Market Data",
                        description: "Connect to real-time exchange data feeds. Disable to use cached data and reduce API usage.",
                        isOn: $settings.liveMarketData,
                        style: .default
                    )
                    
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
                        StrategyConfigurationView()
                    }
                } header: {
                    Label("Trading", systemImage: "chart.line.uptrend.xyaxis")
                } footer: {
                    Text("Configure trading behavior, market data sources, and strategy settings. Demo Mode is recommended for new users to test strategies safely.")
                }
                
                // MARK: - Security Section
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Button("Manage API Keys") {
                            navigationCoordinator.navigate(to: .exchangeKeys, in: .settings)
                        }
                        .foregroundColor(.primary)
                        Text("Configure exchange API credentials for live trading. Keys are stored securely in Keychain.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        NavigationLink("Binance Configuration") {
                            BinanceKeysView()
                        }
                        Text("Set up Binance API keys for trading and market data access.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        NavigationLink("Kraken Configuration") {
                            KrakenKeysView()
                        }
                        Text("Set up Kraken API keys for trading and market data access.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    StandardToggleRow(
                        title: "Dark Mode",
                        description: "Use dark color scheme throughout the app. Follows system setting when disabled.",
                        isOn: $settings.darkMode,
                        style: .minimal
                    )
                    
                    StandardToggleRow(
                        title: "Haptic Feedback",
                        description: "Enable tactile feedback for button presses, trade confirmations, and other interactions.",
                        isOn: $settings.haptics,
                        style: .default
                    )
                } header: {
                    Label("Security", systemImage: "key")
                } footer: {
                    Text("Manage exchange API credentials and app security settings. API keys are required for live trading and real-time data.")
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
                    
                    StandardToggleRow(
                        title: "AI Debug Mode",
                        description: "Enable additional AI diagnostics and debugging information. May impact performance.",
                        isOn: $settings.aiDebugMode,
                        style: .warning
                    )
                    
                    StandardToggleRow(
                        title: "Verbose AI Logs",
                        description: "Show detailed AI processing logs including model inputs, outputs, and decision reasoning.",
                        isOn: $settings.verboseAILogs,
                        style: .danger
                    )
                    
                    StandardToggleRow(
                        title: "PnL Demo Mode",
                        description: "Use synthetic profit/loss data for testing charts and calculations without real trading history.",
                        isOn: $settings.pnlDemoMode,
                        style: .minimal
                    )
                    
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
                    Text("Debug settings, system information, and diagnostic tools for troubleshooting. Enable verbose logging only when needed as it may impact performance.")
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

// Bundle extension is defined in Utils/LogExporter.swift

#Preview {
    SettingsView()
        .preferredColorScheme(nil)
}