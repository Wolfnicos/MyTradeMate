import SwiftUI

struct AISection: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        Section {
            Toggle("AI Debug Mode", isOn: $settings.aiDebugMode)
                .help("Enable AI debugging features")
            
            Toggle("Verbose AI Logs", isOn: $settings.verboseAILogs)
                .help("Enable detailed AI logging")
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Default Symbol")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Symbol", selection: Binding(
                    get: { "BTC/USDT" },
                    set: { _ in }
                )) {
                    Text("BTC/USDT").tag("BTC/USDT")
                    Text("ETH/USDT").tag("ETH/USDT")
                    Text("BNB/USDT").tag("BNB/USDT")
                }
                .pickerStyle(.menu)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Default Timeframe")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Timeframe", selection: $settings.defaultTimeframe) {
                    Text("5m").tag("5m")
                    Text("1h").tag("1h")
                    Text("4h").tag("4h")
                }
                .pickerStyle(.segmented)
            }
        }
    }
}