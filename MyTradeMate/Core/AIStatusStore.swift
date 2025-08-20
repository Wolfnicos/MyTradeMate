import Foundation
import SwiftUI
import Combine

/// Single source of truth for AI system status
/// Manages AI state, coordinates with prediction engines, and provides telemetry
@MainActor
final class AIStatusStore: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AIStatusStore()
    
    // MARK: - Published Properties
    
    /// Current AI system status - the single source of truth
    @Published private(set) var status: AIStatus = .paused()
    
    /// Whether AI system is available
    @Published private(set) var isAvailable: Bool = true
    
    // MARK: - Dependencies
    
    private let signalManager: SignalManager
    private let marketDataManager: MarketDataManager
    private var refreshTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        self.signalManager = SignalManager.shared
        self.marketDataManager = MarketDataManager.shared
        
        setupBindings()
        setupAutoRefresh()
        loadInitialState()
    }
    
    // MARK: - Public Interface
    
    /// Refresh AI status for given symbol and timeframe
    func refresh(for symbol: String = "BTC", timeframe: Timeframe = .m5) async {
        // Cancel any existing refresh task
        refreshTask?.cancel()
        
        // Start new refresh task
        refreshTask = Task { @MainActor in
            await performRefresh(symbol: symbol, timeframe: timeframe)
        }
        
        await refreshTask?.value
    }
    
    /// Force retry after error
    func retry() async {
        guard case .error = status.state else { return }
        
        // Log retry event
        logTelemetryEvent("ai_refresh_retry_started")
        
        // Use last known parameters or defaults
        await refresh()
    }
    
    /// Pause AI system
    func pause() {
        refreshTask?.cancel()
        status = .paused(lastUpdate: status.lastUpdate)
        
        logTelemetryEvent("ai_paused")
    }
    
    /// Resume AI system
    func resume() async {
        guard case .paused = status.state else { return }
        
        logTelemetryEvent("ai_resumed")
        await refresh()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Listen to SignalManager changes for confidence updates
        signalManager.$confidence
            .receive(on: DispatchQueue.main)
            .sink { [weak self] confidence in
                self?.updateConfidenceIfRunning(confidence)
            }
            .store(in: &cancellables)
    }
    
    private func setupAutoRefresh() {
        // Auto-refresh every 30 seconds when running
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self,
                          case .running = self.status.state else { return }
                    
                    await self.refresh()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialState() {
        // Initialize with current SignalManager state
        let confidence = signalManager.confidence
        
        if confidence > 0 {
            status = .running(confidence: confidence, lastUpdate: Date())
        } else {
            status = .paused()
        }
    }
    
    private func performRefresh(symbol: String, timeframe: Timeframe) async {
        let startTime = Date()
        
        // Set updating state
        status = .updating()
        
        // Log start event
        logTelemetryEvent("ai_refresh_started", metadata: [
            "symbol": symbol,
            "timeframe": timeframe.rawValue
        ])
        
        do {
            // Get current market data
            let candles = marketDataManager.candles
            
            // Ensure we have data
            guard !candles.isEmpty else {
                throw AIStatusError.noMarketData
            }
            
            // Trigger AI prediction refresh
            await triggerAIRefresh(candles: candles, timeframe: timeframe)
            
            // Wait for prediction to complete
            try await waitForPredictionCompletion()
            
            // Calculate latency
            let latency = Date().timeIntervalSince(startTime)
            let confidence = signalManager.confidence
            
            // Update to running state
            status = .running(confidence: confidence, lastUpdate: Date())
            
            // Log success event
            logTelemetryEvent("ai_refresh_succeeded", metadata: [
                "latency_ms": Int(latency * 1000),
                "confidence": confidence,
                "symbol": symbol,
                "timeframe": timeframe.rawValue
            ])
            
        } catch {
            let latency = Date().timeIntervalSince(startTime)
            let errorMessage = error.localizedDescription
            
            // Update to error state
            status = .error(errorMessage, lastUpdate: Date())
            
            // Log failure event
            logTelemetryEvent("ai_refresh_failed", metadata: [
                "latency_ms": Int(latency * 1000),
                "error": errorMessage,
                "symbol": symbol,
                "timeframe": timeframe.rawValue
            ])
        }
    }
    
    private func triggerAIRefresh(candles: [Candle], timeframe: Timeframe) async {
        // Use existing SignalManager refresh method
        await signalManager.refreshPrediction(candles: candles, timeframe: timeframe)
    }
    
    private func waitForPredictionCompletion() async throws {
        // Wait up to 5 seconds for prediction to complete
        let timeout = Date().addingTimeInterval(5)
        
        while Date() < timeout {
            // Check if we have a valid signal
            if signalManager.currentSignal != nil && signalManager.confidence > 0 {
                return
            }
            
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        throw AIStatusError.predictionTimeout
    }
    
    private func updateConfidenceIfRunning(_ confidence: Double) {
        guard case .running = status.state else { return }
        
        status = .running(
            confidence: confidence,
            lastUpdate: status.lastUpdate ?? Date()
        )
    }
    
    private func logTelemetryEvent(_ event: String, metadata: [String: Any] = [:]) {
        // Log telemetry event
        var logData = metadata
        logData["event"] = event
        logData["timestamp"] = ISO8601DateFormatter().string(from: Date())
        
        print("📊 AIStatusStore Telemetry: \(event) - \(logData)")
        
        // In a full implementation, this would send to analytics service
        // AnalyticsService.shared.track(event, properties: logData)
    }
}

// MARK: - AI Status Errors

enum AIStatusError: LocalizedError {
    case noMarketData
    case predictionTimeout
    case networkError(Error)
    case engineUnavailable
    
    var errorDescription: String? {
        switch self {
        case .noMarketData:
            return "No market data available"
        case .predictionTimeout:
            return "AI prediction timed out"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .engineUnavailable:
            return "AI engine is unavailable"
        }
    }
}

// MARK: - Extensions for Integration

extension AIStatusStore {
    
    /// Integration point for app lifecycle
    func handleAppDidBecomeActive() async {
        logTelemetryEvent("ai_app_foreground")
        
        // Refresh if we were running before
        if case .running = status.state {
            await refresh()
        }
    }
    
    /// Integration point for timeframe changes
    func handleTimeframeChanged(_ timeframe: Timeframe) async {
        logTelemetryEvent("ai_timeframe_changed", metadata: [
            "timeframe": timeframe.rawValue
        ])
        
        // Only refresh if AI is currently running
        guard case .running = status.state else { return }
        
        await refresh(for: "BTC", timeframe: timeframe)
    }
    
    /// Integration point for strategy changes
    func handleStrategyUpdated() async {
        logTelemetryEvent("ai_strategy_updated")
        
        // Refresh if running to reflect new strategy weights
        guard case .running = status.state else { return }
        
        await refresh()
    }
}