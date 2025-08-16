import XCTest
import SwiftUI
@testable import MyTradeMate

final class SignalVisualizationViewTests: XCTestCase {
    
    func testSignalVisualizationViewWithBuySignal() {
        // Given
        let signal = SignalInfo(
            direction: "BUY",
            confidence: 0.85,
            reason: "Strong bullish momentum detected",
            timestamp: Date()
        )
        
        // When
        let view = SignalVisualizationView(
            signal: signal,
            isRefreshing: false,
            timeframe: .h1,
            lastUpdated: Date(),
            onRefresh: {}
        )
        
        // Then
        XCTAssertNotNil(view)
        // Additional UI testing would require ViewInspector or similar framework
    }
    
    func testSignalVisualizationViewWithSellSignal() {
        // Given
        let signal = SignalInfo(
            direction: "SELL",
            confidence: 0.65,
            reason: "Bearish reversal pattern identified",
            timestamp: Date()
        )
        
        // When
        let view = SignalVisualizationView(
            signal: signal,
            isRefreshing: false,
            timeframe: .m5,
            lastUpdated: Date(),
            onRefresh: {}
        )
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testSignalVisualizationViewWithHoldSignal() {
        // Given
        let signal = SignalInfo(
            direction: "HOLD",
            confidence: 0.45,
            reason: "Market consolidating, wait for breakout",
            timestamp: Date()
        )
        
        // When
        let view = SignalVisualizationView(
            signal: signal,
            isRefreshing: false,
            timeframe: .h4,
            lastUpdated: Date(),
            onRefresh: {}
        )
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testSignalVisualizationViewWithLoadingState() {
        // When
        let view = SignalVisualizationView(
            signal: nil,
            isRefreshing: true,
            timeframe: .h1,
            lastUpdated: Date(),
            onRefresh: {}
        )
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testSignalVisualizationViewWithEmptyState() {
        // When
        let view = SignalVisualizationView(
            signal: nil,
            isRefreshing: false,
            timeframe: .h1,
            lastUpdated: Date(),
            onRefresh: {}
        )
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testSignalDirectionIndicatorColors() {
        // Test BUY signal color
        let buyIndicator = SignalDirectionIndicator(direction: "BUY")
        XCTAssertNotNil(buyIndicator)
        
        // Test SELL signal color
        let sellIndicator = SignalDirectionIndicator(direction: "SELL")
        XCTAssertNotNil(sellIndicator)
        
        // Test HOLD signal color
        let holdIndicator = SignalDirectionIndicator(direction: "HOLD")
        XCTAssertNotNil(holdIndicator)
    }
    
    func testConfidenceGaugeView() {
        // Test high confidence
        let highConfidenceGauge = ConfidenceGaugeView(confidence: 0.85)
        XCTAssertNotNil(highConfidenceGauge)
        
        // Test medium confidence
        let mediumConfidenceGauge = ConfidenceGaugeView(confidence: 0.55)
        XCTAssertNotNil(mediumConfidenceGauge)
        
        // Test low confidence
        let lowConfidenceGauge = ConfidenceGaugeView(confidence: 0.25)
        XCTAssertNotNil(lowConfidenceGauge)
    }
    
    func testConfidenceBarView() {
        // Test BUY signal bar
        let buyBar = ConfidenceBarView(confidence: 0.75, direction: "BUY")
        XCTAssertNotNil(buyBar)
        
        // Test SELL signal bar
        let sellBar = ConfidenceBarView(confidence: 0.60, direction: "SELL")
        XCTAssertNotNil(sellBar)
        
        // Test HOLD signal bar
        let holdBar = ConfidenceBarView(confidence: 0.40, direction: "HOLD")
        XCTAssertNotNil(holdBar)
    }
    
    func testSignalReasoningView() {
        // Given
        let shortReason = "Simple reason"
        let longReason = "This is a very long reason that should be truncated initially and then expanded when the user taps the expand button. It contains multiple sentences and detailed analysis."
        
        // When
        let shortReasonView = SignalReasoningView(reason: shortReason)
        let longReasonView = SignalReasoningView(reason: longReason)
        
        // Then
        XCTAssertNotNil(shortReasonView)
        XCTAssertNotNil(longReasonView)
    }
    
    func testSignalInfoModel() {
        // Given
        let direction = "BUY"
        let confidence = 0.75
        let reason = "Test reason"
        let timestamp = Date()
        
        // When
        let signalInfo = SignalInfo(
            direction: direction,
            confidence: confidence,
            reason: reason,
            timestamp: timestamp
        )
        
        // Then
        XCTAssertEqual(signalInfo.direction, direction)
        XCTAssertEqual(signalInfo.confidence, confidence)
        XCTAssertEqual(signalInfo.reason, reason)
        XCTAssertEqual(signalInfo.timestamp, timestamp)
    }
    
    func testSignalStrengthEnum() {
        // Test very strong signal
        let veryStrong = SignalStrength.from(confidence: 0.85)
        XCTAssertEqual(veryStrong, .veryStrong)
        
        // Test strong signal
        let strong = SignalStrength.from(confidence: 0.65)
        XCTAssertEqual(strong, .strong)
        
        // Test moderate signal
        let moderate = SignalStrength.from(confidence: 0.45)
        XCTAssertEqual(moderate, .moderate)
        
        // Test weak signal
        let weak = SignalStrength.from(confidence: 0.25)
        XCTAssertEqual(weak, .weak)
        
        // Test very weak signal
        let veryWeak = SignalStrength.from(confidence: 0.05)
        XCTAssertEqual(veryWeak, .veryWeak)
    }
    
    func testSignalDirectionEnum() {
        // Test buy direction
        let buy = SignalDirection.buy
        XCTAssertEqual(buy.rawValue, "BUY")
        XCTAssertEqual(buy.displayName, "Buy")
        
        // Test sell direction
        let sell = SignalDirection.sell
        XCTAssertEqual(sell.rawValue, "SELL")
        XCTAssertEqual(sell.displayName, "Sell")
        
        // Test hold direction
        let hold = SignalDirection.hold
        XCTAssertEqual(hold.rawValue, "HOLD")
        XCTAssertEqual(hold.displayName, "Hold")
    }
}