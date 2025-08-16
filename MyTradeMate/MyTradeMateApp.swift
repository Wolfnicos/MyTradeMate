import SwiftUI
import OSLog
import UIKit

private let logger = os.Logger(subsystem: "com.mytrademate", category: "App")

// Using the proper AppSettings from Models/AppSettings.swift

@main
struct MyTradeMateApp: App {
    @StateObject private var settings = AppSettings.shared
    
    init() {
        setupDependencyInjection()
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
        
        // Run audit
        // await Audit.runOnStartup()
        
        // Validate AI models
        do {
            try await AIModelManager.shared.validateModels()
            Log.ai.success("AI models validated successfully")
            
            // Print model info at startup
            for (kind, model) in AIModelManager.shared.models {
                let inputs = model.modelDescription.inputDescriptionsByName
                let outputs = model.modelDescription.outputDescriptionsByName
                
                Log.ai.info("📊 Model: \(kind.modelName)")
                for (key, desc) in inputs {
                    let shape = desc.multiArrayConstraint?.shape ?? []
                    Log.ai.debug("  Input: \(key) → \(shape)")
                }
                for (key, desc) in outputs {
                    let shape = desc.multiArrayConstraint?.shape ?? []
                    Log.ai.debug("  Output: \(key) → \(shape)")
                }
            }
        } catch {
            Log.error(error, context: "AI model validation", category: .ai)
        }
        
        // Check demo/live isolation
        Log.verbose("Demo mode: \(settings.demoMode ? "ENABLED" : "DISABLED")", category: .app)
        Log.verbose("PnL demo mode: \(settings.isDemoPnL ? "ENABLED" : "DISABLED")", category: .pnl)
        
        Log.app.info("Startup diagnostics complete")
    }
}