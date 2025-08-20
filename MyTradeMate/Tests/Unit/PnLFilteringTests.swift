import XCTest
@testable import MyTradeMate

final class PnLFilteringTests: XCTestCase {
    
    var viewModel: PnLVM!
    
    override func setUp() {
        super.setUp()
        viewModel = PnLVM()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testDateFilterRanges() {
        // Test all date filter options return correct ranges
        let calendar = Calendar.current
        let now = Date()
        
        // Test "All Time" filter
        let allTimeRange = PnLDateFilter.all.dateRange
        XCTAssertNil(allTimeRange.0)
        XCTAssertNil(allTimeRange.1)
        
        // Test "Today" filter
        let todayRange = PnLDateFilter.today.dateRange
        XCTAssertNotNil(todayRange.0)
        XCTAssertNotNil(todayRange.1)
        XCTAssertTrue(calendar.isDate(todayRange.0!, inSameDayAs: now))
        
        // Test "7 Days" filter
        let weekRange = PnLDateFilter.week.dateRange
        XCTAssertNotNil(weekRange.0)
        XCTAssertNotNil(weekRange.1)
        let expectedWeekStart = calendar.date(byAdding: .day, value: -7, to: now)!
        XCTAssertTrue(abs(weekRange.0!.timeIntervalSince(expectedWeekStart)) < 1.0)
        
        // Test "30 Days" filter
        let monthRange = PnLDateFilter.month.dateRange
        XCTAssertNotNil(monthRange.0)
        XCTAssertNotNil(monthRange.1)
        let expectedMonthStart = calendar.date(byAdding: .day, value: -30, to: now)!
        XCTAssertTrue(abs(monthRange.0!.timeIntervalSince(expectedMonthStart)) < 1.0)
        
        // Test "90 Days" filter
        let quarterRange = PnLDateFilter.quarter.dateRange
        XCTAssertNotNil(quarterRange.0)
        XCTAssertNotNil(quarterRange.1)
        let expectedQuarterStart = calendar.date(byAdding: .day, value: -90, to: now)!
        XCTAssertTrue(abs(quarterRange.0!.timeIntervalSince(expectedQuarterStart)) < 1.0)
    }
    
    func testDateFilterUpdate() {
        // Given
        let initialFilter = viewModel.dateFilter
        
        // When
        viewModel.updateDateFilter(.week)
        
        // Then
        XCTAssertEqual(viewModel.dateFilter, .week)
        XCTAssertNotEqual(viewModel.dateFilter, initialFilter)
    }
    
    func testSymbolFilterUpdate() {
        // Given
        let initialSymbol = viewModel.symbolFilter
        
        // When
        viewModel.updateSymbolFilter("BTCUSDT")
        
        // Then
        XCTAssertEqual(viewModel.symbolFilter, "BTCUSDT")
        XCTAssertNotEqual(viewModel.symbolFilter, initialSymbol)
    }
    
    func testAvailableSymbolsInitialization() {
        // Given - Fresh view model
        let vm = PnLVM()
        
        // Then - Should start with "All" as default
        XCTAssertEqual(vm.availableSymbols, ["All"])
        XCTAssertEqual(vm.symbolFilter, "All")
    }
    
    func testFilterOptionsEnumeration() {
        // Test that all filter options are available
        let allFilters = PnLDateFilter.allCases
        
        XCTAssertEqual(allFilters.count, 5)
        XCTAssertTrue(allFilters.contains(.all))
        XCTAssertTrue(allFilters.contains(.today))
        XCTAssertTrue(allFilters.contains(.week))
        XCTAssertTrue(allFilters.contains(.month))
        XCTAssertTrue(allFilters.contains(.quarter))
    }
    
    func testFilterDisplayNames() {
        // Test that filter display names are user-friendly
        XCTAssertEqual(PnLDateFilter.all.rawValue, "All Time")
        XCTAssertEqual(PnLDateFilter.today.rawValue, "Today")
        XCTAssertEqual(PnLDateFilter.week.rawValue, "7 Days")
        XCTAssertEqual(PnLDateFilter.month.rawValue, "30 Days")
        XCTAssertEqual(PnLDateFilter.quarter.rawValue, "90 Days")
    }
    
    func testFilterIdentifiableConformance() {
        // Test that filters can be used in SwiftUI pickers
        let filter = PnLDateFilter.week
        XCTAssertEqual(filter.id, filter.rawValue)
    }
}