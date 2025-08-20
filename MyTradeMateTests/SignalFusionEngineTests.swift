import XCTest
@testable import MyTradeMate

final class SignalFusionEngineTests: XCTestCase {
    
    var fusionEngine: SignalFusionEngine!
    
    override func setUp() {
        super.setUp()
        fusionEngine = SignalFusionEngine()
    }
    
    override func tearDown() {
        fusionEngine = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Helpers
    
    private func createMockAISignal(vote: Action, confidence: Double) -> AISignal {
        return AISignal(source: "MockAI", vote: vote, confidence: confidence)
    }
    
    private func createMockStrategySignal(name: String, vote: Action, score: Double) -> AIStrategySignal {
        return AIStrategySignal(
            name: name,
            vote: vote,
            score: score,
            details: ["test_detail": 1.0]
        )
    }
    
    // MARK: - AI Signal Tests
    
    func testFuseWithOnlyAISignal() {
        // Given
        let aiSignal = createMockAISignal(vote: .buy, confidence: 0.8)
        let strategySignals: [AIStrategySignal] = []
        
        // When
        let result = fusionEngine.fuse(aiSignal: aiSignal, strategySignals: strategySignals)
        
        // Then
        XCTAssertEqual(result.action, .buy)
        XCTAssertEqual(result.confidence, 0.8, accuracy: 0.01)
        XCTAssertEqual(result.source, "AI-Only")
    }
    
    func testFuseWithOnlyStrategySignals() {
        // Given
        let aiSignal: AISignal? = nil
        let strategySignals = [
            createMockStrategySignal(name: "RSI", vote: .buy, score: 0.7),
            createMockStrategySignal(name: "MACD", vote: .sell, score: 0.6),
            createMockStrategySignal(name: "EMA", vote: .buy, score: 0.8)
        ]
        
        // When
        let result = fusionEngine.fuse(aiSignal: aiSignal, strategySignals: strategySignals)
        
        // Then
        XCTAssertEqual(result.action, .buy) // Should be buy (2 buy vs 1 sell)
        XCTAssertEqual(result.confidence, 0.7, accuracy: 0.01) // Average of buy signals
        XCTAssertEqual(result.source, "Strategy-Only")
    }
    
    func testFuseWithAIAndStrategySignals() {
        // Given
        let aiSignal = createMockAISignal(vote: .buy, confidence: 0.9)
        let strategySignals = [
            createMockStrategySignal(name: "RSI", vote: .buy, score: 0.7),
            createMockStrategySignal(name: "MACD", vote: .sell, score: 0.6),
            createMockStrategySignal(name: "EMA", vote: .buy, score: 0.8)
        ]
        
        // When
        let result = fusionEngine.fuse(aiSignal: aiSignal, strategySignals: strategySignals)
        
        // Then
        XCTAssertEqual(result.action, .buy)
        XCTAssertGreaterThan(result.confidence, 0.7) // Should be weighted average
        XCTAssertEqual(result.source, "AI+Strategy")
    }
    
    func testFuseWithConflictingSignals() {
        // Given
        let aiSignal = createMockAISignal(vote: .buy, confidence: 0.6)
        let strategySignals = [
            createMockStrategySignal(name: "RSI", vote: .sell, score: 0.8),
            createMockStrategySignal(name: "MACD", vote: .sell, score: 0.9),
            createMockStrategySignal(name: "EMA", vote: .sell, score: 0.7)
        ]
        
        // When
        let result = fusionEngine.fuse(aiSignal: aiSignal, strategySignals: strategySignals)
        
        // Then
        XCTAssertEqual(result.action, .sell) // Strategies should win due to higher confidence
        XCTAssertGreaterThan(result.confidence, 0.7)
        XCTAssertEqual(result.source, "AI+Strategy")
    }
    
    func testFuseWithHoldSignals() {
        // Given
        let aiSignal = createMockAISignal(vote: .hold, confidence: 0.5)
        let strategySignals = [
            createMockStrategySignal(name: "RSI", vote: .hold, score: 0.4),
            createMockStrategySignal(name: "MACD", vote: .hold, score: 0.3)
        ]
        
        // When
        let result = fusionEngine.fuse(aiSignal: aiSignal, strategySignals: strategySignals)
        
        // Then
        XCTAssertEqual(result.action, .hold)
        XCTAssertLessThan(result.confidence, 0.5) // Should be low confidence
        XCTAssertEqual(result.source, "AI+Strategy")
    }
    
    func testFuseWithEmptyInputs() {
        // Given
        let aiSignal: AISignal? = nil
        let strategySignals: [AIStrategySignal] = []
        
        // When
        let result = fusionEngine.fuse(aiSignal: aiSignal, strategySignals: strategySignals)
        
        // Then
        XCTAssertEqual(result.action, .hold)
        XCTAssertEqual(result.confidence, 0.0)
        XCTAssertEqual(result.source, "No-Signal")
    }
    
    func testFuseWithHighConfidenceAI() {
        // Given
        let aiSignal = createMockAISignal(vote: .buy, confidence: 0.95)
        let strategySignals = [
            createMockStrategySignal(name: "RSI", vote: .sell, score: 0.6),
            createMockStrategySignal(name: "MACD", vote: .sell, score: 0.5)
        ]
        
        // When
        let result = fusionEngine.fuse(aiSignal: aiSignal, strategySignals: strategySignals)
        
        // Then
        XCTAssertEqual(result.action, .buy) // High confidence AI should override strategies
        XCTAssertGreaterThan(result.confidence, 0.8)
        XCTAssertEqual(result.source, "AI+Strategy")
    }
    
    func testFuseWithEqualVotes() {
        // Given
        let aiSignal = createMockAISignal(vote: .buy, confidence: 0.5)
        let strategySignals = [
            createMockStrategySignal(name: "RSI", vote: .buy, score: 0.5),
            createMockStrategySignal(name: "MACD", vote: .sell, score: 0.5),
            createMockStrategySignal(name: "EMA", vote: .hold, score: 0.5)
        ]
        
        // When
        let result = fusionEngine.fuse(aiSignal: aiSignal, strategySignals: strategySignals)
        
        // Then
        // Should default to hold when votes are equal
        XCTAssertEqual(result.action, .hold)
        XCTAssertEqual(result.confidence, 0.5, accuracy: 0.01)
        XCTAssertEqual(result.source, "AI+Strategy")
    }
    
    // MARK: - Performance Tests
    
    func testFusePerformance() {
        // Given
        let aiSignal = createMockAISignal(vote: .buy, confidence: 0.8)
        let strategySignals = (0..<100).map { i in
            createMockStrategySignal(name: "Strategy\(i)", vote: .buy, score: 0.7)
        }
        
        // When & Then
        measure {
            _ = fusionEngine.fuse(aiSignal: aiSignal, strategySignals: strategySignals)
        }
    }
    
    // MARK: - Edge Cases
    
    func testFuseWithExtremeConfidenceValues() {
        // Given
        let aiSignal = createMockAISignal(vote: .buy, confidence: 1.0)
        let strategySignals = [
            createMockStrategySignal(name: "RSI", vote: .sell, score: 0.0)
        ]
        
        // When
        let result = fusionEngine.fuse(aiSignal: aiSignal, strategySignals: strategySignals)
        
        // Then
        XCTAssertEqual(result.action, .buy)
        XCTAssertEqual(result.confidence, 1.0, accuracy: 0.01)
    }
    
    func testFuseWithNegativeConfidence() {
        // Given
        let aiSignal = createMockAISignal(vote: .buy, confidence: -0.5)
        let strategySignals = [
            createMockStrategySignal(name: "RSI", vote: .sell, score: -0.3)
        ]
        
        // When
        let result = fusionEngine.fuse(aiSignal: aiSignal, strategySignals: strategySignals)
        
        // Then
        // Should handle negative values gracefully
        XCTAssertEqual(result.action, .hold)
        XCTAssertEqual(result.confidence, 0.0, accuracy: 0.01)
    }
}
