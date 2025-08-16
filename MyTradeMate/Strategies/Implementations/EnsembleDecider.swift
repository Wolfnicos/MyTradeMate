import Foundation
import OSLog

private let logger = Logger(subsystem: "com.mytrademate", category: "StrategyEngine")

public class EnsembleDecider {
    private var strategies: [Strategy] = []
    private let regimeDetector = RegimeDetector()
    
    public init() {
        setupDefaultStrategies()
    }
    
    private func setupDefaultStrategies() {
        strategies = [
            EMAStrategy(),
            RSIStrategy(),
            MACDStrategy(),
            MeanReversionStrategy(),
            BreakoutStrategy()
        ]
    }
    
    public func decide(candles: [Candle], verboseLogging: Bool = false) -> EnsembleDecision {
        guard candles.count >= 50 else {
            return EnsembleDecision(
                direction: .hold,
                confidence: 0.0,
                signals: [],
                regime: .ranging,
                reasoning: "Insufficient data for ensemble decision"
            )
        }
        
        // Detect market regime
        let regime = regimeDetector.detectRegime(candles: candles)
        let recommendedStrategies = Set(regimeDetector.recommendStrategies(for: regime))
        
        if verboseLogging {
            logger.info("Market regime: \(String(describing: regime))")
            logger.info("Recommended strategies: \(recommendedStrategies.joined(separator: ", "))")
        }
        
        // Collect signals from enabled strategies
        var signals: [StrategySignal] = []
        var totalWeight: Double = 0
        
        for strategy in strategies where strategy.isEnabled {
            // Adjust weight based on regime
            let adjustedWeight = recommendedStrategies.contains(strategy.name) ? 
                strategy.weight * 1.5 : strategy.weight
            
            let signal = strategy.signal(candles: candles)
            signals.append(signal)
            totalWeight += adjustedWeight
            
            if verboseLogging {
                logger.info("\(strategy.name): \(String(describing: signal.direction)) @ \(String(format: "%.2f", signal.confidence * 100))% confidence")
            }
        }
        
        guard !signals.isEmpty && totalWeight > 0 else {
            return EnsembleDecision(
                direction: .hold,
                confidence: 0.0,
                signals: [],
                regime: regime,
                reasoning: "No active strategies"
            )
        }
        
        // Calculate weighted vote
        var buyScore: Double = 0
        var sellScore: Double = 0
        var holdScore: Double = 0
        
        for (index, signal) in signals.enumerated() {
            let strategy = strategies[index]
            let weight = recommendedStrategies.contains(strategy.name) ? 
                strategy.weight * 1.5 : strategy.weight
            let normalizedWeight = weight / totalWeight
            
            switch signal.direction {
            case .buy:
                buyScore += signal.confidence * normalizedWeight
            case .sell:
                sellScore += signal.confidence * normalizedWeight
            case .hold:
                holdScore += signal.confidence * normalizedWeight
            }
        }
        
        // Determine final direction and confidence
        let maxScore = max(buyScore, sellScore, holdScore)
        let direction: StrategySignal.Direction
        let confidence: Double
        let reasoning: String
        
        if maxScore == buyScore && buyScore > 0.4 {
            direction = .buy
            confidence = buyScore
            reasoning = buildReasoning(for: .buy, signals: signals, regime: regime)
        } else if maxScore == sellScore && sellScore > 0.4 {
            direction = .sell
            confidence = sellScore
            reasoning = buildReasoning(for: .sell, signals: signals, regime: regime)
        } else {
            direction = .hold
            confidence = holdScore
            reasoning = buildReasoning(for: .hold, signals: signals, regime: regime)
        }
        
        if verboseLogging {
            logger.info("Ensemble decision: \(String(describing: direction)) @ \(String(format: "%.2f", confidence * 100))%")
            logger.info("Scores - Buy: \(String(format: "%.2f", buyScore)), Sell: \(String(format: "%.2f", sellScore)), Hold: \(String(format: "%.2f", holdScore))")
        }
        
        return EnsembleDecision(
            direction: direction,
            confidence: confidence,
            signals: signals,
            regime: regime,
            reasoning: reasoning
        )
    }
    
    private func buildReasoning(for direction: StrategySignal.Direction, 
                               signals: [StrategySignal], 
                               regime: RegimeDetector.MarketRegime) -> String {
        let agreeing = signals.filter { $0.direction == direction }
        let strategyNames = agreeing.map { $0.strategyName }.joined(separator: ", ")
        
        let regimeString: String
        switch regime {
        case .trending(let dir):
            regimeString = dir == .bullish ? "bullish trend" : "bearish trend"
        case .ranging:
            regimeString = "ranging market"
        case .volatile:
            regimeString = "volatile market"
        }
        
        if agreeing.isEmpty {
            return "Mixed signals in \(regimeString)"
        } else {
            return "\(strategyNames) agree in \(regimeString)"
        }
    }
    
    public func updateStrategyWeight(strategyName: String, weight: Double) {
        if let index = strategies.firstIndex(where: { $0.name == strategyName }) {
            strategies[index].weight = max(0, min(2, weight)) // Clamp between 0 and 2
        }
    }
    
    public func enableStrategy(strategyName: String, enabled: Bool) {
        if let index = strategies.firstIndex(where: { $0.name == strategyName }) {
            strategies[index].isEnabled = enabled
        }
    }
}

// MARK: - Ensemble Decision
public struct EnsembleDecision {
    public let direction: StrategySignal.Direction
    public let confidence: Double
    public let signals: [StrategySignal]
    public let regime: RegimeDetector.MarketRegime
    public let reasoning: String
    public let timestamp: Date
    
    public init(direction: StrategySignal.Direction,
                confidence: Double,
                signals: [StrategySignal],
                regime: RegimeDetector.MarketRegime,
                reasoning: String) {
        self.direction = direction
        self.confidence = confidence
        self.signals = signals
        self.regime = regime
        self.reasoning = reasoning
        self.timestamp = Date()
    }
}
