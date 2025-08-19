import Foundation
import SwiftUI

@MainActor
final class StrategiesViewModel: ObservableObject {
    // MARK: - Injected Dependencies
    @Injected private var strategyManager: StrategyManagerProtocol
    @Injected private var errorManager: ErrorManagerProtocol
    @Injected private var settings: AppSettingsProtocol
    
    // MARK: - Published Properties
    @Published var availableStrategies: [TradingStrategy] = []
    @Published var activeStrategies: [TradingStrategy] = []
    @Published var isLoading = false
    @Published var selectedStrategy: TradingStrategy?
    
    // MARK: - Initialization
    init() {
        loadStrategies()
    }
    
    // MARK: - Public Methods
    
    func refreshStrategies() {
        loadStrategies()
    }
    
    func enableStrategy(_ strategy: TradingStrategy) {
        Task {
            do {
                await strategyManager.enableStrategy(withId: strategy.id)
                await MainActor.run {
                    loadStrategies()
                }
                Log.userAction("Enabled strategy: \(strategy.name)")
            } catch {
                errorManager.handle(error, context: "Enable Strategy")
            }
        }
    }
    
    func disableStrategy(_ strategy: TradingStrategy) {
        Task {
            do {
                await strategyManager.disableStrategy(withId: strategy.id)
                await MainActor.run {
                    loadStrategies()
                }
                Log.userAction("Disabled strategy: \(strategy.name)")
            } catch {
                errorManager.handle(error, context: "Disable Strategy")
            }
        }
    }
    
    func selectStrategy(_ strategy: TradingStrategy) {
        selectedStrategy = strategy
        Log.userAction("Selected strategy: \(strategy.name)")
    }
    
    // MARK: - Private Methods
    
    private func loadStrategies() {
        isLoading = true
        
        Task {
            let available = await strategyManager.availableStrategies
            let active = await strategyManager.activeStrategies
            
            await MainActor.run {
                self.availableStrategies = available
                self.activeStrategies = active
                self.isLoading = false
            }
        }
    }
}

// MARK: - Testing Support
extension StrategiesViewModel {
    convenience init(
        strategyManager: StrategyManagerProtocol,
        errorManager: ErrorManagerProtocol,
        settings: AppSettingsProtocol
    ) {
        // Register mocks for testing
        DIContainer.shared.registerMock(StrategyManagerProtocol.self, mock: strategyManager)
        DIContainer.shared.registerMock(ErrorManagerProtocol.self, mock: errorManager)
        DIContainer.shared.registerMock(AppSettingsProtocol.self, mock: settings)
        
        self.init()
    }
}