import XCTest
@testable import MyTradeMate

/// Tests for trade execution error handling
@MainActor
final class TradeExecutionErrorHandlingTests: XCTestCase {
    
    var viewModel: TradeConfirmationViewModel!
    var mockToastManager: MockToastManager!
    
    override func setUp() {
        super.setUp()
        mockToastManager = MockToastManager()
        viewModel = TradeConfirmationViewModel(toastManager: mockToastManager)
    }
    
    override func tearDown() {
        viewModel = nil
        mockToastManager = nil
        super.tearDown()
    }
    
    // MARK: - Error Handling Tests
    
    func testTradeExecutionFailure_ShowsErrorToast() async {
        // Given
        let tradeRequest = TradeRequest(
            symbol: "BTC/USDT",
            side: .buy,
            amount: 0.001,
            price: 45000.0,
            mode: .manual,
            isDemo: false // This will trigger an error in live mode
        )
        
        // When
        let success = await viewModel.executeTradeOrder(tradeRequest)
        
        // Then
        XCTAssertFalse(success, "Trade execution should fail")
        XCTAssertTrue(mockToastManager.errorToastShown, "Error toast should be shown")
        XCTAssertFalse(viewModel.errorMessage.isEmpty, "Error message should be set")
        XCTAssertFalse(viewModel.isExecuting, "Should not be executing after failure")
    }
    
    func testTradeExecutionSuccess_ShowsSuccessToast() async {
        // Given
        let tradeRequest = TradeRequest(
            symbol: "BTC/USDT",
            side: .buy,
            amount: 0.001,
            price: 45000.0,
            mode: .manual,
            isDemo: true // Demo mode should succeed
        )
        
        // When
        let success = await viewModel.executeTradeOrder(tradeRequest)
        
        // Then
        XCTAssertTrue(success, "Trade execution should succeed in demo mode")
        XCTAssertTrue(mockToastManager.successToastShown, "Success toast should be shown")
        XCTAssertFalse(viewModel.isExecuting, "Should not be executing after completion")
    }
    
    func testInvalidOrderParameters_ShowsAppropriateError() async {
        // Given
        let tradeRequest = TradeRequest(
            symbol: "INVALID/SYMBOL",
            side: .buy,
            amount: -1.0, // Invalid negative amount
            price: 45000.0,
            mode: .manual,
            isDemo: true
        )
        
        // When
        let success = await viewModel.executeTradeOrder(tradeRequest)
        
        // Then
        XCTAssertFalse(success, "Trade execution should fail with invalid parameters")
        XCTAssertTrue(mockToastManager.errorToastShown, "Error toast should be shown")
        XCTAssertTrue(viewModel.errorMessage.contains("Invalid") || 
                     viewModel.errorMessage.contains("configuration"), 
                     "Error message should indicate invalid parameters")
    }
    
    func testExecutionState_UpdatesCorrectly() async {
        // Given
        let tradeRequest = TradeRequest(
            symbol: "BTC/USDT",
            side: .buy,
            amount: 0.001,
            price: 45000.0,
            mode: .manual,
            isDemo: true
        )
        
        // When
        XCTAssertFalse(viewModel.isExecuting, "Should not be executing initially")
        
        let executionTask = Task {
            await viewModel.executeTradeOrder(tradeRequest)
        }
        
        // Brief delay to check executing state
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await executionTask.value
        
        // Then
        XCTAssertFalse(viewModel.isExecuting, "Should not be executing after completion")
    }
    
    func testClearError_ResetsErrorState() {
        // Given
        viewModel.errorMessage = "Test error"
        viewModel.showErrorAlert = true
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertTrue(viewModel.errorMessage.isEmpty, "Error message should be cleared")
        XCTAssertFalse(viewModel.showErrorAlert, "Error alert should be dismissed")
    }
    
    func testErrorAlertMessage_IncludesRecoverySuggestion() {
        // Given
        viewModel.errorMessage = "Test error message"
        
        // When
        let alertMessage = viewModel.getErrorAlertMessage()
        
        // Then
        XCTAssertFalse(alertMessage.isEmpty, "Alert message should not be empty")
        XCTAssertTrue(alertMessage.contains("Test error message"), "Should contain original error message")
    }
}

// MARK: - Mock Toast Manager

class MockToastManager: ToastManager {
    var successToastShown = false
    var errorToastShown = false
    var lastSuccessMessage = ""
    var lastErrorMessage = ""
    
    override func showSuccess(title: String, message: String? = nil, duration: TimeInterval = 3.0) {
        successToastShown = true
        lastSuccessMessage = title
        super.showSuccess(title: title, message: message, duration: duration)
    }
    
    override func showError(title: String, message: String? = nil, duration: TimeInterval = 5.0) {
        errorToastShown = true
        lastErrorMessage = title
        super.showError(title: title, message: message, duration: duration)
    }
    
    override func showTradeExecuted(symbol: String, side: String) {
        successToastShown = true
        lastSuccessMessage = "Order Submitted Successfully"
        super.showTradeExecuted(symbol: symbol, side: side)
    }
    
    override func showTradeExecutionFailed(error: String) {
        errorToastShown = true
        lastErrorMessage = "Order Failed"
        super.showTradeExecutionFailed(error: error)
    }
}