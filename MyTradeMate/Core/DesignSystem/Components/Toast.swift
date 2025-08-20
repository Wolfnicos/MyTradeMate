import SwiftUI

/// Modern toast notification component
/// Provides consistent messaging across the app
struct Toast: View {
    let message: String
    let type: ToastType
    let icon: String?
    let action: ToastAction?
    
    init(
        _ message: String,
        type: ToastType = .info,
        icon: String? = nil,
        action: ToastAction? = nil
    ) {
        self.message = message
        self.type = type
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Icon
            Image(systemName: effectiveIcon)
                .font(.system(size: DesignTokens.IconSize.md, weight: .medium))
                .foregroundColor(type.foregroundColor)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(type.foregroundColor)
                    .multilineTextAlignment(.leading)
                
                if let action = action {
                    Button(action.title) {
                        action.handler()
                    }
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(type.foregroundColor.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Close button (optional)
            if action?.showCloseButton == true {
                Button {
                    // Handle close
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: DesignTokens.IconSize.sm, weight: .medium))
                        .foregroundColor(type.foregroundColor.opacity(0.7))
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(type.backgroundColor)
        .cornerRadius(DesignTokens.Radius.lg)
        .designTokenShadow(DesignTokens.Elevation.md)
    }
    
    private var effectiveIcon: String {
        if let icon = icon {
            return icon
        }
        return type.defaultIcon
    }
}

/// Toast notification types
enum ToastType {
    case success
    case warning
    case error
    case info
    
    var backgroundColor: Color {
        switch self {
        case .success:
            return DesignTokens.Colors.success
        case .warning:
            return DesignTokens.Colors.warning
        case .error:
            return DesignTokens.Colors.error
        case .info:
            return DesignTokens.Colors.info
        }
    }
    
    var foregroundColor: Color {
        return .white
    }
    
    var defaultIcon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}

/// Toast action configuration
struct ToastAction {
    let title: String
    let handler: () -> Void
    let showCloseButton: Bool
    
    init(_ title: String, showCloseButton: Bool = false, handler: @escaping () -> Void) {
        self.title = title
        self.showCloseButton = showCloseButton
        self.handler = handler
    }
}

// MARK: - Toast Manager for Global Toasts

@MainActor
final class ToastManager: ObservableObject {
    @Published var currentToast: ToastData?
    
    private var dismissTask: Task<Void, Never>?
    
    func show(
        _ message: String,
        type: ToastType = .info,
        icon: String? = nil,
        action: ToastAction? = nil,
        duration: TimeInterval = 3.0
    ) {
        // Cancel previous dismiss task
        dismissTask?.cancel()
        
        // Show new toast
        currentToast = ToastData(
            message: message,
            type: type,
            icon: icon,
            action: action
        )
        
        // Auto dismiss after duration
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                dismiss()
            }
        }
    }
    
    func dismiss() {
        dismissTask?.cancel()
        withAnimation(DesignTokens.Animation.fast) {
            currentToast = nil
        }
    }
}

struct ToastData {
    let message: String
    let type: ToastType
    let icon: String?
    let action: ToastAction?
}

// MARK: - Toast Container View

struct ToastContainer<Content: View>: View {
    @StateObject private var toastManager = ToastManager()
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
                .environmentObject(toastManager)
            
            // Toast overlay
            if let toast = toastManager.currentToast {
                VStack {
                    Spacer()
                    
                    Toast(
                        toast.message,
                        type: toast.type,
                        icon: toast.icon,
                        action: toast.action
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onTapGesture {
                        toastManager.dismiss()
                    }
                    
                    Spacer()
                        .frame(height: DesignTokens.Spacing.xl)
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .animation(DesignTokens.Animation.gentle, value: toastManager.currentToast != nil)
            }
        }
    }
}

// MARK: - View Extension for Easy Toast Access

extension View {
    func withToast() -> some View {
        ToastContainer {
            self
        }
    }
}

// MARK: - Preview
#Preview("Toast Notifications") {
    VStack(spacing: DesignTokens.Spacing.lg) {
        Toast("Operation completed successfully", type: .success)
        
        Toast("Please check your settings", type: .warning)
        
        Toast("Connection failed", type: .error)
        
        Toast("New data available", type: .info, icon: "arrow.down.circle")
        
        Toast(
            "Trade executed",
            type: .success,
            action: ToastAction("View Details", showCloseButton: true) {
                print("View details tapped")
            }
        )
    }
    .padding()
    .background(DesignTokens.Colors.surface)
}