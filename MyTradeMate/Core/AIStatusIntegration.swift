import Foundation
import SwiftUI
import Combine

/// Integration helper for AI Status Bar across the app
/// Coordinates AI status updates with various app events
@MainActor
final class AIStatusIntegration: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AIStatusIntegration()
    
    // MARK: - Dependencies
    
    private let aiStatusStore = AIStatusStore.shared
    private let timeframeStore = TimeframeStore.shared
    private let settingsRepository = SettingsRepository.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupTimeframeIntegration()
        setupSettingsIntegration()
        setupAppLifecycleIntegration()
    }
    
    // MARK: - Public Interface
    
    /// Initialize AI status when app starts
    func initialize() async {
        await aiStatusStore.refresh()
    }
    
    /// Handle app becoming active
    func handleAppDidBecomeActive() async {
        await aiStatusStore.handleAppDidBecomeActive()
    }
    
    /// Handle app going to background
    func handleAppDidEnterBackground() {
        // Pause AI updates to save battery
        aiStatusStore.pause()
    }
    
    // MARK: - Private Integration Setup
    
    private func setupTimeframeIntegration() {
        // Listen for timeframe changes from TimeframeStore
        timeframeStore.$selectedTimeframe
            .removeDuplicates()
            .dropFirst() // Skip initial value
            .sink { [weak self] timeframe in
                Task { @MainActor [weak self] in
                    // Wait for timeframe data to finish loading
                    await self?.waitForTimeframeLoadComplete()
                    
                    // Then refresh AI status
                    await self?.aiStatusStore.handleTimeframeChanged(timeframe)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupSettingsIntegration() {
        // Listen for strategy changes
        Publishers.CombineLatest(
            settingsRepository.$strategyEnabled,
            settingsRepository.$strategyWeights
        )
        .removeDuplicates { lhs, rhs in
            // Custom equality check for dictionaries
            NSDictionary(dictionary: lhs.0).isEqual(to: rhs.0) &&
            NSDictionary(dictionary: lhs.1).isEqual(to: rhs.1)
        }
        .dropFirst() // Skip initial values
        .debounce(for: .seconds(1), scheduler: DispatchQueue.main) // Debounce rapid changes
        .sink { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.aiStatusStore.handleStrategyUpdated()
            }
        }
        .store(in: &cancellables)
        
        // Listen for trading mode changes (affects AI behavior)
        settingsRepository.$tradingMode
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] tradingMode in
                Task { @MainActor [weak self] in
                    // AI behavior might differ by trading mode
                    await self?.aiStatusStore.refresh()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupAppLifecycleIntegration() {
        // Listen for app lifecycle notifications
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.handleAppDidBecomeActive()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleAppDidEnterBackground()
                }
            }
            .store(in: &cancellables)
    }
    
    private func waitForTimeframeLoadComplete() async {
        // Wait for timeframe loading to complete before refreshing AI
        while timeframeStore.isLoading {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        // Small additional delay to ensure data is fully processed
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
    }
}

// MARK: - SwiftUI Environment Integration

/// Environment key for AI status integration
struct AIStatusIntegrationKey: EnvironmentKey {
    static let defaultValue = AIStatusIntegration.shared
}

extension EnvironmentValues {
    var aiStatusIntegration: AIStatusIntegration {
        get { self[AIStatusIntegrationKey.self] }
        set { self[AIStatusIntegrationKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {
    /// Initialize AI status integration
    func withAIStatusIntegration() -> some View {
        self
            .environment(\.aiStatusIntegration, AIStatusIntegration.shared)
            .onAppear {
                Task {
                    await AIStatusIntegration.shared.initialize()
                }
            }
    }
}