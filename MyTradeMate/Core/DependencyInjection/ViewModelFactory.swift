import Foundation
import SwiftUI

// MARK: - ViewModel Factory
final class ViewModelFactory {
    private let container: ServiceContainer
    
    init(container: ServiceContainer = DIContainer.shared) {
        self.container = container
    }
    
    // MARK: - ViewModel Creation Methods
    
    func makeDashboardViewModel() -> DashboardVM {
        return DashboardVM()
    }
    
    func makeExchangeKeysViewModel() -> ExchangeKeysViewModel {
        return ExchangeKeysViewModel()
    }
    
    func makeStrategiesViewModel() -> StrategiesViewModel {
        return StrategiesViewModel()
    }
    
    // MARK: - Testing Support
    
    func makeDashboardViewModel(
        marketDataService: MarketDataServiceProtocol,
        aiModelManager: AIModelManagerProtocol,
        errorManager: ErrorManagerProtocol,
        settings: AppSettingsProtocol,
        strategyManager: StrategyManagerProtocol
    ) -> DashboardVM {
        // Register test dependencies
        container.register(MarketDataServiceProtocol.self, instance: marketDataService)
        container.register(AIModelManagerProtocol.self, instance: aiModelManager)
        container.register(ErrorManagerProtocol.self, instance: errorManager)
        container.register(AppSettingsProtocol.self, instance: settings)
        container.register(StrategyManagerProtocol.self, instance: strategyManager)
        
        return DashboardVM()
    }
    
    func makeExchangeKeysViewModel(
        keychainStore: KeychainStoreProtocol,
        errorManager: ErrorManagerProtocol
    ) -> ExchangeKeysViewModel {
        return ExchangeKeysViewModel(
            keychainStore: keychainStore,
            errorManager: errorManager
        )
    }
}

// MARK: - Environment Key for ViewModelFactory
struct ViewModelFactoryKey: EnvironmentKey {
    static let defaultValue = ViewModelFactory()
}

extension EnvironmentValues {
    var viewModelFactory: ViewModelFactory {
        get { self[ViewModelFactoryKey.self] }
        set { self[ViewModelFactoryKey.self] = newValue }
    }
}

// MARK: - View Extension for Easy Access
extension View {
    func viewModelFactory(_ factory: ViewModelFactory) -> some View {
        environment(\.viewModelFactory, factory)
    }
}

// MARK: - Property Wrapper for ViewModel Creation
@propertyWrapper
struct ViewModelInjected<T> {
    private let factory: ViewModelFactory
    private let creator: (ViewModelFactory) -> T
    
    var wrappedValue: T {
        creator(factory)
    }
    
    init(_ creator: @escaping (ViewModelFactory) -> T, factory: ViewModelFactory = ViewModelFactory()) {
        self.creator = creator
        self.factory = factory
    }
}

// MARK: - Example Usage in Views
/*
struct ExampleView: View {
    @ViewModelInjected(\.makeDashboardViewModel) private var viewModel: DashboardVM
    
    var body: some View {
        // View implementation
    }
}
*/