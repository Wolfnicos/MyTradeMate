import SwiftUI

// MARK: - Strategy Confirmation Dialog
struct StrategyConfirmationDialog: View {
    let strategyName: String
    let isEnabling: Bool
    let isExecuting: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ConfirmationDialog.strategyToggle(
            strategyName: strategyName,
            isEnabling: isEnabling,
            isExecuting: isExecuting,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}

// MARK: - Strategy Settings Confirmation Dialog
struct StrategySettingsConfirmationDialog: View {
    let strategyName: String
    let changes: [String]
    let isExecuting: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ConfirmationDialog(
            title: "Apply Strategy Changes",
            message: "The following changes will be applied to \(strategyName):",
            icon: "gearshape.fill",
            iconColor: .blue,
            confirmButtonText: "Apply Changes",
            confirmButtonColor: .blue,
            cancelButtonText: "Cancel",
            isDestructive: false,
            isExecuting: isExecuting,
            onConfirm: onConfirm,
            onCancel: onCancel,
            content: {
                AnyView(
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(changes, id: \.self) { change in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 12))
                                
                                Text(change)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                )
            }
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        StrategyConfirmationDialog(
            strategyName: "RSI Strategy",
            isEnabling: true,
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
        
        StrategySettingsConfirmationDialog(
            strategyName: "MACD Strategy",
            changes: [
                "RSI threshold changed to 30/70",
                "Stop loss set to 2%",
                "Take profit set to 5%"
            ],
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
    }
    .padding()
    .background(Color.black.opacity(0.3))
}