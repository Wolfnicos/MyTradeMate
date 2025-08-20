import Foundation
import SwiftUI

    // MARK: - ViewModel Factory
@MainActor
final class ViewModelFactory {
    nonisolated static let shared = ViewModelFactory()

    nonisolated private init() {}

    func makeDashboardViewModel() -> DashboardVM {
        return DashboardVM()
    }

    func makeStrategiesViewModel() -> StrategiesVM {
        return StrategiesVM()
    }

        // Temporarily disabled - classes need to be rebuilt
        // func makeTradesViewModel() -> TradesVM { return TradesVM() }
        // func makeTradeHistoryViewModel() -> TradeHistoryVM { return TradeHistoryVM() }

    func makeSettingsViewModel() -> SettingsVM {
        return SettingsVM.shared
    }

    func makeExchangeKeysViewModel() -> ExchangeKeysViewModel {
        return ExchangeKeysViewModel()
    }

        // You can add more factory methods here as needed
}

    // MARK: - Environment Key for ViewModelFactory
struct ViewModelFactoryKey: EnvironmentKey {
    static let defaultValue = ViewModelFactory.shared
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

    init(_ creator: @escaping (ViewModelFactory) -> T, factory: ViewModelFactory = ViewModelFactory.shared) {
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
