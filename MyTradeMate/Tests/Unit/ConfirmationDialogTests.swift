import XCTest
import SwiftUI
@testable import MyTradeMate

class ConfirmationDialogTests: XCTestCase {
    
    // MARK: - Base ConfirmationDialog Tests
    
    func testConfirmationDialogInitialization() {
        let dialog = ConfirmationDialog(
            title: "Test Title",
            message: "Test Message",
            icon: "checkmark.circle",
            iconColor: .green,
            confirmButtonText: "Confirm",
            confirmButtonColor: .blue,
            cancelButtonText: "Cancel",
            isDestructive: false,
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
    
    func testSimpleConfirmationDialog() {
        let dialog = ConfirmationDialog.simple(
            title: "Save Changes",
            message: "Do you want to save your changes?",
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
    
    func testDestructiveConfirmationDialog() {
        let dialog = ConfirmationDialog.destructive(
            title: "Delete Account",
            message: "This action cannot be undone.",
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
    
    func testSettingsChangeConfirmationDialog() {
        let dialog = ConfirmationDialog.settingsChange(
            title: "Apply Settings",
            message: "Settings will be applied.",
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
    
    func testStrategyToggleConfirmationDialog() {
        let dialog = ConfirmationDialog.strategyToggle(
            strategyName: "RSI Strategy",
            isEnabling: true,
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
    
    // MARK: - TradeConfirmationDialog Tests
    
    func testTradeConfirmationDialogInitialization() {
        let trade = TradeRequest(
            symbol: "BTC/USDT",
            side: .buy,
            amount: 0.001,
            price: 45000.0,
            mode: .manual,
            isDemo: true
        )
        
        let dialog = TradeConfirmationDialog(
            trade: trade,
            onConfirm: {},
            onCancel: {},
            isExecuting: false
        )
        
        XCTAssertNotNil(dialog)
    }
    
    func testTradeConfirmationDialogWithLiveTrade() {
        let trade = TradeRequest(
            symbol: "ETH/USDT",
            side: .sell,
            amount: 0.1,
            price: 3000.0,
            mode: .manual,
            isDemo: false
        )
        
        let dialog = TradeConfirmationDialog(
            trade: trade,
            onConfirm: {},
            onCancel: {},
            isExecuting: false
        )
        
        XCTAssertNotNil(dialog)
    }
    
    // MARK: - StrategyConfirmationDialog Tests
    
    func testStrategyConfirmationDialogEnabling() {
        let dialog = StrategyConfirmationDialog(
            strategyName: "MACD Strategy",
            isEnabling: true,
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
    
    func testStrategyConfirmationDialogDisabling() {
        let dialog = StrategyConfirmationDialog(
            strategyName: "RSI Strategy",
            isEnabling: false,
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
    
    func testStrategySettingsConfirmationDialog() {
        let changes = [
            "RSI threshold changed to 30/70",
            "Stop loss set to 2%",
            "Take profit set to 5%"
        ]
        
        let dialog = StrategySettingsConfirmationDialog(
            strategyName: "RSI Strategy",
            changes: changes,
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
    
    // MARK: - SettingsConfirmationDialog Tests
    
    func testSettingChangeModel() {
        let change = SettingChange(
            settingName: "Auto Trading",
            oldValue: "Disabled",
            newValue: "Enabled",
            requiresRestart: false,
            warning: "This will allow AI to place real trades"
        )
        
        XCTAssertEqual(change.settingName, "Auto Trading")
        XCTAssertEqual(change.oldValue, "Disabled")
        XCTAssertEqual(change.newValue, "Enabled")
        XCTAssertFalse(change.requiresRestart)
        XCTAssertEqual(change.warning, "This will allow AI to place real trades")
    }
    
    func testSettingsConfirmationDialog() {
        let changes = [
            SettingChange(
                settingName: "Auto Trading",
                oldValue: "Disabled",
                newValue: "Enabled",
                requiresRestart: false,
                warning: "This will allow AI to place real trades"
            )
        ]
        
        let dialog = SettingsConfirmationDialog(
            title: "Apply Settings Changes",
            changes: changes,
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
    
    func testAutoTradingConfirmationDialogEnabling() {
        let dialog = AutoTradingConfirmationDialog(
            isEnabling: true,
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
    
    func testAutoTradingConfirmationDialogDisabling() {
        let dialog = AutoTradingConfirmationDialog(
            isEnabling: false,
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
    
    // MARK: - AccountDeletionConfirmationDialog Tests
    
    func testAccountDeletionConfirmationDialog() {
        let dialog = AccountDeletionConfirmationDialog(
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
    
    func testDataExportConfirmationDialog() {
        let dialog = DataExportConfirmationDialog(
            exportType: .logs,
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
    
    func testExportTypeDisplayNames() {
        XCTAssertEqual(ExportType.logs.displayName, "Diagnostic Logs")
        XCTAssertEqual(ExportType.tradingData.displayName, "Trading Data")
        XCTAssertEqual(ExportType.allData.displayName, "All Data")
    }
    
    func testExportTypeIncludedData() {
        let logsIncluded = ExportType.logs.includedData
        XCTAssertTrue(logsIncluded.contains("Application logs"))
        XCTAssertTrue(logsIncluded.contains("Error reports"))
        
        let tradingIncluded = ExportType.tradingData.includedData
        XCTAssertTrue(tradingIncluded.contains("Trade history"))
        XCTAssertTrue(tradingIncluded.contains("P&L data"))
        
        let allIncluded = ExportType.allData.includedData
        XCTAssertTrue(allIncluded.contains("All trading data"))
        XCTAssertTrue(allIncluded.contains("Strategy configurations"))
    }
    
    func testExportTypeExcludedData() {
        let logsExcluded = ExportType.logs.excludedData
        XCTAssertTrue(logsExcluded.contains("API keys and secrets"))
        
        let tradingExcluded = ExportType.tradingData.excludedData
        XCTAssertTrue(tradingExcluded.contains("API keys and secrets"))
        
        let allExcluded = ExportType.allData.excludedData
        XCTAssertTrue(allExcluded.contains("API keys and secrets (for security)"))
    }
    
    // MARK: - Integration Tests
    
    func testConfirmationDialogCallbacks() {
        var confirmCalled = false
        var cancelCalled = false
        
        let dialog = ConfirmationDialog.simple(
            title: "Test",
            message: "Test message",
            onConfirm: { confirmCalled = true },
            onCancel: { cancelCalled = true }
        )
        
        // Note: In a real UI test, we would simulate button taps
        // For unit tests, we just verify the dialog can be created with callbacks
        XCTAssertNotNil(dialog)
        XCTAssertFalse(confirmCalled)
        XCTAssertFalse(cancelCalled)
    }
    
    func testExecutingStateHandling() {
        let dialog = ConfirmationDialog.simple(
            title: "Test",
            message: "Test message",
            isExecuting: true,
            onConfirm: {},
            onCancel: {}
        )
        
        XCTAssertNotNil(dialog)
    }
}