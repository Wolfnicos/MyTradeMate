import SwiftUI

struct MarketDataSection: View {
    @StateObject private var appSettings = AppSettings.shared
    
    var body: some View {
        Section("Market Data") {
            StandardToggleRow(
                title: "Live Market Data",
                description: "Connect to real-time exchange data feeds. Disable to use cached data and reduce API usage.",
                isOn: $appSettings.liveMarketDataEnabled,
                style: .default
            )
            
            StandardToggleRow(
                title: "Demo Mode",
                description: "Use simulated trading environment with synthetic data for testing strategies safely.",
                isOn: $appSettings.demoMode,
                style: .warning
            )
        }
    }
}