import SwiftUI

struct TradingSection: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        Section {
            Toggle("Confirm Trades", isOn: $settings.confirmTrades)
                .help("Show confirmation dialog before placing trades")
            
            Toggle("Paper Trading", isOn: Binding(
                get: { !settings.liveMarketDataEnabled },
                set: { settings.liveMarketDataEnabled = !$0 }
            ))
                .help("Simulate trades without real money")
            
            Toggle("Auto Trading", isOn: $settings.autoTrading)
                .help("Enable automated trading based on signals")
                .disabled(!settings.confirmTrades)
        }
    }
}