import SwiftUI

// Temporary Spacing and CornerRadius structs for this file until DesignSystem is properly imported
private struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

private struct CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 20
}

/// Toast notification types
enum ToastType {
    case success
    case error
    case info
    case warning
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .info:
            return .blue
        case .warning:
            return .orange
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success:
            return Color.green.opacity(0.1)
        case .error:
            return Color.red.opacity(0.1)
        case .info:
            return Color.blue.opacity(0.1)
        case .warning:
            return Color.orange.opacity(0.1)
        }
    }
}

/// A reusable toast notification component
struct ToastView: View {
    let type: ToastType
    let title: String
    let message: String?
    let onDismiss: (() -> Void)?
    
    init(
        type: ToastType,
        title: String,
        message: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: type.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(type.color)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .footnoteMediumStyle()
                
                if let message = message {
                    Text(message)
                        .caption1Style()
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(type.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(CornerRadius.md)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }
    
    private var accessibilityLabel: String {
        let typeLabel = switch type {
        case .success: "Success"
        case .error: "Error"
        case .info: "Information"
        case .warning: "Warning"
        }
        
        if let message = message {
            return "\(typeLabel): \(title). \(message)"
        } else {
            return "\(typeLabel): \(title)"
        }
    }
}

// MARK: - Convenience Initializers

extension ToastView {
    /// Success toast for completed operations
    static func success(
        title: String,
        message: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> ToastView {
        ToastView(
            type: .success,
            title: title,
            message: message,
            onDismiss: onDismiss
        )
    }
    
    /// Error toast for failed operations
    static func error(
        title: String,
        message: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> ToastView {
        ToastView(
            type: .error,
            title: title,
            message: message,
            onDismiss: onDismiss
        )
    }
    
    /// Info toast for general information
    static func info(
        title: String,
        message: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> ToastView {
        ToastView(
            type: .info,
            title: title,
            message: message,
            onDismiss: onDismiss
        )
    }
    
    /// Warning toast for cautionary messages
    static func warning(
        title: String,
        message: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> ToastView {
        ToastView(
            type: .warning,
            title: title,
            message: message,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Predefined Toast Messages

extension ToastView {
    /// Success toast for trade execution
    static func tradeExecuted(
        symbol: String,
        side: String,
        onDismiss: (() -> Void)? = nil
    ) -> ToastView {
        ToastView.success(
            title: "Order Submitted Successfully",
            message: "\(side.capitalized) order for \(symbol) has been placed",
            onDismiss: onDismiss
        )
    }
    
    /// Error toast for trade execution failure
    static func tradeExecutionFailed(
        error: String,
        onDismiss: (() -> Void)? = nil
    ) -> ToastView {
        ToastView.error(
            title: "Order Failed",
            message: error,
            onDismiss: onDismiss
        )
    }
    
    /// Success toast for settings saved
    static func settingsSaved(
        onDismiss: (() -> Void)? = nil
    ) -> ToastView {
        ToastView.success(
            title: "Settings Saved",
            message: "Your changes have been applied",
            onDismiss: onDismiss
        )
    }
    
    /// Success toast for API keys validated
    static func apiKeysValidated(
        exchange: String,
        onDismiss: (() -> Void)? = nil
    ) -> ToastView {
        ToastView.success(
            title: "API Keys Validated",
            message: "\(exchange) connection established successfully",
            onDismiss: onDismiss
        )
    }
    
    /// Error toast for API key validation failure
    static func apiKeyValidationFailed(
        exchange: String,
        error: String,
        onDismiss: (() -> Void)? = nil
    ) -> ToastView {
        ToastView.error(
            title: "\(exchange) Connection Failed",
            message: error,
            onDismiss: onDismiss
        )
    }
    
    /// Info toast for strategy changes
    static func strategyChanged(
        strategy: String,
        enabled: Bool,
        onDismiss: (() -> Void)? = nil
    ) -> ToastView {
        ToastView.info(
            title: "Strategy \(enabled ? "Enabled" : "Disabled")",
            message: "\(strategy) is now \(enabled ? "active" : "inactive")",
            onDismiss: onDismiss
        )
    }
    
    /// Success toast for data export
    static func dataExported(
        type: String,
        onDismiss: (() -> Void)? = nil
    ) -> ToastView {
        ToastView.success(
            title: "Export Successful",
            message: "\(type) has been exported successfully",
            onDismiss: onDismiss
        )
    }
    
    /// Error toast for data export failure
    static func dataExportFailed(
        type: String,
        error: String,
        onDismiss: (() -> Void)? = nil
    ) -> ToastView {
        ToastView.error(
            title: "Export Failed",
            message: "Failed to export \(type): \(error)",
            onDismiss: onDismiss
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        ToastView.success(
            title: "Order Submitted Successfully",
            message: "Buy order for BTC/USD has been placed",
            onDismiss: { print("Success toast dismissed") }
        )
        
        ToastView.error(
            title: "Connection Failed",
            message: "Unable to connect to exchange API",
            onDismiss: { print("Error toast dismissed") }
        )
        
        ToastView.info(
            title: "Settings Updated",
            message: "Auto trading has been enabled",
            onDismiss: { print("Info toast dismissed") }
        )
        
        ToastView.warning(
            title: "High Risk Trade",
            message: "This trade exceeds your risk tolerance",
            onDismiss: { print("Warning toast dismissed") }
        )
        
        // Predefined toasts
        ToastView.tradeExecuted(
            symbol: "BTC/USD",
            side: "buy",
            onDismiss: { print("Trade toast dismissed") }
        )
        
        ToastView.settingsSaved(
            onDismiss: { print("Settings toast dismissed") }
        )
    }
    .padding()
}