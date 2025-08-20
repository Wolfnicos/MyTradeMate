import SwiftUI

struct TradingSection: View {
    @EnvironmentObject var settings: SettingsRepository
    
    var body: some View {
        Section("Trading") {
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
                    get: { settings.paperTrading },
                    set: { settings.paperTrading = $0 }
                ),
                style: .prominent
            )
            
            StandardToggleRow(
                title: "Auto Trading",
                description: "Enable automated trading based on AI signals. Requires valid API keys and confirmation trades enabled.",
                isOn: $settings.autoTradingEnabled,
                style: .success,
                isDisabled: !settings.confirmTrades
            )
        }
    }
}