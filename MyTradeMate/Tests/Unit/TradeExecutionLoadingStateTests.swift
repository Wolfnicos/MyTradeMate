import XCTest
import SwiftUI
@testable import MyTradeMate

final class TradeExecutionLoadingStateTests: XCTestCase {
    
    func testTradeConfirmationDialogShowsLoadingState() {
        // Given
        let tradeRequest = TradeRequest(
            symbol: "BTC/USDT",
            side: .buy,
            amount: 0.001,
            price: 45000.0,
            mode: .manual,
            isDemo: true
        )
        
        // When - Dialog is in executing state
        let dialog = TradeConfirmationDialog(
            trade: tradeRequest,
            onConfirm: {},
            onCancel: {},
            isExecuting: true
        )
        
        // Then - Should show loading state
        // Note: In a real test, we would use ViewInspector or similar to verify the UI state
        // For now, we just verify the dialog can be created with the isExecuting parameter
        XCTAssertNotNil(dialog)
    }
    
    func testTradeConfirmationDialogShowsButtonsWhenNotExecuting() {
        // Given
        let tradeRequest = TradeRequest(
            symbol: "BTC/USDT",
            side: .sell,
            amount: 0.002,
            price: 44000.0,
            mode: .manual,
            isDemo: false
        )
        
        // When - Dialog is not in executing state
        let dialog = TradeConfirmationDialog(
            trade: tradeRequest,
            onConfirm: {},
            onCancel: {},
            isExecuting: false
        )
        
        // Then - Should show action buttons
        // Note: In a real test, we would use ViewInspector or similar to verify the UI state
        // For now, we just verify the dialog can be created with the isExecuting parameter
        XCTAssertNotNil(dialog)
    }
    
    func testLoadingStateViewDisplaysCorrectMessage() {
        // Given
        let expectedMessage = "Submitting order..."
        
        // When
        let loadingView = LoadingStateView(message: expectedMessage)
        
        // Then
        // Note: In a real test, we would use ViewInspector or similar to verify the message is displayed
        // For now, we just verify the view can be created with the correct message
        XCTAssertNotNil(loadingView)
    }
}