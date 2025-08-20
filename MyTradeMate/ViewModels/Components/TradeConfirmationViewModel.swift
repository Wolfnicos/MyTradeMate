import Foundation
import SwiftUI
import Combine

@MainActor
final class TradeConfirmationViewModel: ObservableObject {
    @Published var isExecuting = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published var currentOrderStatus: TrackedOrder?
    
    private let tradeManager = TradeManager.shared
    private let errorManager = ErrorManager.shared
    private let orderTracker = OrderStatusTracker.shared
    private var toastManager: ToastManager?
    
    init(toastManager: ToastManager? = nil) {
        self.toastManager = toastManager
    }
    
    func executeTradeOrder(_ request: TradeRequest) async -> Bool {
        isExecuting = true
        
        let trackedOrder = await orderTracker.executeOrderWithTracking(request)
        currentOrderStatus = trackedOrder
        
        if trackedOrder.isCompleted {
            toastManager?.showTradeExecuted(
                symbol: request.symbol,
                side: request.side.rawValue
            )
            
            Log.trade.info("✅ Order executed successfully: \(request.side.rawValue) \(request.amount) \(request.symbol)")
            
            isExecuting = false
            return true
            
        } else if trackedOrder.isFailed {
            if let errorMessage = trackedOrder.errorMessage {
                handleTradeError(AppError.tradeExecutionFailed(details: errorMessage))
            } else {
                handleTradeError(AppError.tradeExecutionFailed(details: "Unknown error occurred"))
            }
            
            isExecuting = false
            return false
            
        } else {
            isExecuting = false
            return false
        }
    }
    
    private func handleTradeError(_ error: AppError) {
        Log.trade.error("❌ Order execution failed: \(error.localizedDescription)")
        
        errorManager.handle(error, context: "Trade execution")
        
        toastManager?.showTradeExecutionFailed(error: error.localizedDescription)
        
        errorMessage = error.localizedDescription
        
        if error.severity == .critical || error.severity == .high {
            showErrorAlert = true
        }
    }
    
    func setToastManager(_ manager: ToastManager) {
        self.toastManager = manager
    }
    
    func clearError() {
        showErrorAlert = false
        errorMessage = ""
    }
    
    func getErrorAlertMessage() -> String {
        guard !errorMessage.isEmpty else { return "An unknown error occurred" }
        
        var message = errorMessage
        
        if let currentError = errorManager.currentError,
           let recoverySuggestion = currentError.recoverySuggestion {
            message += "\n\n\(recoverySuggestion)"
        }
        
        return message
    }
    
    func getCurrentOrderStatus() -> TrackedOrder? {
        return currentOrderStatus
    }
    
    func clearOrderStatus() {
        currentOrderStatus = nil
    }
    
    func errorAlert() -> Alert {
        Alert(
            title: Text("Order Failed"),
            message: Text(getErrorAlertMessage()),
            primaryButton: .default(Text("OK")) {
                self.clearError()
            },
            secondaryButton: .default(Text("Retry")) {
                self.clearError()
            }
        )
    }
}
