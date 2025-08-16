import Foundation

// MARK: - Service Container Protocol
protocol ServiceContainer {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func register<T>(_ type: T.Type, instance: T)
    func resolve<T>(_ type: T.Type) -> T
    func resolve<T>(_ type: T.Type) -> T?
}

// MARK: - Dependency Injection Container
final class DIContainer: ServiceContainer {
    static let shared = DIContainer()
    
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    
    private init() {
        registerDefaultServices()
    }
    
    // MARK: - Registration
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        services[key] = instance
    }
    
    // MARK: - Resolution
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        // Check for existing instance
        if let service = services[key] as? T {
            return service
        }
        
        // Check for factory
        if let factory = factories[key] {
            let instance = factory() as! T
            // Store singleton instances
            services[key] = instance
            return instance
        }
        
        fatalError("Service \(key) not registered")
    }
    
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        // Check for existing instance
        if let service = services[key] as? T {
            return service
        }
        
        // Check for factory
        if let factory = factories[key] {
            let instance = factory() as! T
            services[key] = instance
            return instance
        }
        
        return nil
    }
    
    // MARK: - Default Service Registration
    
    private func registerDefaultServices() {
        // Core Services
        register(KeychainStoreProtocol.self) { KeychainStore.shared }
        register(ErrorManagerProtocol.self) { ErrorManager.shared }
        register(NavigationCoordinator.self) { NavigationCoordinator() }
        
        // Market Data Services
        register(MarketDataServiceProtocol.self) { MarketDataService.shared }
        register(AIModelManagerProtocol.self) { AIModelManager.shared }
        
        // Exchange Clients
        register(BinanceClientProtocol.self) { BinanceClient() }
        register(KrakenClientProtocol.self) { KrakenClient() }
        
        // Strategy Services
        register(StrategyManagerProtocol.self) { StrategyManager.shared }
        
        // Settings
        register(AppSettingsProtocol.self) { AppSettings.shared }
        
        Log.app.info("Dependency injection container initialized with default services")
    }
    
    // MARK: - Testing Support
    
    func registerMock<T>(_ type: T.Type, mock: T) {
        let key = String(describing: type)
        services[key] = mock
        Log.app.debug("Registered mock for \(key)")
    }
    
    func reset() {
        services.removeAll()
        factories.removeAll()
        registerDefaultServices()
        Log.app.debug("Dependency injection container reset")
    }
}

// MARK: - Property Wrapper for Dependency Injection
@propertyWrapper
struct Injected<T> {
    private let container: ServiceContainer
    
    var wrappedValue: T {
        container.resolve(T.self)
    }
    
    init(container: ServiceContainer = DIContainer.shared) {
        self.container = container
    }
}

// MARK: - Optional Dependency Injection
@propertyWrapper
struct OptionalInjected<T> {
    private let container: ServiceContainer
    
    var wrappedValue: T? {
        container.resolve(T.self)
    }
    
    init(container: ServiceContainer = DIContainer.shared) {
        self.container = container
    }
}