import Foundation

// ✅ ADD: Prediction error types for proper fallback handling
public enum PredictionError: Error, CustomStringConvertible {
    case modelNotFound(String)
    case modelLoadingFailed(String, Error)
    case predictionFailed(String, Error) 
    case insufficientData(String)
    case timeout(String)
    
    public var description: String {
        switch self {
        case .modelNotFound(let model):
            return "Model not found: \(model)"
        case .modelLoadingFailed(let model, let error):
            return "Model loading failed for \(model): \(error.localizedDescription)"
        case .predictionFailed(let model, let error):
            return "Prediction failed for \(model): \(error.localizedDescription)"
        case .insufficientData(let model):
            return "Insufficient data for \(model) prediction"
        case .timeout(let model):
            return "Prediction timeout for \(model)"
        }
    }
}

// ✅ ADD: Result type that can handle both success and error cases
public enum PredictionOutcome {
    case success(PredictionResult)
    case failure(PredictionError)
    case strategyFallback(reason: String)
}

    /// Unified prediction container used by ViewModels/UI.
public struct PredictionResult: Sendable {
    public let signal: String          // e.g., "BUY", "SELL", "HOLD"
    public let confidence: Double      // 0.0 ... 1.0
    public let model: ModelKind        // unified enum for all models/timeframes
    public let timestamp: Date

    public init(signal: String, confidence: Double, model: ModelKind, timestamp: Date) {
        self.signal = signal
        self.confidence = confidence
        self.model = model
        self.timestamp = timestamp
    }
}

    // MARK: - Backward compatibility helpers for older call sites
public extension PredictionResult {
        /// Legacy initializer kept for old code: `modelName: String`
    init(signal: String, confidence: Double, modelName: String, timestamp: Date) {
            // Map legacy string to ModelKind; default safely to 5m if unknown
        let fallback: ModelKind = .m5
        let resolved = ModelKind(rawValue: modelName) ?? ModelKind.fromLegacyName(modelName) ?? fallback
        self.init(signal: signal, confidence: confidence, model: resolved, timestamp: timestamp)
    }

        /// Legacy property expected in Views
    var modelName: String { model.rawValue }

        /// Tiny meta wrapper so `result.meta["..."]` continues to work
    struct PredictionMeta {
        private let storage: [String:String]
        init(_ storage: [String:String]) { self.storage = storage }
        subscript(_ key: String) -> String? { storage[key] }
    }

        /// Derived metadata used by some UI bits (non-optional for direct subscripting)
    var meta: PredictionMeta {
        let name = model.rawValue
        let lower = name.lowercased()
        let tf = lower.contains("5m") ? "5m" : (lower.contains("1h") ? "1h" : (lower.contains("4h") ? "4h" : ""))
        return PredictionMeta([
            "modelName": name,
            "timeframe": tf
        ])
    }
}
