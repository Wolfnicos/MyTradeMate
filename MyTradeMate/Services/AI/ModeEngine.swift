import Foundation
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "ModeEngine")

// MARK: - Mode Engine for Normal vs Precision Trading

/// Manages different trading modes with distinct thresholds and consensus rules
public class ModeEngine {
    
    // MARK: - Mode Configuration
    
    private let normalConfig: ModeConfiguration
    private let precisionConfig: ModeConfiguration
    
    public init() {
        self.normalConfig = ModeConfiguration.normalMode()
        self.precisionConfig = ModeConfiguration.precisionMode()
    }
    
    // MARK: - Main Interface
    
    /// Process multi-timeframe predictions according to mode settings
    public func processMultiTimeframePredictions(
        predictions: [PredictionResult],
        uncertainties: [UncertaintyResult],
        mode: TradingMode
    ) -> ModeProcessingResult {
        
        let config = mode == .live ? precisionConfig : normalConfig
        
        // Filter predictions that meet mode-specific thresholds
        let qualifiedPredictions = filterQualifiedPredictions(
            predictions: predictions,
            uncertainties: uncertainties,
            config: config
        )
        
        // Apply consensus rules
        let consensusResult = applyConsensusRules(
            predictions: qualifiedPredictions,
            config: config
        )
        
        // Calculate mode-specific confidence
        let modeConfidence = calculateModeConfidence(
            consensusResult: consensusResult,
            allPredictions: predictions,
            config: config
        )
        
        return ModeProcessingResult(
            mode: mode,
            consensusSignal: consensusResult.signal,
            consensusConfidence: consensusResult.confidence,
            modeAdjustedConfidence: modeConfidence,
            qualifiedPredictions: qualifiedPredictions,
            consensusDetails: consensusResult.details,
            shouldExecute: shouldExecuteInMode(
                signal: consensusResult.signal,
                confidence: modeConfidence,
                config: config
            )
        )
    }
    
    // MARK: - Prediction Filtering
    
    /// Filter predictions that meet mode-specific quality thresholds
    private func filterQualifiedPredictions(
        predictions: [PredictionResult],
        uncertainties: [UncertaintyResult],
        config: ModeConfiguration
    ) -> [QualifiedPrediction] {
        
        var qualified: [QualifiedPrediction] = []
        
        for (index, prediction) in predictions.enumerated() {
            let uncertainty = index < uncertainties.count ? uncertainties[index] : 
                UncertaintyResult(epistemic: 0.5, aleatoric: 0.3, total: 0.8, confidenceInterval: 0.2...0.8)
            
            let qualifies = evaluateQualification(
                prediction: prediction,
                uncertainty: uncertainty,
                config: config
            )
            
            if qualifies.passes {
                qualified.append(QualifiedPrediction(
                    prediction: prediction,
                    uncertainty: uncertainty,
                    qualityScore: qualifies.score,
                    timeframePriority: getTimeframePriority(prediction.model.timeframeLabel)
                ))
            }
        }
        
        return qualified.sorted { $0.qualityScore > $1.qualityScore }
    }
    
    /// Evaluate if prediction qualifies for the current mode
    private func evaluateQualification(
        prediction: PredictionResult,
        uncertainty: UncertaintyResult,
        config: ModeConfiguration
    ) -> (passes: Bool, score: Double) {
        
        // Check minimum confidence threshold
        guard prediction.confidence >= config.minConfidenceThreshold else {
            return (false, 0.0)
        }
        
        // Check maximum uncertainty threshold
        guard uncertainty.total <= config.maxUncertaintyThreshold else {
            return (false, 0.0)
        }
        
        // Calculate quality score
        let confidenceScore = prediction.confidence
        let uncertaintyScore = 1.0 - uncertainty.total
        let qualityScore = 0.7 * confidenceScore + 0.3 * uncertaintyScore
        
        let passes = qualityScore >= config.minQualityScore
        
        return (passes, qualityScore)
    }
    
    /// Get timeframe priority for consensus weighting
    private func getTimeframePriority(_ timeframe: String) -> Double {
        // Higher timeframes generally get higher priority
        if timeframe.contains("4h") || timeframe.contains("4H") {
            return 1.0
        } else if timeframe.contains("1h") {
            return 0.8
        } else if timeframe.contains("5m") {
            return 0.6
        } else {
            return 0.5
        }
    }
    
    // MARK: - Consensus Rules
    
    /// Apply mode-specific consensus rules to qualified predictions
    private func applyConsensusRules(
        predictions: [QualifiedPrediction],
        config: ModeConfiguration
    ) -> ConsensusResult {
        
        guard !predictions.isEmpty else {
            return ConsensusResult(
                signal: "HOLD",
                confidence: 0.0,
                details: "No qualified predictions available"
            )
        }
        
        // Apply consensus strategy based on mode
        switch config.consensusStrategy {
        case .majority:
            return applyMajorityConsensus(predictions: predictions, config: config)
        case .weighted:
            return applyWeightedConsensus(predictions: predictions, config: config)
        case .unanimous:
            return applyUnanimousConsensus(predictions: predictions, config: config)
        case .bestQuality:
            return applyBestQualityConsensus(predictions: predictions, config: config)
        }
    }
    
    /// Majority vote consensus
    private func applyMajorityConsensus(
        predictions: [QualifiedPrediction],
        config: ModeConfiguration
    ) -> ConsensusResult {
        
        let signals = predictions.map { $0.prediction.signal }
        let signalCounts = Dictionary(grouping: signals, by: { $0 })
            .mapValues { $0.count }
        
        guard let majoritySignal = signalCounts.max(by: { $0.value < $1.value })?.key else {
            return ConsensusResult(signal: "HOLD", confidence: 0.0, details: "No clear majority")
        }
        
        let majorityCount = signalCounts[majoritySignal] ?? 0
        let majorityRatio = Double(majorityCount) / Double(predictions.count)
        
        // Require stronger majority for precision mode
        let requiredMajority = config.requiredMajorityRatio
        
        if majorityRatio >= requiredMajority {
            let majorityPredictions = predictions.filter { $0.prediction.signal == majoritySignal }
            let avgConfidence = majorityPredictions.map { $0.prediction.confidence }.reduce(0, +) / Double(majorityPredictions.count)
            
            return ConsensusResult(
                signal: majoritySignal,
                confidence: avgConfidence * majorityRatio,
                details: "Majority consensus: \(majorityCount)/\(predictions.count) models agree"
            )
        } else {
            return ConsensusResult(
                signal: "HOLD",
                confidence: 0.0,
                details: "Insufficient majority: \(String(format: "%.1f%%", majorityRatio * 100)) < \(String(format: "%.1f%%", requiredMajority * 100))"
            )
        }
    }
    
    /// Weighted consensus based on quality scores
    private func applyWeightedConsensus(
        predictions: [QualifiedPrediction],
        config: ModeConfiguration
    ) -> ConsensusResult {
        
        var signalWeights: [String: Double] = [:]
        var signalConfidences: [String: [Double]] = [:]
        
        for pred in predictions {
            let signal = pred.prediction.signal
            let weight = pred.qualityScore * pred.timeframePriority
            
            signalWeights[signal, default: 0.0] += weight
            signalConfidences[signal, default: []].append(pred.prediction.confidence)
        }
        
        guard let topSignal = signalWeights.max(by: { $0.value < $1.value })?.key else {
            return ConsensusResult(signal: "HOLD", confidence: 0.0, details: "No weighted consensus")
        }
        
        let totalWeight = signalWeights.values.reduce(0, +)
        let signalWeight = signalWeights[topSignal] ?? 0.0
        let weightRatio = signalWeight / totalWeight
        
        if weightRatio >= config.requiredMajorityRatio {
            let confidences = signalConfidences[topSignal] ?? []
            let avgConfidence = confidences.isEmpty ? 0.0 : confidences.reduce(0, +) / Double(confidences.count)
            
            return ConsensusResult(
                signal: topSignal,
                confidence: avgConfidence * weightRatio,
                details: "Weighted consensus: \(String(format: "%.1f%%", weightRatio * 100)) weight"
            )
        } else {
            return ConsensusResult(
                signal: "HOLD",
                confidence: 0.0,
                details: "Insufficient weighted consensus: \(String(format: "%.1f%%", weightRatio * 100))"
            )
        }
    }
    
    /// Unanimous consensus (strict agreement)
    private func applyUnanimousConsensus(
        predictions: [QualifiedPrediction],
        config: ModeConfiguration
    ) -> ConsensusResult {
        
        let signals = Set(predictions.map { $0.prediction.signal })
        
        if signals.count == 1, let unanimousSignal = signals.first {
            let avgConfidence = predictions.map { $0.prediction.confidence }.reduce(0, +) / Double(predictions.count)
            
            return ConsensusResult(
                signal: unanimousSignal,
                confidence: avgConfidence,
                details: "Unanimous agreement: all \(predictions.count) models agree"
            )
        } else {
            return ConsensusResult(
                signal: "HOLD",
                confidence: 0.0,
                details: "No unanimous agreement: \(signals.count) different signals"
            )
        }
    }
    
    /// Best quality prediction consensus
    private func applyBestQualityConsensus(
        predictions: [QualifiedPrediction],
        config: ModeConfiguration
    ) -> ConsensusResult {
        
        guard let bestPrediction = predictions.max(by: { $0.qualityScore < $1.qualityScore }) else {
            return ConsensusResult(signal: "HOLD", confidence: 0.0, details: "No quality predictions")
        }
        
        return ConsensusResult(
            signal: bestPrediction.prediction.signal,
            confidence: bestPrediction.prediction.confidence,
            details: "Best quality model: score \(String(format: "%.3f", bestPrediction.qualityScore))"
        )
    }
    
    // MARK: - Confidence Calculation
    
    /// Calculate mode-adjusted confidence
    private func calculateModeConfidence(
        consensusResult: ConsensusResult,
        allPredictions: [PredictionResult],
        config: ModeConfiguration
    ) -> Double {
        
        let baseConfidence = consensusResult.confidence
        
        // Apply mode-specific adjustments
        var adjustedConfidence = baseConfidence
        
        // Precision mode penalty for disagreement
        if config.mode == .precision {
            let signals = Set(allPredictions.map { $0.signal })
            if signals.count > 1 {
                let disagreementPenalty = min(0.2, Double(signals.count - 1) * 0.1)
                adjustedConfidence *= (1.0 - disagreementPenalty)
            }
        }
        
        // Apply conservative scaling
        adjustedConfidence *= config.conservativeScaling
        
        // Ensure within target range [50%, 90%]
        return max(0.5, min(0.9, adjustedConfidence))
    }
    
    /// Determine if signal should be executed in current mode
    private func shouldExecuteInMode(
        signal: String,
        confidence: Double,
        config: ModeConfiguration
    ) -> Bool {
        
        guard signal != "HOLD" else { return false }
        
        return confidence >= config.executionThreshold
    }
}

// MARK: - Supporting Data Structures

public struct ModeConfiguration {
    public let mode: AITradingModeType
    public let minConfidenceThreshold: Double
    public let maxUncertaintyThreshold: Double
    public let minQualityScore: Double
    public let consensusStrategy: ConsensusStrategy
    public let requiredMajorityRatio: Double
    public let executionThreshold: Double
    public let conservativeScaling: Double
    
    public static func normalMode() -> ModeConfiguration {
        return ModeConfiguration(
            mode: .normal,
            minConfidenceThreshold: 0.55,
            maxUncertaintyThreshold: 0.35,
            minQualityScore: 0.6,
            consensusStrategy: .weighted,
            requiredMajorityRatio: 0.6,
            executionThreshold: 0.65,
            conservativeScaling: 0.9
        )
    }
    
    public static func precisionMode() -> ModeConfiguration {
        return ModeConfiguration(
            mode: .precision,
            minConfidenceThreshold: 0.7,
            maxUncertaintyThreshold: 0.25,
            minQualityScore: 0.75,
            consensusStrategy: .unanimous,
            requiredMajorityRatio: 0.8,
            executionThreshold: 0.8,
            conservativeScaling: 0.85
        )
    }
}

public struct QualifiedPrediction {
    public let prediction: PredictionResult
    public let uncertainty: UncertaintyResult
    public let qualityScore: Double
    public let timeframePriority: Double
}

public struct ConsensusResult {
    public let signal: String
    public let confidence: Double
    public let details: String
}

public struct ModeProcessingResult {
    public let mode: TradingMode
    public let consensusSignal: String
    public let consensusConfidence: Double
    public let modeAdjustedConfidence: Double
    public let qualifiedPredictions: [QualifiedPrediction]
    public let consensusDetails: String
    public let shouldExecute: Bool
}

public enum AITradingModeType {
    case normal
    case precision
}

public enum ConsensusStrategy {
    case majority
    case weighted
    case unanimous
    case bestQuality
}