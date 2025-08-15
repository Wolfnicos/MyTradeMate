import CoreML

enum ModelKind: String { 
    case m5 = "BitcoinAI_5m_enhanced"
    case h1 = "BitcoinAI_1h_enhanced" 
    case h4 = "BTC_4H_Model"
}

struct CoreMLInspector {
    static func logModelIO(_ model: MLModel, name: String) {
        let md = model.modelDescription

        print("🔍 MODEL \(name)")
        print("  • Inputs:")
        for (k, v) in md.inputDescriptionsByName.sorted(by: { $0.key < $1.key }) {
            print("    - \(k): \(v.type), shape=\(v.multiArrayConstraint?.shape as? [Int] ?? [])")
        }
        print("  • Outputs:")
        for (k, v) in md.outputDescriptionsByName.sorted(by: { $0.key < $1.key }) {
            print("    - \(k): \(v.type), shape=\(v.multiArrayConstraint?.shape as? [Int] ?? [])")
        }
    }

    /// Returnează cheia de input acceptată de model pentru vectori 1×10.
    static func detectDense10Key(for model: MLModel) -> String? {
        model.modelDescription.inputDescriptionsByName
            .first { _, desc in
                if case .multiArray = desc.type {
                    let shape = (desc.multiArrayConstraint?.shape as? [Int]) ?? []
                    return shape == [10] || shape == [1,10] || shape == [10,1]
                }
                return false
            }?.key
    }
    
    /// Detectează cheia pentru modelul 4H (OHLC)
    static func detectOHLCKeys(for model: MLModel) -> [String] {
        let expectedKeys = ["open", "high", "low", "close"]
        let availableKeys = Set(model.modelDescription.inputDescriptionsByName.keys)
        return expectedKeys.filter { availableKeys.contains($0) }
    }
}

@MainActor
func runModelSanityCheck() {
    print("\n🚀 Starting CoreML Model Sanity Check...")
    
    do {
        // Check 5m model
        if let url = Bundle.main.url(forResource: ModelKind.m5.rawValue, withExtension: "mlmodel") ??
                     Bundle.main.url(forResource: ModelKind.m5.rawValue, withExtension: "mlmodelc") {
            let compiledURL = try MLModel.compileModel(at: url)
            let m5 = try MLModel(contentsOf: compiledURL)
            CoreMLInspector.logModelIO(m5, name: ModelKind.m5.rawValue)
            print("   → detected dense key:", CoreMLInspector.detectDense10Key(for: m5) ?? "nil")
        } else {
            print("❌ \(ModelKind.m5.rawValue): File not found in bundle")
        }

        // Check 1h model
        if let url = Bundle.main.url(forResource: ModelKind.h1.rawValue, withExtension: "mlmodel") ??
                     Bundle.main.url(forResource: ModelKind.h1.rawValue, withExtension: "mlmodelc") {
            let compiledURL = try MLModel.compileModel(at: url)
            let h1 = try MLModel(contentsOf: compiledURL)
            CoreMLInspector.logModelIO(h1, name: ModelKind.h1.rawValue)
            print("   → detected dense key:", CoreMLInspector.detectDense10Key(for: h1) ?? "nil")
        } else {
            print("❌ \(ModelKind.h1.rawValue): File not found in bundle")
        }

        // Check 4h model
        if let url = Bundle.main.url(forResource: ModelKind.h4.rawValue, withExtension: "mlmodel") ??
                     Bundle.main.url(forResource: ModelKind.h4.rawValue, withExtension: "mlmodelc") {
            let compiledURL = try MLModel.compileModel(at: url)
            let h4 = try MLModel(contentsOf: compiledURL)
            CoreMLInspector.logModelIO(h4, name: ModelKind.h4.rawValue)
            print("   → detected OHLC keys:", CoreMLInspector.detectOHLCKeys(for: h4))
        } else {
            print("❌ \(ModelKind.h4.rawValue): File not found in bundle")
        }
        
    } catch {
        print("❌ Model load error:", error.localizedDescription)
    }
    
    print("✅ CoreML Model Sanity Check Complete\n")
}