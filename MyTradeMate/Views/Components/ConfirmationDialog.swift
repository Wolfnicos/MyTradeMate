import SwiftUI

// MARK: - Confirmation Dialog Base Component
struct ConfirmationDialog: View {
    let title: String
    let message: String?
    let icon: String?
    let iconColor: Color
    let confirmButtonText: String
    let confirmButtonColor: Color
    let cancelButtonText: String
    let isDestructive: Bool
    let isExecuting: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let content: (() -> AnyView)?
    
    init(
        title: String,
        message: String? = nil,
        icon: String? = nil,
        iconColor: Color = .blue,
        confirmButtonText: String = "Confirm",
        confirmButtonColor: Color = .blue,
        cancelButtonText: String = "Cancel",
        isDestructive: Bool = false,
        isExecuting: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        @ViewBuilder content: (() -> AnyView)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
        self.confirmButtonText = confirmButtonText
        self.confirmButtonColor = confirmButtonColor
        self.cancelButtonText = cancelButtonText
        self.isDestructive = isDestructive
        self.isExecuting = isExecuting
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 48))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Custom Content
            if let content = content {
                content()
            }
            
            // Action Buttons or Loading State
            if isExecuting {
                VStack(spacing: 16) {
                    LoadingStateView(message: "Processing...")
                    
                    Text("Please wait...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 50)
            } else {
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text(cancelButtonText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .disabled(isExecuting)
                    
                    Button(action: onConfirm) {
                        Text(confirmButtonText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isDestructive ? .red : confirmButtonColor)
                            .cornerRadius(12)
                    }
                    .disabled(isExecuting)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Convenience Initializers
extension ConfirmationDialog {
    // Simple confirmation dialog
    static func simple(
        title: String,
        message: String,
        confirmButtonText: String = "Confirm",
        cancelButtonText: String = "Cancel",
        isDestructive: Bool = false,
        isExecuting: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> ConfirmationDialog {
        ConfirmationDialog(
            title: title,
            message: message,
            confirmButtonText: confirmButtonText,
            cancelButtonText: cancelButtonText,
            isDestructive: isDestructive,
            isExecuting: isExecuting,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
    
    // Destructive action confirmation
    static func destructive(
        title: String,
        message: String,
        confirmButtonText: String = "Delete",
        cancelButtonText: String = "Cancel",
        isExecuting: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> ConfirmationDialog {
        ConfirmationDialog(
            title: title,
            message: message,
            icon: "exclamationmark.triangle.fill",
            iconColor: .red,
            confirmButtonText: confirmButtonText,
            confirmButtonColor: .red,
            cancelButtonText: cancelButtonText,
            isDestructive: true,
            isExecuting: isExecuting,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
    
    // Settings change confirmation
    static func settingsChange(
        title: String,
        message: String,
        confirmButtonText: String = "Apply Changes",
        cancelButtonText: String = "Cancel",
        isExecuting: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> ConfirmationDialog {
        ConfirmationDialog(
            title: title,
            message: message,
            icon: "gearshape.fill",
            iconColor: .blue,
            confirmButtonText: confirmButtonText,
            confirmButtonColor: .blue,
            cancelButtonText: cancelButtonText,
            isDestructive: false,
            isExecuting: isExecuting,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
    
    // Strategy toggle confirmation
    static func strategyToggle(
        strategyName: String,
        isEnabling: Bool,
        isExecuting: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> ConfirmationDialog {
        let action = isEnabling ? "enable" : "disable"
        let actionCapitalized = isEnabling ? "Enable" : "Disable"
        
        return ConfirmationDialog(
            title: "\(actionCapitalized) Strategy",
            message: "Are you sure you want to \(action) the \(strategyName) strategy?",
            icon: isEnabling ? "play.circle.fill" : "pause.circle.fill",
            iconColor: isEnabling ? .green : .orange,
            confirmButtonText: actionCapitalized,
            confirmButtonColor: isEnabling ? .green : .orange,
            cancelButtonText: "Cancel",
            isDestructive: false,
            isExecuting: isExecuting,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Simple confirmation
        ConfirmationDialog.simple(
            title: "Save Changes",
            message: "Do you want to save your changes?",
            onConfirm: {},
            onCancel: {}
        )
        
        // Destructive confirmation
        ConfirmationDialog.destructive(
            title: "Delete Account",
            message: "This action cannot be undone. All your data will be permanently deleted.",
            onConfirm: {},
            onCancel: {}
        )
        
        // Strategy toggle
        ConfirmationDialog.strategyToggle(
            strategyName: "RSI Strategy",
            isEnabling: true,
            onConfirm: {},
            onCancel: {}
        )
    }
    .padding()
    .background(Color.black.opacity(0.3))
}
</content>
</invoke>