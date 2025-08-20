import SwiftUI

/// Read-only trading mode indicator that reflects SettingsRepository state  
/// Used throughout the app to show current trading mode without allowing changes
struct ReadOnlyModeChip: View {
    @ObservedObject private var settingsRepository = SettingsRepository.shared
    
    var body: some View {
        TradingModeChip(settingsRepository.tradingMode)
            .accessibilityLabel("Current trading mode: \(settingsRepository.tradingMode.title)")
    }
}

#Preview("Demo Mode") {
    ReadOnlyModeChip()
        .padding()
}

#Preview("All Modes") {
    VStack(spacing: 16) {
        ReadOnlyModeChip()
        
        // Preview different states by temporarily changing the store
        // Note: This would work better with a preview-specific store
        Text("Demo, Paper, and Live modes")
            .font(.caption)
    }
    .padding()
}