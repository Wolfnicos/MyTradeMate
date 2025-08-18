import SwiftUI
import OSLog
import UIKit
import WidgetKit
import CoreML

private let logger = os.Logger(subsystem: "com.mytrademate", category: "App")

// Using the proper AppSettings from Models/AppSettings.swift

@main
struct MyTradeMateApp: App {
    @StateObject private var appSettings = AppSettings.shared
    
    init() {
        setupDependencyInjection()
        setupAppearance()
        configureLogging()
        
        // Initialize StrategyManager to ensure strategies are loaded
        _ = StrategyManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            RootTabs()
                .environmentObject(appSettings)
                .preferredColorScheme(appSettings.darkMode ? .dark : .light)
                .task {
                    await runStartupDiagnostics()
                }
        }
    }
    
    private func setupAppearance() {
        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.largeTitleTextAttributes = [.font: UIFont.systemFont(ofSize: 34, weight: .bold)]
        navAppearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        
        // Tab bar appearance - match the navigation bar's translucent blur exactly
        let tabAppearance = UITabBarAppearance()
        
        // Use the same configuration as navigation bar for consistency
        tabAppearance.configureWithDefaultBackground()
        
        // Remove any solid background color to allow full translucency
        tabAppearance.backgroundColor = .clear
        
        // Use the same blur effect as navigation bars
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        
        // Ensure tab bar icons adapt properly to light/dark mode
        // Use system colors that automatically adapt to appearance changes
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        // Apply the same configuration to compact layout (for smaller screens)
        tabAppearance.compactInlineLayoutAppearance.normal.iconColor = UIColor.systemGray
        tabAppearance.compactInlineLayoutAppearance.selected.iconColor = UIColor.systemBlue
        tabAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        tabAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        // Apply to both standard and scroll edge appearances for consistency
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        // Ensure the tab bar is translucent like navigation bar
        UITabBar.appearance().isTranslucent = true
    }
    
    private func setupDependencyInjection() {
        // Initialize services as needed
        Log.app.info("App services initialized")
    }
    
    private func configureLogging() {
        // Configure logging subsystems
        Log.app.info("MyTradeMate starting up...")
        Log.verbose("Demo mode: \(AppSettings.shared.demoMode)", category: .app)
        Log.verbose("Verbose logging: \(AppSettings.shared.verboseAILogs)", category: .app)
    }
    
    @MainActor
    private func runStartupDiagnostics() async {
        Log.app.info("Running startup diagnostics...")
        
        // Tab icons are configured to work in both light and dark modes
        // via the setupAppearance() method and ThemeManager.updateTabBarAppearance()
        Log.app.info("Tab icons configured for light/dark mode support")
        
        // Run audit
        // await Audit.runOnStartup()
        
        // Validate AI models
        do {
            try await AIModelManager.shared.validateModels()
            Log.ai.success("AI models validated successfully")
            
            // Print model info at startup
            // Print model info at startup
            for (name, mlModel) in AIModelManager.shared.models {
                let inputs  = mlModel.modelDescription.inputDescriptionsByName
                let outputs = mlModel.modelDescription.outputDescriptionsByName

                Log.ai.info("📊 Model: \(name)")
                for (key, desc) in inputs {
                    let shape = desc.multiArrayConstraint?.shape ?? []
                    Log.ai.debug("🐛   Input: \(key) → \(shape)")
                }
                for (key, desc) in outputs {
                    let shape = desc.multiArrayConstraint?.shape ?? []
                    Log.ai.debug("🐛   Output: \(key) → \(shape)")
                }
            }
        } catch {
            Log.error(error, context: "AI model validation", category: .ai)
        }
        
        // Check demo/live isolation
        Log.verbose("Demo mode: \(appSettings.demoMode ? "ENABLED" : "DISABLED")", category: .app)
        Log.verbose("PnL demo mode: \(appSettings.isDemoPnL ? "ENABLED" : "DISABLED")", category: .pnl)
        
        Log.app.info("Startup diagnostics complete")
        
        // Initialize widget refresh system
        // TODO: Re-enable when widget integration is complete
        // Task {
        //     await setupWidgetRefresh()
        // }
    }
    
    @MainActor
    private func setupWidgetRefresh() async {
        // Widget refresh system will be initialized when WidgetDataManager is properly integrated
        // TODO: Integrate WidgetDataManager when widget target is properly configured
        Log.app.info("Widget refresh system placeholder - integration pending")
    }
}
