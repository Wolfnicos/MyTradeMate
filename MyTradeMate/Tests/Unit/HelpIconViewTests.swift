import XCTest
import SwiftUI
@testable import MyTradeMate

final class HelpIconViewTests: XCTestCase {
    
    func testHelpIconViewCreation() {
        // Given
        let helpText = "This is help text for testing"
        
        // When
        let helpIcon = HelpIconView(helpText: helpText)
        
        // Then
        XCTAssertNotNil(helpIcon)
        XCTAssertEqual(helpIcon.helpText, helpText)
    }
    
    func testHelpIconModifier() {
        // Given
        let helpText = "This is help text for testing"
        let testView = Text("Test View")
        
        // When
        let modifiedView = testView.helpIcon(helpText)
        
        // Then
        XCTAssertNotNil(modifiedView)
    }
    
    func testHelpIconAccessibility() {
        // Given
        let helpText = "This is help text for testing"
        let helpIcon = HelpIconView(helpText: helpText)
        
        // When/Then
        // The accessibility properties are set in the view
        // This test ensures the component can be created without errors
        XCTAssertNotNil(helpIcon)
    }
    
    func testHelpIconWithLongText() {
        // Given
        let longHelpText = """
        This is a very long help text that should wrap properly in the tooltip.
        It contains multiple lines and should be displayed correctly in the popover.
        The text should be readable and properly formatted.
        """
        
        // When
        let helpIcon = HelpIconView(helpText: longHelpText)
        
        // Then
        XCTAssertNotNil(helpIcon)
        XCTAssertEqual(helpIcon.helpText, longHelpText)
    }
    
    func testHelpIconWithEmptyText() {
        // Given
        let emptyText = ""
        
        // When
        let helpIcon = HelpIconView(helpText: emptyText)
        
        // Then
        XCTAssertNotNil(helpIcon)
        XCTAssertEqual(helpIcon.helpText, emptyText)
    }
}