import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var market: MarketDataService
    @StateObject private var theme = ThemeManager.shared

    var body: some View {
        Form {
            Section(header: Text("Data")) {
                Toggle("Live market data (WebSocket)", isOn: Binding(
                    get: { market.isLiveEnabled },
                    set: { market.setLiveEnabled($0) }
                ))
            }
            
            Section(header: Text("Experience")) {
                Toggle("Haptics", isOn: $theme.isHapticsEnabled)
                Toggle("Dark Mode", isOn: $theme.isDarkMode)
                Toggle("Confirm trades", isOn: $theme.isConfirmTradesEnabled)
            }

            Section(header: Text("About")) {
                Text("MyTradeMate v1.0")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
