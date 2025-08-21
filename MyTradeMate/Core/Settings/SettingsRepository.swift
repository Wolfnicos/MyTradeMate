import Foundation
import Combine
import SwiftUI

// MARK: - SettingsRepository

/// Unified settings state for live engine binding
public struct SettingsState: Equatable {
    // Trading Routing
    public let routingEnabled: Bool
    public let strategyMinConf: Double
    public let strategyMaxConf: Double
    
    // Multi-Asset Trading
    public let selectedTradingPair: TradingPair
    public let defaultAmountMode: AmountMode
    public let defaultAmountValue: Double
    public let feeBps: Double
    public let slippageBps: Double
    
    // Strategy Settings (All 15 Strategies)
    public let rsiEnabled: Bool
    public let rsiWeight: Double
    public let emaEnabled: Bool
    public let emaWeight: Double
    public let macdEnabled: Bool
    public let macdWeight: Double
    public let meanRevEnabled: Bool
    public let meanRevWeight: Double
    public let atrEnabled: Bool
    public let atrWeight: Double
    
    // ✅ ADD: Missing strategies (10 additional strategies)
    public let bollingerEnabled: Bool
    public let bollingerWeight: Double
    public let ichimokuEnabled: Bool
    public let ichimokuWeight: Double
    public let parabolicSAREnabled: Bool
    public let parabolicSARWeight: Double
    public let williamsREnabled: Bool
    public let williamsRWeight: Double
    public let gridTradingEnabled: Bool
    public let gridTradingWeight: Double
    public let swingTradingEnabled: Bool
    public let swingTradingWeight: Double
    public let scalpingEnabled: Bool
    public let scalpingWeight: Double
    public let volumeEnabled: Bool
    public let volumeWeight: Double
    public let adxEnabled: Bool
    public let adxWeight: Double
    public let stochasticEnabled: Bool
    public let stochasticWeight: Double
    
    // Safety Settings
    public let autoTradingEnabled: Bool
    
    public init(
        routingEnabled: Bool, strategyMinConf: Double, strategyMaxConf: Double,
        selectedTradingPair: TradingPair, defaultAmountMode: AmountMode, defaultAmountValue: Double,
        feeBps: Double, slippageBps: Double,
        rsiEnabled: Bool, rsiWeight: Double, emaEnabled: Bool, emaWeight: Double,
        macdEnabled: Bool, macdWeight: Double, meanRevEnabled: Bool, meanRevWeight: Double,
        atrEnabled: Bool, atrWeight: Double,
        // ✅ ADD: All 15 strategies parameters
        bollingerEnabled: Bool, bollingerWeight: Double,
        ichimokuEnabled: Bool, ichimokuWeight: Double, parabolicSAREnabled: Bool, parabolicSARWeight: Double,
        williamsREnabled: Bool, williamsRWeight: Double, gridTradingEnabled: Bool, gridTradingWeight: Double,
        swingTradingEnabled: Bool, swingTradingWeight: Double, scalpingEnabled: Bool, scalpingWeight: Double,
        volumeEnabled: Bool, volumeWeight: Double, adxEnabled: Bool, adxWeight: Double,
        stochasticEnabled: Bool, stochasticWeight: Double, autoTradingEnabled: Bool
    ) {
        self.routingEnabled = routingEnabled
        self.strategyMinConf = strategyMinConf
        self.strategyMaxConf = strategyMaxConf
        self.selectedTradingPair = selectedTradingPair
        self.defaultAmountMode = defaultAmountMode
        self.defaultAmountValue = defaultAmountValue
        self.feeBps = feeBps
        self.slippageBps = slippageBps
        self.rsiEnabled = rsiEnabled
        self.rsiWeight = rsiWeight
        self.emaEnabled = emaEnabled
        self.emaWeight = emaWeight
        self.macdEnabled = macdEnabled
        self.macdWeight = macdWeight
        self.meanRevEnabled = meanRevEnabled
        self.meanRevWeight = meanRevWeight
        self.atrEnabled = atrEnabled
        self.atrWeight = atrWeight
        
        // ✅ ADD: Assign all new strategy properties
        self.bollingerEnabled = bollingerEnabled
        self.bollingerWeight = bollingerWeight
        self.ichimokuEnabled = ichimokuEnabled
        self.ichimokuWeight = ichimokuWeight
        self.parabolicSAREnabled = parabolicSAREnabled
        self.parabolicSARWeight = parabolicSARWeight
        self.williamsREnabled = williamsREnabled
        self.williamsRWeight = williamsRWeight
        self.gridTradingEnabled = gridTradingEnabled
        self.gridTradingWeight = gridTradingWeight
        self.swingTradingEnabled = swingTradingEnabled
        self.swingTradingWeight = swingTradingWeight
        self.scalpingEnabled = scalpingEnabled
        self.scalpingWeight = scalpingWeight
        self.volumeEnabled = volumeEnabled
        self.volumeWeight = volumeWeight
        self.adxEnabled = adxEnabled
        self.adxWeight = adxWeight
        self.stochasticEnabled = stochasticEnabled
        self.stochasticWeight = stochasticWeight
        
        self.autoTradingEnabled = autoTradingEnabled
    }
    
    // MARK: - Equatable
    public static func == (lhs: SettingsState, rhs: SettingsState) -> Bool {
        return lhs.routingEnabled == rhs.routingEnabled &&
               lhs.strategyMinConf == rhs.strategyMinConf &&
               lhs.strategyMaxConf == rhs.strategyMaxConf &&
               lhs.selectedTradingPair == rhs.selectedTradingPair &&
               lhs.defaultAmountMode == rhs.defaultAmountMode &&
               lhs.defaultAmountValue == rhs.defaultAmountValue &&
               lhs.feeBps == rhs.feeBps &&
               lhs.slippageBps == rhs.slippageBps &&
               lhs.rsiEnabled == rhs.rsiEnabled &&
               lhs.rsiWeight == rhs.rsiWeight &&
               lhs.emaEnabled == rhs.emaEnabled &&
               lhs.emaWeight == rhs.emaWeight &&
               lhs.macdEnabled == rhs.macdEnabled &&
               lhs.macdWeight == rhs.macdWeight &&
               lhs.meanRevEnabled == rhs.meanRevEnabled &&
               lhs.meanRevWeight == rhs.meanRevWeight &&
               lhs.atrEnabled == rhs.atrEnabled &&
               lhs.atrWeight == rhs.atrWeight &&
               // ✅ ADD: All 15 strategies equality checks
               lhs.bollingerEnabled == rhs.bollingerEnabled &&
               lhs.bollingerWeight == rhs.bollingerWeight &&
               lhs.ichimokuEnabled == rhs.ichimokuEnabled &&
               lhs.ichimokuWeight == rhs.ichimokuWeight &&
               lhs.parabolicSAREnabled == rhs.parabolicSAREnabled &&
               lhs.parabolicSARWeight == rhs.parabolicSARWeight &&
               lhs.williamsREnabled == rhs.williamsREnabled &&
               lhs.williamsRWeight == rhs.williamsRWeight &&
               lhs.gridTradingEnabled == rhs.gridTradingEnabled &&
               lhs.gridTradingWeight == rhs.gridTradingWeight &&
               lhs.swingTradingEnabled == rhs.swingTradingEnabled &&
               lhs.swingTradingWeight == rhs.swingTradingWeight &&
               lhs.scalpingEnabled == rhs.scalpingEnabled &&
               lhs.scalpingWeight == rhs.scalpingWeight &&
               lhs.volumeEnabled == rhs.volumeEnabled &&
               lhs.volumeWeight == rhs.volumeWeight &&
               lhs.adxEnabled == rhs.adxEnabled &&
               lhs.adxWeight == rhs.adxWeight &&
               lhs.stochasticEnabled == rhs.stochasticEnabled &&
               lhs.stochasticWeight == rhs.stochasticWeight &&
               lhs.autoTradingEnabled == rhs.autoTradingEnabled
    }
}

/// Centralized settings repository with proper persistence and type safety
@MainActor
public final class SettingsRepository: ObservableObject {
    public static let shared = SettingsRepository()
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private var updateStateTask: Task<Void, Never>?
    private var isBootstrapping = false
    
    // MARK: - Published Properties
    
    // Trading Settings
    @Published public var useStrategyRouting: Bool {
        didSet { 
            save(useStrategyRouting, forKey: .useStrategyRouting)
            deferredUpdateState()
        }
    }
    @Published public var strategyConfidenceMin: Double {
        didSet { 
            save(strategyConfidenceMin, forKey: .strategyConfidenceMin)
            deferredUpdateState()
        }
    }
    @Published public var strategyConfidenceMax: Double {
        didSet { 
            save(strategyConfidenceMax, forKey: .strategyConfidenceMax)
            deferredUpdateState()
        }
    }
    @Published public var tradeThreshold: Double {
        didSet { save(tradeThreshold, forKey: .tradeThreshold) }
    }
    
    // Multi-Asset Trading Settings
    @Published public var selectedTradingPair: TradingPair {
        didSet { 
            saveTradingPair(selectedTradingPair, forKey: .selectedTradingPair)
            deferredUpdateState()
        }
    }
    @Published public var defaultAmountMode: AmountMode {
        didSet { 
            save(defaultAmountMode.rawValue, forKey: .defaultAmountMode)
            deferredUpdateState()
        }
    }
    @Published public var defaultAmountValue: Double {
        didSet { 
            save(defaultAmountValue, forKey: .defaultAmountValue)
            deferredUpdateState()
        }
    }
    @Published public var autoTradingEnabled: Bool {
        didSet { 
            save(autoTradingEnabled, forKey: .autoTradingEnabled)
            deferredUpdateState()
        }
    }
    @Published public var confirmTrades: Bool {
        didSet { save(confirmTrades, forKey: .confirmTrades) }
    }
    @Published public var paperTrading: Bool {
        didSet { save(paperTrading, forKey: .paperTrading) }
    }
    @Published public var hapticsEnabled: Bool {
        didSet { save(hapticsEnabled, forKey: .hapticsEnabled) }
    }
    @Published public var darkMode: Bool {
        didSet { save(darkMode, forKey: .darkMode) }
    }
    
    // Paper Trading Settings
    @Published public var paperStartingCash: Double {
        didSet { save(paperStartingCash, forKey: .paperStartingCash) }
    }
    @Published public var paperFeeBps: Double {
        didSet { save(paperFeeBps, forKey: .paperFeeBps) }
    }
    @Published public var paperSlippageBps: Double {
        didSet { save(paperSlippageBps, forKey: .paperSlippageBps) }
    }
    
    // Risk Management
    @Published public var riskDefaultSL: Double {
        didSet { save(riskDefaultSL, forKey: .riskDefaultSL) }
    }
    @Published public var riskDefaultTP: Double {
        didSet { save(riskDefaultTP, forKey: .riskDefaultTP) }
    }
    
    // Strategy Settings
    @Published public var strategyEnabled: [String: Bool] = [:] {
        didSet { 
            if !isBootstrapping {
                saveStrategySettings()
                deferredUpdateState()
            }
        }
    }
    @Published public var strategyWeights: [String: Double] = [:] {
        didSet { 
            if !isBootstrapping {
                saveStrategySettings()
                deferredUpdateState()
            }
        }
    }
    
    // System Settings
    @Published public var verboseLogging: Bool {
        didSet { if !isBootstrapping { save(verboseLogging, forKey: .verboseLogging) } }
    }
    
    // Trading Mode
    @Published public var tradingMode: TradingMode {
        didSet { if !isBootstrapping { save(tradingMode.rawValue, forKey: .tradingMode) } }
    }
    
    // Theme
    @Published public var preferredTheme: AppTheme {
        didSet { 
            if !isBootstrapping { 
                save(preferredTheme.rawValue, forKey: .preferredTheme)
                notifyThemeChange()
            }
        }
    }
    
    // MetaSignal Settings
    @Published public var metaAiWeight: Double {
        didSet { save(metaAiWeight, forKey: .metaAiWeight) }
    }
    @Published public var metaStrategyWeight: Double {
        didSet { save(metaStrategyWeight, forKey: .metaStrategyWeight) }
    }
    @Published public var metaMinConfidenceM1: Double {
        didSet { save(metaMinConfidenceM1, forKey: .metaMinConfidenceM1) }
    }
    @Published public var metaMinConfidenceM5: Double {
        didSet { save(metaMinConfidenceM5, forKey: .metaMinConfidenceM5) }
    }
    @Published public var metaMinConfidenceM15: Double {
        didSet { save(metaMinConfidenceM15, forKey: .metaMinConfidenceM15) }
    }
    @Published public var metaMinConfidenceH1: Double {
        didSet { save(metaMinConfidenceH1, forKey: .metaMinConfidenceH1) }
    }
    @Published public var metaMinConfidenceH4: Double {
        didSet { save(metaMinConfidenceH4, forKey: .metaMinConfidenceH4) }
    }
    
    // MARK: - Live Engine Binding
    
    /// Single @Published state for live engine subscription
    @Published public private(set) var state: SettingsState = SettingsState(
        routingEnabled: true, strategyMinConf: 0.55, strategyMaxConf: 0.90,
        selectedTradingPair: .btcUsd, defaultAmountMode: .percentOfEquity, defaultAmountValue: 5.0,
        feeBps: 10.0, slippageBps: 5.0,
        rsiEnabled: true, rsiWeight: 1.0, emaEnabled: true, emaWeight: 1.0,
        macdEnabled: true, macdWeight: 1.0, meanRevEnabled: true, meanRevWeight: 1.0,
        atrEnabled: true, atrWeight: 1.0,
        // ✅ ADD: All 15 strategies with default enabled state
        bollingerEnabled: true, bollingerWeight: 1.0,
        ichimokuEnabled: true, ichimokuWeight: 1.0, parabolicSAREnabled: true, parabolicSARWeight: 1.0,
        williamsREnabled: true, williamsRWeight: 1.0, gridTradingEnabled: true, gridTradingWeight: 1.0,
        swingTradingEnabled: true, swingTradingWeight: 1.0, scalpingEnabled: true, scalpingWeight: 1.0,
        volumeEnabled: true, volumeWeight: 1.0, adxEnabled: true, adxWeight: 1.0,
        stochasticEnabled: true, stochasticWeight: 1.0, autoTradingEnabled: false
    )
    
    // MARK: - Settings Keys
    
    private enum SettingsKey: String {
        case useStrategyRouting = "settings.useStrategyRouting"
        case strategyConfidenceMin = "settings.strategyConfidenceMin"
        case strategyConfidenceMax = "settings.strategyConfidenceMax"
        case tradeThreshold = "settings.tradeThreshold"
        case paperStartingCash = "settings.paperStartingCash"
        case paperFeeBps = "settings.paperFeeBps"
        case paperSlippageBps = "settings.paperSlippageBps"
        case riskDefaultSL = "settings.riskDefaultSL"
        case riskDefaultTP = "settings.riskDefaultTP"
        case strategyEnabled = "settings.strategyEnabled"
        case strategyWeights = "settings.strategyWeights"
        case selectedTradingPair = "settings.selectedTradingPair"
        case defaultAmountMode = "settings.defaultAmountMode"
        case defaultAmountValue = "settings.defaultAmountValue"
        case autoTradingEnabled = "settings.autoTradingEnabled"
        case confirmTrades = "settings.confirmTrades"
        case paperTrading = "settings.paperTrading"
        case hapticsEnabled = "settings.hapticsEnabled"
        case darkMode = "settings.darkMode"
        case verboseLogging = "settings.verboseLogging"
        case metaAiWeight = "settings.metaAiWeight"
        case metaStrategyWeight = "settings.metaStrategyWeight"
        case metaMinConfidenceM1 = "settings.metaMinConfidenceM1"
        case metaMinConfidenceM5 = "settings.metaMinConfidenceM5"
        case metaMinConfidenceM15 = "settings.metaMinConfidenceM15"
        case metaMinConfidenceH1 = "settings.metaMinConfidenceH1"
        case metaMinConfidenceH4 = "settings.metaMinConfidenceH4"
        case schemaVersion = "settings.schemaVersion"
        case tradingMode = "settings.tradingMode"
        case preferredTheme = "settings.preferredTheme"
    }
    
    // MARK: - Schema Versioning
    
    private let currentSchemaVersion = 1
    
    // MARK: - Initialization
    
    init() {
        // Initialize all required properties with defaults first
        self.useStrategyRouting = true
        self.strategyConfidenceMin = 0.55
        self.strategyConfidenceMax = 0.90
        self.tradeThreshold = 0.65
        self.paperStartingCash = 10_000.0
        self.paperFeeBps = 10.0
        self.paperSlippageBps = 5.0
        self.riskDefaultSL = 0.02
        self.riskDefaultTP = 0.04
        self.selectedTradingPair = .btcUsd
        self.defaultAmountMode = .percentOfEquity
        self.defaultAmountValue = 5.0
        self.autoTradingEnabled = false
        self.confirmTrades = true
        self.paperTrading = false
        self.hapticsEnabled = true
        self.darkMode = false
        self.verboseLogging = false
        self.tradingMode = .demo
        self.preferredTheme = .system
        self.metaAiWeight = 0.6
        self.metaStrategyWeight = 0.4
        self.metaMinConfidenceM1 = 0.70
        self.metaMinConfidenceM5 = 0.65
        self.metaMinConfidenceM15 = 0.62
        self.metaMinConfidenceH1 = 0.60
        self.metaMinConfidenceH4 = 0.58
        
        // Now set bootstrapping and load actual values
        isBootstrapping = true
        
        // Load all settings with bootstrap guard
        loadAllSettings()
        
        // Initialize the unified state
        updateState()
        
        isBootstrapping = false
        
        Log.settings.info("✅ SettingsRepository initialized")
    }
    
    // MARK: - Settings Loading
    
    private func loadAllSettings() {
        // Load settings with defaults
        self.useStrategyRouting = load(forKey: .useStrategyRouting, defaultValue: true)
        self.strategyConfidenceMin = load(forKey: .strategyConfidenceMin, defaultValue: 0.55)
        self.strategyConfidenceMax = load(forKey: .strategyConfidenceMax, defaultValue: 0.90)
        self.tradeThreshold = load(forKey: .tradeThreshold, defaultValue: 0.65)
        
        self.paperStartingCash = load(forKey: .paperStartingCash, defaultValue: 10_000.0)
        self.paperFeeBps = load(forKey: .paperFeeBps, defaultValue: 10.0)
        self.paperSlippageBps = load(forKey: .paperSlippageBps, defaultValue: 5.0)
        
        self.riskDefaultSL = load(forKey: .riskDefaultSL, defaultValue: 0.02) // 2%
        self.riskDefaultTP = load(forKey: .riskDefaultTP, defaultValue: 0.04) // 4%
        
        // Multi-Asset Trading Settings
        self.selectedTradingPair = loadTradingPair(forKey: .selectedTradingPair, defaultValue: .btcUsd)
        self.defaultAmountMode = AmountMode(rawValue: load(forKey: .defaultAmountMode, defaultValue: "percent_equity")) ?? .percentOfEquity
        self.defaultAmountValue = load(forKey: .defaultAmountValue, defaultValue: 5.0) // 5% of equity
        self.autoTradingEnabled = load(forKey: .autoTradingEnabled, defaultValue: false)
        self.confirmTrades = load(forKey: .confirmTrades, defaultValue: true)
        self.paperTrading = load(forKey: .paperTrading, defaultValue: false)
        self.hapticsEnabled = load(forKey: .hapticsEnabled, defaultValue: true)
        self.darkMode = load(forKey: .darkMode, defaultValue: false)
        
        self.verboseLogging = load(forKey: .verboseLogging, defaultValue: false)
        self.tradingMode = TradingMode(rawValue: load(forKey: .tradingMode, defaultValue: "demo")) ?? .demo
        self.preferredTheme = AppTheme(rawValue: load(forKey: .preferredTheme, defaultValue: "System")) ?? .system
        
        // MetaSignal Settings
        self.metaAiWeight = load(forKey: .metaAiWeight, defaultValue: 0.6)
        self.metaStrategyWeight = load(forKey: .metaStrategyWeight, defaultValue: 0.4)
        self.metaMinConfidenceM1 = load(forKey: .metaMinConfidenceM1, defaultValue: 0.70)
        self.metaMinConfidenceM5 = load(forKey: .metaMinConfidenceM5, defaultValue: 0.65)
        self.metaMinConfidenceM15 = load(forKey: .metaMinConfidenceM15, defaultValue: 0.62)
        self.metaMinConfidenceH1 = load(forKey: .metaMinConfidenceH1, defaultValue: 0.60)
        self.metaMinConfidenceH4 = load(forKey: .metaMinConfidenceH4, defaultValue: 0.58)
        
        // Load strategy settings
        self.strategyEnabled = loadStrategyEnabled()
        self.strategyWeights = loadStrategyWeights()
        
        // Perform migration if needed
        migrateIfNeeded()
    }
    
    // MARK: - Strategy Management
    
    public func updateStrategyEnabled(_ strategyName: String, enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.strategyEnabled[strategyName] = enabled
            Log.settings.debug("📝 Strategy \(strategyName): \(enabled ? "enabled" : "disabled")")
        }
    }
    
    public func updateStrategyWeight(_ strategyName: String, weight: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let clampedWeight = max(0.1, min(2.0, weight))
            self.strategyWeights[strategyName] = clampedWeight
            Log.settings.debug("⚖️ Strategy \(strategyName) weight: \(clampedWeight)")
        }
    }
    
    public func isStrategyEnabled(_ strategyName: String) -> Bool {
        return strategyEnabled[strategyName] ?? true // Default to enabled
    }
    
    public func getStrategyWeight(_ strategyName: String) -> Double {
        return strategyWeights[strategyName] ?? 1.0 // Default weight
    }
    
    // MARK: - MetaSignal Settings
    
    public func getMetaSignalSettings() -> MetaSignalEngine.MetaSignalSettings {
        let thresholds: [Timeframe: Double] = [
            .m1: metaMinConfidenceM1,
            .m5: metaMinConfidenceM5,
            .m15: metaMinConfidenceM15,
            .h1: metaMinConfidenceH1,
            .h4: metaMinConfidenceH4
        ]
        
        return MetaSignalEngine.MetaSignalSettings(
            aiWeight: metaAiWeight,
            strategyWeight: metaStrategyWeight,
            cryptoIndicatorsWeight: 0.25,  // New parameter for crypto indicators
            minConfidenceThresholds: thresholds,
            useWhaleTracking: true,  // Enable whale tracking
            useSentimentAnalysis: true,  // Enable sentiment analysis
            useOnChainMetrics: true,  // Enable on-chain metrics
            adaptiveWeighting: true,  // Enable adaptive weights
            riskProfile: .balanced  // Balanced risk profile
        )
    }
    
    // MARK: - Validation
    
    public func validateSettings() -> [String] {
        var warnings: [String] = []
        
        // Validate confidence ranges
        if strategyConfidenceMin >= strategyConfidenceMax {
            warnings.append("Strategy confidence min (\(strategyConfidenceMin)) must be less than max (\(strategyConfidenceMax))")
        }
        
        if strategyConfidenceMin < 0.5 || strategyConfidenceMax > 1.0 {
            warnings.append("Strategy confidence values must be between 0.5 and 1.0")
        }
        
        // Validate trade threshold
        if tradeThreshold < 0.5 || tradeThreshold > 1.0 {
            warnings.append("Trade threshold must be between 0.5 and 1.0")
        }
        
        // Validate paper trading settings
        if paperStartingCash < 1000 {
            warnings.append("Paper trading starting cash should be at least $1,000")
        }
        
        if paperFeeBps < 0 || paperFeeBps > 100 {
            warnings.append("Paper trading fees should be between 0-100 basis points (0-1%)")
        }
        
        // Validate risk settings
        if riskDefaultSL <= 0 || riskDefaultSL > 0.1 {
            warnings.append("Default stop loss should be between 0.1% and 10%")
        }
        
        if riskDefaultTP <= riskDefaultSL {
            warnings.append("Default take profit should be greater than stop loss")
        }
        
        return warnings
    }
    
    // MARK: - Reset Functions
    
    public func resetToDefaults() {
        Log.settings.info("🔄 Resetting all settings to defaults")
        
        useStrategyRouting = true
        strategyConfidenceMin = 0.55
        strategyConfidenceMax = 0.90
        tradeThreshold = 0.65
        
        paperStartingCash = 10_000.0
        paperFeeBps = 10.0
        paperSlippageBps = 5.0
        
        riskDefaultSL = 0.02
        riskDefaultTP = 0.04
        
        verboseLogging = false
        tradingMode = .live
        preferredTheme = .system
        
        // Reset strategy settings
        strategyEnabled.removeAll()
        strategyWeights.removeAll()
        
        Log.settings.info("✅ Settings reset complete")
    }
    
    public func resetPaperAccount() async {
        Log.settings.info("🔄 Resetting paper account settings")
        
        paperStartingCash = 10_000.0
        // TODO: Re-enable when TradingEngine is fixed
        // await TradingEngine.shared.resetPaperAccount()
        
        Log.settings.info("✅ Paper account reset complete")
    }
    
    // MARK: - State Updates
    
    /// Safely defer state updates to avoid publishing warnings
    private func deferredUpdateState() {
        DispatchQueue.main.async { [weak self] in
            self?.updateState()
        }
    }
    
    /// Update theme through ThemeManager when preferredTheme changes
    private func notifyThemeChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            ThemeManager.shared.setTheme(self.preferredTheme)
        }
    }
    
    /// Update the unified state whenever any setting changes
    private func updateState() {
        // Cancel any pending update task
        updateStateTask?.cancel()
        
        // Create a new debounced update task
        updateStateTask = Task { @MainActor in
            // Wait a short delay to debounce rapid updates
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            // Check if task was cancelled during the delay
            if Task.isCancelled { return }
            
            state = SettingsState(
                routingEnabled: useStrategyRouting,
                strategyMinConf: strategyConfidenceMin,
                strategyMaxConf: strategyConfidenceMax,
                selectedTradingPair: selectedTradingPair,
                defaultAmountMode: defaultAmountMode,
                defaultAmountValue: defaultAmountValue,
                feeBps: paperFeeBps,
                slippageBps: paperSlippageBps,
                rsiEnabled: isStrategyEnabled("RSI"),
                rsiWeight: getStrategyWeight("RSI"),
                emaEnabled: isStrategyEnabled("EMA Crossover"),
                emaWeight: getStrategyWeight("EMA Crossover"),
                macdEnabled: isStrategyEnabled("MACD"),
                macdWeight: getStrategyWeight("MACD"),
                meanRevEnabled: isStrategyEnabled("Mean Reversion"),
                meanRevWeight: getStrategyWeight("Mean Reversion"),
                atrEnabled: isStrategyEnabled("ATR Breakout"),
                atrWeight: getStrategyWeight("ATR Breakout"),
                // ✅ ADD: All 15 strategies with dynamic enabled/weight values
                bollingerEnabled: isStrategyEnabled("Bollinger Bands"),
                bollingerWeight: getStrategyWeight("Bollinger Bands"),
                ichimokuEnabled: isStrategyEnabled("Ichimoku"),
                ichimokuWeight: getStrategyWeight("Ichimoku"),
                parabolicSAREnabled: isStrategyEnabled("Parabolic SAR"),
                parabolicSARWeight: getStrategyWeight("Parabolic SAR"),
                williamsREnabled: isStrategyEnabled("Williams %R"),
                williamsRWeight: getStrategyWeight("Williams %R"),
                gridTradingEnabled: isStrategyEnabled("Grid Trading"),
                gridTradingWeight: getStrategyWeight("Grid Trading"),
                swingTradingEnabled: isStrategyEnabled("Swing Trading"),
                swingTradingWeight: getStrategyWeight("Swing Trading"),
                scalpingEnabled: isStrategyEnabled("Scalping"),
                scalpingWeight: getStrategyWeight("Scalping"),
                volumeEnabled: isStrategyEnabled("Volume Profile"),
                volumeWeight: getStrategyWeight("Volume Profile"),
                adxEnabled: isStrategyEnabled("ADX"),
                adxWeight: getStrategyWeight("ADX"),
                stochasticEnabled: isStrategyEnabled("Stochastic"),
                stochasticWeight: getStrategyWeight("Stochastic"),
                autoTradingEnabled: autoTradingEnabled
            )
            
            Log.settings.debug("[SETTINGS] State updated: routing=\(state.routingEnabled), conf=\(String(format: "%.2f", state.strategyMinConf))-\(String(format: "%.2f", state.strategyMaxConf))")
        }
    }
    
    // MARK: - Private Persistence Methods
    
    private func save<T>(_ value: T, forKey key: SettingsKey) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
        UserDefaults.standard.synchronize()
    }
    
    private func load<T>(forKey key: SettingsKey, defaultValue: T) -> T {
        if UserDefaults.standard.object(forKey: key.rawValue) != nil {
            return UserDefaults.standard.object(forKey: key.rawValue) as? T ?? defaultValue
        }
        return defaultValue
    }
    
    private func saveStrategySettings() {
        if let enabledData = try? JSONEncoder().encode(strategyEnabled) {
            UserDefaults.standard.set(enabledData, forKey: SettingsKey.strategyEnabled.rawValue)
        }
        
        if let weightsData = try? JSONEncoder().encode(strategyWeights) {
            UserDefaults.standard.set(weightsData, forKey: SettingsKey.strategyWeights.rawValue)
        }
        
        UserDefaults.standard.synchronize()
    }
    
    private func loadStrategyEnabled() -> [String: Bool] {
        guard let data = UserDefaults.standard.data(forKey: SettingsKey.strategyEnabled.rawValue),
              let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) else {
            return [:]
        }
        return decoded
    }
    
    private func loadStrategyWeights() -> [String: Double] {
        guard let data = UserDefaults.standard.data(forKey: SettingsKey.strategyWeights.rawValue),
              let decoded = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return [:]
        }
        return decoded
    }
    
    // MARK: - TradingPair Persistence Helpers
    
    private func saveTradingPair(_ pair: TradingPair, forKey key: SettingsKey) {
        let data = [
            "baseSymbol": pair.base.symbol,
            "quoteCurrency": pair.quote.rawValue
        ]
        
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key.rawValue)
        }
    }
    
    private func loadTradingPair(forKey key: SettingsKey, defaultValue: TradingPair) -> TradingPair {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data),
              let baseSymbol = decoded["baseSymbol"],
              let quoteCurrencyRaw = decoded["quoteCurrency"],
              let quoteCurrency = QuoteCurrency(rawValue: quoteCurrencyRaw),
              let asset = Asset.asset(for: baseSymbol) else {
            return defaultValue
        }
        
        return TradingPair(base: asset, quote: quoteCurrency)
    }
    
    // MARK: - Migration
    
    private func migrateIfNeeded() {
        let savedVersion = UserDefaults.standard.integer(forKey: SettingsKey.schemaVersion.rawValue)
        
        if savedVersion < currentSchemaVersion {
            Log.settings.info("🔄 Migrating settings from v\(savedVersion) to v\(currentSchemaVersion)")
            performMigration(from: savedVersion, to: currentSchemaVersion)
            UserDefaults.standard.set(currentSchemaVersion, forKey: SettingsKey.schemaVersion.rawValue)
            Log.settings.info("✅ Settings migration complete")
        }
    }
    
    private func performMigration(from oldVersion: Int, to newVersion: Int) {
        // Add migration logic here as schema evolves
        // For now, this is a no-op since we're at v1
        
        switch oldVersion {
        case 0:
            // Migration from no schema to v1
            // Set default values for any new settings
            break
        default:
            break
        }
    }
    
    // MARK: - Debug/Export
    
    public func exportSettings() -> [String: Any] {
        return [
            "useStrategyRouting": useStrategyRouting,
            "strategyConfidenceMin": strategyConfidenceMin,
            "strategyConfidenceMax": strategyConfidenceMax,
            "tradeThreshold": tradeThreshold,
            "paperStartingCash": paperStartingCash,
            "paperFeeBps": paperFeeBps,
            "paperSlippageBps": paperSlippageBps,
            "riskDefaultSL": riskDefaultSL,
            "riskDefaultTP": riskDefaultTP,
            "strategyEnabled": strategyEnabled,
            "strategyWeights": strategyWeights,
            "verboseLogging": verboseLogging,
            "tradingMode": tradingMode.rawValue,
            "preferredTheme": preferredTheme.rawValue,
            "schemaVersion": currentSchemaVersion
        ]
    }
}

// MARK: - Logging Extension
// Using Log.settings from main Log enum