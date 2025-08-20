import XCTest
@testable import MyTradeMate

final class TradeFilteringSortingTests: XCTestCase {
    
    var viewModel: TradesVM!
    
    override func setUp() {
        super.setUp()
        viewModel = TradesVM()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testSearchFiltering() {
        // Given
        let btcTrade = Trade(
            id: "1",
            symbol: "BTCUSDT",
            side: .long,
            size: 0.01,
            entryPrice: 45000,
            currentPrice: 46000,
            leverage: 1,
            timestamp: Date()
        )
        
        let ethTrade = Trade(
            id: "2",
            symbol: "ETHUSD",
            side: .short,
            size: 0.1,
            entryPrice: 2500,
            currentPrice: 2400,
            leverage: 2,
            timestamp: Date()
        )
        
        viewModel.openPositions = [btcTrade, ethTrade]
        
        // When
        viewModel.updateSearch("BTC")
        
        // Then
        XCTAssertEqual(viewModel.filteredTrades.count, 1)
        XCTAssertEqual(viewModel.filteredTrades.first?.symbol, "BTCUSDT")
    }
    
    func testSideFiltering() {
        // Given
        let longTrade = Trade(
            id: "1",
            symbol: "BTCUSDT",
            side: .long,
            size: 0.01,
            entryPrice: 45000,
            currentPrice: 46000,
            leverage: 1,
            timestamp: Date()
        )
        
        let shortTrade = Trade(
            id: "2",
            symbol: "ETHUSD",
            side: .short,
            size: 0.1,
            entryPrice: 2500,
            currentPrice: 2400,
            leverage: 2,
            timestamp: Date()
        )
        
        viewModel.openPositions = [longTrade, shortTrade]
        
        // When - Filter for long only
        viewModel.updateFilter(.buyOnly)
        
        // Then
        XCTAssertEqual(viewModel.filteredTrades.count, 1)
        XCTAssertEqual(viewModel.filteredTrades.first?.side, .long)
        
        // When - Filter for short only
        viewModel.updateFilter(.sellOnly)
        
        // Then
        XCTAssertEqual(viewModel.filteredTrades.count, 1)
        XCTAssertEqual(viewModel.filteredTrades.first?.side, .short)
    }
    
    func testDateSorting() {
        // Given
        let olderDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let newerDate = Date()
        
        let olderTrade = Trade(
            id: "1",
            symbol: "BTCUSDT",
            side: .long,
            size: 0.01,
            entryPrice: 45000,
            currentPrice: 46000,
            leverage: 1,
            timestamp: olderDate
        )
        
        let newerTrade = Trade(
            id: "2",
            symbol: "ETHUSD",
            side: .short,
            size: 0.1,
            entryPrice: 2500,
            currentPrice: 2400,
            leverage: 2,
            timestamp: newerDate
        )
        
        viewModel.openPositions = [olderTrade, newerTrade]
        
        // When - Sort by newest first
        viewModel.updateSort(.dateNewest)
        
        // Then
        XCTAssertEqual(viewModel.filteredTrades.first?.id, "2")
        XCTAssertEqual(viewModel.filteredTrades.last?.id, "1")
        
        // When - Sort by oldest first
        viewModel.updateSort(.dateOldest)
        
        // Then
        XCTAssertEqual(viewModel.filteredTrades.first?.id, "1")
        XCTAssertEqual(viewModel.filteredTrades.last?.id, "2")
    }
    
    func testPriceSorting() {
        // Given
        let lowerPriceTrade = Trade(
            id: "1",
            symbol: "ETHUSD",
            side: .long,
            size: 0.1,
            entryPrice: 2000,
            currentPrice: 2100,
            leverage: 1,
            timestamp: Date()
        )
        
        let higherPriceTrade = Trade(
            id: "2",
            symbol: "BTCUSDT",
            side: .short,
            size: 0.01,
            entryPrice: 45000,
            currentPrice: 46000,
            leverage: 1,
            timestamp: Date()
        )
        
        viewModel.openPositions = [lowerPriceTrade, higherPriceTrade]
        
        // When - Sort by highest price first
        viewModel.updateSort(.priceHighest)
        
        // Then
        XCTAssertEqual(viewModel.filteredTrades.first?.id, "2")
        XCTAssertEqual(viewModel.filteredTrades.last?.id, "1")
        
        // When - Sort by lowest price first
        viewModel.updateSort(.priceLowest)
        
        // Then
        XCTAssertEqual(viewModel.filteredTrades.first?.id, "1")
        XCTAssertEqual(viewModel.filteredTrades.last?.id, "2")
    }
    
    func testQuantitySorting() {
        // Given
        let smallerQuantityTrade = Trade(
            id: "1",
            symbol: "BTCUSDT",
            side: .long,
            size: 0.01,
            entryPrice: 45000,
            currentPrice: 46000,
            leverage: 1,
            timestamp: Date()
        )
        
        let largerQuantityTrade = Trade(
            id: "2",
            symbol: "ETHUSD",
            side: .short,
            size: 0.5,
            entryPrice: 2500,
            currentPrice: 2400,
            leverage: 1,
            timestamp: Date()
        )
        
        viewModel.openPositions = [smallerQuantityTrade, largerQuantityTrade]
        
        // When - Sort by largest quantity first
        viewModel.updateSort(.quantityLargest)
        
        // Then
        XCTAssertEqual(viewModel.filteredTrades.first?.id, "2")
        XCTAssertEqual(viewModel.filteredTrades.last?.id, "1")
        
        // When - Sort by smallest quantity first
        viewModel.updateSort(.quantitySmallest)
        
        // Then
        XCTAssertEqual(viewModel.filteredTrades.first?.id, "1")
        XCTAssertEqual(viewModel.filteredTrades.last?.id, "2")
    }
    
    func testCombinedFilteringAndSorting() {
        // Given
        let btcLongTrade = Trade(
            id: "1",
            symbol: "BTCUSDT",
            side: .long,
            size: 0.01,
            entryPrice: 45000,
            currentPrice: 46000,
            leverage: 1,
            timestamp: Date().addingTimeInterval(-3600)
        )
        
        let btcShortTrade = Trade(
            id: "2",
            symbol: "BTCUSDT",
            side: .short,
            size: 0.02,
            entryPrice: 44000,
            currentPrice: 43000,
            leverage: 1,
            timestamp: Date()
        )
        
        let ethLongTrade = Trade(
            id: "3",
            symbol: "ETHUSD",
            side: .long,
            size: 0.1,
            entryPrice: 2500,
            currentPrice: 2600,
            leverage: 1,
            timestamp: Date().addingTimeInterval(-1800)
        )
        
        viewModel.openPositions = [btcLongTrade, btcShortTrade, ethLongTrade]
        
        // When - Search for BTC and filter for long positions, sort by quantity
        viewModel.updateSearch("BTC")
        viewModel.updateFilter(.buyOnly)
        viewModel.updateSort(.quantityLargest)
        
        // Then - Should only show BTC long trades, sorted by quantity
        XCTAssertEqual(viewModel.filteredTrades.count, 1)
        XCTAssertEqual(viewModel.filteredTrades.first?.id, "1")
        XCTAssertEqual(viewModel.filteredTrades.first?.side, .long)
        XCTAssertTrue(viewModel.filteredTrades.first?.symbol.contains("BTC") == true)
    }
}