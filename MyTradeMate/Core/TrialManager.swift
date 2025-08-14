import Foundation

actor TrialManager {
    static let shared = TrialManager()
    
    private let defaults = UserDefaults.standard
    private let trialDuration: TimeInterval = 3 * 24 * 60 * 60 // 3 days in seconds
    private let trialStartKey = "trialStart"
    
    private init() {
        // Set trial start on first launch
        if defaults.object(forKey: trialStartKey) == nil {
            defaults.set(Date(), forKey: trialStartKey)
        }
    }
    
    var isTrialActive: Bool {
        guard let startDate = defaults.object(forKey: trialStartKey) as? Date else {
            return false
        }
        return Date().timeIntervalSince(startDate) < trialDuration
    }
    
    var daysLeft: Int {
        guard let startDate = defaults.object(forKey: trialStartKey) as? Date else {
            return 0
        }
        
        let timeLeft = trialDuration - Date().timeIntervalSince(startDate)
        return max(0, Int(ceil(timeLeft / (24 * 60 * 60))))
    }
    
    func canUseAutoTrading() -> Bool {
        isTrialActive
    }
    
    func resetTrial() {
        // For testing only
        defaults.removeObject(forKey: trialStartKey)
        defaults.set(Date(), forKey: trialStartKey)
    }
}
