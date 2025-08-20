import XCTest
@testable import MyTradeMate

class WidgetConfigurationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear any existing configuration
        if let userDefaults = UserDefaults(suiteName: "group.com.mytrademate.app") {
            userDefaults.removeObject(forKey: "widget_configuration")
        }
    }
    
    func testDefaultConfiguration() {
        let config = WidgetConfiguration.default
        
        XCTAssertEqual(config.displayMode, "balanced")
        XCTAssertEqual(config.primarySymbol, "AUTO")
        XCTAssertTrue(config.showDemoMode)
        XCTAssertEqual(config.colorTheme, "standard")
        XCTAssertEqual(config.updateFrequency, "normal")
    }
    
    func testConfigurationUpdateInterval() {
        let fastConfig = WidgetConfiguration(
            displayMode: "balanced",
            primarySymbol: "BTC/USDT",
            showDemoMode: true,
            colorTheme: "standard",
            updateFrequency: "fast"
        )
        XCTAssertEqual(fastConfig.updateInterval, 60)
        
        let normalConfig = WidgetConfiguration(
            displayMode: "balanced",
            primarySymbol: "BTC/USDT",
            showDemoMode: true,
            colorTheme: "standard",
            updateFrequency: "normal"
        )
        XCTAssertEqual(normalConfig.updateInterval, 120)
        
        let slowConfig = WidgetConfiguration(
            displayMode: "balanced",
            primarySymbol: "BTC/USDT",
            showDemoMode: true,
            colorTheme: "standard",
            updateFrequency: "slow"
        )
        XCTAssertEqual(slowConfig.updateInterval, 300)
        
        let manualConfig = WidgetConfiguration(
            displayMode: "balanced",
            primarySymbol: "BTC/USDT",
            showDemoMode: true,
            colorTheme: "standard",
            updateFrequency: "manual"
        )
        XCTAssertEqual(manualConfig.updateInterval, 3600)
    }
    
    func testEffectiveSymbol() {
        let autoConfig = WidgetConfiguration(
            displayMode: "balanced",
            primarySymbol: "AUTO",
            showDemoMode: true,
            colorTheme: "standard",
            updateFrequency: "normal"
        )
        XCTAssertEqual(autoConfig.effectiveSymbol, "BTC/USDT")
        
        let specificConfig = WidgetConfiguration(
            displayMode: "balanced",
            primarySymbol: "ETH/USDT",
            showDemoMode: true,
            colorTheme: "standard",
            updateFrequency: "normal"
        )
        XCTAssertEqual(specificConfig.effectiveSymbol, "ETH/USDT")
    }
    
    func testShouldShowDemoMode() {
        let showConfig = WidgetConfiguration(
            displayMode: "balanced",
            primarySymbol: "BTC/USDT",
            showDemoMode: true,
            colorTheme: "standard",
            updateFrequency: "normal"
        )
        XCTAssertTrue(showConfig.shouldShowDemoMode)
        
        let hideConfig = WidgetConfiguration(
            displayMode: "balanced",
            primarySymbol: "BTC/USDT",
            showDemoMode: false,
            colorTheme: "standard",
            updateFrequency: "normal"
        )
        XCTAssertFalse(hideConfig.shouldShowDemoMode)
    }
    
    func testWidgetConfigurationManager() {
        let manager = WidgetDataManager.shared
        
        // Test saving and loading configuration
        let testConfig = WidgetConfiguration(
            displayMode: "detailed",
            primarySymbol: "ETH/USDT",
            showDemoMode: false,
            colorTheme: "vibrant",
            updateFrequency: "fast"
        )
        
        manager.saveWidgetConfiguration(testConfig)
        let loadedConfig = manager.loadWidgetConfiguration()
        
        XCTAssertEqual(loadedConfig.displayMode, "detailed")
        XCTAssertEqual(loadedConfig.primarySymbol, "ETH/USDT")
        XCTAssertFalse(loadedConfig.showDemoMode)
        XCTAssertEqual(loadedConfig.colorTheme, "vibrant")
        XCTAssertEqual(loadedConfig.updateFrequency, "fast")
    }
    
    func testConfigurationEncoding() {
        let config = WidgetConfiguration(
            displayMode: "minimal",
            primarySymbol: "ADA/USDT",
            showDemoMode: true,
            colorTheme: "subtle",
            updateFrequency: "slow"
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        XCTAssertNoThrow(try encoder.encode(config))
        
        // Test decoding
        let decoder = JSONDecoder()
        do {
            let encoded = try encoder.encode(config)
            let decoded = try decoder.decode(WidgetConfiguration.self, from: encoded)
            
            XCTAssertEqual(decoded.displayMode, config.displayMode)
            XCTAssertEqual(decoded.primarySymbol, config.primarySymbol)
            XCTAssertEqual(decoded.showDemoMode, config.showDemoMode)
            XCTAssertEqual(decoded.colorTheme, config.colorTheme)
            XCTAssertEqual(decoded.updateFrequency, config.updateFrequency)
        } catch {
            XCTFail("Configuration encoding/decoding failed: \(error)")
        }
    }
    
    func testLoadDefaultConfigurationWhenNoneExists() {
        let manager = WidgetDataManager.shared
        let config = manager.loadWidgetConfiguration()
        
        // Should return default configuration when none exists
        XCTAssertEqual(config.displayMode, WidgetConfiguration.default.displayMode)
        XCTAssertEqual(config.primarySymbol, WidgetConfiguration.default.primarySymbol)
        XCTAssertEqual(config.showDemoMode, WidgetConfiguration.default.showDemoMode)
        XCTAssertEqual(config.colorTheme, WidgetConfiguration.default.colorTheme)
        XCTAssertEqual(config.updateFrequency, WidgetConfiguration.default.updateFrequency)
    }
}