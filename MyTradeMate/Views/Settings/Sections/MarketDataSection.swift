import SwiftUI

struct MarketDataSection: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        Section {
            StandardToggleRow(
                title: "Live Market Data",
                description: "Connect to real-time exchange data feeds. Disable to use cached data and reduce API usage.",
                isOn: $settings.liveMarketDataEnabled,
                style: .default
            )
            
            StandardToggleRow(
                title: "Demo Mode",
                description: "Use simulated trading environment with synthetic data for testing strategies safely.",
                isOn: $settings.demoMode,
                style: .warning
            )
        }
    }
}