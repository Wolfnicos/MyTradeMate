import Foundation
import Combine

// MARK: - Supporting Types

struct EnsembleSignal {
    let direction: SignalDirection
    let confidence: Double
    let reason: String
    let contributingStrategies: [String]
    let timestamp: Date
}

// MARK: - StrategyManager

@MainActor
final class StrategyManager: ObservableObject {
    static let shared = StrategyManager()
    
    @Published var strategies: [Strategy] = []
    @Published var lastSignals: [String: StrategySignal] = [:]
    @Published var isGeneratingSignals: Bool = false
    @Published var ensembleSignal: EnsembleSignal? = nil
    
    // MARK: - Private Properties
    private let settingsRepo = SettingsRepository.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var enabledStrategies: [Strategy] {
        strategies.filter { strategy in
            settingsRepo.isStrategyEnabled(strategy.name)
        }
    }
    
    var activeStrategies: [Strategy] {
        enabledStrategies
    }
    
    var availableStrategies: [Strategy] {
        strategies
    }
    
    init() {
        setupStrategies()
        setupBindings()
    }
    
    private func setupBindings() {
        // Subscribe to strategy changes to trigger UI updates
        settingsRepo.$strategyEnabled
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func setupStrategies() {
        strategies = [
            RSIStrategy.shared,
            EMAStrategy.shared,
            MACDStrategy.shared,
            MeanReversionStrategy.shared,
            BreakoutStrategy.shared,
            BollingerBandsStrategy.shared,
            IchimokuStrategy.shared,
            ParabolicSARStrategy.shared,
            WilliamsRStrategy.shared,
            GridTradingStrategy.shared,
            SwingTradingStrategy.shared,
            ScalpingStrategy.shared,
            VolumeStrategy.shared,
            ADXStrategy.shared,
            StochasticStrategy.shared
        ]
        
        // Strategies are now managed by SettingsRepository
        // No need to hardcode enabled/disabled states
        
        Log.ai.info("Initialized \(strategies.count) strategies")
    }
    
    func enableStrategy(named name: String) {
        settingsRepo.updateStrategyEnabled(name, enabled: true)
        Log.userAction("Strategy enabled", parameters: ["strategy": name])
    }
    
    func disableStrategy(named name: String) {
        settingsRepo.updateStrategyEnabled(name, enabled: false)
        Log.userAction("Strategy disabled", parameters: ["strategy": name])
    }
    
    func updateStrategyWeight(named name: String, weight: Double) {
        settingsRepo.updateStrategyWeight(name, weight: weight)
        Log.userAction("Strategy weight updated", parameters: ["strategy": name, "weight": weight])
    }
    
    func generateSignals(from candles: [Candle]) async -> EnsembleSignal {
        isGeneratingSignals = true
        defer { isGeneratingSignals = false }
        
        let performanceLogger = PerformanceLogger("Strategy signal generation", category: .ai)
        
        var signals: [StrategySignal] = []
        
        // Generate signals from all active strategies
        for strategy in activeStrategies {
            let requiredCandles = strategy.requiredCandles()
            
            guard candles.count >= requiredCandles else {
                Log.aiDebug("Insufficient data for \(strategy.name): need \(requiredCandles), have \(candles.count)")
                continue
            }
            
            let signal = strategy.signal(candles: candles)
            signals.append(signal)
            lastSignals[strategy.name] = signal
            
            Log.aiDebug("\(strategy.name): \(signal.direction) (\(String(format: "%.1f", signal.confidence * 100))%) - \(signal.reason)")
        }
        
        // Create ensemble signal
        let ensemble = createEnsembleSignal(from: signals)
        ensembleSignal = ensemble
        
        performanceLogger.finish()
        
        Log.ai.info("Ensemble signal: \(ensemble.direction) (\(String(format: "%.1f", ensemble.confidence * 100))%)")
        
        return ensemble
    }
    
    private func createEnsembleSignal(from signals: [StrategySignal]) -> EnsembleSignal {
        guard !signals.isEmpty else {
            return EnsembleSignal(
                direction: .hold,
                confidence: 0.0,
                reason: "No active strategies",
                contributingStrategies: [],
                timestamp: Date()
            )
        }
        
        // Weight signals by strategy weight and confidence
        var buyScore: Double = 0
        var sellScore: Double = 0
        var holdScore: Double = 0
        var totalWeight: Double = 0
        
        var contributingStrategies: [String] = []
        
        for signal in signals {
            let weight = settingsRepo.getStrategyWeight(signal.strategyName)
            let weightedConfidence = signal.confidence * weight
            
            switch signal.direction {
            case .buy:
                buyScore += weightedConfidence
            case .sell:
                sellScore += weightedConfidence
            case .hold:
                holdScore += weightedConfidence
            }
            
            totalWeight += weight
            contributingStrategies.append(signal.strategyName)
        }
        
        // Normalize scores
        if totalWeight > 0 {
            buyScore /= totalWeight
            sellScore /= totalWeight
            holdScore /= totalWeight
        }
        
        // Determine final direction
        let maxScore = max(buyScore, sellScore, holdScore)
        let direction: SignalDirection
        let reason: String
        
        if maxScore == buyScore {
            direction = .buy
            reason = "Buy signals dominate"
        } else if maxScore == sellScore {
            direction = .sell
            reason = "Sell signals dominate"
        } else {
            direction = .hold
            reason = "Hold signals dominate"
        }
        
        return EnsembleSignal(
            direction: direction,
            confidence: maxScore,
            reason: reason,
            contributingStrategies: contributingStrategies,
            timestamp: Date()
        )
    }
}