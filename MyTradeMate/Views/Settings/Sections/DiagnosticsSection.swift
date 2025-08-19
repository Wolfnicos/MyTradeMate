import SwiftUI
import CoreML

struct DiagnosticsSection: View {
    @EnvironmentObject var settings: SettingsRepository
    
    var body: some View {
        Section("Diagnostics") {
            StandardToggleRow(
                title: "Verbose Logging",
                description: "Enable detailed logging for debugging. May impact performance.",
                isOn: $settings.verboseLogging,
                style: .warning
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Button("Run CoreML Sanity Check") {
                    Task {
                        await runCorMLSanityCheck()
                    }
                }
                Text("Validate AI models and check their input/output configurations. Use for troubleshooting AI issues.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Button("Dump Last Feature Vector") {
                    dumpLastFeatureVector()
                }
                Text("Export the last computed feature vector used for AI predictions. Useful for debugging model inputs.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Button("Clear Cache") {
                    clearCache()
                }
                Text("Clear all cached market data and force fresh data retrieval. Use if experiencing data issues.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func runCorMLSanityCheck() async {
        Log.ai.info("🔍 Running CoreML Sanity Check...")
        let aiManager = AIModelManager.shared
        
        do {
            try await aiManager.validateModels()
            Log.ai.info("✅ CoreML models validated successfully")
            
            for (kind, model) in aiManager.models {
                guard let mlModel = model as? MLModel,
                      let modelKind = kind as? ModelKind else { continue }
                let inputs = mlModel.modelDescription.inputDescriptionsByName
                let outputs = mlModel.modelDescription.outputDescriptionsByName
                
                Log.ai.info("📊 Model: \(modelKind.modelName)")
                for (key, desc) in inputs {
                    let shape = desc.multiArrayConstraint?.shape ?? []
                    Log.ai.info("  Input: \(key) -> \(shape)")
                }
                for (key, desc) in outputs {
                    let shape = desc.multiArrayConstraint?.shape ?? []
                    Log.ai.info("  Output: \(key) -> \(shape)")
                }
            }
        } catch {
            Log.ai.info("❌ CoreML validation failed: \(error)")
        }
    }
    
    private func dumpLastFeatureVector() {
        Log.ai.info("📋 Feature vector dump requested - implement in DashboardVM")
        // This would be implemented to show the last computed feature vector
    }
    
    private func clearCache() {
        Log.ai.info("🧹 Clearing cache...")
        // Clear any cached data
        MarketDataService.shared.candles.removeAll()
        Log.ai.info("✅ Cache cleared")
    }
}