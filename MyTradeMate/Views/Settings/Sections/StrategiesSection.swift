import SwiftUI

struct StrategiesSection: View {
    @EnvironmentObject var settings: SettingsRepository
    
    var body: some View {
        Section("Strategies") {
            NavigationLink(destination: StrategiesView()) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Strategy Configuration")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Text("Configure and manage trading strategies")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            StandardToggleRow(
                title: "Strategy Routing",
                description: "Use strategies for short timeframes, AI for 4h timeframes",
                isOn: $settings.useStrategyRouting,
                style: .prominent
            )
        }
    }
}