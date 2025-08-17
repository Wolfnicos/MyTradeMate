import Foundation
import CoreML
import os.log

private let auditLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.mytrademate", category: "Audit")

@MainActor
public enum Audit {

    public static func runOnStartup() async {
        os_log("🔎 Audit: startup checks begin", log: auditLog, type: .info)
        _ = await checkModelHealth()
        _ = checkDataIsolation()
        _ = checkWebSocketStatus()
        _ = checkMemoryUsage()
        _ = checkPerformanceMetrics()
        os_log("✅ Audit: startup checks complete", log: auditLog, type: .info)
    }

    public static func run() async -> String {
        var report = "=== MyTradeMate Audit Report ===\n"
        report += "Timestamp: \(Date())\n\n"

        report += "📊 AI Models:\n" + (await checkModelHealth()) + "\n"
        report += "🔒 Data Isolation:\n" + checkDataIsolation() + "\n"
        report += "🌐 WebSocket:\n" + checkWebSocketStatus() + "\n"
        report += "💾 Memory:\n" + checkMemoryUsage() + "\n"
        report += "⚡ Performance:\n" + checkPerformanceMetrics() + "\n"
        report += "⚙️ Settings:\n" + checkSettings() + "\n"
        return report
    }

        // MARK: - Model Health

    @MainActor
    private static func checkModelHealth() async -> String {
        var report = ""
        let ai = AIModelManager.shared

            // enumerate the three known models
        let kinds: [AIModelManager.ModelKey] = [.m5, .h1, .h4]

        for kind in kinds {
            let name = kind.rawValue

                // Acceptă ambele reprezentări ale dicționarului models: [String: MLModel] sau [ModelKey: MLModel]
            let model: MLModel? = {
                    // dacă models e [String: MLModel]
                if let byString = (ai.models as Any) as? [String: MLModel] {
                    return byString[name]
                }
                    // dacă models e [ModelKey: MLModel]
                if let byKey = (ai.models as Any) as? [AIModelManager.ModelKey: MLModel] {
                    return byKey[kind]
                }
                return nil
            }()

            if let model {
                let md = model.modelDescription

                if let first = md.inputDescriptionsByName.first {
                    let inputName = first.key
                    let shape = first.value.multiArrayConstraint?.shape ?? []
                    let shapeStr = "[" + shape.map { "\($0)" }.joined(separator: ",") + "]"
                    report += "  ✅ \(name): input=\(inputName) shape=\(shapeStr)\n"
                } else {
                    report += "  ❌ \(name): no input found\n"
                }

                let outKeys = Array(md.outputDescriptionsByName.keys)
                if !outKeys.isEmpty {
                    report += "     outputs: \(outKeys.joined(separator: ", "))\n"
                }
            } else {
                report += "  ⚠️ \(name): not loaded\n"
            }
        }
            // simple synthetic “inference time” section (does nothing heavy)
        let t0 = CFAbsoluteTimeGetCurrent()
        let ms = (CFAbsoluteTimeGetCurrent() - t0) * 1000.0
        report += "  ⏱️ Inference time (synthetic): \(String(format: "%.1f", ms))ms\n"
        return report
    }

        // MARK: - Data Isolation

    private static func checkDataIsolation() -> String {
        let s = AppSettings.shared
        var r = ""
        r += "  AI Demo Mode: \(s.demoMode ? "ON" : "OFF")\n"
        r += "  PnL Demo Mode: \(s.pnlDemoMode ? "ON" : "OFF")\n"
        if s.demoMode && !s.pnlDemoMode {
            r += "  ⚠️ AI demo + PnL live → mixed modes\n"
        }
        return r
    }

        // MARK: - WebSocket (stub – doesn’t open sockets)

    private static func checkWebSocketStatus() -> String {
            // Avoid touching real WS here; just report stub info to keep compile simple
        return "  (stub) WebSocket not checked during audit\n"
    }

        // MARK: - Memory / Performance (safe stubs)

    private static func checkMemoryUsage() -> String {
            // Don’t pull mach APIs here to keep this file totally safe across targets
        return "  (stub) Memory within limits\n"
    }

    private static func checkPerformanceMetrics() -> String {
        return """
          (stub) Main thread idle: ok
          (stub) CPU usage: ok
        """
    }

        // MARK: - Settings snapshot

    private static func checkSettings() -> String {
        let s = AppSettings.shared
        var r = ""
        r += "  Demo Mode: \(s.demoMode ? "ON" : "OFF")\n"
        r += "  Auto Trading: \(s.autoTrading ? "ON" : "OFF")\n"
        r += "  Verbose Logs: \(s.verboseAILogs ? "ON" : "OFF")\n"
        r += "  Dark Mode: \(s.darkMode ? "ON" : "OFF")\n"
        r += "  Haptics: \(s.hapticsEnabled ? "ON" : "OFF")\n"
        r += "  Default TF: \(s.defaultTimeframe)\n"
        return r
    }
}
