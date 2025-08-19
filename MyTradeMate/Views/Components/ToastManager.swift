import SwiftUI
import Combine

/// Toast data model for managing individual toasts
struct Toast: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let title: String
    let message: String?
    let duration: TimeInterval
    let isDismissible: Bool
    
    init(
        type: ToastType,
        title: String,
        message: String? = nil,
        duration: TimeInterval = 3.0,
        isDismissible: Bool = true
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
        self.isDismissible = isDismissible
    }
    
    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

/// Observable toast manager for handling toast notifications
@MainActor
class ToastManager: ObservableObject {
    @Published var toasts: [Toast] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Show a toast notification
    func show(_ toast: Toast) {
        toasts.append(toast)
        
        // Auto-dismiss after duration
        Timer.publish(every: toast.duration, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.dismiss(toast)
            }
            .store(in: &cancellables)
    }
    
    /// Show a success toast
    func showSuccess(
        title: String,
        message: String? = nil,
        duration: TimeInterval = 3.0
    ) {
        let toast = Toast(
            type: .success,
            title: title,
            message: message,
            duration: duration
        )
        show(toast)
    }
    
    /// Show an error toast
    func showError(
        title: String,
        message: String? = nil,
        duration: TimeInterval = 5.0
    ) {
        let toast = Toast(
            type: .error,
            title: title,
            message: message,
            duration: duration
        )
        show(toast)
    }
    
    /// Show an info toast
    func showInfo(
        title: String,
        message: String? = nil,
        duration: TimeInterval = 3.0
    ) {
        let toast = Toast(
            type: .info,
            title: title,
            message: message,
            duration: duration
        )
        show(toast)
    }
    
    /// Show a warning toast
    func showWarning(
        title: String,
        message: String? = nil,
        duration: TimeInterval = 4.0
    ) {
        let toast = Toast(
            type: .warning,
            title: title,
            message: message,
            duration: duration
        )
        show(toast)
    }
    
    /// Dismiss a specific toast
    func dismiss(_ toast: Toast) {
        toasts.removeAll { $0.id == toast.id }
    }
    
    /// Dismiss all toasts
    func dismissAll() {
        toasts.removeAll()
        cancellables.removeAll()
    }
}

/// Toast container view that displays toasts at the top of the screen
struct ToastContainer: View {
    @EnvironmentObject var toastManager: ToastManager
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(toastManager.toasts) { toast in
                ToastView(
                    type: toast.type,
                    title: toast.title,
                    message: toast.message,
                    onDismiss: toast.isDismissible ? {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            toastManager.dismiss(toast)
                        }
                    } : nil
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: toastManager.toasts)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .environmentObject(toastManager)
    }
}

/// Environment key for toast manager
private struct ToastManagerKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue = ToastManager()
}

extension EnvironmentValues {
    var toastManager: ToastManager {
        get { self[ToastManagerKey.self] }
        set { self[ToastManagerKey.self] = newValue }
    }
}

/// View modifier to add toast functionality to any view
struct ToastModifier: ViewModifier {
    @EnvironmentObject var toastManager: ToastManager
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .environmentObject(toastManager)
            
            VStack {
                VStack(spacing: 8) {
                    ForEach(toastManager.toasts) { toast in
                        ToastView(
                            type: toast.type,
                            title: toast.title,
                            message: toast.message,
                            onDismiss: toast.isDismissible ? {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    toastManager.dismiss(toast)
                                }
                            } : nil
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .animation(.easeInOut(duration: 0.3), value: toastManager.toasts)
                
                Spacer()
            }
        }
    }
}

extension View {
    /// Add toast functionality to any view
    func withToasts() -> some View {
        modifier(ToastModifier())
    }
}

// MARK: - Predefined Toast Methods for ToastManager

extension ToastManager {
    /// Show success toast for trade execution
    func showTradeExecuted(symbol: String, side: String) {
        showSuccess(
            title: "Order Submitted Successfully",
            message: "\(side.capitalized) order for \(symbol) has been placed"
        )
    }
    
    /// Show error toast for trade execution failure
    func showTradeExecutionFailed(error: String) {
        showError(
            title: "Order Failed",
            message: error,
            duration: 5.0
        )
    }
    
    /// Show success toast for settings saved
    func showSettingsSaved() {
        showSuccess(
            title: "Settings Saved",
            message: "Your changes have been applied"
        )
    }
    
    /// Show success toast for API keys validated
    func showAPIKeysValidated(exchange: String) {
        showSuccess(
            title: "API Keys Validated",
            message: "\(exchange) connection established successfully"
        )
    }
    
    /// Show error toast for API key validation failure
    func showAPIKeyValidationFailed(exchange: String, error: String) {
        showError(
            title: "\(exchange) Connection Failed",
            message: error,
            duration: 5.0
        )
    }
    
    /// Show info toast for strategy changes
    func showStrategyChanged(strategy: String, enabled: Bool) {
        showInfo(
            title: "Strategy \(enabled ? "Enabled" : "Disabled")",
            message: "\(strategy) is now \(enabled ? "active" : "inactive")"
        )
    }
    
    /// Show success toast for data export
    func showDataExported(type: String) {
        showSuccess(
            title: "Export Successful",
            message: "\(type) has been exported successfully"
        )
    }
    
    /// Show error toast for data export failure
    func showDataExportFailed(type: String, error: String) {
        showError(
            title: "Export Failed",
            message: "Failed to export \(type): \(error)",
            duration: 5.0
        )
    }
}

#Preview {
    struct ToastPreview: View {
        @EnvironmentObject var toastManager: ToastManager
        
        var body: some View {
            VStack(spacing: 20) {
                Button("Show Success Toast") {
                    toastManager.showSuccess(
                        title: "Success!",
                        message: "Operation completed successfully"
                    )
                }
                .buttonStyle(.borderedProminent)
                
                Button("Show Error Toast") {
                    toastManager.showError(
                        title: "Error Occurred",
                        message: "Something went wrong"
                    )
                }
                .buttonStyle(.bordered)
                
                Button("Show Info Toast") {
                    toastManager.showInfo(
                        title: "Information",
                        message: "Here's some useful information"
                    )
                }
                .buttonStyle(.bordered)
                
                Button("Show Warning Toast") {
                    toastManager.showWarning(
                        title: "Warning",
                        message: "Please be careful"
                    )
                }
                .buttonStyle(.bordered)
                
                Button("Show Trade Success") {
                    toastManager.showTradeExecuted(symbol: "BTC/USD", side: "buy")
                }
                .buttonStyle(.borderedProminent)
                
                Button("Dismiss All") {
                    toastManager.dismissAll()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
    
    return ToastPreview()
        .withToasts()
}