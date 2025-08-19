import Foundation
import Combine

/// Strategy outcome with signal and confidence from vote aggregation
public struct StrategyOutcome {
    public let signal: String // "BUY", "SELL", "HOLD"
    public let confidence: Double // 0.55-0.90 for strategies
    public let reason: String
    public let source: String // "Strategies"
    public let activeStrategies: [String]
    public let voteBreakdown: [String: Int]
    public let timestamp: Date
    
    public init(signal: String, confidence: Double, reason: String, source: String, 
                activeStrategies: [String], voteBreakdown: [String: Int]) {
        self.signal = signal
        self.confidence = max(0.55, min(0.90, confidence)) // Clamp to strategy range
        self.reason = reason
        self.source = source
        self.activeStrategies = activeStrategies
        self.voteBreakdown = voteBreakdown
        self.timestamp = Date()
    }
}

/// Lightweight aggregator that collects votes from enabled strategies
@MainActor
public final class StrategyEngine: ObservableObject {
    public static let shared = StrategyEngine()
    
    // Use SettingsRepository for persistence
    private let settingsRepo = SettingsRepository.shared
    private var cancellables = Set<AnyCancellable>()
    
    public var isUseStrategiesForShortTF: Bool {
        settingsRepo.useStrategyRouting
    }
    
    public var strategyConfidenceMin: Double {
        settingsRepo.strategyConfidenceMin
    }
    
    public var strategyConfidenceMax: Double {
        settingsRepo.strategyConfidenceMax
    }
    
    // Strategy instances
    private let rsiStrategy = RSIStrategy.shared
    private let emaStrategy = EMAStrategy.shared
    private let macdStrategy = MACDStrategy.shared
    private let meanReversionStrategy = MeanReversionStrategy.shared
    private let breakoutStrategy = BreakoutStrategy.shared
    private let bollingerBandsStrategy = BollingerBandsStrategy.shared
    private let ichimokuStrategy = IchimokuStrategy.shared
    private let parabolicSARStrategy = ParabolicSARStrategy.shared
    private let williamsRStrategy = WilliamsRStrategy.shared
    private let gridTradingStrategy = GridTradingStrategy.shared
    private let swingTradingStrategy = SwingTradingStrategy.shared
    private let scalpingStrategy = ScalpingStrategy.shared
    private let volumeStrategy = VolumeStrategy.shared
    private let adxStrategy = ADXStrategy.shared
    private let stochasticStrategy = StochasticStrategy.shared
    
    public var allStrategies: [Strategy] {
        [
            rsiStrategy, emaStrategy, macdStrategy, meanReversionStrategy, breakoutStrategy,
            bollingerBandsStrategy, ichimokuStrategy, parabolicSARStrategy, williamsRStrategy,
            gridTradingStrategy, swingTradingStrategy, scalpingStrategy, volumeStrategy,
            adxStrategy, stochasticStrategy
        ]
    }
    
    public var activeStrategies: [Strategy] {
        allStrategies.filter { strategy in
            // Use settings repository to check if strategy is enabled
            settingsRepo.isStrategyEnabled(strategy.name)
        }
    }
    
    public func refreshActiveStrategies() async {
        // This method is called when strategies are enabled/disabled
        // The activeStrategies computed property will automatically reflect changes
        Log.settings.info("[ENGINE] Refreshing active strategies")
    }
    
    private init() {
        loadSettings()
        setupSettingsBinding()
    }
    
    /// Subscribe to live settings changes from SettingsRepository
    private func setupSettingsBinding() {
        // Wire Settings → live engine as specified
        settingsRepo.$state
            .removeDuplicates()
            .sink { [weak self] state in
                self?.handleSettingsChange(state)
            }
            .store(in: &cancellables)
    }
    
    /// Handle settings state changes - just log them, don't write back to avoid circular updates
    private func handleSettingsChange(_ state: SettingsState) {
        // Just log the current state - no circular updates to avoid publishing warnings
        Log.settings.info("[ENGINE] Settings updated: routing=\(state.routingEnabled) confidence=\(String(format: "%.2f", state.strategyMinConf))-\(String(format: "%.2f", state.strategyMaxConf))")
        
        // The engine will automatically reflect changes through computed properties like activeStrategies
        // which read directly from SettingsRepository without triggering circular updates
    }
    
    /// Generate signal with proper [STRATEGY] logging format
    public func generateSignal(timeframe: Timeframe, candles: [Candle]) -> StrategyOutcome? {
        return evaluate(timeframe: timeframe, candles: candles)
    }
    
    /// Main evaluation method for strategy-based prediction
    public func evaluate(timeframe: Timeframe, candles: [Candle]) -> StrategyOutcome? {
        // Safety checks
        guard isUseStrategiesForShortTF else {
            Log.ai.debug("⚠️ Strategy routing disabled for short timeframes")
            return nil
        }
        
        guard candles.count >= 50 else {
            Log.ai.debug("⚠️ Insufficient candles for strategy evaluation: \(candles.count)")
            return nil
        }
        
        let activeStrats = activeStrategies
        guard !activeStrats.isEmpty else {
            Log.ai.debug("⚠️ No active strategies enabled")
            return nil
        }
        
        Log.ai.debug("🔍 Evaluating \(activeStrats.count) strategies for TF=\(timeframe.rawValue)")
        
        // Collect votes from all active strategies
        var votes: [String: Int] = ["BUY": 0, "SELL": 0, "HOLD": 0]
        var confidences: [Double] = []
        var reasons: [String] = []
        var strategyNames: [String] = []
        
        for strategy in activeStrats {
            let signal = strategy.signal(candles: candles)
            let voteKey = signal.direction.voteKey
            votes[voteKey, default: 0] += 1
            
            // Weight confidence by strategy weight from settings
            let strategyWeight = settingsRepo.getStrategyWeight(strategy.name)
            let weightedConfidence = signal.confidence * strategyWeight
            confidences.append(weightedConfidence)
            reasons.append("\(strategy.name): \(signal.reason)")
            strategyNames.append(strategy.name)
            
            Log.ai.debug("  📊 \(strategy.name): \(voteKey) (conf=\(String(format: "%.2f", signal.confidence)), weight=\(String(format: "%.1f", strategyWeight)))")
        }
        
        // Determine winning signal
        let buyVotes = votes["BUY"] ?? 0
        let sellVotes = votes["SELL"] ?? 0
        let holdVotes = votes["HOLD"] ?? 0
        let totalVotes = buyVotes + sellVotes + holdVotes
        
        let winningSignal: String
        let maxVotes: Int
        
        if buyVotes > sellVotes && buyVotes > holdVotes {
            winningSignal = "BUY"
            maxVotes = buyVotes
        } else if sellVotes > buyVotes && sellVotes > holdVotes {
            winningSignal = "SELL"
            maxVotes = sellVotes
        } else {
            winningSignal = "HOLD"
            maxVotes = holdVotes
        }
        
        // Calculate confidence based on vote purity and average strategy confidence
        let votePurity = totalVotes > 0 ? Double(maxVotes) / Double(totalVotes) : 0.0
        let avgConfidence = confidences.isEmpty ? 0.5 : confidences.reduce(0, +) / Double(confidences.count)
        
        // Combine vote purity with average confidence
        let baseConfidence = (votePurity * 0.6) + (avgConfidence * 0.4)
        let finalConfidence = max(strategyConfidenceMin, min(strategyConfidenceMax, baseConfidence))
        
        // Create detailed reason summary
        let votesSummary = "votes BUY:\(buyVotes) SELL:\(sellVotes) HOLD:\(holdVotes)"
        let reason = "\(votesSummary) → \(winningSignal) (purity=\(String(format: "%.2f", votePurity)))"
        
        // [STRATEGY] logging format as specified
        let purityPercent = String(format: "%.0f%%", votePurity * 100)
        let avgConfFormatted = String(format: "%.2f", avgConfidence)
        let finalConfFormatted = String(format: "%.2f", finalConfidence)
        
        Log.strategy.info("[STRATEGY] votes: BUY=\(buyVotes) SELL=\(sellVotes) HOLD=\(holdVotes), purity=\(purityPercent), avgConf=\(avgConfFormatted) → FINAL=\(winningSignal) conf=\(finalConfFormatted)")
        
        // Additional debug logging
        Log.ai.debug("📈 Active strategies: [\(strategyNames.joined(separator: ", "))]")
        
        // Log individual strategy contributions if verbose logging enabled
        if activeStrats.count > 1 {
            let strategyDetails = zip(strategyNames, reasons).map { name, reason in
                let strategySignal = activeStrats.first { $0.name == name }?.signal(candles: candles)
                let vote = strategySignal?.direction.voteKey ?? "UNKNOWN"
                return "\(name)→\(vote)"
            }.joined(separator: ", ")
            Log.ai.debug("🗳️ Individual votes: \(strategyDetails)")
        }
        
        return StrategyOutcome(
            signal: winningSignal,
            confidence: finalConfidence,
            reason: reason,
            source: "Strategies",
            activeStrategies: strategyNames,
            voteBreakdown: votes
        )
    }
    
    // MARK: - Strategy Management (delegated to SettingsRepository)
    
    public func enableStrategy(named name: String) {
        settingsRepo.updateStrategyEnabled(name, enabled: true)
        Log.ai.info("✅ Strategy enabled: \(name)")
    }
    
    public func disableStrategy(named name: String) {
        settingsRepo.updateStrategyEnabled(name, enabled: false)
        Log.ai.info("❌ Strategy disabled: \(name)")
    }
    
    public func updateStrategyWeight(named name: String, weight: Double) {
        settingsRepo.updateStrategyWeight(name, weight: weight)
        Log.ai.info("⚖️ Strategy weight updated: \(name) = \(weight)")
    }
    
    // MARK: - Legacy Support (deprecated - use SettingsRepository directly)
    
    private func loadSettings() {
        // Settings are now handled by SettingsRepository
        // This method exists for backward compatibility but is effectively a no-op
    }
    
    public func updateUseStrategiesForShortTF(_ enabled: Bool) {
        settingsRepo.useStrategyRouting = enabled
        Log.ai.info("🔄 Strategy routing for short TF: \(enabled ? "ENABLED" : "DISABLED")")
    }
    
    public func updateConfidenceRange(minValue: Double, maxValue: Double) {
        settingsRepo.strategyConfidenceMin = Swift.max(0.55, Swift.min(0.89, minValue))
        settingsRepo.strategyConfidenceMax = Swift.max(settingsRepo.strategyConfidenceMin + 0.01, Swift.min(0.90, maxValue))
        Log.ai.info("📊 Strategy confidence range: \(String(format: "%.2f", settingsRepo.strategyConfidenceMin))-\(String(format: "%.2f", settingsRepo.strategyConfidenceMax))")
    }
}

// MARK: - Helper Extensions

private extension StrategySignal.Direction {
    var voteKey: String {
        switch self {
        case .buy: return "BUY"
        case .sell: return "SELL"
        case .hold: return "HOLD"
        }
    }
}

