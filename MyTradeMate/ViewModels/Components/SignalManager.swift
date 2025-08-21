import Foundation
import Combine
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "SignalManager")



// MARK: - Signal Manager
@MainActor
final class SignalManager: ObservableObject {
    // MARK: - Shared Instance
    static let shared = SignalManager()
    
    // MARK: - Dependencies
    private let aiModelManager = AIModelManager.shared
    private let strategyManager = StrategyManager.shared
    private let errorManager = ErrorManager.shared
    private let metaSignalEngine = MetaSignalEngine.shared
    private let signalFusionEngine = SignalFusionEngine.shared // ✅ ENABLED: SignalFusionEngine integration
    
    // MARK: - Published Properties
    @Published var currentSignal: SignalInfo?
    @Published var confidence: Double = 0.0
    @Published var isRefreshing = false
    
    // ✅ ADD: Final signal from SignalFusionEngine as single source of truth
    @Published var finalSignal: FinalDecision?
    
    // MARK: - Private Properties
    private var lastPredictionTime: Date = .distantPast
    private var lastThrottleLog: Date = .distantPast
    private let predictionThrottleInterval: TimeInterval = 0.5
    
    // ✅ ADD: Circuit Breaker for AI Prediction Failures
    private var consecutiveFailures: Int = 0
    private var circuitBreakerOpenUntil: Date = .distantPast
    private let maxFailuresBeforeOpen: Int = 3
    private let baseBackoffDelay: TimeInterval = 5.0 // Start at 5 seconds
    private let maxBackoffDelay: TimeInterval = 120.0 // Cap at 2 minutes
    
    // MARK: - Initialization
    init() {
        // Initialize with default values
    }
    
    // MARK: - Public Methods
    func refreshPrediction(candles: [Candle], timeframe: Timeframe) {
        guard !isRefreshing else { return }
        
        Task {
            await refreshPredictionAsync(candles: candles, timeframe: timeframe)
        }
    }
    
    func generateDemoSignal() -> SignalInfo {
        let signals = ["BUY", "SELL", "HOLD"]
        let direction = signals.randomElement() ?? "HOLD"
        let confidence = Double.random(in: 0.5...0.95)
        
        let reasons = [
            "BUY": "Strong bullish momentum detected",
            "SELL": "Bearish reversal pattern identified",
            "HOLD": "Market consolidating, wait for breakout"
        ]
        
        return SignalInfo(
            direction: direction,
            confidence: confidence,
            reason: reasons[direction] ?? "Demo signal"
        )
    }
    
    // MARK: - Private Methods
    private func refreshPredictionAsync(candles: [Candle], timeframe: Timeframe) async {
        // Throttle predictions
        let timeSinceLastPrediction = Date().timeIntervalSince(lastPredictionTime)
        guard timeSinceLastPrediction >= predictionThrottleInterval else {
            // Only log throttling when verbose logging is enabled and at most once per second
            let now = Date()
            if AppSettings.shared.verboseAILogs && now.timeIntervalSince(lastThrottleLog) >= 1.0 {
                Log.ai.info("Throttling prediction, last was \(String(format: "%.1f", timeSinceLastPrediction))s ago")
                lastThrottleLog = now
            }
            return
        }
        
        await MainActor.run {
            isRefreshing = true
        }
        
        defer {
            Task { @MainActor in
                isRefreshing = false
            }
        }
        
        lastPredictionTime = Date()
        
        guard candles.count >= 50 else {
            logger.warning("Insufficient candles for prediction: \(candles.count)")
            return
        }
        
        let verboseLogging = AppSettings.shared.verboseAILogs
        
        if AppSettings.shared.demoMode {
            // Demo mode - generate synthetic signal
            let demoSignal = generateDemoSignal()
            await MainActor.run {
                self.currentSignal = demoSignal
                self.confidence = demoSignal.confidence
            }
            
            if verboseLogging {
                logger.info("Demo signal: \(demoSignal.direction) @ \(String(format: "%.1f%%", demoSignal.confidence * 100))")
            }
        } else {
            // Live mode - use AI and strategy signals
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // ✅ ADD: Get CoreML prediction with retry logic
            let coreMLSignal = await predictWithRetry(
                timeframe: timeframe,
                candles: candles,
                maxRetries: 3
            )
            
            // ✅ FIX: Get individual strategy signals for Direct Fusion
            let individualStrategySignals = await strategyManager.generateIndividualSignals(from: candles)
            
            // ✅ FIX: Use direct strategy signals for proper fusion
            let finalSignal = combineSignalsWithDirectFusion(
                coreML: coreMLSignal,
                strategySignals: individualStrategySignals,
                candles: candles,
                timeframe: timeframe,
                verboseLogging: verboseLogging
            )
            
            let inferenceTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            if verboseLogging {
                logger.info("Inference time: \(String(format: "%.1f", inferenceTime))ms")
                logger.info("Final signal: \(finalSignal.direction) @ \(String(format: "%.1f%%", finalSignal.confidence * 100))")
            }
            
            await MainActor.run {
                self.currentSignal = finalSignal
                self.confidence = finalSignal.confidence
            }
        }
    }
    
    // MARK: - ✅ ENHANCED: Direct Strategy Signal Fusion
    
    private func combineSignalsWithDirectFusion(
        coreML: PredictionResult?,
        strategySignals: [StrategySignal],
        candles: [Candle],
        timeframe: Timeframe,
        verboseLogging: Bool
    ) -> SignalInfo {
        
        // ✅ DIRECT FUSION: Use real individual strategy signals
        let fusionResult = signalFusionEngine.fuseSignals(
            aiSignal: coreML,
            strategySignals: strategySignals,
            candles: candles,
            timeframe: timeframe
        )
        
        // ✅ UPDATE: Store final decision for dashboard binding
        finalSignal = fusionResult
        
        // ✅ ENHANCED VERBOSE LOGGING: Show fusion breakdown with individual votes
        if verboseLogging {
            logger.info("🔄 SignalFusionEngine Direct Fusion Result:")
            logger.info("   Final Action: \(fusionResult.action.rawValue.uppercased())")
            logger.info("   Final Confidence: \(String(format: "%.1f%%", fusionResult.confidence * 100))")
            logger.info("   Total Components: \(fusionResult.components.count)")
            
            // Show AI components
            let aiComponents = fusionResult.components.filter { $0.source.contains("AI") }
            if !aiComponents.isEmpty {
                logger.info("   🧠 AI Components:")
                for component in aiComponents {
                    logger.info("     - \(component.source): \(component.vote.rawValue.uppercased()) @\(String(format: "%.2f", component.score)) (weight: \(String(format: "%.2f", component.weight)))")
                }
            } else {
                logger.info("   ⚡ AI Status: Strategy-Only Mode (no AI signals)")
            }
            
            // Show Strategy components
            let strategyComponents = fusionResult.components.filter { $0.source.contains("Strategy") }
            logger.info("   📊 Strategy Components (\(strategyComponents.count)/15 active):")
            for component in strategyComponents {
                logger.info("     - \(component.source): \(component.vote.rawValue.uppercased()) @\(String(format: "%.2f", component.score)) (weight: \(String(format: "%.2f", component.weight)))")
            }
            
            logger.info("   💡 Rationale: \(fusionResult.rationale)")
        }
        
        // ✅ Convert FinalDecision back to SignalInfo for legacy compatibility
        return SignalInfo(
            direction: fusionResult.action.rawValue.uppercased(),
            confidence: fusionResult.confidence,
            reason: fusionResult.rationale
        )
    }
    
    // MARK: - ✅ ENHANCED: AI Model Prediction with Circuit Breaker
    
    private func predictWithRetry(
        timeframe: Timeframe,
        candles: [Candle],
        maxRetries: Int
    ) async -> PredictionResult? {
        
        // ✅ CHECK: Circuit breaker - skip prediction if circuit is open
        if isCircuitBreakerOpen() {
            let remainingTime = circuitBreakerOpenUntil.timeIntervalSince(Date())
            logger.warning("⚡ Circuit breaker OPEN - AI predictions paused for \(Int(remainingTime))s more")
            
            // Track circuit breaker event
            AnalyticsService.shared.trackAI("ai_circuit_breaker_open", 
                timeframe: timeframe.rawValue, 
                metadata: [
                    "consecutive_failures": self.consecutiveFailures,
                    "remaining_time": Int(remainingTime)
                ])
            
            return nil
        }
        
        for attempt in 1...maxRetries {
            let prediction = await aiModelManager.predictSafely(
                timeframe: timeframe,
                candles: candles,
                mode: .live
            )
            
            if let prediction = prediction {
                // ✅ SUCCESS: Reset circuit breaker on successful prediction
                if consecutiveFailures > 0 {
                    logger.info("✅ AI model recovered after \(self.consecutiveFailures) failures - circuit breaker RESET")
                    resetCircuitBreaker()
                }
                
                if attempt > 1 {
                    logger.info("✅ AI model prediction succeeded on attempt \(attempt)")
                }
                return prediction
            }
            
            if attempt < maxRetries {
                let delay = TimeInterval(attempt) * 0.5 // Exponential backoff: 0.5s, 1s, 1.5s
                logger.warning("⚠️ AI model prediction failed (attempt \(attempt)/\(maxRetries)). Retrying in \(delay)s...")
                
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } else {
                // ✅ FAILURE: All retries failed - update circuit breaker
                recordPredictionFailure(timeframe: timeframe)
                
                logger.error("❌ AI model prediction failed after \(maxRetries) attempts. Consecutive failures: \(self.consecutiveFailures)")
            }
        }
        
        return nil
    }
    
    // MARK: - ✅ ADD: Circuit Breaker Logic
    
    private func isCircuitBreakerOpen() -> Bool {
        return Date() < circuitBreakerOpenUntil
    }
    
    private func recordPredictionFailure(timeframe: Timeframe) {
        consecutiveFailures += 1
        
        if consecutiveFailures >= maxFailuresBeforeOpen {
            openCircuitBreaker(timeframe: timeframe)
        }
    }
    
    private func openCircuitBreaker(timeframe: Timeframe) {
        // ✅ EXPONENTIAL BACKOFF: Calculate backoff delay with cap
        let backoffDelay = min(
            maxBackoffDelay,
            baseBackoffDelay * pow(2.0, Double(consecutiveFailures - maxFailuresBeforeOpen))
        )
        
        circuitBreakerOpenUntil = Date().addingTimeInterval(backoffDelay)
        
        logger.warning("🔴 Circuit breaker OPENED - AI predictions paused for \(Int(backoffDelay))s (failures: \(self.consecutiveFailures))")
        
        // Track circuit breaker opening
        AnalyticsService.shared.trackAI("ai_circuit_breaker_opened", 
            timeframe: timeframe.rawValue, 
            metadata: [
                "consecutive_failures": self.consecutiveFailures,
                "backoff_delay": Int(backoffDelay)
            ])
    }
    
    private func resetCircuitBreaker() {
        consecutiveFailures = 0
        circuitBreakerOpenUntil = .distantPast
        
        // Track circuit breaker reset
        AnalyticsService.shared.trackAI("ai_circuit_breaker_reset")
    }
    
    /// Public getter for circuit breaker status (for Dashboard display)
    var isAIPaused: Bool {
        return isCircuitBreakerOpen()
    }
}

// Using StrategyStore from Models/LegacyStrategy.swift