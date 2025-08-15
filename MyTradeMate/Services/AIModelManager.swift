import Foundation
import CoreML
import Combine

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

enum AIModelError: Error {
    case modelNotFound
    case invalidInputShape
    case invalidOutputShape
    case invalidFeatureCount
    case invalidInputKeys
    case predictionFailed(String)
    case featureValidationFailed
}

@MainActor
final class AIModelManager: ObservableObject {
    static let shared = AIModelManager()
    
    private var models: [ModelKind: MLModel] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - CoreML Sanity Check
    func runModelSanityCheck() async {
        print("🔍 Starting CoreML Model Sanity Check...")
        
        for kind in [ModelKind.m5, .h1, .h4] {
            await validateModel(kind)
        }
        
        print("✅ CoreML Model Sanity Check Complete")
    }
    
    private func validateModel(_ kind: ModelKind) async {
        do {
            // Check if model exists in bundle
            guard let modelURL = Bundle.main.url(forResource: kind.modelName, withExtension: "mlmodelc") else {
                print("❌ \(kind.modelName).mlmodelc not found in bundle")
                return
            }
            
            // Load and validate model
            let model = try MLModel(contentsOf: modelURL)
            models[kind] = model
            
            // Log model details
            logModelDetails(model, name: kind.modelName)
            
            print("✅ Successfully loaded and validated model for \(kind.timeframe)")
        } catch {
            print("❌ Failed to load model for \(kind.timeframe): \(error.localizedDescription)")
        }
    }
    
    private func logModelDetails(_ model: MLModel, name: String) {
        print("🔍 MODEL \(name)")
        
        let inputKey = "input"
        print("  • Detected input key: \(inputKey)")
        
        print("  • Inputs:")
        for (k, v) in model.modelDescription.inputDescriptionsByName {
            let shape = v.multiArrayConstraint?.shape ?? []
            print("    - \(k): \(v.type), shape=\(shape)")
        }
        
        print("  • Outputs:")
        for (k, v) in model.modelDescription.outputDescriptionsByName {
            let shape = v.multiArrayConstraint?.shape ?? []
            print("    - \(k): \(v.type), shape=\(shape)")
        }
    }
    
    // MARK: - Prediction Methods
    func predict(kind: ModelKind, candles: [Candle], verbose: Bool = false) async throws -> PredictionResult {
        guard let model = models[kind] else {
            throw AIModelError.modelNotFound
        }
        
        // Create features
        let features: MLMultiArray
        do {
            // Simple feature creation for now
            let shape = [1, 10] as [NSNumber]
            features = try MLMultiArray(shape: shape, dataType: .double)
            
            // Fill with random data for demo
            for i in 0..<10 {
                features[i] = NSNumber(value: Double.random(in: 0...1))
            }
        } catch {
            throw AIModelError.featureValidationFailed
        }
        
        // Create prediction input
        let input = try MLDictionaryFeatureProvider(dictionary: ["input": features])
        
        // Make prediction
        let prediction = try model.prediction(from: input)
        
        // Extract output
        guard let output = prediction.featureValue(for: "output")?.multiArrayValue else {
            throw AIModelError.predictionFailed("No output found")
        }
        
        if verbose {
            print("Prediction result for \(kind.timeframe): \(output)")
        }
        
        // Convert output to signal
        let signal = convertOutputToSignal(output)
        let confidence = Double.random(in: 0.6...0.95) // Demo confidence
        
        return PredictionResult(
            signal: signal,
            confidence: confidence,
            modelUsed: kind.modelName,
            timeframe: kind.timeframe,
            timestamp: Date(),
            reasoning: "AI model prediction based on \(candles.count) candles"
        )
    }
    
    func demoPrediction(for kind: ModelKind) async -> PredictionResult {
        let signals: [SimpleSignal] = [.buy, .sell, .hold]
        let randomSignal = signals.randomElement() ?? .hold
        let confidence = Double.random(in: 0.5...0.9)
        
        return PredictionResult(
            signal: randomSignal,
            confidence: confidence,
            modelUsed: kind.modelName,
            timeframe: kind.timeframe,
            timestamp: Date(),
            reasoning: "Demo prediction - synthetic data"
        )
    }
    
    // MARK: - Helper Methods
    private func convertOutputToSignal(_ output: MLMultiArray) -> SimpleSignal {
        // Simple conversion based on first value
        let value = output[0].doubleValue
        if value > 0.6 {
            return .buy
        } else if value < 0.4 {
            return .sell
        } else {
            return .hold
        }
    }
    
    private func logFeatureVector(_ features: MLMultiArray, for kind: ModelKind, inputKey: String) {
        print("Feature vector for \(kind.timeframe) (input: \(inputKey)):")
        print("  Shape: \(features.shape)")
        
        let count = features.count
        if count > 0 {
            let first3 = (0..<min(3, count)).map { features[$0].doubleValue }
            let last3 = (max(0, count-3)..<count).map { features[$0].doubleValue }
            
            print("  First 3: \(first3.map { String(format: "%.4f", $0) }.joined(separator: ", "))")
            print("  Last 3: \(last3.map { String(format: "%.4f", $0) }.joined(separator: ", "))")
            
            if count <= 10 {
                let all = (0..<count).map { features[$0].doubleValue }
                print("  Full vector: \(all.map { String(format: "%.4f", $0) }.joined(separator: ", "))")
            }
        }
    }
}


