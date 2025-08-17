import Foundation
import CoreML

    /// Manager pentru încărcarea modelelor CoreML și inferență.
    /// - expune: `shared`, `validateModels()`, `predictDense(...)`, `predict4H(...)`
    /// - expune compat: `predictSafely(...)` folosit de DashboardVM vechi
@MainActor
final class AIModelManager {

        // MARK: - Chei interne (numele fișierelor mlmodel)
    enum ModelKey: String, CaseIterable, Hashable {
        case m5 = "BitcoinAI_5m_enhanced"    // input: "dense_input"    → [1, 10]
        case h1 = "BitcoinAI_1h_enhanced"    // input: "dense_4_input"  → [1, 10]
        case h4 = "BTC_4H_Model"             // input explicit (12 features)

        var modelName: String { rawValue }
    }

        // MARK: - Singleton
    static let shared = AIModelManager()
    private init() {}

        // MARK: - Stocare modele
        /// Modelele încărcate, indexate intern după `ModelKey`.
    private(set) var modelsByKey: [ModelKey: MLModel] = [:]

        /// Map public doar pentru citire: `ModelKind` → `MLModel`
    public var models: [ModelKind: MLModel] {
        modelsByKey.reduce(into: [:]) { dict, pair in
            dict[pair.key.asPublicKind] = pair.value
        }
    }

        // MARK: - Încărcare/validare
        /// Încarcă/validează modelele din bundle și loghează shapes pentru debugging.
    @discardableResult
    func validateModels() async throws -> Bool {
        var loaded: [ModelKey: MLModel] = [:]

        for key in ModelKey.allCases {
            if let url = Bundle.main.url(forResource: key.rawValue, withExtension: "mlmodelc")
                ?? Bundle.main.url(forResource: key.rawValue, withExtension: "mlmodel") {

                let compiledURL: URL
                if url.pathExtension == "mlmodel" {
                    compiledURL = try await MLModel.compileModel(at: url)
                } else {
                    compiledURL = url
                }

                let model = try MLModel(contentsOf: compiledURL)
                loaded[key] = model
                Log.ai.info("✅ Loaded model: \(key.rawValue)")
            } else {
                Log.ai.warning("⚠️ Model \(key.rawValue) not found in bundle")
            }
        }

        self.modelsByKey = loaded

        for (key, model) in loaded {
            let inputs  = model.modelDescription.inputDescriptionsByName
            let outputs = model.modelDescription.outputDescriptionsByName

            Log.ai.debug("📊 Model: \(key.rawValue)")
            for (k, d) in inputs {
                let shape = (d.multiArrayConstraint?.shape ?? []).map { $0.intValue }
                Log.ai.debug("🐛   Input: \(k) → \(shape)")
            }
            for (k, d) in outputs {
                let shape = (d.multiArrayConstraint?.shape ?? []).map { $0.intValue }
                Log.ai.debug("🐛   Output: \(k) → \(shape)")
            }
        }

        return !loaded.isEmpty
    }

        // MARK: - Inferență: modele dense (m5 / h1)
    func predictDense(modelName: ModelKey, inputKey: String, features: [Float]) throws -> MLFeatureProvider {
        guard let model = modelsByKey[modelName] else {
            throw NSError(
                domain: "AIModelManager", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Model \(modelName.rawValue) not loaded"]
            )
        }

        let x = normalizeToCount(features, count: 10)
        let arr = try make2DFloatArray(values: x, count: 10)

        let input = try MLDictionaryFeatureProvider(dictionary: [
            inputKey: MLFeatureValue(multiArray: arr)
        ])
        return try model.prediction(from: input)
    }

        // MARK: - Inferență: model 4h (input explicit 12 features)
    func predict4H(explicitInputs: [String: NSNumber]) throws -> MLFeatureProvider {
        guard let model = modelsByKey[.h4] else {
            throw NSError(
                domain: "AIModelManager", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Model \(ModelKey.h4.rawValue) not loaded"]
            )
        }

        var dict: [String: MLFeatureValue] = [:]
        for (k, v) in explicitInputs {
            dict[k] = MLFeatureValue(double: v.doubleValue)
        }
        let input = try MLDictionaryFeatureProvider(dictionary: dict)
        return try model.prediction(from: input)
    }

        // MARK: - Compat: folosit de ViewModel-le vechi
    func predictSafely(kind: ModelKey, denseFeatures: [Float]) -> PredictionResult? {
        guard let inputKey = (kind == .m5) ? "dense_input" : (kind == .h1 ? "dense_4_input" : nil) else {
            return nil
        }

        do {
            let out = try predictDense(modelName: kind, inputKey: inputKey, features: denseFeatures)

            if let idVal = out.featureValue(for: "Identity")?.doubleValue {
                let signal: String = idVal >= 0.5 ? "BUY" : "SELL"
                let confidence = max(0.0, min(1.0, abs(idVal - 0.5) * 2.0))
                return PredictionResult(
                    signal: signal,
                    confidence: confidence,
                    model: kind.asPublicKind,
                    timestamp: Date()
                )
            }

            if let anyDict = out.featureValue(for: "classProbability")?.dictionaryValue {
                var buy = 0.0, sell = 0.0, hold = 0.0
                for (k, v) in anyDict {
                    if let s = k as? String {
                        if s.uppercased() == "BUY"  { buy  = v.doubleValue }
                        if s.uppercased() == "SELL" { sell = v.doubleValue }
                        if s.uppercased() == "HOLD" { hold = v.doubleValue }
                    } else if let i = k as? Int {
                        if i == 0 { sell = v.doubleValue }
                        if i == 1 { hold = v.doubleValue }
                    }
                }
                let maxVal = max(buy, sell, hold)
                let signal: String = (maxVal == buy) ? "BUY" : ((maxVal == sell) ? "SELL" : "HOLD")

                return PredictionResult(
                    signal: signal,
                    confidence: maxVal,
                    model: kind.asPublicKind,
                    timestamp: Date()
                )
            }

            return nil
        } catch {
            Log.ai.error("predictSafely error: \(error.localizedDescription)")
            return nil
        }
    }

        // MARK: - Utils
    private func make2DFloatArray(values: [Float], count: Int) throws -> MLMultiArray {
        let shape: [NSNumber] = [1, count].map { NSNumber(value: $0) }
        let arr = try MLMultiArray(shape: shape, dataType: .float32)
        for (i, v) in values.enumerated() where i < count {
            arr[i] = NSNumber(value: v)
        }
        return arr
    }

    private func normalizeToCount(_ values: [Float], count: Int) -> [Float] {
        if values.count == count { return values }
        if values.count > count { return Array(values.prefix(count)) }
        return values + Array(repeating: 0, count: count - values.count)
    }
}

    // MARK: - Bridge intern → enum public
private extension AIModelManager.ModelKey {
    var asPublicKind: ModelKind {
        switch self {
        case .m5: return .m5
        case .h1: return .h1
        case .h4: return .h4
        }
    }
}
