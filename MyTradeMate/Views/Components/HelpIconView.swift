import SwiftUI

/// A reusable help icon component that displays a tooltip when tapped
struct HelpIconView: View {
    let helpText: String
    @State private var showTooltip = false
    
    var body: some View {
        Button(action: {
            showTooltip.toggle()
        }) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showTooltip, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(helpText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: 280)
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityLabel("Help")
        .accessibilityHint("Tap to show help information")
    }
}

/// A modifier to add help icons to any view
struct HelpIconModifier: ViewModifier {
    let helpText: String
    
    func body(content: Content) -> some View {
        HStack {
            content
            Spacer()
            HelpIconView(helpText: helpText)
        }
    }
}

extension View {
    /// Adds a help icon with tooltip to the trailing edge of the view
    func helpIcon(_ helpText: String) -> some View {
        modifier(HelpIconModifier(helpText: helpText))
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Demo Mode")
            .helpIcon("Use simulated trading environment for testing strategies without real money. All trades will be virtual and no actual funds will be used.")
        
        Text("Auto Trading")
            .helpIcon("Allow AI strategies to automatically place trades when conditions are met. This requires valid API keys and live mode to be enabled.")
        
        Text("Paper Trading")
            .helpIcon("Simulate trades with real market data but without actual money. This is different from Demo Mode as it uses live market prices.")
    }
    .padding()
}