import Foundation
import CoreML
import Combine
import os

// MARK: - Feature Builder (inline)
private enum FeatureBuilder {
    static func vector10(from candles: [Candle]) throws -> [Float] {
        guard candles.count >= 50 else {
            Log.ai.info("Not enough candles for features: \(candles.count)/50")
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
        
        Log.ai.info("Built \(features.count) features: \(features.prefix(3))...")
        return features
    }
}

// MARK: - Model Types
enum ModelKind: String {
    case m5 = "BitcoinAI_5m_enhanced"
    case h1 = "BitcoinAI_1h_enhanced" 
    case h4 = "BitcoinAI_4h_enhanced"
    
    var timeframe: String {
        switch self {
        case .m5: return "m5"
        case .h1: return "h1"
        case .h4: return "h4"
        }
    }
    
    var modelName: String {
        return self.rawValue
    }
}

enum SimpleSignal {
    case buy, sell, hold
    
    var stringValue: String {
        switch self {
        case .buy: return "BUY"
        case .sell: return "SELL"
        case .hold: return "HOLD"
        }
    }
}

struct PredictionResult {
    let signal: String // "BUY", "SELL", "HOLD"
    let confidence: Double
    let modelName: String
    let meta: [String: String]
    
    init(signal: String, confidence: Double, modelName: String, meta: [String: String] = [:]) {
        self.signal = signal
        self.confidence = confidence
        self.modelName = modelName
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
    
    // Performance optimization
    private var lastInferenceTime: Date = .distantPast
    private var inferenceCount = 0
    
    private init() {
        // Preload models on init
        Task {
            await preloadModels()
        }
        
        // Listen for memory pressure notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryPressure),
            name: .memoryPressureChanged,
            object: nil
        )
        
        // Listen for optimization notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOptimizationPause),
            name: .pauseNonEssentialOperations,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleMemoryPressure(_ notification: Notification) {
        guard let level = notification.userInfo?["level"] as? MemoryPressureManager.MemoryPressureLevel else { return }
        
        Task { @MainActor in
            switch level {
            case .warning:
                await reduceModelCache()
            case .critical:
                await unloadInactiveModels()
            case .normal:
                break
            }
        }
    }
    
    @objc private func handleOptimizationPause(_ notification: Notification) {
        Task { @MainActor in
            // Pause non-essential model operations
            Log.performance("Pausing non-essential AI operations due to optimization")
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
    
    func predict(symbol: String, timeframe: Timeframe, candles: [Candle], precision: Bool) async -> PredictionResult {
        // Check inference throttling
        guard InferenceThrottler.shared.shouldAllowInference() else {
            Log.ai.debug("Inference throttled, returning cached or default prediction")
            return PredictionResult(signal: "HOLD", confidence: 0.5, 
                                   modelName: "THROTTLED", meta: ["throttled": "true"])
        }
        
        // Demo mode override
        if AppSettings.shared.demoMode {
            let directions = ["BUY", "SELL", "HOLD"]
            let dir = directions.randomElement() ?? "HOLD"
            Log.ai.info("Demo prediction → \(dir)")
            
            // Record inference for throttling
            InferenceThrottler.shared.recordInference()
            
            return PredictionResult(signal: dir, confidence: Double.random(in: 0.55...0.9), 
                                   modelName: "DEMO", meta: ["demo": "1"])
        }
        
        // Record inference attempt
        InferenceThrottler.shared.recordInference()
        inferenceCount += 1
        lastInferenceTime = Date()
        
        let result: PredictionResult
        if precision {
            // Precision mode: ensemble across models
            result = await ensemblePrediction(symbol: symbol, candles: candles)
        } else {
            // Normal mode: single model for timeframe
            result = await singleModelPrediction(timeframe: timeframe, candles: candles)
        }
        
        Log.performance("AI inference completed", duration: Date().timeIntervalSince(lastInferenceTime))
        return result
    }
    
    func predictSafely(timeframe: Timeframe, candles: [Candle], mode: TradingMode) async -> PredictionResult {
        return await predict(symbol: "BTC/USDT", timeframe: timeframe, candles: candles, precision: false)
    }
    
    private func singleModelPrediction(timeframe: Timeframe, candles: [Candle]) async -> PredictionResult {
        guard candles.count >= 50 else {
            return PredictionResult(signal: "HOLD", confidence: 0, modelName: "N/A", 
                                  meta: ["reason": "insufficient_candles"])
        }
        
        let modelKind = modelKindForTimeframe(timeframe)
        
        do {
            let model = try await loadModel(for: timeframe)
            let features = try FeatureBuilder.vector10(from: candles)
            
            let inputName = model.modelDescription.inputDescriptionsByName.keys.first ?? "dense_input"
            let array = try MLMultiArray(shape: [10], dataType: .float32)
            for (i, v) in features.enumerated() { array[i] = NSNumber(value: v) }
            let input = [inputName: MLFeatureValue(multiArray: array)]
            
            let provider = try MLDictionaryFeatureProvider(dictionary: input)
            let output = try model.prediction(from: provider)
            
            // Convert output to prediction result
            return convertToPredictionResult(output: output, modelName: modelKind.modelName)
        } catch {
            let ns = error as NSError
            print("CoreML EVAL ERROR: \(ns.localizedDescription) code=\(ns.code) domain=\(ns.domain)")
            if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("Underlying: \(underlying), code=\(underlying.code)")
            }
            Log.ai.error("Prediction failed: \(ns.localizedDescription)")
            return PredictionResult(signal: "HOLD", confidence: 0, modelName: modelKind.modelName, 
                                  meta: ["error": "eval_failed"])
        }
    }
    
    private func ensemblePrediction(symbol: String, candles: [Candle]) async -> PredictionResult {
        var predictions: [PredictionResult] = []
        
        // Run all models
        for timeframe: Timeframe in [.m5, .h1, .h4] {
            let result = await singleModelPrediction(timeframe: timeframe, candles: candles)
            predictions.append(result)
        }
        
        // Majority vote
        let buyVotes = predictions.filter { $0.signal == "BUY" }
        let sellVotes = predictions.filter { $0.signal == "SELL" }
        let holdVotes = predictions.filter { $0.signal == "HOLD" }
        
        let finalSignal: String
        let avgConfidence: Double
        
        if buyVotes.count > max(sellVotes.count, holdVotes.count) {
            finalSignal = "BUY"
            avgConfidence = buyVotes.map { $0.confidence }.reduce(0, +) / Double(buyVotes.count)
        } else if sellVotes.count > holdVotes.count {
            finalSignal = "SELL"
            avgConfidence = sellVotes.map { $0.confidence }.reduce(0, +) / Double(sellVotes.count)
        } else {
            finalSignal = "HOLD"
            avgConfidence = holdVotes.map { $0.confidence }.reduce(0, +) / Double(max(holdVotes.count, 1))
        }
        
        return PredictionResult(signal: finalSignal, confidence: avgConfidence, 
                               modelName: "Ensemble", meta: ["models": "m5,h1,h4"])
    }
    
    private func convertToPredictionResult(output: MLFeatureProvider, modelName: String) -> PredictionResult {
        // Try to find output values
        let outputNames = output.featureNames
        
        if let classLabel = output.featureValue(for: "classLabel")?.stringValue {
            let confidence = output.featureValue(for: "confidence")?.doubleValue ?? 0.5
            return PredictionResult(signal: classLabel.uppercased(), confidence: confidence, 
                                   modelName: modelName, meta: [:])
        }
        
        // Fallback to first output
        if let firstOutput = outputNames.first,
           let value = output.featureValue(for: firstOutput)?.doubleValue {
            let signal = value > 0.5 ? "BUY" : "HOLD"
            return PredictionResult(signal: signal, confidence: abs(value), 
                                   modelName: modelName, meta: [:])
        }
        
        return PredictionResult(signal: "HOLD", confidence: 0, modelName: modelName, meta: [:])
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
            signal: signal.stringValue,
            confidence: confidence,
            modelName: kind.modelName,
            meta: [:]
        )
    }
    
    func demoPrediction(for kind: ModelKind) async -> PredictionResult {
        let signals: [SimpleSignal] = [.buy, .sell, .hold]
        let signal = signals.randomElement() ?? .hold
        
        return PredictionResult(
            signal: signal.stringValue,
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
        .init(signal: "HOLD", confidence: 0, modelName: modelName, meta: [:])
    }
    
    static func from(features out: MLFeatureProvider, modelName: String) -> PredictionResult {
        // Generic mapping: prefer "classLabel" or "signal" + "confidence"
        if let label = out.featureValue(for: "classLabel")?.stringValue {
            let conf = out.featureValue(for: "confidence")?.doubleValue ?? 0
            let signal = label.uppercased()
            return .init(signal: signal, confidence: conf, modelName: modelName, meta: [:])
        }
        // Fallback: if model outputs logits array
        if let logits = out.featureValue(for: "output")?.multiArrayValue {
            // pick max index
            var maxI = 0; var maxV = logits[0].doubleValue
            for i in 1..<logits.count { if logits[i].doubleValue > maxV { maxV = logits[i].doubleValue; maxI = i } }
            let mapping = ["HOLD","BUY","SELL"]
            let label = mapping.indices.contains(maxI) ? mapping[maxI] : "HOLD"
            return .init(signal: label,
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
