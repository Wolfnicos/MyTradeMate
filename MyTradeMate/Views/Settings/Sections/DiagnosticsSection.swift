import SwiftUI

struct DiagnosticsSection: View {
    var body: some View {
        Section {
            Button("Run CoreML Sanity Check") {
                Task {
                    await runCorMLSanityCheck()
                }
            }
            
            Button("Dump Last Feature Vector") {
                dumpLastFeatureVector()
            }
            
            Button("Clear Cache") {
                clearCache()
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
                let inputs = model.modelDescription.inputDescriptionsByName
                let outputs = model.modelDescription.outputDescriptionsByName
                
                Log.ai.info("📊 Model: \(kind.modelName)")
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