import SwiftUI
import UIKit

// Using DesignSystem for spacing and corner radius

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

/// Modern 2025 Toast notification component
struct ToastView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let type: ToastType
    let title: String
    let message: String?
    let onDismiss: (() -> Void)?
    
    // Modern 2025 UI State
    @State private var isVisible = false
    @State private var showGlow = false
    @State private var isPressed = false
    
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
        HStack(spacing: 16) {
            // Modern icon with glow effect
            ZStack {
                if showGlow {
                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(type.color)
                        .blur(radius: 2)
                        .scaleEffect(1.2)
                        .opacity(0.6)
                        .animation(themeManager.slowAnimation.repeatForever(autoreverses: true), value: showGlow)
                }
                
                Image(systemName: type.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(type.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(TextColor.primary)
                
                if let message = message {
                    Text(message)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TextColor.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    onDismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(themeManager.primaryColor.opacity(0.1))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(themeManager.primaryColor)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(themeManager.fastAnimation, value: isPressed)
                .pressEvents {
                    withAnimation(themeManager.fastAnimation) {
                        isPressed = true
                    }
                } onRelease: {
                    withAnimation(themeManager.fastAnimation) {
                        isPressed = false
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            themeManager.neumorphicCardBackground()
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: type.color.opacity(0.2),
            radius: isVisible ? 8 : 4,
            x: 0,
            y: isVisible ? 4 : 2
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .animation(themeManager.defaultAnimation.delay(0.1), value: isVisible)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .onAppear {
            withAnimation(themeManager.defaultAnimation.delay(0.1)) {
                isVisible = true
            }
            withAnimation(themeManager.defaultAnimation.delay(0.5)) {
                showGlow = true
            }
        }
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

// MARK: - Modern Toast Container
struct ModernToastContainer: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var toastManager: ToastManager
    
    var body: some View {
        ZStack {
            // Background overlay when toasts are present
            if !toastManager.toasts.isEmpty {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Dismiss all toasts on background tap
                        toastManager.dismissAll()
                    }
            }
            
            // Toast stack
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    ForEach(Array(toastManager.toasts.enumerated()), id: \.element.id) { index, toast in
                        ModernToastView(
                            type: toast.type,
                            title: toast.title,
                            message: toast.message
                        ) {
                            toastManager.dismiss(toast)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .zIndex(Double(toastManager.toasts.count - index))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Safe area padding
            }
        }
        .animation(themeManager.defaultAnimation, value: toastManager.toasts.count)
    }
}

// MARK: - Modern Toast View (Enhanced)
struct ModernToastView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let type: ToastType
    let title: String
    let message: String?
    let onDismiss: () -> Void
    
    // Modern 2025 UI State
    @State private var isVisible = false
    @State private var showGlow = false
    @State private var isPressed = false
    @State private var showProgress = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Modern icon with glow effect
            ZStack {
                if showGlow {
                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(type.color)
                        .blur(radius: 2)
                        .scaleEffect(1.2)
                        .opacity(0.6)
                        .animation(themeManager.slowAnimation.repeatForever(autoreverses: true), value: showGlow)
                }
                
                Image(systemName: type.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(type.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(TextColor.primary)
                
                if let message = message {
                    Text(message)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TextColor.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Progress indicator
            if showProgress {
                ZStack {
                    Circle()
                        .stroke(type.color.opacity(0.2), lineWidth: 2)
                        .frame(width: 16, height: 16)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            type.color,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(showProgress ? 360 : 0))
                        .animation(
                            themeManager.slowAnimation.repeatForever(autoreverses: false),
                            value: showProgress
                        )
                }
            }
            
            // Dismiss button
            Button(action: {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                onDismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(themeManager.primaryColor.opacity(0.1))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(themeManager.primaryColor)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(themeManager.fastAnimation, value: isPressed)
            .pressEvents {
                withAnimation(themeManager.fastAnimation) {
                    isPressed = true
                }
            } onRelease: {
                withAnimation(themeManager.fastAnimation) {
                    isPressed = false
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            themeManager.neumorphicCardBackground()
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: type.color.opacity(0.2),
            radius: isVisible ? 8 : 4,
            x: 0,
            y: isVisible ? 4 : 2
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .animation(themeManager.defaultAnimation.delay(0.1), value: isVisible)
        .onAppear {
            withAnimation(themeManager.defaultAnimation.delay(0.1)) {
                isVisible = true
            }
            withAnimation(themeManager.defaultAnimation.delay(0.5)) {
                showGlow = true
                showProgress = true
            }
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

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
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
                    .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.8), Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
    .environmentObject(ThemeManager.shared)
}