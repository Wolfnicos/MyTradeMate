import SwiftUI

struct AISection: View {
    @StateObject private var appSettings = AppSettings.shared
    
    var body: some View {
        Section("AI Configuration") {
            StandardToggleRow(
                title: "AI Debug Mode",
                description: "Enable AI debugging features and additional diagnostics. May impact performance.",
                isOn: $appSettings.aiDebugMode,
                style: .warning
            )
            
            StandardToggleRow(
                title: "Verbose AI Logs",
                description: "Enable detailed AI logging including model inputs, outputs, and decision reasoning.",
                isOn: $appSettings.verboseAILogs,
                style: .danger
            )
            
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
                
                Text("Primary trading pair for AI analysis and signals.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Default Timeframe")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Timeframe", selection: $appSettings.defaultTimeframe) {
                    Text("5m").tag("5m")
                    Text("1h").tag("1h")
                    Text("4h").tag("4h")
                }
                .pickerStyle(.segmented)
                
                Text("Chart timeframe for AI analysis. Shorter timeframes provide more frequent signals but may be noisier.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}