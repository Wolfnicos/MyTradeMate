import Foundation
import Combine
import SwiftUI

// MARK: - Strategy Configuration Manager
@MainActor
final class StrategyConfigurationManager: ObservableObject {
    // MARK: - Injected Dependencies
    @Injected private var strategyManager: StrategyManagerProtocol
    @Injected private var settings: AppSettingsProtocol
    @Injected private var errorManager: ErrorManagerProtocol
    
    // MARK: - Published Properties
    @Published var strategies: [StrategyInfo] = []
    @Published var selectedStrategy: StrategyInfo?
    @Published var isLoading = false
    
    // MARK: - Initialization
    init() {
        setupStrategies()
    }
    
    // MARK: - Public Methods
    func loadStrategies() {
        isLoading = true
        
        Task {
            let availableStrategies = strategyManager.availableStrategies
            let strategyInfos = availableStrategies.map { strategy in
                StrategyInfo(
                    id: strategy.id,
                    name: strategy.name,
                    description: getStrategyDescription(for: strategy.name),
                    isEnabled: strategy.isEnabled,
                    weight: 1.0, // Default weight
                    parameters: strategy.parameters.map { param in
                        StrategyParameter(
                            id: param.id,
                            name: param.name,
                            type: getParameterType(for: param.type),
                            value: param.currentValue as? Double ?? 0.0,
                            min: param.range?.lowerBound ?? 0.0,
                            max: param.range?.upperBound ?? 100.0,
                            step: 1.0
                        )
                    }
                )
            }
            
            await MainActor.run {
                self.strategies = strategyInfos
                self.isLoading = false
            }
        }
    }
    
    func toggleStrategy(_ strategy: StrategyInfo) {
        if let index = strategies.firstIndex(where: { $0.id == strategy.id }) {
            strategies[index].isEnabled.toggle()
            
            // Update the strategy manager
            if strategies[index].isEnabled {
                strategyManager.enableStrategy(withId: strategy.id)
            } else {
                strategyManager.disableStrategy(withId: strategy.id)
            }
            
            Log.userAction("Toggled strategy \(strategy.name): \(strategies[index].isEnabled ? "ON" : "OFF")")
        }
    }
    
    func updateStrategyWeight(_ strategy: StrategyInfo, weight: Double) {
        if let index = strategies.firstIndex(where: { $0.id == strategy.id }) {
            strategies[index].weight = weight
            Log.userAction("Updated \(strategy.name) weight to \(weight)")
        }
    }
    
    func updateStrategyParameter(_ strategy: StrategyInfo, parameter: StrategyParameter, value: Double) {
        if let strategyIndex = strategies.firstIndex(where: { $0.id == strategy.id }),
           let paramIndex = strategies[strategyIndex].parameters.firstIndex(where: { $0.id == parameter.id }) {
            
            strategies[strategyIndex].parameters[paramIndex].value = value
            
            // Update the actual strategy parameter
            do {
                let actualStrategy = strategyManager.availableStrategies.first { $0.id == strategy.id }
                let actualParam = actualStrategy?.parameters.first { $0.id == parameter.id }
                
                if let actualParam = actualParam {
                    try actualStrategy?.updateParameter(actualParam, value: value)
                }
                
                Log.userAction("Updated \(strategy.name) parameter \(parameter.name) to \(value)")
            } catch {
                errorManager.handle(error, context: "Update Strategy Parameter")
            }
        }
    }
    
    func selectStrategy(_ strategy: StrategyInfo) {
        selectedStrategy = strategy
        Log.userAction("Selected strategy: \(strategy.name)")
    }
    
    func resetStrategyToDefaults(_ strategy: StrategyInfo) {
        if let index = strategies.firstIndex(where: { $0.id == strategy.id }) {
            // Reset parameters to default values
            for paramIndex in strategies[index].parameters.indices {
                let param = strategies[index].parameters[paramIndex]
                // Reset to middle of range as default
                let defaultValue = (param.min + param.max) / 2
                strategies[index].parameters[paramIndex].value = defaultValue
            }
            
            // Reset weight
            strategies[index].weight = 1.0
            
            Log.userAction("Reset \(strategy.name) to defaults")
        }
    }
    
    // MARK: - Private Methods
    private func setupStrategies() {
        loadStrategies()
    }
    
    private func getStrategyDescription(for name: String) -> String {
        switch name {
        case "RSI":
            return "Relative Strength Index - identifies overbought/oversold conditions"
        case "MACD":
            return "Moving Average Convergence Divergence - trend following momentum indicator"
        case "EMA Crossover":
            return "Exponential Moving Average crossover - identifies trend changes"
        case "Mean Reversion":
            return "Identifies when price deviates significantly from its mean"
        case "Breakout":
            return "Detects price breakouts from consolidation patterns"
        case "Bollinger Bands":
            return "Uses volatility bands to identify overbought/oversold conditions"
        case "Stochastic":
            return "Momentum oscillator comparing closing price to price range"
        case "Williams %R":
            return "Momentum indicator measuring overbought/oversold levels"
        default:
            return "Trading strategy for market analysis"
        }
    }
    
    private func getParameterType(for type: StrategyParameter.ParameterType) -> StrategyParameter.ParameterType {
        switch type {
        case .integer, .double:
            return .slider
        case .boolean:
            return .stepper
        case .string:
            return .textField
        }
    }
}

// MARK: - Strategy Info Model
struct StrategyInfo: Identifiable {
    let id: String
    let name: String
    let description: String
    var isEnabled: Bool
    var weight: Double
    var parameters: [StrategyParameter]
}

// MARK: - Strategy Parameter Model
struct StrategyParameter: Identifiable {
    enum ParameterType {
        case slider
        case stepper
        case textField
    }
    
    let id: String
    let name: String
    let type: ParameterType
    var value: Double
    let min: Double
    let max: Double
    let step: Double
}