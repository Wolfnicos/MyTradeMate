import SwiftUI
import OSLog
import UIKit

private let logger = os.Logger(subsystem: "com.mytrademate", category: "App")

// MARK: - AppSettings Implementation (inline due to target issues)
@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private let ud = UserDefaults.standard
    
    // MARK: Keys
    private struct K {
        static let liveMarketData   = "live_market_data"
        static let demoMode         = "demo_mode"
        static let aiDebugMode      = "ai_debug_mode"
        static let verboseAILogs    = "verbose_ai_logs"
        static let confirmTrades    = "confirm_trades"
        static let pnlDemoMode      = "pnl_demo_mode"
        static let paperTrading     = "paper_trading"
        static let haptics          = "haptics_enabled"
        static let darkMode         = "dark_mode"
        static let defaultTimeframe = "default_timeframe"
        static let defaultSymbol    = "default_symbol"
        static let autoTrading      = "auto_trading"
    }
    
    // MARK: Published settings
    @Published public var liveMarketData: Bool {
        didSet { ud.set(liveMarketData, forKey: K.liveMarketData) }
    }
    @Published public var demoMode: Bool {
        didSet { ud.set(demoMode, forKey: K.demoMode) }
    }
    @Published public var aiDebugMode: Bool {
        didSet { ud.set(aiDebugMode, forKey: K.aiDebugMode) }
    }
    @Published public var verboseAILogs: Bool {
        didSet { ud.set(verboseAILogs, forKey: K.verboseAILogs) }
    }
    @Published public var confirmTrades: Bool {
        didSet { ud.set(confirmTrades, forKey: K.confirmTrades) }
    }
    @Published public var pnlDemoMode: Bool {
        didSet { ud.set(pnlDemoMode, forKey: K.pnlDemoMode) }
    }
    @Published public var paperTrading: Bool {
        didSet { ud.set(paperTrading, forKey: K.paperTrading) }
    }
    @Published public var haptics: Bool {
        didSet { ud.set(haptics, forKey: K.haptics) }
    }
    @Published public var darkMode: Bool {
        didSet { ud.set(darkMode, forKey: K.darkMode) }
    }
    @Published public var defaultTimeframe: String {
        didSet { ud.set(defaultTimeframe, forKey: K.defaultTimeframe) }
    }
    @Published public var defaultSymbol: String {
        didSet { ud.set(defaultSymbol, forKey: K.defaultSymbol) }
    }
    @Published public var autoTrading: Bool {
        didSet { ud.set(autoTrading, forKey: K.autoTrading) }
    }
    
    // MARK: Computed helpers
    public var isDemoAI: Bool { demoMode }
    public var isDemoPnL: Bool { pnlDemoMode }
    
    // Legacy compatibility
    public var liveMarketDataEnabled: Bool {
        get { liveMarketData }
        set { liveMarketData = newValue }
    }
    public var hapticsEnabled: Bool {
        get { haptics }
        set { haptics = newValue }
    }
    
    private init() {
        liveMarketData   = ud.object(forKey: K.liveMarketData) as? Bool ?? true
        demoMode         = ud.object(forKey: K.demoMode) as? Bool ?? true
        aiDebugMode      = ud.object(forKey: K.aiDebugMode) as? Bool ?? false
        verboseAILogs    = ud.object(forKey: K.verboseAILogs) as? Bool ?? true
        confirmTrades    = ud.object(forKey: K.confirmTrades) as? Bool ?? true
        pnlDemoMode      = ud.object(forKey: K.pnlDemoMode) as? Bool ?? true
        paperTrading     = ud.object(forKey: K.paperTrading) as? Bool ?? true
        haptics          = ud.object(forKey: K.haptics) as? Bool ?? true
        darkMode         = ud.object(forKey: K.darkMode) as? Bool ?? false
        defaultTimeframe = ud.string(forKey: K.defaultTimeframe) ?? "m5"
        defaultSymbol    = ud.string(forKey: K.defaultSymbol) ?? "BTC/USDT"
        autoTrading      = ud.object(forKey: K.autoTrading) as? Bool ?? false
    }
}

@main
struct MyTradeMateApp: App {
    @StateObject private var settings = AppSettings.shared
    
    init() {
        setupAppearance()
        configureLogging()
    }
    
    var body: some Scene {
        WindowGroup {
            RootTabs()
                .environmentObject(settings)
                .preferredColorScheme(settings.darkMode ? .dark : .light)
                .task {
                    await runStartupDiagnostics()
                }
        }
    }
    
    private func setupAppearance() {
        // Navigation bar appearance
        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.font: UIFont.systemFont(ofSize: 34, weight: .bold)]
        appearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
        
        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    private func configureLogging() {
        // Configure logging subsystems
        logger.info("MyTradeMate starting up...")
        // logger.info("Demo mode: \(AppSettings.shared.demoMode)")
        // logger.info("Verbose logging: \(AppSettings.shared.verboseAILogs)")
    }
    
    @MainActor
    private func runStartupDiagnostics() async {
        logger.info("Running startup diagnostics...")
        
        // Run audit
        // await Audit.runOnStartup()
        
        // Validate AI models
        do {
            try await AIModelManager.shared.validateModels()
            logger.info("✅ AI models validated successfully")
            
            // Print model info at startup
            for (kind, model) in AIModelManager.shared.models {
                let inputs = model.modelDescription.inputDescriptionsByName
                let outputs = model.modelDescription.outputDescriptionsByName
                
                logger.info("📊 Model: \(kind.modelName)")
                for (key, desc) in inputs {
                    let shape = desc.multiArrayConstraint?.shape ?? []
                    logger.info("  Input: \(key) → \(shape)")
                }
                for (key, desc) in outputs {
                    let shape = desc.multiArrayConstraint?.shape ?? []
                    logger.info("  Output: \(key) → \(shape)")
                }
            }
        } catch {
            logger.error("❌ AI model validation failed: \(error.localizedDescription)")
        }
        
        // Check demo/live isolation
        // if settings.demoMode {
        //     logger.info("🎭 Running in DEMO mode - no real trades")
        // }
        // if settings.pnlDemoMode {
        //     logger.info("📊 PnL in DEMO mode - synthetic equity curve")
        // }
        
        logger.info("Startup diagnostics complete")
    }
}