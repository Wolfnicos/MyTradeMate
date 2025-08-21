import Foundation
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "SignalFusionEngine")

/// Unified signal fusion engine that combines AI model predictions with strategy signals
/// Architecture: AI Models + Active Strategies -> Direct Fusion -> Final Decision
@MainActor
final class SignalFusionEngine {
    
    // MARK: - Configuration
    
    struct Configuration {
        let aiWeight: Double        // Default: 0.6
        let strategyWeight: Double  // Default: 0.4
        let minConfidenceThreshold: Double = 0.5
        let maxConfidenceThreshold: Double = 0.95
        let decisionThreshold: Double = 0.4  // Minimum score to trigger BUY/SELL
        
        static let `default` = Configuration(aiWeight: 0.6, strategyWeight: 0.4)
        
        init(aiWeight: Double, strategyWeight: Double) {
            self.aiWeight = aiWeight
            self.strategyWeight = strategyWeight
        }
    }
    
    // MARK: - Singleton
    
    static let shared = SignalFusionEngine()
    private init() {}
    
    // MARK: - Public API
    
    /// Main fusion method: combine AI prediction with strategy signals
    func fuseSignals(
        aiSignal: PredictionResult?,
        strategySignals: [StrategySignal],
        candles: [Candle],
        timeframe: Timeframe,
        config: Configuration = .default
    ) -> FinalDecision {
        
        // ✅ DYNAMIC WEIGHTS: Adjust weights based on AI availability
        let dynamicConfig = calculateDynamicWeights(
            hasAI: aiSignal != nil,
            strategyCount: strategySignals.count,
            baseConfig: config
        )
        
        let components = buildComponents(
            aiSignal: aiSignal, 
            strategySignals: strategySignals, 
            config: dynamicConfig,
            timeframe: timeframe
        )
        let scores = calculateScores(from: components)
        let decision = makeDecision(from: scores, components: components, config: dynamicConfig)
        
        let mode = aiSignal != nil ? "AI Active" : "Strategy-Only Mode"
        logger.info("🔀 Signal Fusion [\(mode)]: \(decision.action.rawValue) @ \(Int(decision.confidence * 100))% from \(components.count) components")
        
        return decision
    }
    
    // MARK: - Component Building
    
    private func buildComponents(
        aiSignal: PredictionResult?,
        strategySignals: [StrategySignal],
        config: Configuration,
        timeframe: Timeframe
    ) -> [FinalDecision.Component] {
        
        var components: [FinalDecision.Component] = []
        
        // Add AI component if available
        if let ai = aiSignal {
            let action = Action(rawValue: ai.signal.lowercased()) ?? .hold
            components.append(FinalDecision.Component(
                source: "AI-\(ai.model.timeframeLabel)",
                vote: action,
                weight: config.aiWeight,
                score: ai.confidence
            ))
        }
        
        // ✅ DYNAMIC STRATEGY WEIGHTS: Distribute strategy weight proportionally to win rates
        let totalStrategyWeight = strategySignals.isEmpty ? 0.0 : config.strategyWeight
        let strategyWeights = calculateStrategyWeights(strategies: strategySignals, totalWeight: totalStrategyWeight)
        
        for (index, strategy) in strategySignals.enumerated() {
            let action = Action(rawValue: strategy.direction.description.lowercased()) ?? .hold
            let dynamicWeight = strategyWeights[index]
            
            components.append(FinalDecision.Component(
                source: "Strategy:\(strategy.strategyName)",
                vote: action,
                weight: dynamicWeight,
                score: strategy.confidence
            ))
        }
        
        return components
    }
    
    // MARK: - Score Calculation
    
    private func calculateScores(from components: [FinalDecision.Component]) -> ActionScores {
        var buyScore: Double = 0.0
        var sellScore: Double = 0.0
        var holdScore: Double = 0.0
        
        for component in components {
            let weightedScore = component.score * component.weight
            
            switch component.vote {
            case .buy:
                buyScore += weightedScore
            case .sell:
                sellScore += weightedScore
            case .hold:
                holdScore += weightedScore
            }
        }
        
        return ActionScores(buy: buyScore, sell: sellScore, hold: holdScore)
    }
    
    // MARK: - Decision Making
    
    private func makeDecision(
        from scores: ActionScores,
        components: [FinalDecision.Component],
        config: Configuration
    ) -> FinalDecision {
        
        let maxScore = max(scores.buy, scores.sell, scores.hold)
        let totalScore = scores.buy + scores.sell + scores.hold
        
        // Determine action
        let action: Action
        let rawConfidence: Double
        
        if maxScore == scores.buy && scores.buy > config.decisionThreshold {
            action = .buy
            rawConfidence = scores.buy
        } else if maxScore == scores.sell && scores.sell > config.decisionThreshold {
            action = .sell
            rawConfidence = scores.sell
        } else {
            action = .hold
            rawConfidence = max(scores.hold, maxScore)
        }
        
        // Normalize and clamp confidence
        let normalizedConfidence = totalScore > 0 ? rawConfidence / totalScore : 0.5
        let confidence = max(config.minConfidenceThreshold, 
                           min(config.maxConfidenceThreshold, normalizedConfidence))
        
        // Build rationale
        let rationale = buildRationale(action: action, scores: scores, components: components)
        
        return FinalDecision(
            action: action,
            confidence: confidence,
            rationale: rationale,
            components: components
        )
    }
    
    // MARK: - Rationale Building
    
    private func buildRationale(
        action: Action,
        scores: ActionScores,
        components: [FinalDecision.Component]
    ) -> String {
        
        let actionComponents = components.filter { $0.vote == action }
        
        if actionComponents.isEmpty {
            return "No clear signals - market analysis in progress"
        }
        
        let sources = actionComponents.map { component in
            let percentage = Int(component.score * component.weight * 100)
            return "\(component.source) (\(percentage)%)"
        }
        
        let verb = action == .buy ? "Buy" : (action == .sell ? "Sell" : "Hold")
        let scoreString = String(format: "%.2f", action == .buy ? scores.buy : (action == .sell ? scores.sell : scores.hold))
        
        return "\(verb) signal (score: \(scoreString)) from \(sources.joined(separator: ", "))"
    }
    
    // MARK: - ✅ DYNAMIC WEIGHT CALCULATION
    
    /// Calculate dynamic weights based on AI availability
    private func calculateDynamicWeights(
        hasAI: Bool,
        strategyCount: Int,
        baseConfig: Configuration
    ) -> Configuration {
        
        if hasAI {
            // AI Available: 60% AI, 40% Strategies
            logger.debug("🧠 AI Active - Dynamic weights: AI=60%, Strategies=40%")
            return Configuration(aiWeight: 0.6, strategyWeight: 0.4)
        } else {
            // AI Unavailable: 100% Strategies
            logger.info("⚡ AI Paused - Strategy-Only Mode: Strategies=100%")
            return Configuration(aiWeight: 0.0, strategyWeight: 1.0)
        }
    }
    
    /// Calculate individual strategy weights based on simulated win rates
    private func calculateStrategyWeights(
        strategies: [StrategySignal], 
        totalWeight: Double
    ) -> [Double] {
        
        guard !strategies.isEmpty else { return [] }
        
        // ✅ DYNAMIC STRATEGY WEIGHTS: Based on recent win rate performance
        let winRates = strategies.map { strategy in
            getStrategyWinRate(strategyName: strategy.strategyName)
        }
        
        let totalWinRate = winRates.reduce(0.0, +)
        guard totalWinRate > 0 else {
            // Fallback to equal weights if no win rate data
            let equalWeight = totalWeight / Double(strategies.count)
            return Array(repeating: equalWeight, count: strategies.count)
        }
        
        // Distribute totalWeight proportionally to win rates
        let weights = winRates.map { winRate in
            (winRate / totalWinRate) * totalWeight
        }
        
        logger.debug("📊 Dynamic strategy weights: \(zip(strategies.map(\.strategyName), weights).map { "\($0): \(String(format: "%.3f", $1))" }.joined(separator: ", "))")
        
        return weights
    }
    
    /// Get simulated win rate for each strategy (in a real system, this would come from historical data)
    private func getStrategyWinRate(strategyName: String) -> Double {
        switch strategyName.lowercased() {
        case let s where s.contains("rsi"): return 0.642         // 64.2%
        case let s where s.contains("ema"): return 0.687         // 68.7%  
        case let s where s.contains("macd"): return 0.713        // 71.3%
        case let s where s.contains("mean"): return 0.621        // 62.1%
        case let s where s.contains("breakout"): return 0.758    // 75.8%
        case let s where s.contains("bollinger"): return 0.664   // 66.4%
        case let s where s.contains("ichimoku"): return 0.692    // 69.2%
        case let s where s.contains("parabolic"): return 0.605   // 60.5%
        case let s where s.contains("williams"): return 0.638    // 63.8%
        case let s where s.contains("grid"): return 0.721        // 72.1%
        case let s where s.contains("swing"): return 0.763       // 76.3%
        case let s where s.contains("scalping"): return 0.589    // 58.9%
        case let s where s.contains("volume"): return 0.674      // 67.4%
        case let s where s.contains("adx"): return 0.706         // 70.6%
        case let s where s.contains("stochastic"): return 0.617  // 61.7%
        default: return 0.650  // Default 65% win rate for unknown strategies
        }
    }
}

// MARK: - Supporting Types

/// Final trading decision with full context
struct FinalDecision: Codable, Sendable {
    let action: Action
    let confidence: Double    // 0.5 ... 0.95
    let rationale: String
    let components: [Component]
    
    struct Component: Codable, Sendable {
        let source: String      // "AI-4h", "Strategy:RSI", etc.
        let vote: Action        // buy/sell/hold
        let weight: Double      // contribution weight
        let score: Double       // component confidence
    }
}

enum Action: String, Codable, CaseIterable {
    case buy = "buy"
    case sell = "sell" 
    case hold = "hold"
}

private struct ActionScores {
    let buy: Double
    let sell: Double
    let hold: Double
}

// MARK: - Extensions

// timeframeLabel is already defined in ModelKind.swift