import Foundation

// MARK: - Structured Logging Helper
enum Log {
    static func ai(_ s: String) { 
        if AppSettings.shared.verboseAILogs { 
            print("[AI] " + s) 
        } 
    }
    
    static func ws(_ s: String) { 
        print("[WS] " + s) 
    }
    
    static func pnl(_ s: String) { 
        if AppSettings.shared.verboseAILogs { 
            print("[PnL] " + s) 
        } 
    }
}
