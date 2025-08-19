import SwiftUI
import Combine
import OSLog
import Foundation

struct MyTradeMateApp: App {
    // Core singletons
    @StateObject private var settingsRepository = SettingsRepository.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    // Manager singletons
    @StateObject private var marketDataManager = MarketDataManager.shared
    @StateObject private var signalManager = SignalManager.shared
    @StateObject private var tradingManager = TradingManager.shared
    @StateObject private var strategyManager = StrategyManager.shared
    @StateObject private var regimeDetectionManager = RegimeDetectionManager()
    @StateObject private var riskManager = RiskManager.shared
    @StateObject private var pnlManager = PnLManager.shared
    @StateObject private var toastManager = ToastManager()
    
    // View Models
    @StateObject private var dashboardVM = RefactoredDashboardVM(
        marketDataManager: MarketDataManager.shared,
        signalManager: SignalManager.shared,
        tradingManager: TradingManager.shared
    )
    @StateObject private var strategiesVM = RefactoredStrategiesVM()
    @StateObject private var settingsVM = SettingsVM.shared
    @StateObject private var tradesVM = TradesVM()
    @StateObject private var pnlVM = PnLVM()
    
    init() {
        // Set up DI container
        let container = DIContainer()
        DIContainer.shared = container
        
        // View models are now initialized directly in property declarations
        
        // Register core services
        container.register(SettingsRepository.self, instance: SettingsRepository.shared)
        container.register(ThemeManager.self, instance: ThemeManager.shared)
        container.register(MarketDataManager.self, instance: MarketDataManager.shared)
        container.register(SignalManager.self, instance: SignalManager.shared)
        container.register(StrategyManager.self, instance: StrategyManager.shared)
        container.register(TradingManager.self, instance: TradingManager.shared)
        
        // Configure logging
        Log.settings.info("[APP] MyTradeMate starting up...")
        Log.settings.info("[APP] Trading mode: \(settingsRepository.tradingMode)")
        Log.settings.info("[APP] Verbose logging: \(settingsRepository.verboseLogging)")
        
        setupAppearance()
        
        // Initialize managers
        themeManager.setTheme(settingsRepository.preferredTheme)
        // StrategyManager is initialized automatically in init()
    }

    var body: some Scene {
        WindowGroup {
            RootTabs()
                // Core services
                .environmentObject(settingsRepository)
                .environmentObject(themeManager)
                .environmentObject(navigationCoordinator)
                
                // Managers
                .environmentObject(marketDataManager)
                .environmentObject(signalManager)
                .environmentObject(tradingManager)
                .environmentObject(strategyManager)
                .environmentObject(regimeDetectionManager)
                .environmentObject(riskManager)
                .environmentObject(pnlManager)
                .environmentObject(toastManager)
                
                // View Models
                .environmentObject(dashboardVM)
                .environmentObject(strategiesVM)
                .environmentObject(settingsVM)
                .environmentObject(tradesVM)
                .environmentObject(pnlVM)
                
                // Theme
                .preferredColorScheme(colorScheme)
                .task {
                    // Initialize market data and signals
                    await marketDataManager.loadMarketData()
                    signalManager.refreshPrediction(
                        candles: marketDataManager.candles,
                        timeframe: AppSettings.shared.timeframe
                    )
                    
                    // Log startup info
                    Log.settings.info("[APP] Market data loaded")
                    Log.settings.info("[APP] Active strategies: \(strategyManager.activeStrategies.count)")
                }
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch settingsRepository.preferredTheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    private func setupAppearance() {
        #if os(iOS)
        // Configure iOS-specific appearance
        setupIOSAppearance()
        #endif
    }
    
    #if os(iOS)
    private func setupIOSAppearance() {
        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        navAppearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        
        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.backgroundColor = .clear
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        
        // Configure tab bar item appearances
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemGray
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        // Apply to stacked layout
        tabAppearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        tabAppearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        // Apply to compact layout
        tabAppearance.compactInlineLayoutAppearance.normal.iconColor = .systemGray
        tabAppearance.compactInlineLayoutAppearance.selected.iconColor = .systemBlue
        tabAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = normalAttributes
        tabAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        // Apply appearances
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().isTranslucent = true
    }
    #endif
    
    private func configureLogging() {
        Log.settings.info("[APP] MyTradeMate starting up...")
        Log.settings.info("[APP] Trading mode: \(settingsRepository.tradingMode)")
        Log.settings.info("[APP] Verbose logging: \(settingsRepository.verboseLogging)")
    }
    
    @MainActor
    private func runStartupDiagnostics() async {
        Log.settings.info("[APP] Running startup diagnostics...")
        
        // Check trading mode
        Log.settings.info("[APP] Running in \(settingsRepository.tradingMode.rawValue.uppercased()) mode")
        
        // Log active strategies
        let activeCount = strategyManager.activeStrategies.count
        Log.settings.info("[APP] Active strategies: \(activeCount)")
        
        if settingsRepository.verboseLogging {
            let activeNames = strategyManager.activeStrategies.map { $0.name }.joined(separator: ", ")
            Log.settings.debug("[APP] Active strategies: \(activeNames)")
        }
        
        Log.settings.info("[APP] Startup diagnostics completed")
    }
}
