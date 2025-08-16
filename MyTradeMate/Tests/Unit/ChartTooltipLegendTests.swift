import XCTest
import SwiftUI
@testable import MyTradeMate

/// Tests for chart tooltip and legend functionality
final class ChartTooltipLegendTests: XCTestCase {
    
    // MARK: - Chart Legend Tests
    
    func testChartLegendCreation() {
        let items = [
            LegendItem(label: "Test Item 1", color: .green),
            LegendItem(label: "Test Item 2", systemImage: "circle")
        ]
        
        let legend = ChartLegend(items: items, title: "Test Legend")
        
        XCTAssertEqual(legend.items.count, 2)
        XCTAssertEqual(legend.title, "Test Legend")
        XCTAssertEqual(legend.items[0].label, "Test Item 1")
        XCTAssertEqual(legend.items[1].label, "Test Item 2")
    }
    
    func testCandlestickLegend() {
        let legend = ChartLegend.candlestickLegend()
        
        XCTAssertEqual(legend.title, "Chart Legend")
        XCTAssertEqual(legend.items.count, 4)
        
        let labels = legend.items.map { $0.label }
        XCTAssertTrue(labels.contains("Bullish Candle"))
        XCTAssertTrue(labels.contains("Bearish Candle"))
        XCTAssertTrue(labels.contains("Volume"))
        XCTAssertTrue(labels.contains("Price Range"))
    }
    
    func testPnLLegend() {
        let legend = ChartLegend.pnlLegend()
        
        XCTAssertEqual(legend.title, "Profit & Loss Chart")
        XCTAssertEqual(legend.items.count, 4)
        
        let labels = legend.items.map { $0.label }
        XCTAssertTrue(labels.contains("Profit"))
        XCTAssertTrue(labels.contains("Loss"))
        XCTAssertTrue(labels.contains("Equity Over Time"))
        XCTAssertTrue(labels.contains("Break Even"))
    }
    
    func testPriceLegend() {
        let legend = ChartLegend.priceLegend()
        
        XCTAssertEqual(legend.title, "Price Chart")
        XCTAssertEqual(legend.items.count, 4)
        
        let labels = legend.items.map { $0.label }
        XCTAssertTrue(labels.contains("Price Movement"))
        XCTAssertTrue(labels.contains("Current Price"))
        XCTAssertTrue(labels.contains("Time Period"))
        XCTAssertTrue(labels.contains("Price Trend"))
    }
    
    // MARK: - Tooltip Data Tests
    
    func testCandlestickTooltipData() {
        let candle = Candle(
            openTime: Date(),
            open: 100.0,
            high: 110.0,
            low: 95.0,
            close: 105.0,
            volume: 1000.0
        )
        
        let tooltipData = TooltipData.candlestick(candle: candle)
        
        XCTAssertEqual(tooltipData.title, "Candlestick Data")
        XCTAssertEqual(tooltipData.values.count, 5)
        
        let labels = tooltipData.values.map { $0.label }
        XCTAssertTrue(labels.contains("Open"))
        XCTAssertTrue(labels.contains("High"))
        XCTAssertTrue(labels.contains("Low"))
        XCTAssertTrue(labels.contains("Close"))
        XCTAssertTrue(labels.contains("Volume"))
        
        // Test values
        XCTAssertEqual(tooltipData.values[0].value, "100.00") // Open
        XCTAssertEqual(tooltipData.values[1].value, "110.00") // High
        XCTAssertEqual(tooltipData.values[2].value, "95.00")  // Low
        XCTAssertEqual(tooltipData.values[3].value, "105.00") // Close
        XCTAssertEqual(tooltipData.values[4].value, "1000")   // Volume
    }
    
    func testPnLTooltipData() {
        let equity = 10500.0
        let timestamp = Date()
        let change = 250.0
        
        let tooltipData = TooltipData.pnl(equity: equity, timestamp: timestamp, change: change)
        
        XCTAssertEqual(tooltipData.title, "P&L Data")
        XCTAssertEqual(tooltipData.values.count, 4)
        
        let labels = tooltipData.values.map { $0.label }
        XCTAssertTrue(labels.contains("Time"))
        XCTAssertTrue(labels.contains("Equity"))
        XCTAssertTrue(labels.contains("Change"))
        XCTAssertTrue(labels.contains("% Change"))
        
        // Test equity value
        let equityValue = tooltipData.values.first { $0.label == "Equity" }?.value
        XCTAssertEqual(equityValue, "10500.00")
        
        // Test change value
        let changeValue = tooltipData.values.first { $0.label == "Change" }?.value
        XCTAssertEqual(changeValue, "+250.00")
    }
    
    func testPriceTooltipData() {
        let price = 45000.0
        let timestamp = Date()
        let change = 500.0
        
        let tooltipData = TooltipData.price(price: price, timestamp: timestamp, change: change)
        
        XCTAssertEqual(tooltipData.title, "Price Data")
        XCTAssertEqual(tooltipData.values.count, 3)
        
        let labels = tooltipData.values.map { $0.label }
        XCTAssertTrue(labels.contains("Time"))
        XCTAssertTrue(labels.contains("Price"))
        XCTAssertTrue(labels.contains("Change"))
        
        // Test price value
        let priceValue = tooltipData.values.first { $0.label == "Price" }?.value
        XCTAssertEqual(priceValue, "45000.00")
        
        // Test change value
        let changeValue = tooltipData.values.first { $0.label == "Change" }?.value
        XCTAssertEqual(changeValue, "+500.00")
    }
    
    // MARK: - Chart Explanation Tests
    
    func testChartExplanationTypes() {
        let candlestickExplanation = ChartExplanation.candlestick()
        XCTAssertEqual(candlestickExplanation.type.title, "Candlestick Chart")
        XCTAssertEqual(candlestickExplanation.type.icon, "chart.bar")
        XCTAssertTrue(candlestickExplanation.type.description.contains("open, high, low, close"))
        
        let pnlExplanation = ChartExplanation.pnl()
        XCTAssertEqual(pnlExplanation.type.title, "P&L Chart")
        XCTAssertEqual(pnlExplanation.type.icon, "dollarsign.circle")
        XCTAssertTrue(pnlExplanation.type.description.contains("profit and loss"))
        
        let priceExplanation = ChartExplanation.price()
        XCTAssertEqual(priceExplanation.type.title, "Price Chart")
        XCTAssertEqual(priceExplanation.type.icon, "chart.line.uptrend.xyaxis")
        XCTAssertTrue(priceExplanation.type.description.contains("price movement"))
        
        let volumeExplanation = ChartExplanation.volume()
        XCTAssertEqual(volumeExplanation.type.title, "Volume Chart")
        XCTAssertEqual(volumeExplanation.type.icon, "chart.bar.fill")
        XCTAssertTrue(volumeExplanation.type.description.contains("trading volume"))
    }
    
    func testCompactChartExplanation() {
        let compactExplanation = ChartExplanation.candlestick(compact: true)
        XCTAssertTrue(compactExplanation.isCompact)
        
        let normalExplanation = ChartExplanation.candlestick(compact: false)
        XCTAssertFalse(normalExplanation.isCompact)
    }
    
    // MARK: - Volume Formatting Tests
    
    func testVolumeFormatting() {
        // Test large volume (millions)
        let largeVolume = 2_500_000.0
        let candleLarge = Candle(openTime: Date(), open: 100, high: 110, low: 95, close: 105, volume: largeVolume)
        let tooltipLarge = TooltipData.candlestick(candle: candleLarge)
        let volumeValueLarge = tooltipLarge.values.first { $0.label == "Volume" }?.value
        XCTAssertEqual(volumeValueLarge, "2.5M")
        
        // Test medium volume (thousands)
        let mediumVolume = 1_500.0
        let candleMedium = Candle(openTime: Date(), open: 100, high: 110, low: 95, close: 105, volume: mediumVolume)
        let tooltipMedium = TooltipData.candlestick(candle: candleMedium)
        let volumeValueMedium = tooltipMedium.values.first { $0.label == "Volume" }?.value
        XCTAssertEqual(volumeValueMedium, "1.5K")
        
        // Test small volume
        let smallVolume = 500.0
        let candleSmall = Candle(openTime: Date(), open: 100, high: 110, low: 95, close: 105, volume: smallVolume)
        let tooltipSmall = TooltipData.candlestick(candle: candleSmall)
        let volumeValueSmall = tooltipSmall.values.first { $0.label == "Volume" }?.value
        XCTAssertEqual(volumeValueSmall, "500")
    }
    
    // MARK: - Color Tests
    
    func testTooltipColors() {
        // Test bullish candle (close > open)
        let bullishCandle = Candle(openTime: Date(), open: 100, high: 110, low: 95, close: 105, volume: 1000)
        let bullishTooltip = TooltipData.candlestick(candle: bullishCandle)
        let closeValue = bullishTooltip.values.first { $0.label == "Close" }
        XCTAssertEqual(closeValue?.color, .green)
        
        // Test bearish candle (close < open)
        let bearishCandle = Candle(openTime: Date(), open: 105, high: 110, low: 95, close: 100, volume: 1000)
        let bearishTooltip = TooltipData.candlestick(candle: bearishCandle)
        let closeValueBearish = bearishTooltip.values.first { $0.label == "Close" }
        XCTAssertEqual(closeValueBearish?.color, .red)
        
        // Test P&L colors
        let profitTooltip = TooltipData.pnl(equity: 10000, timestamp: Date(), change: 500)
        let changeValue = profitTooltip.values.first { $0.label == "Change" }
        XCTAssertEqual(changeValue?.color, .green)
        
        let lossTooltip = TooltipData.pnl(equity: 10000, timestamp: Date(), change: -500)
        let lossChangeValue = lossTooltip.values.first { $0.label == "Change" }
        XCTAssertEqual(lossChangeValue?.color, .red)
    }
}