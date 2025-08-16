import Foundation
import Combine
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.mytrademate", category: "Strategies")

// MARK: - Refactored Strategies ViewModel
@MainActor
final class RefactoredStrategiesVM: ObservableObject {
    // MARK: - Component Managers
    @StateObject private var configurationManager = StrategyConfigurationManager()
    @StateObject private var regimeDetectionManager = RegimeDetectionManager()
    
    // MARK: - Injected Dependencies
    @Injected private var settings: AppSettingsProtocol
    @Injected private var marketDataService: MarketDataServiceProtocol
    
    // MARK: - Published Properties (Delegated to Components)
    
    // Strategy Configuration Properties
    var strategies: [StrategyInfo] { configurationManager.strategies }
    var selectedStrategy: StrategyInfo? { 
        get { configurationManager.selectedStrategy }
        set { configurationManager.selectedStrategy = newValue }
    }
    var isLoading: Bool { configurationManager.isLoading }
    
    // Regime Detection Properties
    var currentRegime: MarketRegime { regimeDetectionManager.currentRegime }
    var regimeConfidence: Double { regimeDetectionManager.regimeConfidence }
    var recommendedStrategies: [String] { regimeDetectionManager.recommendedStrategies }
    var regimeHistory: [RegimeRecord] { regimeDetectionManager.regimeHistory }
    
    // MARK: - Computed Properties
    var regimeColor: Color { currentRegime.color }
    var regimeDescription: String { currentRegime.description }
    
    var enabledStrategies: [StrategyInfo] {
        strategies.filter { $0.isEnabled }
    }
    
    var disabledStrategies: [StrategyInfo] {
        strategies.filter { !$0.isEnabled }
    }
    
    var totalStrategyWeight: Double {
        enabledStrategies.reduce(0) { $0 + $1.weight }
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var regimeUpdateTimer: Timer?
    
    // MARK: - Initialization
    init() {
        setupBindings()
        startRegimeMonitoring()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Update regime when strategies change
        configurationManager.$strategies
            .dropFirst()
            .sink { [weak self] _ in
                self?.updateRegimeDetection()
            }
            .store(in: &cancellables)
        
        // Log regime changes
        regimeDetectionManager.$currentRegime
            .dropFirst()
            .sink { regime in
                Log.ai.info("Market regime changed to: \(regime.rawValue)")
            }
            .store(in: &cancellables)
    }
    
    private func startRegimeMonitoring() {
        // Update regime detection every 30 seconds
        regimeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateRegimeDetection()
        }
    }
    
    // MARK: - Public Methods (Delegated to Components)
    
    // Strategy Configuration Methods
    func loadStrategies() {
        configurationManager.loadStrategies()
    }
    
    func toggleStrategy(_ strategy: StrategyInfo) {
        configurationManager.toggleStrategy(strategy)
        Log.userAction("Toggled strategy: \(strategy.name)")
    }
    
    func updateStrategyWeight(_ strategy: StrategyInfo, weight: Double) {
        configurationManager.updateStrategyWeight(strategy, weight: weight)
    }
    
    func updateStrategyParameter(_ strategy: StrategyInfo, parameter: StrategyParameter, value: Double) {
        configurationManager.updateStrategyParameter(strategy, parameter: parameter, value: value)
    }
    
    func selectStrategy(_ strategy: StrategyInfo) {
        configurationManager.selectStrategy(strategy)
    }
    
    func resetStrategyToDefaults(_ strategy: StrategyInfo) {
        configurationManager.resetStrategyToDefaults(strategy)
    }
    
    // Regime Detection Methods
    func updateRegimeDetection() {
        Task {
            do {
                let candles = try await marketDataService.fetchCandles(
                    symbol: settings.defaultSymbol,
                    timeframe: .m5
                )
                
                await MainActor.run {
                    self.regimeDetectionManager.detectRegime(from: candles)
                }
            } catch {
                Log.error(error, context: "Update regime detection")
            }
        }
    }
    
    func getRegimeAnalysis() -> RegimeAnalysis? {
        Task {
            do {
                let candles = try await marketDataService.fetchCandles(
                    symbol: settings.defaultSymbol,
                    timeframe: .m5
                )
                
                return regimeDetectionManager.getRegimeAnalysis(for: candles)
            } catch {
                Log.error(error, context: "Get regime analysis")
                return nil
            }
        }
        return nil
    }
    
    // MARK: - Utility Methods
    func refreshAll() {
        loadStrategies()
        updateRegimeDetection()
        Log.userAction("Refreshed strategies and regime detection")
    }
    
    func exportConfiguration() -> StrategyConfiguration {
        return StrategyConfiguration(
            strategies: strategies,
            currentRegime: currentRegime,
            timestamp: Date()
        )
    }
    
    func importConfiguration(_ configuration: StrategyConfiguration) {
        // Update strategy configurations
        for configStrategy in configuration.strategies {
            if let index = strategies.firstIndex(where: { $0.id == configStrategy.id }) {
                configurationManager.strategies[index] = configStrategy
            }
        }
        
        Log.userAction("Imported strategy configuration")
    }
    
    // MARK: - Legacy Compatibility Methods
    func getStrategyByName(_ name: String) -> StrategyInfo? {
        return strategies.first { $0.name == name }
    }
    
    func enableRecommendedStrategies() {
        for strategyName in recommendedStrategies {
            if let strategy = getStrategyByName(strategyName) {
                configurationManager.toggleStrategy(strategy)
            }
        }
        Log.userAction("Enabled recommended strategies for \(currentRegime.rawValue) regime")
    }
    
    // MARK: - Cleanup
    deinit {
        regimeUpdateTimer?.invalidate()
    }
}

// MARK: - Supporting Models
struct StrategyConfiguration: Codable {
    let strategies: [StrategyInfo]
    let currentRegime: MarketRegime
    let timestamp: Date
}

// MARK: - StrategyInfo Codable Extension
extension StrategyInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, description, isEnabled, weight, parameters
    }
}

// MARK: - StrategyParameter Codable Extension
extension StrategyParameter: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, type, value, min, max, step
    }
    
    enum ParameterTypeCodable: String, Codable {
        case slider, stepper, textField
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let typeString = try container.decode(ParameterTypeCodable.self, forKey: .type)
        switch typeString {
        case .slider: type = .slider
        case .stepper: type = .stepper
        case .textField: type = .textField
        }
        value = try container.decode(Double.self, forKey: .value)
        min = try container.decode(Double.self, forKey: .min)
        max = try container.decode(Double.self, forKey: .max)
        step = try container.decode(Double.self, forKey: .step)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        let typeString: ParameterTypeCodable
        switch type {
        case .slider: typeString = .slider
        case .stepper: typeString = .stepper
        case .textField: typeString = .textField
        }
        try container.encode(typeString, forKey: .type)
        try container.encode(value, forKey: .value)
        try container.encode(min, forKey: .min)
        try container.encode(max, forKey: .max)
        try container.encode(step, forKey: .step)
    }
}

// MARK: - MarketRegime Codable Extension
extension MarketRegime: Codable {}

// MARK: - Factory Method for Easy Migration
extension RefactoredStrategiesVM {
    /// Creates a RefactoredStrategiesVM that can be used as a drop-in replacement for StrategiesVM
    static func createCompatible() -> RefactoredStrategiesVM {
        return RefactoredStrategiesVM()
    }
}

// MARK: - Preview Support
extension RefactoredStrategiesVM {
    static func preview() -> RefactoredStrategiesVM {
        let vm = RefactoredStrategiesVM()
        // Set up preview data
        return vm
    }
}