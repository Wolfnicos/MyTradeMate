import SwiftUI

/// Read-only trading mode indicator that reflects TradingModeStore state
/// Used throughout the app to show current trading mode without allowing changes
/// This is the ONLY way to display mode - mode changes must go through TradingModeStore
struct ReadOnlyModeChip: View {
    @StateObject private var tradingModeStore = TradingModeStore.shared
    
    var body: some View {
        ModernTradingModeChip(mode: tradingModeStore.currentMode)
            .accessibilityLabel("Current trading mode: \(tradingModeStore.currentMode.title)")
    }
}

/// Simple trading mode chip for display purposes
struct ModernTradingModeChip: View {
    let mode: TradingMode
    
    var body: some View {
        Text(mode.title.uppercased())
            .font(.caption.weight(.medium))
            .foregroundColor(modeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(modeColor.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(modeColor, lineWidth: 1)
            )
            .cornerRadius(6)
    }
    
    private var modeColor: Color {
        switch mode {
        case .demo:
            return .blue
        case .paper:
            return .green
        case .live:
            return .red
        }
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