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
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Haptics", isOn: $theme.isHapticsEnabled)
                    
                    if theme.isHapticsEnabled {
                        HStack(spacing: 12) {
                            Button("✅ Success") {
                                Haptics.play(.success)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("⚠️ Warning") {
                                Haptics.play(.warning)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("❌ Error") {
                                Haptics.play(.error)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.leading, 16)
                    }
                }
                
                Picker("Theme", selection: $theme.isDarkMode) {
                    Text("Light").tag(false)
                    Text("Dark").tag(true)
                }
                .pickerStyle(.segmented)
                
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
