import Foundation

enum Log {
    static func ai(_ msg: @autoclosure () -> String) {
        guard AppSettings.shared.verboseAILogs else { return }
        print("[AI] \(msg())")
    }
    
    static func ws(_ msg: @autoclosure () -> String) {
        guard AppSettings.shared.verboseAILogs else { return }
        print("[WS] \(msg())")
    }
    
    static func pnl(_ msg: @autoclosure () -> String) {
        guard AppSettings.shared.verboseAILogs else { return }
        print("[PnL] \(msg())")
    }
    
    static func ui(_ msg: @autoclosure () -> String) {
        guard AppSettings.shared.verboseAILogs else { return }
        print("[UI] \(msg())")
    }
}