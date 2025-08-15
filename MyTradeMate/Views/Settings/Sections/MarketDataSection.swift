import SwiftUI

struct MarketDataSection: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        Section {
            Toggle("Live Market Data", isOn: $settings.liveMarketDataEnabled)
                .help("Use live market data from exchanges")
            
            Toggle("Demo Mode", isOn: $settings.demoMode)
                .help("Use synthetic data for testing")
        }
    }
}