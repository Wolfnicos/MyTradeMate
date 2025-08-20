import XCTest
import SwiftUI
@testable import MyTradeMate

final class LoadingStateViewTests: XCTestCase {
    
    func testLoadingStateViewCreation() {
        // Given
        let message = "Analyzing market..."
        
        // When
        let loadingView = LoadingStateView(message: message)
        
        // Then
        XCTAssertNotNil(loadingView)
    }
    
    func testLoadingStateViewWithDifferentMessages() {
        // Given
        let messages = [
            "Analyzing market...",
            "Loading signal...",
            "Calculating performance...",
            "Generating strategy signals..."
        ]
        
        // When & Then
        for message in messages {
            let loadingView = LoadingStateView(message: message)
            XCTAssertNotNil(loadingView)
        }
    }
}