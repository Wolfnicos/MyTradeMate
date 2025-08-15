import Foundation
import CoreML
import Combine

// MARK: - Logging Helper
private enum Log {
    static func ai(_ msg: @autoclosure () -> String) {
        print("[AI] \(msg())")
    }
}

// MARK: - Feature Builder (inline)
private enum FeatureBuilder {
    static func vector10(from candles: [Candle]) throws -> [Float] {
        guard candles.count >= 50 else {
            Log.ai("Not enough candles for features: \(candles.count)/50")
            return Array(repeating: 0.0, count: 10)
        }
        
        var features: [Float] = []
        
        // 1. Simple momentum
        if candles.count >= 2 {
            let current = candles[candles.count - 1].close
            let previous = candles[candles.count - 2].close
            let momentum = Float((current - previous) / previous)
            features.append(momentum)
        } else {
            features.append(0.0)
        }
        
        // 2-10. Simple features (normalized)
        for i in 1..<10 {
            features.append(Float.random(in: -1...1)) // Placeholder implementation
        }
        
        Log.ai("Built \(features.count) features: \(features.prefix(3))...")
        return features
    }
}

// MARK: - Model Types
enum ModelKind {
    case m5, h1, h4
    
    var timeframe: String {
        switch self {
        case .m5: return "5m"
        case .h1: return "1h"
        case .h4: return "4h"
        }
    }
    
    var modelName: String {
        switch self {
        case .m5: return "BitcoinAI_5m_enhanced"
        case .h1: return "BitcoinAI_1h_enhanced"
        case .h4: return "BTC_4H_Model"
        }
    }
}

enum SimpleSignal {
    case buy, sell, hold
}

struct PredictionResult {
    let signal: SimpleSignal
    let confidence: Double
    let modelUsed: String
    let timeframe: String
    let timestamp: Date
    let reasoning: String?
    let meta: [String: Any]
    
    init(signal: SimpleSignal, confidence: Double, modelName: String, meta: [String: Any] = [:]) {
        self.signal = signal
        self.confidence = confidence
        self.modelUsed = modelName
        self.timeframe = ""
        self.timestamp = Date()
        self.reasoning = nil
        self.meta = meta
    }
}

enum AIModelError: Error {
    case modelNotFound
    case invalidInputShape
    case invalidOutputShape
    case invalidFeatureCount
    case invalidInputKeys
    case predictionFailed(String)
    case featureGenerationFailed
}

@MainActor
final class AIModelManager: ObservableObject {
    static let shared = AIModelManager()
    
    @Published var models: [ModelKind: MLModel] = [:]
    
    private init() {
        // Preload models on init
        Task {
            await preloadModels()
        }
    }
    
    func preloadModels() async {
        for kind in [ModelKind.m5, .h1, .h4] {
            do {
                let model = try await loadModel(kind: kind)
                models[kind] = model
            } catch {
                print("Error loading model \(kind.modelName): \(error)")
            }
        }
    }
    
    func loadModel(kind: ModelKind) async throws -> MLModel {
        guard let url = Bundle.main.url(forResource: kind.modelName, withExtension: "mlmodelc") else {
            throw AIModelError.modelNotFound
        }
        
        return try MLModel(contentsOf: url)
    }
    
    func validateModels() async throws {
        for (kind, model) in models {
            // Check input shape
            guard let input = model.modelDescription.inputDescriptionsByName.first,
                  let shape = input.value.multiArrayConstraint?.shape,
                  shape.count > 1 else {
                throw AIModelError.invalidInputShape
            }
            
            // Check output shape
            guard let output = model.modelDescription.outputDescriptionsByName.first,
                  let outputShape = output.value.multiArrayConstraint?.shape,
                  outputShape.count > 0 else {
                throw AIModelError.invalidOutputShape
            }
        }
    }
    
    func predictSafely(timeframe: Timeframe, candles: [Candle], mode: TradingMode) async -> PredictionResult {
        let settings = AppSettings.shared
        
        // Demo override
        if settings.demoMode || settings.aiDebugMode {
            let mock = PredictionResult(signal: .buy, confidence: 0.78, modelName: "Demo", meta: ["demo": "true"])
            Log.ai("Demo prediction → \(mock.signal)")
            return mock
        }
        
        do {
            let model = try await loadModel(for: timeframe)
            let md = model.modelDescription
            Log.ai("Loaded model \(md.metadata[.author] ?? "") / \(md.predictedFeatureName ?? "unknown")")
            
            if timeframe == .h4 {
                // OHLC model
                let keys = ohlcKeys(for: model)
                guard keys.count == 4 else {
                    Log.ai("❌ OHLC keys missing: \(keys)")
                    return .empty(modelName: "OHLC-missing")
                }
                
                guard candles.count >= 2 else { return .empty(modelName: "not-enough-candles") }
                let last = candles.last!
                let prev = candles[candles.count - 2]
                
                let inputs: [String: MLFeatureValue] = [
                    "open": .init(double: last.open),
                    "high": .init(double: last.high),
                    "low":  .init(double: last.low),
                    "close": .init(double: last.close),
                    // OPTIONAL: add prev close if model has it
                    "prev_close": md.inputDescriptionsByName.keys.contains("prev_close") ? .init(double: prev.close) : nil
                ].compactMapValues { $0 }
                
                Log.ai("→ OHLC inputs: \(inputs.map { "\($0.key)=\($0.value.doubleValue)" }.joined(separator: ", "))")
                
                let dict = try MLDictionaryFeatureProvider(dictionary: inputs)
                let out = try model.prediction(from: dict)
                Log.ai("← OHLC output: \(out.featureNames.map { "\($0)=\(out.featureValue(for: $0)!)" }.joined(separator: ", "))")
                
                return PredictionResult.from(features: out, modelName: "BTC_4H_Model")
            } else {
                // Dense 10 model
                let vec = try FeatureBuilder.vector10(from: candles)
                let key = denseKey(for: model) ?? "dense_input"
                let arr = try MLMultiArray(shape: [10], dataType: .float32)
                for (i, v) in vec.enumerated() { arr[i] = NSNumber(value: v) }
                
                Log.ai("→ Dense vector (10): \(vec.map { String(format: "%.5f", $0) }.joined(separator: ", "))")
                Log.ai("→ Using input key '\(key)' (fallback to detected)")
                
                let prov = try MLDictionaryFeatureProvider(dictionary: [key: MLFeatureValue(multiArray: arr)])
                let out = try model.prediction(from: prov)
                Log.ai("← Dense output: \(out.featureNames.map { "\($0)=\(out.featureValue(for: $0)!)" }.joined(separator: ", "))")
                
                return PredictionResult.from(features: out, modelName: currentModelName(for: timeframe))
            }
        } catch {
            let ns = error as NSError
            let shapes = models.values.first?.modelDescription.inputDescriptionsByName.mapValues { $0.multiArrayConstraint?.shape ?? [] } ?? [:]
            Log.ai("❌ CoreML prediction failed | \(ns.localizedDescription)")
            Log.ai("↳ domain=\(ns.domain) code=\(ns.code)")
            Log.ai("↳ reason=\(ns.localizedFailureReason ?? "nil") suggestion=\(ns.localizedRecoverySuggestion ?? "nil")")
            Log.ai("↳ userInfo=\(ns.userInfo)")
            Log.ai("↳ model inputs=\(shapes)")
            return .empty(modelName: "error")
        }
    }
    
    private func denseKey(for model: MLModel) -> String? {
        let d = model.modelDescription.inputDescriptionsByName
        for (k, v) in d {
            guard case .multiArray = v.type else { continue }
            let shape = (v.multiArrayConstraint?.shape as? [Int]) ?? []
            if shape == [10] || shape == [1,10] || shape == [10,1] { return k }
        }
        return nil
    }
    
    private func ohlcKeys(for model: MLModel) -> [String] {
        let keys = Set(model.modelDescription.inputDescriptionsByName.keys)
        return ["open","high","low","close"].filter { keys.contains($0) }
    }
    
    private func loadModel(for timeframe: Timeframe) async throws -> MLModel {
        let kind = modelKindForTimeframe(timeframe)
        if let cached = models[kind] { return cached }
        return try await loadModel(kind: kind)
    }
    
    private func modelKindForTimeframe(_ timeframe: Timeframe) -> ModelKind {
        switch timeframe {
        case .m5: return .m5
        case .h1: return .h1
        case .h4: return .h4
        }
    }
    
    private func currentModelName(for timeframe: Timeframe) -> String {
        return modelKindForTimeframe(timeframe).modelName
    }
    
    func predict(kind: ModelKind, candles: [Double], verbose: Bool = false) async throws -> PredictionResult {
        guard let model = models[kind] else {
            throw AIModelError.modelNotFound
        }
        
        // Simple feature generation for now
        let features: MLMultiArray
        do {
            let shape = [1, 10] as [NSNumber]
            features = try MLMultiArray(shape: shape, dataType: .double)
            
            // Fill with random data for demo
            for i in 0..<10 {
                features[i] = NSNumber(value: Double.random(in: 0...1))
            }
        } catch {
            throw AIModelError.featureGenerationFailed
        }
        
        // Input validation
        guard let inputName = model.modelDescription.inputDescriptionsByName.keys.first else {
            throw AIModelError.invalidInputKeys
        }
        
        let provider = try MLDictionaryFeatureProvider(
            dictionary: [inputName: features]
        )
        
        // Prediction
        let prediction = try model.prediction(from: provider)
        
        guard let outputName = model.modelDescription.outputDescriptionsByName.keys.first,
              let output = prediction.featureValue(for: outputName)?.multiArrayValue else {
            throw AIModelError.invalidOutputShape
        }
        
        let signal = convertOutputToSignal(output)
        let confidence = output.count > 0 ? output[0].doubleValue : 0.5
        
        return PredictionResult(
            signal: signal,
            confidence: confidence,
            modelName: kind.modelName,
            meta: [:]
        )
    }
    
    func demoPrediction(for kind: ModelKind) async -> PredictionResult {
        let signals: [SimpleSignal] = [.buy, .sell, .hold]
        let signal = signals.randomElement()!
        
        return PredictionResult(
            signal: signal,
            confidence: Double.random(in: 0.6...0.9),
            modelName: "Demo Model",
            meta: [:]
        )
    }
    
    private func convertOutputToSignal(_ output: MLMultiArray) -> SimpleSignal {
        // Check array size first
        let count = output.count
        
        if count == 0 {
            return .hold
        }
        
        let buyProb = output[0].doubleValue
        
        if count == 1 {
            // Single value - treat as buy probability
            return buyProb > 0.5 ? .buy : .hold
        }
        
        if count >= 2 {
            let sellProb = output[1].doubleValue
            
            if count >= 3 {
                let holdProb = output[2].doubleValue
                
                if buyProb > sellProb && buyProb > holdProb {
                    return .buy
                } else if sellProb > buyProb && sellProb > holdProb {
                    return .sell
                } else {
                    return .hold
                }
            } else {
                // Only 2 values - compare buy vs sell
                return buyProb > sellProb ? .buy : .sell
            }
        }
        
        return .hold
    }
}

private extension PredictionResult {
    static func empty(modelName: String) -> PredictionResult {
        .init(signal: .hold, confidence: 0, modelName: modelName, meta: [:])
    }
    
    static func from(features out: MLFeatureProvider, modelName: String) -> PredictionResult {
        // Generic mapping: prefer "classLabel" or "signal" + "confidence"
        if let label = out.featureValue(for: "classLabel")?.stringValue {
            let conf = out.featureValue(for: "confidence")?.doubleValue ?? 0
            let s: SimpleSignal = SimpleSignal(rawValue: label.uppercased()) ?? .hold
            return .init(signal: s, confidence: conf, modelName: modelName, meta: [:])
        }
        // Fallback: if model outputs logits array
        if let logits = out.featureValue(for: "output")?.multiArrayValue {
            // pick max index
            var maxI = 0; var maxV = logits[0].doubleValue
            for i in 1..<logits.count { if logits[i].doubleValue > maxV { maxV = logits[i].doubleValue; maxI = i } }
            let mapping = ["HOLD","BUY","SELL"]
            let label = mapping.indices.contains(maxI) ? mapping[maxI] : "HOLD"
            return .init(signal: SimpleSignal(rawValue: label) ?? .hold,
                         confidence: maxV, modelName: modelName, meta: [:])
        }
        return .empty(modelName: modelName)
    }
}

extension SimpleSignal {
    init?(rawValue: String) {
        switch rawValue.uppercased() {
        case "BUY": self = .buy
        case "SELL": self = .sell  
        case "HOLD": self = .hold
        default: return nil
        }
    }
}
