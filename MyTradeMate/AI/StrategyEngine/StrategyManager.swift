import Foundation
import Combine

/// Manages and coordinates all trading strategies
@MainActor
final class StrategyManager: ObservableObject, StrategyManagerProtocol {
    static let shared = StrategyManager()
    
    @Published var strategies: [any Strategy] = []
    @Published var _activeStrategies: [any Strategy] = []
    @Published var lastSignals: [String: StrategySignal] = [:]
    @Published var ensembleSignal: EnsembleSignal?
    @Published var isGeneratingSignals: Bool = false
    
    // Computed property for enabled strategies
    var enabledStrategies: [any Strategy] {
        return strategies.filter { $0.isEnabled }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupStrategies()
        loadConfiguration()
    }
    
    // MARK: - Strategy Management
    
    private func setupStrategies() {
        strategies = [
            // Original strategies
            RSIStrategy(),                    // 0
            EMAStrategy(),                    // 1
            MACDStrategy(),                   // 2
            MeanReversionStrategy(),          // 3
            BreakoutStrategy(),               // 4
            
            // Technical analysis strategies
            BollingerBandsStrategy(),         // 5
            // StochasticStrategy(),             // 6 - TODO: Add when file is included in target
            WilliamsRStrategy(),              // 7
            ADXStrategy(),                    // 8
            IchimokuStrategy(),               // 9
            ParabolicSARStrategy(),           // 10
            VolumeStrategy(),                 // 11
            
            // Specialized trading strategies
            ScalpingStrategy(),               // 12
            SwingTradingStrategy(),           // 13
            GridTradingStrategy()             // 14
        ]
        
        // Enable some default strategies for demonstration
        strategies[0].isEnabled = true   // RSI
        strategies[5].isEnabled = true   // Bollinger Bands
        strategies[6].isEnabled = true   // WilliamsR (index 6 since Stochastic is commented out)
        strategies[8].isEnabled = true   // Ichimoku (adjusted index)
        strategies[12].isEnabled = true  // Swing Trading (adjusted index)
        
        // Disable others by default
        let disabledIndices = [1, 2, 3, 4, 7, 9, 10, 11, 13, 14]
        for i in disabledIndices {
            if i < strategies.count {
                strategies[i].isEnabled = false
            }
        }
        
        updateActiveStrategies()
        
        Log.ai.info("Initialized \(strategies.count) strategies with \(enabledStrategies.count) enabled")
        Log.ai.info("Enabled strategies: \(enabledStrategies.map { $0.name }.joined(separator: ", "))")
    }
    
    func enableStrategy(named name: String) {
        if let index = strategies.firstIndex(where: { $0.name == name }) {
            strategies[index].isEnabled = true
            updateActiveStrategies()
            saveConfiguration()
            Log.userAction("Strategy enabled", parameters: ["strategy": name])
        }
    }
    
    func disableStrategy(named name: String) {
        if let index = strategies.firstIndex(where: { $0.name == name }) {
            strategies[index].isEnabled = false
            updateActiveStrategies()
            saveConfiguration()
            Log.userAction("Strategy disabled", parameters: ["strategy": name])
        }
    }
    
    func updateStrategyWeight(named name: String, weight: Double) {
        if let index = strategies.firstIndex(where: { $0.name == name }) {
            strategies[index].weight = max(0.1, min(2.0, weight))
            saveConfiguration()
            Log.userAction("Strategy weight updated", parameters: ["strategy": name, "weight": weight])
        }
    }
    
    private func updateActiveStrategies() {
        _activeStrategies = strategies.filter { $0.isEnabled }
        Log.ai.info("Active strategies: \(_activeStrategies.map { $0.name }.joined(separator: ", "))")
    }
    
    // MARK: - Signal Generation
    
    func generateSignals(from candles: [Candle]) async -> EnsembleSignal {
        isGeneratingSignals = true
        defer { isGeneratingSignals = false }
        
        let performanceLogger = PerformanceLogger("Strategy signal generation", category: .ai)
        
        var signals: [StrategySignal] = []
        
        // Generate signals from all active strategies
        for strategy in _activeStrategies {
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
            guard let strategy = _activeStrategies.first(where: { $0.name == signal.strategyName }) else { continue }
            
            let weight = strategy.weight * signal.confidence
            totalWeight += weight
            contributingStrategies.append(signal.strategyName)
            
            switch signal.direction {
            case .buy:
                buyScore += weight
            case .sell:
                sellScore += weight
            case .hold:
                holdScore += weight
            }
        }
        
        // Normalize scores
        if totalWeight > 0 {
            buyScore /= totalWeight
            sellScore /= totalWeight
            holdScore /= totalWeight
        }
        
        // Determine ensemble direction and confidence
        let direction: StrategySignal.Direction
        let confidence: Double
        let reason: String
        
        if buyScore > sellScore && buyScore > holdScore {
            direction = .buy
            confidence = buyScore
            let buyStrategies = signals.filter { $0.direction == .buy }.map { $0.strategyName }
            reason = "Buy consensus from: \(buyStrategies.joined(separator: ", "))"
            
        } else if sellScore > buyScore && sellScore > holdScore {
            direction = .sell
            confidence = sellScore
            let sellStrategies = signals.filter { $0.direction == .sell }.map { $0.strategyName }
            reason = "Sell consensus from: \(sellStrategies.joined(separator: ", "))"
            
        } else {
            direction = .hold
            confidence = holdScore
            reason = "No clear consensus (\(signals.count) strategies)"
        }
        
        return EnsembleSignal(
            direction: direction,
            confidence: confidence,
            reason: reason,
            contributingStrategies: contributingStrategies,
            timestamp: Date()
        )
    }
    
    // MARK: - Configuration Persistence
    
    private func saveConfiguration() {
        let config = StrategyManagerConfiguration(
            enabledStrategies: strategies.filter { $0.isEnabled }.map { $0.name },
            strategyWeights: Dictionary(uniqueKeysWithValues: strategies.map { ($0.name, $0.weight) })
        )
        
        do {
            let data = try JSONEncoder().encode(config)
            UserDefaults.standard.set(data, forKey: "strategyConfiguration")
            Log.verbose("Strategy configuration saved", category: .ai)
        } catch {
            Log.error(error, context: "Saving strategy configuration", category: .ai)
        }
    }
    
    private func loadConfiguration() {
        guard let data = UserDefaults.standard.data(forKey: "strategyConfiguration") else { return }
        
        do {
            let config = try JSONDecoder().decode(StrategyManagerConfiguration.self, from: data)
            
            // Apply configuration
            for i in 0..<strategies.count {
                strategies[i].isEnabled = config.enabledStrategies.contains(strategies[i].name)
                strategies[i].weight = config.strategyWeights[strategies[i].name] ?? 1.0
            }
            
            updateActiveStrategies()
            Log.verbose("Strategy configuration loaded", category: .ai)
            
        } catch {
            Log.error(error, context: "Loading strategy configuration", category: .ai)
        }
    }
    
    // MARK: - Strategy Parameter Updates
    
    func updateStrategyParameter(strategyName: String, parameter: String, value: Any) {
        guard let strategy = strategies.first(where: { $0.name == strategyName }) else {
            Log.warning("Strategy not found: \(strategyName)", category: .ai)
            return
        }
        
        // Update parameter based on strategy type
        switch strategy {
        case let rsiStrategy as RSIStrategy:
            rsiStrategy.updateParameter(key: parameter, value: value)
        case let emaStrategy as EMAStrategy:
            updateEMAParameter(emaStrategy, parameter: parameter, value: value)
        case let macdStrategy as MACDStrategy:
            updateMACDParameter(macdStrategy, parameter: parameter, value: value)
        case let meanReversionStrategy as MeanReversionStrategy:
            updateMeanReversionParameter(meanReversionStrategy, parameter: parameter, value: value)
        case let breakoutStrategy as BreakoutStrategy:
            updateBreakoutParameter(breakoutStrategy, parameter: parameter, value: value)
        default:
            Log.warning("Unknown strategy type for parameter update: \(strategyName)", category: .ai)
        }
        
        saveConfiguration()
    }
    
    // MARK: - Private Parameter Update Methods
    
    private func updateEMAParameter(_ strategy: EMAStrategy, parameter: String, value: Any) {
        switch parameter {
        case "fastPeriod":
            if let intValue = value as? Int {
                strategy.fastPeriod = max(1, min(50, intValue))
            }
        case "slowPeriod":
            if let intValue = value as? Int {
                strategy.slowPeriod = max(2, min(100, intValue))
            }
        default:
            Log.warning("Unknown EMA parameter: \(parameter)", category: .ai)
        }
    }
    
    private func updateMACDParameter(_ strategy: MACDStrategy, parameter: String, value: Any) {
        switch parameter {
        case "fastPeriod":
            if let intValue = value as? Int {
                strategy.fastPeriod = max(1, min(50, intValue))
            }
        case "slowPeriod":
            if let intValue = value as? Int {
                strategy.slowPeriod = max(2, min(100, intValue))
            }
        case "signalPeriod":
            if let intValue = value as? Int {
                strategy.signalPeriod = max(1, min(50, intValue))
            }
        default:
            Log.warning("Unknown MACD parameter: \(parameter)", category: .ai)
        }
    }
    
    private func updateMeanReversionParameter(_ strategy: MeanReversionStrategy, parameter: String, value: Any) {
        switch parameter {
        case "period":
            if let intValue = value as? Int {
                strategy.period = max(5, min(100, intValue))
            }
        case "standardDeviations":
            if let doubleValue = value as? Double {
                strategy.standardDeviations = max(0.5, min(4.0, doubleValue))
            }
        default:
            Log.warning("Unknown Mean Reversion parameter: \(parameter)", category: .ai)
        }
    }
    
    private func updateBreakoutParameter(_ strategy: BreakoutStrategy, parameter: String, value: Any) {
        switch parameter {
        case "atrPeriod":
            if let intValue = value as? Int {
                strategy.atrPeriod = max(5, min(50, intValue))
            }
        case "multiplier":
            if let doubleValue = value as? Double {
                strategy.multiplier = max(0.5, min(5.0, doubleValue))
            }
        default:
            Log.warning("Unknown Breakout parameter: \(parameter)", category: .ai)
        }
    }
    
    // MARK: - StrategyManagerProtocol Conformance
    
    var availableStrategies: [any TradingStrategy] {
        get async {
            // Convert Strategy to TradingStrategy - they're compatible protocols
            return strategies.map { StrategyAdapter(strategy: $0) }
        }
    }
    
    var activeStrategies: [any TradingStrategy] {
        get async {
            return _activeStrategies.map { StrategyAdapter(strategy: $0) }
        }
    }
    
    func addStrategy(_ strategy: any TradingStrategy) async {
        // Convert TradingStrategy back to Strategy if needed
        // For now, log that this is called but maintain existing logic
        Log.warning("addStrategy called with TradingStrategy protocol - not implemented", category: .ai)
    }
    
    func removeStrategy(withId id: String) async {
        if let index = strategies.firstIndex(where: { $0.name == id }) {
            strategies.remove(at: index)
            updateActiveStrategies()
            saveConfiguration()
            Log.userAction("Strategy removed", parameters: ["strategyId": id])
        }
    }
    
    func enableStrategy(withId id: String) async {
        enableStrategy(named: id)
    }
    
    func disableStrategy(withId id: String) async {
        disableStrategy(named: id)
    }
    
    func generateSignals(for candles: [Candle]) async -> [StrategySignal] {
        let ensembleSignal = await generateSignals(from: candles)
        // Return individual signals for protocol conformance
        return Array(lastSignals.values)
    }
}

// MARK: - Strategy Adapter

/// Adapter to bridge Strategy protocol to TradingStrategy protocol
private struct StrategyAdapter: TradingStrategy {
    private let strategy: any Strategy
    
    init(strategy: any Strategy) {
        self.strategy = strategy
    }
    
    var id: String { strategy.name }
    var name: String { strategy.name }
    var isEnabled: Bool {
        get { strategy.isEnabled }
        set { /* This adapter is read-only */ }
    }
    var parameters: [StrategyParameter] { [] } // Simplified for now
    
    func generateSignal(from candles: [Candle]) async -> StrategySignal {
        return strategy.signal(candles: candles)
    }
    
    func updateParameter(_ parameter: StrategyParameter, value: Any) throws {
        // This would need to be implemented to modify the underlying strategy
        throw NSError(domain: "StrategyAdapter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Parameter updates not supported through adapter"])
    }
}

// MARK: - Supporting Types

struct EnsembleSignal {
    let direction: StrategySignal.Direction
    let confidence: Double
    let reason: String
    let contributingStrategies: [String]
    let timestamp: Date
}

private struct StrategyManagerConfiguration: Codable {
    let enabledStrategies: [String]
    let strategyWeights: [String: Double]
}