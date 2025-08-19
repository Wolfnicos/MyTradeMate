import Foundation
import Combine
import SwiftUI
import OSLog

private let logger = Logger.shared

// Using StrategyInfo and StrategyParameter from Models/StrategyModels.swift

@MainActor
final class StrategiesVM: ObservableObject {
    // MARK: - Published Properties
    @Published var strategies: [StrategyInfo] = []
    @Published var currentRegime: String = "Ranging"
    @Published var recommendedStrategies: [String] = []
    @Published var selectedStrategy: StrategyInfo? = nil
    @Published var lastSignals: [String: StrategySignal] = [:]
    @Published var isGeneratingSignals: Bool = false
    @Published var ensembleSignal: EnsembleSignal? = nil
    
    // MARK: - Private Properties
    private let ensembleDecider = EnsembleDecider()
    private let regimeDetector = RegimeDetector()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var regimeColor: Color {
        switch currentRegime {
        case "Trending Up": return Accent.green
        case "Trending Down": return Accent.red
        case "Volatile": return Accent.yellow
        default: return Brand.blue
        }
    }
    
    // MARK: - Initialization
    init() {
        setupStrategies()
        updateRegime()
    }
    
    // MARK: - Setup
    private func setupStrategies() {
        strategies = [
            StrategyInfo(
                id: "ema",
                name: "EMA Crossover",
                description: "Exponential Moving Average crossover strategy",
                isEnabled: true,
                weight: 1.0,
                parameters: [
                    StrategyParameter(
                        id: "fast",
                        name: "Fast Period",
                        type: .slider,
                        value: 9,
                        minValue: 5,
                        maxValue: 20,
                        step: 1
                    ),
                    StrategyParameter(
                        id: "slow",
                        name: "Slow Period",
                        type: .slider,
                        value: 21,
                        minValue: 10,
                        maxValue: 50,
                        step: 1
                    )
                ]
            ),
            StrategyInfo(
                id: "rsi",
                name: "RSI Swing",
                description: "Relative Strength Index momentum strategy",
                isEnabled: true,
                weight: 1.0,
                parameters: [
                    StrategyParameter(
                        id: "period",
                        name: "Period",
                        type: .stepper,
                        value: 14,
                        minValue: 5,
                        maxValue: 30,
                        step: 1
                    ),
                    StrategyParameter(
                        id: "oversold",
                        name: "Oversold",
                        type: .textField,
                        value: 30,
                        minValue: 10,
                        maxValue: 40,
                        step: 5
                    ),
                    StrategyParameter(
                        id: "overbought",
                        name: "Overbought",
                        type: .textField,
                        value: 70,
                        minValue: 60,
                        maxValue: 90,
                        step: 5
                    )
                ]
            ),
            StrategyInfo(
                id: "macd",
                name: "MACD",
                description: "Moving Average Convergence Divergence strategy",
                isEnabled: true,
                weight: 1.0,
                parameters: [
                    StrategyParameter(
                        id: "fast",
                        name: "Fast",
                        type: .stepper,
                        value: 12,
                        minValue: 5,
                        maxValue: 20,
                        step: 1
                    ),
                    StrategyParameter(
                        id: "slow",
                        name: "Slow",
                        type: .stepper,
                        value: 26,
                        minValue: 20,
                        maxValue: 40,
                        step: 1
                    ),
                    StrategyParameter(
                        id: "signal",
                        name: "Signal",
                        type: .stepper,
                        value: 9,
                        minValue: 5,
                        maxValue: 15,
                        step: 1
                    )
                ]
            ),
            StrategyInfo(
                id: "meanrev",
                name: "Mean Reversion",
                description: "Bollinger Bands mean reversion strategy",
                isEnabled: false,
                weight: 1.0,
                parameters: [
                    StrategyParameter(
                        id: "period",
                        name: "Period",
                        type: .slider,
                        value: 20,
                        minValue: 10,
                        maxValue: 50,
                        step: 1
                    ),
                    StrategyParameter(
                        id: "deviations",
                        name: "Std Dev",
                        type: .slider,
                        value: 2.0,
                        minValue: 1.0,
                        maxValue: 3.0,
                        step: 0.5
                    )
                ]
            ),
            StrategyInfo(
                id: "breakout",
                name: "ATR Breakout",
                description: "Average True Range breakout strategy",
                isEnabled: false,
                weight: 1.0,
                parameters: [
                    StrategyParameter(
                        id: "period",
                        name: "ATR Period",
                        type: .stepper,
                        value: 14,
                        minValue: 5,
                        maxValue: 30,
                        step: 1
                    ),
                    StrategyParameter(
                        id: "multiplier",
                        name: "Multiplier",
                        type: .slider,
                        value: 1.5,
                        minValue: 0.5,
                        maxValue: 3.0,
                        step: 0.1
                    )
                ]
            )
        ]
    }
    
    // MARK: - Public Methods
    func loadStrategies() {
        // Strategies are already loaded in init
        updateRegime()
    }
    
    func toggleStrategy(_ id: String, enabled: Bool) {
        guard let index = strategies.firstIndex(where: { $0.id == id }) else { return }
        
        strategies[index].isEnabled = enabled
        ensembleDecider.enableStrategy(strategyName: strategies[index].name, enabled: enabled)
        
        Task { await logger.info("Strategy \(strategies[index].name) \(enabled ? "enabled" : "disabled")") }
        Haptics.playImpact(.light)
    }
    
    func updateWeight(_ id: String, weight: Double) {
        guard let index = strategies.firstIndex(where: { $0.id == id }) else { return }
        
        strategies[index].weight = weight
        ensembleDecider.updateStrategyWeight(strategyName: strategies[index].name, weight: weight)
        
        Task { await logger.info("Strategy \(strategies[index].name) weight updated to \(weight)") }
    }
    
    func updateParameter(strategyId: String, paramId: String, value: Double) {
        guard let strategyIndex = strategies.firstIndex(where: { $0.id == strategyId }),
              let paramIndex = strategies[strategyIndex].parameters.firstIndex(where: { $0.id == paramId }) else {
            return
        }
        
        strategies[strategyIndex].parameters[paramIndex].value = value
        
        // Update the actual strategy parameters
        updateStrategyEngine(strategyId: strategyId, paramId: paramId, value: value)
        
        Task { await logger.info("Parameter \(paramId) for \(strategies[strategyIndex].name) updated to \(value)") }
    }
    
    func enableStrategy(named name: String) {
        guard let index = strategies.firstIndex(where: { $0.name == name }) else { return }
        toggleStrategy(strategies[index].id, enabled: true)
    }
    
    func disableStrategy(named name: String) {
        guard let index = strategies.firstIndex(where: { $0.name == name }) else { return }
        toggleStrategy(strategies[index].id, enabled: false)
    }
    
    // MARK: - Private Methods
    private func updateRegime() {
        // Get recent candles for regime detection
        Task {
            do {
                let candles = try await MarketDataService.shared.fetchCandles(
                    symbol: "BTCUSDT",
                    timeframe: .h1
                )
                
                let regime = regimeDetector.detectRegime(candles: candles)
                let recommended = regimeDetector.recommendStrategies(for: regime)
                
                await MainActor.run {
                    switch regime {
                    case .trending(let direction):
                        switch direction {
                        case .bullish:
                            self.currentRegime = "Trending Up"
                        case .bearish:
                            self.currentRegime = "Trending Down"
                        }
                    case .ranging:
                        self.currentRegime = "Ranging"
                    case .volatile:
                        self.currentRegime = "Volatile"
                    }
                    
                    self.recommendedStrategies = recommended
                }
                
                await logger.info("Market regime: \(self.currentRegime)")
                await logger.info("Recommended strategies: \(recommended.joined(separator: ", "))")
            } catch {
                await logger.error("Failed to update regime: \(error.localizedDescription)")
                
                // Use default values in case of error
                await MainActor.run {
                    self.currentRegime = "Unknown"
                    self.recommendedStrategies = ["EMA Crossover", "RSI Swing"]
                }
            }
        }
    }
    
    private func updateStrategyEngine(strategyId: String, paramId: String, value: Double) {
        // Update the actual strategy engine parameters
        Task { await logger.info("Updating strategy engine: \(strategyId).\(paramId) = \(value)") }
        
        switch strategyId {
        case "ema":
            updateEMAStrategy(paramId: paramId, value: value)
        case "rsi":
            updateRSIStrategy(paramId: paramId, value: value)
        case "macd":
            updateMACDStrategy(paramId: paramId, value: value)
        case "meanrev":
            updateMeanReversionStrategy(paramId: paramId, value: value)
        case "breakout":
            updateBreakoutStrategy(paramId: paramId, value: value)
        default:
            Task { await logger.warning("Unknown strategy ID: \(strategyId)") }
        }
    }
    
    private func updateEMAStrategy(paramId: String, value: Double) {
        switch paramId {
        case "fast":
            EMAStrategy.shared.updateFastPeriod(Int(value))
        case "slow":
            EMAStrategy.shared.updateSlowPeriod(Int(value))
        default:
            Task { await logger.warning("Unknown EMA parameter: \(paramId)") }
        }
    }
    
    private func updateRSIStrategy(paramId: String, value: Double) {
        switch paramId {
        case "period":
            RSIStrategy.shared.updatePeriod(Int(value))
        case "oversold":
            RSIStrategy.shared.updateOversoldLevel(value)
        case "overbought":
            RSIStrategy.shared.updateOverboughtLevel(value)
        default:
            Task { await logger.warning("Unknown RSI parameter: \(paramId)") }
        }
    }
    
    private func updateMACDStrategy(paramId: String, value: Double) {
        switch paramId {
        case "fast":
            MACDStrategy.shared.updateFastPeriod(Int(value))
        case "slow":
            MACDStrategy.shared.updateSlowPeriod(Int(value))
        case "signal":
            MACDStrategy.shared.updateSignalPeriod(Int(value))
        default:
            Task { await logger.warning("Unknown MACD parameter: \(paramId)") }
        }
    }
    
    private func updateMeanReversionStrategy(paramId: String, value: Double) {
        switch paramId {
        case "period":
            MeanReversionStrategy.shared.updatePeriod(Int(value))
        case "deviations":
            MeanReversionStrategy.shared.updateStandardDeviations(value)
        default:
            Task { await logger.warning("Unknown Mean Reversion parameter: \(paramId)") }
        }
    }
    
    private func updateBreakoutStrategy(paramId: String, value: Double) {
        switch paramId {
        case "period":
            BreakoutStrategy.shared.updateATRPeriod(Int(value))
        case "multiplier":
            BreakoutStrategy.shared.updateMultiplier(value)
        default:
            Task { await logger.warning("Unknown Breakout parameter: \(paramId)") }
        }
    }
}
