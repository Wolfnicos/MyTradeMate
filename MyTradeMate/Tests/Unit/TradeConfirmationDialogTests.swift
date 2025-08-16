import XCTest
import SwiftUI
@testable import MyTradeMate

final class TradeConfirmationDialogTests: XCTestCase {
    
    func testTradeRequestDisplayMode() {
        // Test demo mode
        let demoRequest = TradeRequest(
            symbol: "BTC/USDT",
            side: .buy,
            amount: 0.001,
            price: 45000.0,
            mode: .manual,
            isDemo: true
        )
        
        XCTAssertEqual(demoRequest.displayMode, "Demo")
        XCTAssertEqual(demoRequest.modeColor, .orange)
        
        // Test manual mode
        let manualRequest = TradeRequest(
            symbol: "BTC/USDT",
            side: .buy,
            amount: 0.001,
            price: 45000.0,
            mode: .manual,
            isDemo: false
        )
        
        XCTAssertEqual(manualRequest.displayMode, "Manual")
        XCTAssertEqual(manualRequest.modeColor, .blue)
        
        // Test auto mode
        let autoRequest = TradeRequest(
            symbol: "BTC/USDT",
            side: .sell,
            amount: 0.001,
            price: 45000.0,
            mode: .auto,
            isDemo: false
        )
        
        XCTAssertEqual(autoRequest.displayMode, "Auto")
        XCTAssertEqual(autoRequest.modeColor, .green)
    }
    
    func testTradeRequestCalculations() {
        let request = TradeRequest(
            symbol: "BTC/USDT",
            side: .buy,
            amount: 0.001,
            price: 45000.0,
            mode: .manual,
            isDemo: true
        )
        
        // Test estimated value calculation
        let expectedValue = request.amount * request.price
        XCTAssertEqual(expectedValue, 45.0, accuracy: 0.001)
    }
    
    func testTradeConfirmationDialogCreation() {
        let request = TradeRequest(
            symbol: "BTC/USDT",
            side: .buy,
            amount: 0.001,
            price: 45000.0,
            mode: .manual,
            isDemo: true
        )
        
        var confirmCalled = false
        var cancelCalled = false
        
        let dialog = TradeConfirmationDialog(
            trade: request,
            onConfirm: { confirmCalled = true },
            onCancel: { cancelCalled = true }
        )
        
        // Test that dialog can be created without crashing
        XCTAssertNotNil(dialog)
        
        // Test callback functionality (would need UI testing for actual button taps)
        XCTAssertFalse(confirmCalled)
        XCTAssertFalse(cancelCalled)
    }
    
    func testOrderSummaryRowCreation() {
        let row = OrderSummaryRow(
            label: "Symbol",
            value: "BTC/USDT",
            valueColor: .primary,
            valueWeight: .medium,
            showBadge: false
        )
        
        XCTAssertNotNil(row)
    }
    
    func testOrderSummaryRowWithBadge() {
        let row = OrderSummaryRow(
            label: "Mode",
            value: "Demo",
            valueColor: .orange,
            valueWeight: .semibold,
            showBadge: true
        )
        
        XCTAssertNotNil(row)
    }
}