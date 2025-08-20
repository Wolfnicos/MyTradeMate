import Foundation
import SwiftUI
import Combine

/// Single source of truth for timeframe management and data loading
/// Handles timeframe changes, cancels old tasks, and provides loading states
@MainActor
final class TimeframeStore: ObservableObject {
    
    // MARK: - Singleton
    static let shared = TimeframeStore()
    
    // MARK: - Published Properties
    
    /// Current selected timeframe - the single source of truth
    @Published private(set) var selectedTimeframe: Timeframe = .m5
    
    /// Loading state for UI feedback
    @Published private(set) var isLoading: Bool = false
    
    /// Error state for failed loads
    @Published private(set) var loadingError: String?
    
    /// Last successful load timestamp
    @Published private(set) var lastUpdated: Date?
    
    // MARK: - Dependencies
    
    private let marketDataManager: MarketDataManager
    private let signalManager: SignalManager
    private var currentLoadTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        // Get shared instances
        self.marketDataManager = MarketDataManager.shared
        self.signalManager = SignalManager.shared
        
        loadInitialTimeframe()
        setupAutoRefresh()
    }
    
    // MARK: - Public Interface
    
    /// Change timeframe with loading state management
    func changeTimeframe(to newTimeframe: Timeframe) async {
        guard newTimeframe != selectedTimeframe else { return }
        
        // Cancel any existing load task
        currentLoadTask?.cancel()
        
        // Update timeframe immediately for UI responsiveness
        selectedTimeframe = newTimeframe
        
        // Start loading with 200ms delay guarantee
        await performTimeframeChange()
    }
    
    /// Force refresh current timeframe data
    func refreshCurrentTimeframe() async {
        await performTimeframeChange()
    }
    
    /// Get loading state for UI
    var isLoadingData: Bool {
        return isLoading
    }
    
    // MARK: - Private Methods
    
    private func loadInitialTimeframe() {
        // Set initial timeframe from saved preferences or default
        selectedTimeframe = UserDefaults.standard.string(forKey: "selectedTimeframe")
            .flatMap(Timeframe.init(rawValue:)) ?? .m5
    }
    
    private func setupAutoRefresh() {
        // Auto-refresh every 30 seconds for selected timeframe
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self, !self.isLoading else { return }
                    await self.refreshCurrentTimeframe()
                }
            }
            .store(in: &cancellables)
    }
    
    private func performTimeframeChange() async {
        // Set loading state immediately (within 200ms requirement)
        isLoading = true
        loadingError = nil
        
        // Create new load task
        currentLoadTask = Task { @MainActor in
            do {
                try await loadDataForTimeframe()
                await triggerAIRecompute()
                
                // Success state
                lastUpdated = Date()
                loadingError = nil
                
                // Haptic feedback for success
                await provideLightHapticFeedback()
                
            } catch {
                // Error handling
                loadingError = error.localizedDescription
                await showErrorToast("Could not fetch data, retrying…")
            }
            
            isLoading = false
        }
        
        await currentLoadTask?.value
    }
    
    private func loadDataForTimeframe() async throws {
        // Load market data for selected timeframe
        try await marketDataManager.loadMarketData(for: selectedTimeframe)
        
        // Persist timeframe selection
        UserDefaults.standard.set(selectedTimeframe.rawValue, forKey: "selectedTimeframe")
    }
    
    private func triggerAIRecompute() async {
        // Trigger AI signal recomputation
        let candles = marketDataManager.candles
        await signalManager.refreshPrediction(candles: candles, timeframe: selectedTimeframe)
    }
    
    private func provideLightHapticFeedback() async {
        // Light haptic feedback on successful load
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func showErrorToast(_ message: String) async {
        // Show error toast using the app's toast system
        // For now, we'll log the error. In a full implementation,
        // this would integrate with ToastManager from our design system
        print("⚠️ TimeframeStore Error: \(message)")
        
        // TODO: Integrate with global ToastManager when available
        // ToastManager.shared?.show(message, type: .error, duration: 3.0)
    }
}

// MARK: - Extensions for Data Access

extension TimeframeStore {
    
    /// Current candles for the selected timeframe
    var currentCandles: [Candle] {
        return marketDataManager.candles
    }
    
    /// Current price from market data
    var currentPrice: Double {
        return marketDataManager.price
    }
    
    /// Price change percentage
    var priceChangePercent: Double {
        return marketDataManager.priceChangePercent
    }
    
    /// Formatted price change string
    var priceChangeString: String {
        return marketDataManager.priceChangePercentString
    }
}

// MARK: - MarketDataManager Extension

extension MarketDataManager {
    
    /// Load market data for specific timeframe
    func loadMarketData(for timeframe: Timeframe) async throws {
        // This method should be implemented in MarketDataManager
        // For now, we'll call the existing loadMarketData method
        await loadMarketData()
    }
}

// MARK: - SignalManager Extension

extension SignalManager {
    
    /// Async version of refreshPrediction
    func refreshPrediction(candles: [Candle], timeframe: Timeframe) async {
        // Convert sync method to async for consistency
        refreshPrediction(candles: candles, timeframe: timeframe)
    }
}

