import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject, @unchecked Sendable {
    @Published var liveMarketData: Bool = true            // WS on/off
    @Published var aiDebug: Bool = false                  // AI debug logs and toasts
    @Published var demoMode: Bool = false                 // governs AI prediction source
    @Published var verboseAILogs: Bool = false           // console logs for development
    @Published var pnlDemoMode: Bool = false             // governs PnL simulator only
    
    static let shared = AppSettings()
    
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        liveMarketData = defaults.bool(forKey: "AppSettings.liveMarketData") 
        aiDebug = defaults.bool(forKey: "AppSettings.aiDebug")
        demoMode = defaults.bool(forKey: "AppSettings.demoMode") 
        verboseAILogs = defaults.bool(forKey: "AppSettings.verboseAILogs")
        pnlDemoMode = defaults.bool(forKey: "AppSettings.pnlDemoMode")
        
        // Default to true for liveMarketData on first launch
        if defaults.object(forKey: "AppSettings.liveMarketData") == nil {
            liveMarketData = true
        }
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(liveMarketData, forKey: "AppSettings.liveMarketData")
        defaults.set(aiDebug, forKey: "AppSettings.aiDebug")
        defaults.set(demoMode, forKey: "AppSettings.demoMode")
        defaults.set(verboseAILogs, forKey: "AppSettings.verboseAILogs")
        defaults.set(pnlDemoMode, forKey: "AppSettings.pnlDemoMode")
    }
    
    // Computed helpers for business logic
    var isDemoAI: Bool { demoMode }
    var isDemoPnL: Bool { pnlDemoMode }
    var shouldShowAIDebug: Bool { aiDebug || verboseAILogs }
    var shouldLogVerbose: Bool { verboseAILogs }
    
    // Debug print for state changes
    func logStateChange(_ property: String, _ value: Any) {
        if shouldShowAIDebug {
            print("⚙️ AppSettings.\(property) = \(value)")
        }
    }
}

// MARK: - Convenience Publishers
extension AppSettings {
    var demoModePublisher: AnyPublisher<Bool, Never> {
        $demoMode.eraseToAnyPublisher()
    }
    
    var timeframeSwitchPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest($aiDebug, $verboseAILogs)
            .map { $0 || $1 }
            .eraseToAnyPublisher()
    }
}