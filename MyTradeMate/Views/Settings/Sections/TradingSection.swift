import SwiftUI

struct TradingSection: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        Section {
            StandardToggleRow(
                title: "Confirm Trades",
                description: "Show confirmation dialog before placing any trade. Recommended for beginners and live trading.",
                isOn: $settings.confirmTrades,
                style: .default
            )
            
            StandardToggleRow(
                title: "Paper Trading",
                description: "Simulate trades with real market data but without actual money. Safe way to test strategies.",
                isOn: Binding(
                    get: { !settings.liveMarketDataEnabled },
                    set: { settings.liveMarketDataEnabled = !$0 }
                ),
                style: .prominent
            )
            
            StandardToggleRow(
                title: "Auto Trading",
                description: "Enable automated trading based on AI signals. Requires valid API keys and confirmation trades enabled.",
                isOn: $settings.autoTrading,
                style: .success,
                isDisabled: !settings.confirmTrades
            )
        }
    }
}