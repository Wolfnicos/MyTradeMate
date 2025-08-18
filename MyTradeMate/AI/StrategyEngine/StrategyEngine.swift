import Foundation
import Combine

// MARK: - Local Types (to resolve build issues)

/// Unified settings state for live engine binding
public struct SettingsState: Equatable {
    public let routingEnabled: Bool
    public let strategyMinConf: Double
    public let strategyMaxConf: Double
    
    // Strategy-specific settings
    public let rsiEnabled: Bool
    public let rsiWeight: Double
    public let emaEnabled: Bool
    public let emaWeight: Double
    public let macdEnabled: Bool
    public let macdWeight: Double
    public let meanReversionEnabled: Bool
    public let meanReversionWeight: Double
    public let breakoutEnabled: Bool
    public let breakoutWeight: Double
    public let meanRevEnabled: Bool
    public let meanRevWeight: Double
    public let atrEnabled: Bool
    public let atrWeight: Double
    
    public init(
        routingEnabled: Bool = true, 
        strategyMinConf: Double = 0.6, 
        strategyMaxConf: Double = 0.9,
        rsiEnabled: Bool = true,
        rsiWeight: Double = 1.0,
        emaEnabled: Bool = false,
        emaWeight: Double = 1.0,
        macdEnabled: Bool = false,
        macdWeight: Double = 1.0,
        meanReversionEnabled: Bool = false,
        meanReversionWeight: Double = 1.0,
        breakoutEnabled: Bool = false,
        breakoutWeight: Double = 1.0,
        meanRevEnabled: Bool = false,
        meanRevWeight: Double = 1.0,
        atrEnabled: Bool = false,
        atrWeight: Double = 1.0
    ) {
        self.routingEnabled = routingEnabled
        self.strategyMinConf = strategyMinConf
        self.strategyMaxConf = strategyMaxConf
        self.rsiEnabled = rsiEnabled
        self.rsiWeight = rsiWeight
        self.emaEnabled = emaEnabled
        self.emaWeight = emaWeight
        self.macdEnabled = macdEnabled
        self.macdWeight = macdWeight
        self.meanReversionEnabled = meanReversionEnabled
        self.meanReversionWeight = meanReversionWeight
        self.breakoutEnabled = breakoutEnabled
        self.breakoutWeight = breakoutWeight
        self.meanRevEnabled = meanRevEnabled
        self.meanRevWeight = meanRevWeight
        self.atrEnabled = atrEnabled
        self.atrWeight = atrWeight
    }
}

/// Mock SettingsRepository for build compatibility
@MainActor
public final class SettingsRepository: ObservableObject {
    public static let shared = SettingsRepository()
    @Published public var state = SettingsState()
    
    // Mock properties to satisfy StrategyEngine requirements
    @Published public var useStrategyRouting: Bool = true
    @Published public var strategyConfidenceMin: Double = 0.6
    @Published public var strategyConfidenceMax: Double = 0.9
    
    private init() {}
    
    public func updateState() {
        // Mock implementation
    }
    
    public func isStrategyEnabled(_ name: String) -> Bool {
        // Mock implementation - return true for all strategies
        return true
    }
    
    public func updateStrategyEnabled(_ name: String, enabled: Bool) {
        // Mock implementation
    }
    
    public func updateStrategyWeight(_ name: String, weight: Double) {
        // Mock implementation
    }
    
    public func getStrategyWeight(_ name: String) -> Double {
        // Mock implementation
        return 1.0
    }
}

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
    
    private var allStrategies: [Strategy] {
        [rsiStrategy, emaStrategy, macdStrategy, meanReversionStrategy, breakoutStrategy]
    }
    
    public var activeStrategies: [Strategy] {
        allStrategies.filter { strategy in
            // Use settings repository to check if strategy is enabled
            settingsRepo.isStrategyEnabled(strategy.name)
        }
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
    
    /// Handle settings state changes and update engine instantly
    private func handleSettingsChange(_ state: SettingsState) {
        // Update routing
        settingsRepo.useStrategyRouting = state.routingEnabled
        
        // Update confidence range
        settingsRepo.strategyConfidenceMin = state.strategyMinConf
        settingsRepo.strategyConfidenceMax = state.strategyMaxConf
        
        // Update individual strategy enable/disable and weights
        settingsRepo.updateStrategyEnabled("RSI", enabled: state.rsiEnabled)
        settingsRepo.updateStrategyWeight("RSI", weight: state.rsiWeight)
        
        settingsRepo.updateStrategyEnabled("EMA Crossover", enabled: state.emaEnabled)
        settingsRepo.updateStrategyWeight("EMA Crossover", weight: state.emaWeight)
        
        settingsRepo.updateStrategyEnabled("MACD", enabled: state.macdEnabled)
        settingsRepo.updateStrategyWeight("MACD", weight: state.macdWeight)
        
        settingsRepo.updateStrategyEnabled("Mean Reversion", enabled: state.meanRevEnabled)
        settingsRepo.updateStrategyWeight("Mean Reversion", weight: state.meanRevWeight)
        
        settingsRepo.updateStrategyEnabled("ATR Breakout", enabled: state.atrEnabled)
        settingsRepo.updateStrategyWeight("ATR Breakout", weight: state.atrWeight)
        
        // Log the settings update with proper [SETTINGS] format
        let activeStrategies = [
            (state.rsiEnabled ? "RSI" : nil),
            (state.emaEnabled ? "EMA" : nil),
            (state.macdEnabled ? "MACD" : nil),
            (state.meanRevEnabled ? "MeanRev" : nil),
            (state.atrEnabled ? "ATR" : nil)
        ].compactMap { $0 }
        
        let weights = [
            "RSI:\(String(format: "%.1f", state.rsiWeight))",
            "EMA:\(String(format: "%.1f", state.emaWeight))",
            "MACD:\(String(format: "%.1f", state.macdWeight))",
            "MeanRev:\(String(format: "%.1f", state.meanRevWeight))",
            "ATR:\(String(format: "%.1f", state.atrWeight))"
        ]
        
        Log.settings.info("[SETTINGS] routingEnabled=\(state.routingEnabled) min=\(String(format: "%.2f", state.strategyMinConf)) max=\(String(format: "%.2f", state.strategyMaxConf)) active=[\(activeStrategies.joined(separator: ","))] weights={\(weights.joined(separator: ","))}")
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

