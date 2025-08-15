import CoreML

enum CoreMLInspector {
    static func logBundleModelsIO() {
        let names = ["BitcoinAI_5m_enhanced", "BitcoinAI_1h_enhanced", "BTC_4H_Model"]
        for name in names {
            if let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
                do {
                    let model = try MLModel(contentsOf: url)
                    logModelIO(model, name: name)
                } catch {
                    print("❌ Failed to load \(name).mlmodelc:", error.localizedDescription)
                }
            } else {
                print("❌ \(name).mlmodelc not found in bundle")
            }
        }
    }

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
}