import Foundation
import SwiftUI
import Combine

/// View model for handling trade confirmation and execution
@MainActor
final class TradeConfirmationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isExecuting = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published var currentOrderStatus: TrackedOrder?
    
    // MARK: - Dependencies
    private let tradeManager = TradeManager.shared
    private let errorManager = ErrorManager.shared
    private let orderTracker = OrderStatusTracker.shared
    private var toastManager: ToastManager?
    
    // MARK: - Initialization
    init(toastManager: ToastManager? = nil) {
        self.toastManager = toastManager
    }
    
    // MARK: - Trade Execution
    
    /// Execute a trade order with proper error handling and user feedback
    func executeTradeOrder(_ request: TradeRequest) async -> Bool {
        isExecuting = true
        
        // Execute order with full status tracking
        let trackedOrder = await orderTracker.executeOrderWithTracking(request)
        currentOrderStatus = trackedOrder
        
        // Show appropriate toast based on result
        if trackedOrder.isCompleted {
            toastManager?.showTradeExecuted(
                symbol: request.symbol,
                side: request.side.rawValue
            )
            
            Log.trade.info("✅ Order executed successfully: \(request.side.rawValue) \(request.amount) \(request.symbol)")
            
            isExecuting = false
            return true
            
        } else if trackedOrder.isFailed {
            // Handle error
            if let errorMessage = trackedOrder.errorMessage {
                handleTradeError(AppError.tradeExecutionFailed(details: errorMessage))
            } else {
                handleTradeError(AppError.tradeExecutionFailed(details: "Unknown error occurred"))
            }
            
            isExecuting = false
            return false
            
        } else {
            // Order is still active (shouldn't happen in current implementation)
            isExecuting = false
            return false
        }
    }
    
    // MARK: - Error Handling
    
    private func handleTradeError(_ error: AppError) {
        // Log the error
        Log.trade.error("❌ Order execution failed: \(error.localizedDescription)")
        
        // Handle through error manager
        errorManager.handle(error, context: "Trade execution")
        
        // Show error toast
        toastManager?.showTradeExecutionFailed(error: error.localizedDescription)
        
        // Set error message for potential alert display
        errorMessage = error.localizedDescription
        
        // Show error alert for critical errors
        if error.severity == .critical || error.severity == .high {
            showErrorAlert = true
        }
    }
    
    // MARK: - Helper Methods
    
    /// Set the toast manager for showing notifications
    func setToastManager(_ manager: ToastManager) {
        self.toastManager = manager
    }
    
    /// Clear any error state
    func clearError() {
        showErrorAlert = false
        errorMessage = ""
    }
    
    /// Get user-friendly error message with recovery suggestions
    func getErrorAlertMessage() -> String {
        guard !errorMessage.isEmpty else { return "An unknown error occurred" }
        
        var message = errorMessage
        
        // Add recovery suggestion if available
        if let currentError = errorManager.currentError,
           let recoverySuggestion = currentError.recoverySuggestion {
            message += "\n\n\(recoverySuggestion)"
        }
        
        return message
    }
    
    /// Get the current order status for UI display
    func getCurrentOrderStatus() -> TrackedOrder? {
        return currentOrderStatus
    }
    
    /// Clear the current order status
    func clearOrderStatus() {
        currentOrderStatus = nil
    }
}

// MARK: - Error Alert Helper

extension TradeConfirmationViewModel {
    /// Create an error alert for SwiftUI
    func errorAlert() -> Alert {
        Alert(
            title: Text("Order Failed"),
            message: Text(getErrorAlertMessage()),
            primaryButton: .default(Text("OK")) {
                self.clearError()
            },
            secondaryButton: .default(Text("Retry")) {
                // The retry action would be handled by the parent view
                self.clearError()
            }
        )
    }
}