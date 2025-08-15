import Foundation

@MainActor
final class SettingsVM: ObservableObject {
    static let shared = SettingsVM()
    
    @Published var demoModeAI: Bool = false
    @Published var demoModePnL: Bool = false
    @Published var autoTrade: Bool = false
    @Published var verboseAILogs: Bool = false
    @Published var timeframe: Timeframe = .m5
    
    // Computed properties for compatibility
    var shouldLogVerbose: Bool { verboseAILogs }
    var isDemoAI: Bool { demoModeAI }
    var isDemoPnL: Bool { demoModePnL }
    
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        demoModeAI = defaults.bool(forKey: "AppSettings.demoModeAI")
        demoModePnL = defaults.bool(forKey: "AppSettings.demoModePnL")
        autoTrade = defaults.bool(forKey: "AppSettings.autoTrade")
        verboseAILogs = defaults.bool(forKey: "AppSettings.verboseAILogs")
        if let timeframeString = defaults.string(forKey: "AppSettings.timeframe"),
           let tf = Timeframe(rawValue: timeframeString) {
            timeframe = tf
        }
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(demoModeAI, forKey: "AppSettings.demoModeAI")
        defaults.set(demoModePnL, forKey: "AppSettings.demoModePnL")
        defaults.set(autoTrade, forKey: "AppSettings.autoTrade")
        defaults.set(verboseAILogs, forKey: "AppSettings.verboseAILogs")
        defaults.set(timeframe.rawValue, forKey: "AppSettings.timeframe")
    }
}