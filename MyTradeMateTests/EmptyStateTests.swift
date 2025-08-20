import XCTest
import SwiftUI
@testable import MyTradeMate

class EmptyStateTests: XCTestCase {
    
    // MARK: - Basic Initialization Tests
    
    func testEmptyStateViewInitialization() {
        // Test that EmptyStateView can be initialized with proper parameters
        let emptyState = EmptyStateView(
            icon: "brain.head.profile",
            title: "No Strategies Available",
            description: "Trading strategies will appear here when loaded"
        )
        
        XCTAssertEqual(emptyState.icon, "brain.head.profile")
        XCTAssertEqual(emptyState.title, "No Strategies Available")
        XCTAssertEqual(emptyState.description, "Trading strategies will appear here when loaded")
        XCTAssertNil(emptyState.actionButton)
        XCTAssertNil(emptyState.actionButtonTitle)
    }
    
    func testEmptyStateViewWithAction() {
        var actionCalled = false
        let emptyState = EmptyStateView(
            icon: "brain.head.profile",
            title: "No Strategies Available",
            description: "Trading strategies will appear here when loaded",
            actionButton: { actionCalled = true },
            actionButtonTitle: "Get Started"
        )
        
        XCTAssertNotNil(emptyState.actionButton)
        XCTAssertEqual(emptyState.actionButtonTitle, "Get Started")
        
        // Simulate button tap
        emptyState.actionButton?()
        XCTAssertTrue(actionCalled)
    }
    
    func testEmptyStateViewWithoutAction() {
        let emptyState = EmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: "No Data",
            description: "Data will appear here when available"
        )
        
        XCTAssertNil(emptyState.actionButton)
        XCTAssertNil(emptyState.actionButtonTitle)
    }
    
    // MARK: - Convenience Method Tests
    
    func testChartNoDataConvenienceMethod() {
        let emptyState = EmptyStateView.chartNoData()
        
        XCTAssertEqual(emptyState.icon, "chart.line.uptrend.xyaxis")
        XCTAssertEqual(emptyState.title, "No Chart Data")
        XCTAssertEqual(emptyState.description, "Market data is loading or unavailable")
        XCTAssertNil(emptyState.actionButton)
        XCTAssertNil(emptyState.actionButtonTitle)
    }
    
    func testChartNoDataWithCustomParameters() {
        var actionCalled = false
        let emptyState = EmptyStateView.chartNoData(
            title: "Custom Chart Title",
            description: "Custom chart description",
            actionButton: { actionCalled = true },
            actionButtonTitle: "Refresh"
        )
        
        XCTAssertEqual(emptyState.icon, "chart.line.uptrend.xyaxis")
        XCTAssertEqual(emptyState.title, "Custom Chart Title")
        XCTAssertEqual(emptyState.description, "Custom chart description")
        XCTAssertNotNil(emptyState.actionButton)
        XCTAssertEqual(emptyState.actionButtonTitle, "Refresh")
        
        emptyState.actionButton?()
        XCTAssertTrue(actionCalled)
    }
    
    func testPnLNoDataConvenienceMethod() {
        let emptyState = EmptyStateView.pnlNoData()
        
        XCTAssertEqual(emptyState.icon, "dollarsign.circle")
        XCTAssertEqual(emptyState.title, "No Trading Data")
        XCTAssertEqual(emptyState.description, "Start trading to see performance here")
        XCTAssertNil(emptyState.actionButton)
        XCTAssertNil(emptyState.actionButtonTitle)
    }
    
    func testPnLNoDataWithCustomParameters() {
        var actionCalled = false
        let emptyState = EmptyStateView.pnlNoData(
            title: "Custom P&L Title",
            description: "Custom P&L description",
            actionButton: { actionCalled = true },
            actionButtonTitle: "Start Trading"
        )
        
        XCTAssertEqual(emptyState.icon, "dollarsign.circle")
        XCTAssertEqual(emptyState.title, "Custom P&L Title")
        XCTAssertEqual(emptyState.description, "Custom P&L description")
        XCTAssertNotNil(emptyState.actionButton)
        XCTAssertEqual(emptyState.actionButtonTitle, "Start Trading")
        
        emptyState.actionButton?()
        XCTAssertTrue(actionCalled)
    }
    
    func testTradesNoDataConvenienceMethod() {
        let emptyState = EmptyStateView.tradesNoData()
        
        XCTAssertEqual(emptyState.icon, "list.bullet.rectangle")
        XCTAssertEqual(emptyState.title, "No Trades Yet")
        XCTAssertEqual(emptyState.description, "Start trading to see performance here")
        XCTAssertNil(emptyState.actionButton)
        XCTAssertNil(emptyState.actionButtonTitle)
    }
    
    func testTradesNoDataWithCustomParameters() {
        var actionCalled = false
        let emptyState = EmptyStateView.tradesNoData(
            title: "Custom Trades Title",
            description: "Custom trades description",
            actionButton: { actionCalled = true },
            actionButtonTitle: "View Strategies"
        )
        
        XCTAssertEqual(emptyState.icon, "list.bullet.rectangle")
        XCTAssertEqual(emptyState.title, "Custom Trades Title")
        XCTAssertEqual(emptyState.description, "Custom trades description")
        XCTAssertNotNil(emptyState.actionButton)
        XCTAssertEqual(emptyState.actionButtonTitle, "View Strategies")
        
        emptyState.actionButton?()
        XCTAssertTrue(actionCalled)
    }
    
    func testStrategiesNoDataConvenienceMethod() {
        let emptyState = EmptyStateView.strategiesNoData()
        
        XCTAssertEqual(emptyState.icon, "brain.head.profile")
        XCTAssertEqual(emptyState.title, "No Strategies Available")
        XCTAssertEqual(emptyState.description, "Trading strategies will appear here when loaded")
        XCTAssertNil(emptyState.actionButton)
        XCTAssertNil(emptyState.actionButtonTitle)
    }
    
    func testStrategiesNoDataWithCustomParameters() {
        var actionCalled = false
        let emptyState = EmptyStateView.strategiesNoData(
            title: "Custom Strategies Title",
            description: "Custom strategies description",
            actionButton: { actionCalled = true },
            actionButtonTitle: "Load Strategies"
        )
        
        XCTAssertEqual(emptyState.icon, "brain.head.profile")
        XCTAssertEqual(emptyState.title, "Custom Strategies Title")
        XCTAssertEqual(emptyState.description, "Custom strategies description")
        XCTAssertNotNil(emptyState.actionButton)
        XCTAssertEqual(emptyState.actionButtonTitle, "Load Strategies")
        
        emptyState.actionButton?()
        XCTAssertTrue(actionCalled)
    }
    
    // MARK: - Edge Cases and Validation Tests
    
    func testEmptyStateWithEmptyStrings() {
        let emptyState = EmptyStateView(
            icon: "",
            title: "",
            description: ""
        )
        
        XCTAssertEqual(emptyState.icon, "")
        XCTAssertEqual(emptyState.title, "")
        XCTAssertEqual(emptyState.description, "")
    }
    
    func testEmptyStateWithLongText() {
        let longTitle = "This is a very long title that might wrap to multiple lines in the UI"
        let longDescription = "This is a very long description that definitely will wrap to multiple lines and should be handled gracefully by the empty state component without breaking the layout or causing any visual issues"
        
        let emptyState = EmptyStateView(
            icon: "exclamationmark.triangle",
            title: longTitle,
            description: longDescription
        )
        
        XCTAssertEqual(emptyState.title, longTitle)
        XCTAssertEqual(emptyState.description, longDescription)
    }
    
    func testEmptyStateWithSpecialCharacters() {
        let titleWithSpecialChars = "No Data! 📊"
        let descriptionWithSpecialChars = "Data will appear here... 🚀 (when available)"
        
        let emptyState = EmptyStateView(
            icon: "chart.bar",
            title: titleWithSpecialChars,
            description: descriptionWithSpecialChars
        )
        
        XCTAssertEqual(emptyState.title, titleWithSpecialChars)
        XCTAssertEqual(emptyState.description, descriptionWithSpecialChars)
    }
    
    // MARK: - Action Button Tests
    
    func testActionButtonWithNilTitle() {
        let emptyState = EmptyStateView(
            icon: "brain.head.profile",
            title: "Test Title",
            description: "Test Description",
            actionButton: { },
            actionButtonTitle: nil
        )
        
        XCTAssertNotNil(emptyState.actionButton)
        XCTAssertNil(emptyState.actionButtonTitle)
    }
    
    func testActionButtonWithEmptyTitle() {
        let emptyState = EmptyStateView(
            icon: "brain.head.profile",
            title: "Test Title",
            description: "Test Description",
            actionButton: { },
            actionButtonTitle: ""
        )
        
        XCTAssertNotNil(emptyState.actionButton)
        XCTAssertEqual(emptyState.actionButtonTitle, "")
    }
    
    func testMultipleActionButtonCalls() {
        var callCount = 0
        let emptyState = EmptyStateView(
            icon: "brain.head.profile",
            title: "Test Title",
            description: "Test Description",
            actionButton: { callCount += 1 },
            actionButtonTitle: "Test Button"
        )
        
        // Simulate multiple button taps
        emptyState.actionButton?()
        emptyState.actionButton?()
        emptyState.actionButton?()
        
        XCTAssertEqual(callCount, 3)
    }
    
    // MARK: - Icon Validation Tests
    
    func testValidSystemIcons() {
        let validIcons = [
            "chart.line.uptrend.xyaxis",
            "dollarsign.circle",
            "list.bullet.rectangle",
            "brain.head.profile",
            "exclamationmark.triangle",
            "chart.bar"
        ]
        
        for icon in validIcons {
            let emptyState = EmptyStateView(
                icon: icon,
                title: "Test Title",
                description: "Test Description"
            )
            
            XCTAssertEqual(emptyState.icon, icon, "Icon should be set correctly for \(icon)")
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityProperties() {
        let emptyState = EmptyStateView(
            icon: "brain.head.profile",
            title: "No Strategies Available",
            description: "Trading strategies will appear here when loaded"
        )
        
        // Test that the component has the expected properties for accessibility
        XCTAssertEqual(emptyState.title, "No Strategies Available")
        XCTAssertEqual(emptyState.description, "Trading strategies will appear here when loaded")
        
        // In a real SwiftUI testing environment, we would verify:
        // - accessibilityElement(children: .combine) is set
        // - accessibilityLabel contains both title and description
        // - The component is properly accessible to VoiceOver
    }
}