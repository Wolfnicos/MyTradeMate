import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.mytrademate", category: "App")

@main
struct MyTradeMateApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var aiManager = AIModelManager.shared
    
    init() {
        setupAppearance()
        configureLogging()
    }
    
    var body: some Scene {
        WindowGroup {
            RootTabs()
                .environmentObject(settings)
                .environmentObject(aiManager)
                .preferredColorScheme(settings.darkMode ? .dark : .light)
                .task {
                    await runStartupDiagnostics()
                }
        }
    }
    
    private func setupAppearance() {
        // Global navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    private func configureLogging() {
        // Configure logging subsystems
        logger.info("MyTradeMate starting up...")
        logger.info("Demo mode: \(AppSettings.shared.demoMode)")
        logger.info("Verbose logging: \(AppSettings.shared.verboseAILogs)")
    }
    
    @MainActor
    private func runStartupDiagnostics() async {
        logger.info("Running startup diagnostics...")
        
        // Run audit
        await Audit.runOnStartup()
        
        // Validate AI models
        do {
            try await aiManager.validateModels()
            logger.info("✅ AI models validated successfully")
        } catch {
            logger.error("❌ AI model validation failed: \(error.localizedDescription)")
        }
        
        // Check demo/live isolation
        if settings.demoMode {
            logger.info("🎭 Running in DEMO mode - no real trades")
        }
        if settings.pnlDemoMode {
            logger.info("📊 PnL in DEMO mode - synthetic equity curve")
        }
        
        logger.info("Startup diagnostics complete")
    }
}