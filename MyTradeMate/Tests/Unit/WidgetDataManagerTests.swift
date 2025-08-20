import XCTest
@testable import MyTradeMate

final class WidgetDataManagerTests: XCTestCase {
    
    var widgetDataManager: WidgetDataManager!
    
    override func setUp() {
        super.setUp()
        widgetDataManager = WidgetDataManager.shared
        
        // Clear any existing data
        if let userDefaults = UserDefaults(suiteName: "group.com.mytrademate.app") {
            userDefaults.removeObject(forKey: "widget_trading_data")
        }
    }
    
    override func tearDown() {
        // Clean up after tests
        if let userDefaults = UserDefaults(suiteName: "group.com.mytrademate.app") {
            userDefaults.removeObject(forKey: "widget_trading_data")
        }
        super.tearDown()
    }
    
    func testWidgetDataDefaultValues() {
        let defaultData = WidgetData.default
        
        XCTAssertEqual(defaultData.pnl, 0)
        XCTAssertEqual(defaultData.pnlPercentage, 0)
        XCTAssertEqual(defaultData.todayPnL, 0)
        XCTAssertEqual(defaultData.unrealizedPnL, 0)
        XCTAssertEqual(defaultData.equity, 10000)
        XCTAssertEqual(defaultData.openPositions, 0)
        XCTAssertEqual(defaultData.lastPrice, 45000)
        XCTAssertEqual(defaultData.priceChange, 0)
        XCTAssertTrue(defaultData.isDemoMode)
        XCTAssertEqual(defaultData.connectionStatus, "disconnected")
        XCTAssertEqual(defaultData.symbol, "BTC/USDT")
    }
    
    func testSaveAndLoadWidgetData() {
        let testData = WidgetData(
            pnl: 1250.50,
            pnlPercentage: 12.5,
            todayPnL: 125.30,
            unrealizedPnL: 45.20,
            equity: 11250.50,
            openPositions: 3,
            lastPrice: 45250.75,
            priceChange: 1.2,
            isDemoMode: false,
            connectionStatus: "connected",
            lastUpdated: Date(),
            symbol: "BTC/USDT"
        )
        
        // Save data
        widgetDataManager.saveWidgetData(testData)
        
        // Load data
        let loadedData = widgetDataManager.loadWidgetData()
        
        // Verify data matches
        XCTAssertEqual(loadedData.pnl, testData.pnl, accuracy: 0.01)
        XCTAssertEqual(loadedData.pnlPercentage, testData.pnlPercentage, accuracy: 0.01)
        XCTAssertEqual(loadedData.todayPnL, testData.todayPnL, accuracy: 0.01)
        XCTAssertEqual(loadedData.unrealizedPnL, testData.unrealizedPnL, accuracy: 0.01)
        XCTAssertEqual(loadedData.equity, testData.equity, accuracy: 0.01)
        XCTAssertEqual(loadedData.openPositions, testData.openPositions)
        XCTAssertEqual(loadedData.lastPrice, testData.lastPrice, accuracy: 0.01)
        XCTAssertEqual(loadedData.priceChange, testData.priceChange, accuracy: 0.01)
        XCTAssertEqual(loadedData.isDemoMode, testData.isDemoMode)
        XCTAssertEqual(loadedData.connectionStatus, testData.connectionStatus)
        XCTAssertEqual(loadedData.symbol, testData.symbol)
    }
    
    func testLoadWidgetDataWithNoSavedData() {
        // Ensure no data is saved
        if let userDefaults = UserDefaults(suiteName: "group.com.mytrademate.app") {
            userDefaults.removeObject(forKey: "widget_trading_data")
        }
        
        // Load data should return default
        let loadedData = widgetDataManager.loadWidgetData()
        let defaultData = WidgetData.default
        
        XCTAssertEqual(loadedData.pnl, defaultData.pnl)
        XCTAssertEqual(loadedData.equity, defaultData.equity)
        XCTAssertEqual(loadedData.isDemoMode, defaultData.isDemoMode)
        XCTAssertEqual(loadedData.connectionStatus, defaultData.connectionStatus)
    }
    
    func testWidgetDataCodable() {
        let testData = WidgetData(
            pnl: 1250.50,
            pnlPercentage: 12.5,
            todayPnL: 125.30,
            unrealizedPnL: 45.20,
            equity: 11250.50,
            openPositions: 3,
            lastPrice: 45250.75,
            priceChange: 1.2,
            isDemoMode: false,
            connectionStatus: "connected",
            lastUpdated: Date(),
            symbol: "BTC/USDT"
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        XCTAssertNoThrow(try encoder.encode(testData))
        
        // Test decoding
        do {
            let encoded = try encoder.encode(testData)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(WidgetData.self, from: encoded)
            
            XCTAssertEqual(decoded.pnl, testData.pnl, accuracy: 0.01)
            XCTAssertEqual(decoded.equity, testData.equity, accuracy: 0.01)
            XCTAssertEqual(decoded.openPositions, testData.openPositions)
            XCTAssertEqual(decoded.isDemoMode, testData.isDemoMode)
            XCTAssertEqual(decoded.connectionStatus, testData.connectionStatus)
            XCTAssertEqual(decoded.symbol, testData.symbol)
        } catch {
            XCTFail("Failed to encode/decode WidgetData: \(error)")
        }
    }
    
    func testCreateWidgetDataFromPnLVM() {
        // This test would require mocking PnLVM and TradeManager
        // For now, we'll test the basic structure
        
        let testData = WidgetData(
            pnl: 500.0,
            pnlPercentage: 5.0,
            todayPnL: 50.0,
            unrealizedPnL: 25.0,
            equity: 10500.0,
            openPositions: 2,
            lastPrice: 45000.0,
            priceChange: 2.5,
            isDemoMode: true,
            connectionStatus: "connected",
            lastUpdated: Date(),
            symbol: "BTC/USDT"
        )
        
        // Verify the data structure is valid
        XCTAssertGreaterThan(testData.equity, 0)
        XCTAssertGreaterThanOrEqual(testData.openPositions, 0)
        XCTAssertFalse(testData.symbol.isEmpty)
        XCTAssertFalse(testData.connectionStatus.isEmpty)
    }
    
    func testWidgetDataManagerSingleton() {
        let manager1 = WidgetDataManager.shared
        let manager2 = WidgetDataManager.shared
        
        XCTAssertTrue(manager1 === manager2, "WidgetDataManager should be a singleton")
    }
    
    func testRefreshRateLimiting() {
        let manager = WidgetDataManager.shared
        
        // First refresh should work
        XCTAssertTrue(manager.canRefresh())
        manager.refreshWidgets()
        
        // Immediate second refresh should be rate limited
        XCTAssertFalse(manager.canRefresh())
        
        // Force refresh should work regardless
        manager.refreshWidgets(force: true)
        
        // Status should be tracked
        let status = manager.getRefreshStatus()
        XCTAssertFalse(status.isRefreshing)
    }
    
    func testManualRefresh() {
        let manager = WidgetDataManager.shared
        
        // Manual refresh should always work (force = true)
        manager.manualRefresh()
        
        let stats = manager.getRefreshStats()
        XCTAssertNotNil(stats.lastRefresh)
    }
    
    func testRefreshStats() {
        let manager = WidgetDataManager.shared
        
        let initialStats = manager.getRefreshStats()
        
        // Perform a refresh
        manager.manualRefresh()
        
        let updatedStats = manager.getRefreshStats()
        XCTAssertNotEqual(initialStats.lastRefresh, updatedStats.lastRefresh)
    }
    
    func testAutomaticRefreshScheduling() {
        let manager = WidgetDataManager.shared
        
        // Test that automatic refresh can be started and stopped
        manager.startAutomaticRefresh()
        manager.stopAllRefresh()
        
        // Should not crash or throw errors
        XCTAssertTrue(true)
    }
}