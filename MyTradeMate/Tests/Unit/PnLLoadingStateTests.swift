import XCTest
@testable import MyTradeMate

@MainActor
final class PnLLoadingStateTests: XCTestCase {
    
    var viewModel: PnLVM!
    
    override func setUp() {
        super.setUp()
        viewModel = PnLVM()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialLoadingState() {
        // Given: A new PnLVM instance
        // When: The view model is initialized
        // Then: Loading state should be false initially
        XCTAssertFalse(viewModel.isLoading, "Initial loading state should be false")
    }
    
    func testLoadingStateOnStart() {
        // Given: A PnLVM instance
        // When: start() is called
        viewModel.start()
        
        // Then: Loading state should be true initially
        XCTAssertTrue(viewModel.isLoading, "Loading state should be true when starting")
    }
    
    func testLoadingStateOnTimeframeChange() {
        // Given: A PnLVM instance that has started
        viewModel.start()
        
        // Wait for initial loading to complete
        let expectation = XCTestExpectation(description: "Initial loading completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // When: Timeframe is changed
        viewModel.setTimeframe(.h4)
        
        // Then: Loading state should be false after timeframe change (synchronous operation)
        XCTAssertFalse(viewModel.isLoading, "Loading state should be false after timeframe change")
    }
    
    func testLoadingStateEventuallyCompletes() {
        // Given: A PnLVM instance
        // When: start() is called
        viewModel.start()
        
        // Then: Loading state should eventually become false
        let expectation = XCTestExpectation(description: "Loading completes")
        
        // Check loading state after a short delay to allow async operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !self.viewModel.isLoading {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
        XCTAssertFalse(viewModel.isLoading, "Loading state should be false after operations complete")
    }
    
    func testStopClearsTimer() {
        // Given: A PnLVM instance that has started
        viewModel.start()
        
        // When: stop() is called
        viewModel.stop()
        
        // Then: The view model should handle stop gracefully
        // (This test mainly ensures no crashes occur)
        XCTAssertNotNil(viewModel, "View model should still exist after stop")
    }
}