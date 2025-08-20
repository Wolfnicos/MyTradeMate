import Foundation
import SwiftUI
import Combine

/// Single source of truth for trading mode management
/// Handles mode changes, API key validation, and state propagation
@MainActor
final class TradingModeStore: ObservableObject {
    
    // MARK: - Singleton
    static let shared = TradingModeStore()
    
    // MARK: - Published Properties
    
    /// Current trading mode - the single source of truth
    @Published private(set) var currentMode: TradingMode = .demo
    
    /// Whether mode change is in progress
    @Published private(set) var isChangingMode: Bool = false
    
    /// Current validation state
    @Published private(set) var validationState: ValidationState = .valid
    
    /// Error message if validation fails
    @Published private(set) var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let settingsRepository: SettingsRepository
    private lazy var exchangeKeysViewModel: ExchangeKeysViewModel = ExchangeKeysViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        self.settingsRepository = SettingsRepository.shared
        setupBindings()
        loadInitialState()
    }
    
    // MARK: - Public Interface
    
    /// Attempt to change trading mode with validation
    func changeTo(_ newMode: TradingMode) async {
        isChangingMode = true
        errorMessage = nil
        
        do {
            try await validateModeChange(to: newMode)
            await applyModeChange(to: newMode)
            validationState = .valid
        } catch {
            validationState = .invalid
            errorMessage = error.localizedDescription
        }
        
        isChangingMode = false
    }
    
    /// Check if mode change is allowed
    func canChangeTo(_ mode: TradingMode) -> Bool {
        switch mode {
        case .demo, .paper:
            return true
        case .live:
            return hasValidAPIKeys()
        }
    }
    
    /// Get validation requirements for a mode
    func requirementsFor(_ mode: TradingMode) -> [ValidationRequirement] {
        switch mode {
        case .demo, .paper:
            return []
        case .live:
            return [
                ValidationRequirement(
                    id: "api-keys",
                    title: "Exchange API Keys",
                    description: "Valid API keys are required for live trading",
                    isMet: hasValidAPIKeys()
                )
            ]
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Listen to SettingsRepository changes
        settingsRepository.$tradingMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMode in
                if self?.currentMode != newMode {
                    self?.currentMode = newMode
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialState() {
        currentMode = settingsRepository.tradingMode
    }
    
    private func validateModeChange(to mode: TradingMode) async throws {
        switch mode {
        case .demo, .paper:
            // Always allowed
            break
            
        case .live:
            // Require API keys
            guard hasValidAPIKeys() else {
                throw TradingModeError.missingAPIKeys
            }
        }
    }
    
    private func applyModeChange(to mode: TradingMode) async {
        // Update SettingsRepository - this will propagate to all observers
        settingsRepository.tradingMode = mode
        currentMode = mode
    }
    
    private func hasValidAPIKeys() -> Bool {
        // Check if we have keys for at least one exchange
        return exchangeKeysViewModel.hasKeys(for: .binance) || exchangeKeysViewModel.hasKeys(for: .kraken)
    }
}

// MARK: - Supporting Types

enum ValidationState {
    case valid
    case invalid
    case checking
}

struct ValidationRequirement: Identifiable {
    let id: String
    let title: String
    let description: String
    let isMet: Bool
}

enum TradingModeError: LocalizedError {
    case missingAPIKeys
    case invalidConfiguration
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKeys:
            return "API keys are required for live trading. Please add them in Settings > Exchange Keys."
        case .invalidConfiguration:
            return "Trading configuration is invalid. Please check your settings."
        case .networkError:
            return "Network error occurred while validating trading mode."
        }
    }
}