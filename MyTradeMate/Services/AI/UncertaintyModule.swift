import Foundation
import CoreML
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "Uncertainty")

// MARK: - Uncertainty Quantification Module

public class UncertaintyModule {
    
    // MARK: - Deep Ensemble Wrapper
    
    /// Quantifies uncertainty using multiple model predictions
    public class DeepEnsemble {
        private let models: [String] // Model identifiers
        private let ensembleSize: Int
        
        public init(models: [String]) {
            self.models = models
            self.ensembleSize = models.count
        }
        
        /// Calculate ensemble uncertainty from multiple predictions
        public func calculateUncertainty(predictions: [PredictionResult]) -> UncertaintyResult {
            guard predictions.count >= 2 else {
                return UncertaintyResult(
                    epistemic: 0.5, // High uncertainty for single prediction
                    aleatoric: 0.3,
                    total: 0.8,
                    confidenceInterval: 0.3...0.7
                )
            }
            
            // Extract confidence values
            let confidences = predictions.map { $0.confidence }
            let signals = predictions.map { $0.signal }
            
            // Calculate epistemic uncertainty (model disagreement)
            let meanConfidence = confidences.reduce(0, +) / Double(confidences.count)
            let variance = confidences.map { pow($0 - meanConfidence, 2) }.reduce(0, +) / Double(confidences.count)
            let epistemicUncertainty = sqrt(variance)
            
            // Calculate aleatoric uncertainty (inherent data noise)
            // Approximated as the inverse of maximum confidence
            let maxConfidence = confidences.max() ?? 0.5
            let aleatoricUncertainty = 1.0 - maxConfidence
            
            // Total uncertainty combines both sources
            let totalUncertainty = sqrt(pow(epistemicUncertainty, 2) + pow(aleatoricUncertainty, 2))
            
            // Calculate confidence interval based on uncertainty
            let halfWidth = totalUncertainty * 0.5
            let lower = max(0.0, meanConfidence - halfWidth)
            let upper = min(1.0, meanConfidence + halfWidth)
            
            return UncertaintyResult(
                epistemic: epistemicUncertainty,
                aleatoric: aleatoricUncertainty,
                total: totalUncertainty,
                confidenceInterval: lower...upper
            )
        }
        
        /// Determine if ensemble predictions are reliable
        public func isReliable(predictions: [PredictionResult], threshold: Double = 0.3) -> Bool {
            let uncertainty = calculateUncertainty(predictions: predictions)
            return uncertainty.total <= threshold
        }
    }
    
    // MARK: - Monte Carlo Dropout Wrapper
    
    /// Simulates MC Dropout for uncertainty estimation
    public class MCDropoutWrapper {
        private let dropoutRate: Double
        private let numSamples: Int
        
        public init(dropoutRate: Double = 0.2, numSamples: Int = 10) {
            self.dropoutRate = dropoutRate
            self.numSamples = numSamples
        }
        
        /// Simulate multiple forward passes with different dropout patterns
        public func estimateUncertainty(basePrediction: PredictionResult) -> UncertaintyResult {
            // Simulate multiple predictions with noise (representing dropout)
            var samples: [Double] = []
            
            for _ in 0..<numSamples {
                // Add noise to simulate dropout effect
                let noise = Double.random(in: -dropoutRate...dropoutRate)
                let noisyConfidence = clamp(basePrediction.confidence + noise, to: 0.0...1.0)
                samples.append(noisyConfidence)
            }
            
            // Calculate statistics
            let mean = samples.reduce(0, +) / Double(samples.count)
            let variance = samples.map { pow($0 - mean, 2) }.reduce(0, +) / Double(samples.count)
            let uncertainty = sqrt(variance)
            
            // Monte Carlo dropout primarily captures epistemic uncertainty
            let epistemicUncertainty = uncertainty
            let aleatoricUncertainty = dropoutRate * 0.5 // Approximation
            let totalUncertainty = sqrt(pow(epistemicUncertainty, 2) + pow(aleatoricUncertainty, 2))
            
            // Calculate confidence interval
            let halfWidth = totalUncertainty
            let lower = max(0.0, mean - halfWidth)
            let upper = min(1.0, mean + halfWidth)
            
            return UncertaintyResult(
                epistemic: epistemicUncertainty,
                aleatoric: aleatoricUncertainty,
                total: totalUncertainty,
                confidenceInterval: lower...upper
            )
        }
        
        /// Check if single model prediction is reliable
        public func isReliable(prediction: PredictionResult, threshold: Double = 0.25) -> Bool {
            let uncertainty = estimateUncertainty(basePrediction: prediction)
            return uncertainty.total <= threshold
        }
    }
    
    // MARK: - Combined Uncertainty Engine
    
    public class UncertaintyEngine {
        private let deepEnsemble: DeepEnsemble
        private let mcDropout: MCDropoutWrapper
        
        public init(modelIdentifiers: [String]) {
            self.deepEnsemble = DeepEnsemble(models: modelIdentifiers)
            self.mcDropout = MCDropoutWrapper()
        }
        
        /// Calculate comprehensive uncertainty from multiple sources
        public func calculateComprehensiveUncertainty(
            predictions: [PredictionResult],
            method: UncertaintyMethod = .ensemble
        ) -> UncertaintyResult {
            switch method {
            case .deepEnsemble:
                return deepEnsemble.calculateUncertainty(predictions: predictions)
                
            case .mcDropout:
                guard let primaryPrediction = predictions.first else {
                    return defaultHighUncertainty()
                }
                return mcDropout.estimateUncertainty(basePrediction: primaryPrediction)
                
            case .ensemble:
                // Combine both methods
                let ensembleUncertainty = deepEnsemble.calculateUncertainty(predictions: predictions)
                
                guard let primaryPrediction = predictions.first else {
                    return ensembleUncertainty
                }
                
                let mcUncertainty = mcDropout.estimateUncertainty(basePrediction: primaryPrediction)
                
                // Weighted combination
                let epistemic = 0.7 * ensembleUncertainty.epistemic + 0.3 * mcUncertainty.epistemic
                let aleatoric = 0.6 * ensembleUncertainty.aleatoric + 0.4 * mcUncertainty.aleatoric
                let total = sqrt(pow(epistemic, 2) + pow(aleatoric, 2))
                
                // Conservative confidence interval (wider of the two)
                let lowerBound = min(ensembleUncertainty.confidenceInterval.lowerBound, 
                                   mcUncertainty.confidenceInterval.lowerBound)
                let upperBound = max(ensembleUncertainty.confidenceInterval.upperBound,
                                   mcUncertainty.confidenceInterval.upperBound)
                
                return UncertaintyResult(
                    epistemic: epistemic,
                    aleatoric: aleatoric,
                    total: total,
                    confidenceInterval: lowerBound...upperBound
                )
            }
        }
        
        /// Determine overall prediction reliability
        public func assessReliability(
            predictions: [PredictionResult],
            mode: ReliabilityMode = .normal
        ) -> ReliabilityAssessment {
            let uncertainty = calculateComprehensiveUncertainty(predictions: predictions)
            
            let threshold: Double
            switch mode {
            case .normal:
                threshold = 0.3 // More lenient for normal mode
            case .precision:
                threshold = 0.2 // Stricter for precision mode
            }
            
            let isReliable = uncertainty.total <= threshold
            let confidence = 1.0 - uncertainty.total
            
            // Determine reliability level
            let level: ReliabilityLevel
            if uncertainty.total <= 0.15 {
                level = .high
            } else if uncertainty.total <= 0.3 {
                level = .moderate
            } else {
                level = .low
            }
            
            return ReliabilityAssessment(
                isReliable: isReliable,
                confidence: confidence,
                level: level,
                uncertainty: uncertainty
            )
        }
        
        private func defaultHighUncertainty() -> UncertaintyResult {
            return UncertaintyResult(
                epistemic: 0.4,
                aleatoric: 0.3,
                total: 0.5,
                confidenceInterval: 0.2...0.8
            )
        }
    }
    
    // MARK: - Utility Functions
    
    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        return max(range.lowerBound, min(range.upperBound, value))
    }
}

// MARK: - Supporting Data Structures

public struct UncertaintyResult {
    public let epistemic: Double       // Model uncertainty
    public let aleatoric: Double       // Data uncertainty
    public let total: Double           // Combined uncertainty
    public let confidenceInterval: ClosedRange<Double>
    
    public init(epistemic: Double, aleatoric: Double, total: Double, confidenceInterval: ClosedRange<Double>) {
        self.epistemic = epistemic
        self.aleatoric = aleatoric
        self.total = total
        self.confidenceInterval = confidenceInterval
    }
}

public struct ReliabilityAssessment {
    public let isReliable: Bool
    public let confidence: Double
    public let level: ReliabilityLevel
    public let uncertainty: UncertaintyResult
    
    public init(isReliable: Bool, confidence: Double, level: ReliabilityLevel, uncertainty: UncertaintyResult) {
        self.isReliable = isReliable
        self.confidence = confidence
        self.level = level
        self.uncertainty = uncertainty
    }
}

public enum UncertaintyMethod: String, CaseIterable {
    case deepEnsemble = "deepEnsemble"
    case mcDropout = "mcDropout"
    case ensemble = "ensemble"
}

public enum ReliabilityMode {
    case normal
    case precision
}

public enum ReliabilityLevel {
    case high
    case moderate
    case low
    
    public var description: String {
        switch self {
        case .high: return "High Reliability"
        case .moderate: return "Moderate Reliability"
        case .low: return "Low Reliability"
        }
    }
}