import Foundation
import Combine
import SwiftUI

// Using StrategyInfo and StrategyParameter from Models/StrategyModels.swift

// MARK: - Strategy Configuration Manager
@MainActor
final class StrategyConfigurationManager: ObservableObject {
    // MARK: - Dependencies
    private let strategyManager = StrategyManager.shared
    private let errorManager = ErrorManager.shared
    
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
            let availableStrategies = strategyManager.strategies
            let strategyInfos = availableStrategies.map { strategy in
                StrategyInfo(
                    id: strategy.name,
                    name: strategy.name,
                    description: getStrategyDescription(for: strategy.name),
                    isEnabled: strategy.isEnabled,
                    weight: 1.0, // Default weight
                    parameters: []
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
                strategyManager.enableStrategy(named: strategy.id)
            } else {
                strategyManager.disableStrategy(named: strategy.id)
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
                let actualStrategy = strategyManager.strategies.first { $0.name == strategy.id }
                // Parameters not available in current Strategy protocol
                
                // Parameter updated
                
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
                let defaultValue = (param.minValue + param.maxValue) / 2
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
        case .slider:
            return .slider
        case .stepper:
            return .stepper
        case .textField:
            return .textField
        }
    }
}

// Using StrategyInfo and StrategyParameter from Models/StrategyModels.swift