import XCTest
import SwiftUI
@testable import MyTradeMate

final class ToastViewTests: XCTestCase {
    
    func testToastTypeProperties() {
        // Test success type
        XCTAssertEqual(ToastType.success.icon, "checkmark.circle.fill")
        XCTAssertEqual(ToastType.success.color, .green)
        
        // Test error type
        XCTAssertEqual(ToastType.error.icon, "xmark.circle.fill")
        XCTAssertEqual(ToastType.error.color, .red)
        
        // Test info type
        XCTAssertEqual(ToastType.info.icon, "info.circle.fill")
        XCTAssertEqual(ToastType.info.color, .blue)
        
        // Test warning type
        XCTAssertEqual(ToastType.warning.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(ToastType.warning.color, .orange)
    }
    
    func testToastCreation() {
        let toast = Toast(
            type: .success,
            title: "Test Title",
            message: "Test Message",
            duration: 5.0,
            isDismissible: true
        )
        
        XCTAssertEqual(toast.type, .success)
        XCTAssertEqual(toast.title, "Test Title")
        XCTAssertEqual(toast.message, "Test Message")
        XCTAssertEqual(toast.duration, 5.0)
        XCTAssertTrue(toast.isDismissible)
    }
    
    func testToastEquality() {
        let toast1 = Toast(type: .success, title: "Test")
        let toast2 = Toast(type: .success, title: "Test")
        
        // Toasts should not be equal even with same content (different IDs)
        XCTAssertNotEqual(toast1, toast2)
        
        // Toast should be equal to itself
        XCTAssertEqual(toast1, toast1)
    }
    
    @MainActor
    func testToastManagerShowAndDismiss() {
        let manager = ToastManager()
        
        // Initially no toasts
        XCTAssertTrue(manager.toasts.isEmpty)
        
        // Show a toast
        let toast = Toast(type: .success, title: "Test")
        manager.show(toast)
        
        XCTAssertEqual(manager.toasts.count, 1)
        XCTAssertEqual(manager.toasts.first?.title, "Test")
        
        // Dismiss the toast
        manager.dismiss(toast)
        XCTAssertTrue(manager.toasts.isEmpty)
    }
    
    @MainActor
    func testToastManagerConvenienceMethods() {
        let manager = ToastManager()
        
        // Test success toast
        manager.showSuccess(title: "Success", message: "Success message")
        XCTAssertEqual(manager.toasts.count, 1)
        XCTAssertEqual(manager.toasts.first?.type, .success)
        XCTAssertEqual(manager.toasts.first?.title, "Success")
        
        // Test error toast
        manager.showError(title: "Error", message: "Error message")
        XCTAssertEqual(manager.toasts.count, 2)
        XCTAssertEqual(manager.toasts.last?.type, .error)
        
        // Test info toast
        manager.showInfo(title: "Info")
        XCTAssertEqual(manager.toasts.count, 3)
        XCTAssertEqual(manager.toasts.last?.type, .info)
        
        // Test warning toast
        manager.showWarning(title: "Warning")
        XCTAssertEqual(manager.toasts.count, 4)
        XCTAssertEqual(manager.toasts.last?.type, .warning)
        
        // Dismiss all
        manager.dismissAll()
        XCTAssertTrue(manager.toasts.isEmpty)
    }
    
    @MainActor
    func testToastManagerPredefinedMethods() {
        let manager = ToastManager()
        
        // Test trade executed toast
        manager.showTradeExecuted(symbol: "BTC/USD", side: "buy")
        XCTAssertEqual(manager.toasts.count, 1)
        XCTAssertEqual(manager.toasts.first?.type, .success)
        XCTAssertEqual(manager.toasts.first?.title, "Order Submitted Successfully")
        XCTAssertTrue(manager.toasts.first?.message?.contains("Buy order for BTC/USD") == true)
        
        // Test settings saved toast
        manager.showSettingsSaved()
        XCTAssertEqual(manager.toasts.count, 2)
        XCTAssertEqual(manager.toasts.last?.title, "Settings Saved")
        
        // Test API keys validated toast
        manager.showAPIKeysValidated(exchange: "Binance")
        XCTAssertEqual(manager.toasts.count, 3)
        XCTAssertEqual(manager.toasts.last?.title, "API Keys Validated")
        XCTAssertTrue(manager.toasts.last?.message?.contains("Binance") == true)
        
        // Test strategy changed toast
        manager.showStrategyChanged(strategy: "RSI Strategy", enabled: true)
        XCTAssertEqual(manager.toasts.count, 4)
        XCTAssertEqual(manager.toasts.last?.type, .info)
        XCTAssertEqual(manager.toasts.last?.title, "Strategy Enabled")
        
        // Test data exported toast
        manager.showDataExported(type: "Trading Logs")
        XCTAssertEqual(manager.toasts.count, 5)
        XCTAssertEqual(manager.toasts.last?.title, "Export Successful")
        
        manager.dismissAll()
        XCTAssertTrue(manager.toasts.isEmpty)
    }
    
    @MainActor
    func testToastManagerErrorMethods() {
        let manager = ToastManager()
        
        // Test trade execution failed toast
        manager.showTradeExecutionFailed(error: "Insufficient funds")
        XCTAssertEqual(manager.toasts.count, 1)
        XCTAssertEqual(manager.toasts.first?.type, .error)
        XCTAssertEqual(manager.toasts.first?.title, "Order Failed")
        XCTAssertEqual(manager.toasts.first?.message, "Insufficient funds")
        
        // Test API key validation failed toast
        manager.showAPIKeyValidationFailed(exchange: "Kraken", error: "Invalid API key")
        XCTAssertEqual(manager.toasts.count, 2)
        XCTAssertEqual(manager.toasts.last?.type, .error)
        XCTAssertEqual(manager.toasts.last?.title, "Kraken Connection Failed")
        
        // Test data export failed toast
        manager.showDataExportFailed(type: "P&L Data", error: "File write error")
        XCTAssertEqual(manager.toasts.count, 3)
        XCTAssertEqual(manager.toasts.last?.type, .error)
        XCTAssertEqual(manager.toasts.last?.title, "Export Failed")
        
        manager.dismissAll()
        XCTAssertTrue(manager.toasts.isEmpty)
    }
}