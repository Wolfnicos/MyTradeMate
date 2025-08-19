import Foundation
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "MetaConfidence")

// MARK: - Meta-Confidence Calculator

/// Calculates comprehensive confidence metrics with agreement scoring and uncertainty penalties
public class MetaConfidenceCalculator {
    
    // MARK: - Properties
    
    private let agreementWeight: Double
    private let uncertaintyWeight: Double
    private let qualityWeight: Double
    private let timeframeWeight: Double
    
    public init(
        agreementWeight: Double = 0.3,
        uncertaintyWeight: Double = 0.25,
        qualityWeight: Double = 0.3,
        timeframeWeight: Double = 0.15
    ) {
        self.agreementWeight = agreementWeight
        self.uncertaintyWeight = uncertaintyWeight
        self.qualityWeight = qualityWeight
        self.timeframeWeight = timeframeWeight
    }
    
    // MARK: - Main Interface
    
    /// Calculate comprehensive meta-confidence from all inputs
    public func calculateMetaConfidence(
        predictions: [PredictionResult],
        uncertainties: [UncertaintyResult],
        conformalResults: [ConformalResult],
        modeResult: ModeProcessingResult
    ) -> MetaConfidenceResult {
        
        // Calculate individual components
        let agreementScore = calculateAgreementScore(predictions: predictions)
        let uncertaintyPenalty = calculateUncertaintyPenalty(uncertainties: uncertainties)
        let qualityScore = calculateQualityScore(conformalResults: conformalResults)
        let timeframeScore = calculateTimeframeScore(predictions: predictions)
        
        // Combine components with weights
        let rawMetaConfidence = 
            agreementWeight * agreementScore +
            uncertaintyWeight * (1.0 - uncertaintyPenalty) +
            qualityWeight * qualityScore +
            timeframeWeight * timeframeScore
        
        // Apply mode-specific adjustments
        let modeAdjustedConfidence = applyModeAdjustments(
            rawConfidence: rawMetaConfidence,
            modeResult: modeResult
        )
        
        // Final confidence mapping to [50%, 90%] range
        let finalConfidence = mapToTargetRange(
            confidence: modeAdjustedConfidence,
            targetRange: 0.5...0.9
        )
        
        return MetaConfidenceResult(
            finalConfidence: finalConfidence,
            agreementScore: agreementScore,
            uncertaintyPenalty: uncertaintyPenalty,
            qualityScore: qualityScore,
            timeframeScore: timeframeScore,
            rawMetaConfidence: rawMetaConfidence,
            modeAdjustedConfidence: modeAdjustedConfidence,
            components: createComponentsBreakdown(
                agreement: agreementScore,
                uncertainty: uncertaintyPenalty,
                quality: qualityScore,
                timeframe: timeframeScore
            )
        )
    }
    
    // MARK: - Agreement Score Calculation
    
    /// Calculate inter-model agreement score
    private func calculateAgreementScore(predictions: [PredictionResult]) -> Double {
        guard predictions.count >= 2 else { return 0.5 }
        
        let signals = predictions.map { $0.signal }
        let confidences = predictions.map { $0.confidence }
        
        // Signal agreement score
        let signalCounts = Dictionary(grouping: signals, by: { $0 }).mapValues { $0.count }
        let maxAgreement = signalCounts.values.max() ?? 0
        let signalAgreement = Double(maxAgreement) / Double(predictions.count)
        
        // Confidence coherence score
        let meanConfidence = confidences.reduce(0, +) / Double(confidences.count)
        let confidenceVariance = confidences.map { pow($0 - meanConfidence, 2) }.reduce(0, +) / Double(confidences.count)
        let confidenceCoherence = max(0.0, 1.0 - sqrt(confidenceVariance) * 2.0)
        
        // Combine signal agreement and confidence coherence
        let agreementScore = 0.7 * signalAgreement + 0.3 * confidenceCoherence
        
        return max(0.0, min(1.0, agreementScore))
    }
    
    // MARK: - Uncertainty Penalty Calculation
    
    /// Calculate penalty based on prediction uncertainty
    private func calculateUncertaintyPenalty(uncertainties: [UncertaintyResult]) -> Double {
        guard !uncertainties.isEmpty else { return 0.5 }
        
        // Average total uncertainty across all predictions
        let avgTotalUncertainty = uncertainties.map { $0.total }.reduce(0, +) / Double(uncertainties.count)
        
        // Average epistemic uncertainty (model disagreement)
        let avgEpistemicUncertainty = uncertainties.map { $0.epistemic }.reduce(0, +) / Double(uncertainties.count)
        
        // Penalty calculation with higher weight on epistemic uncertainty
        let totalPenalty = 0.6 * avgTotalUncertainty + 0.4 * avgEpistemicUncertainty
        
        return max(0.0, min(1.0, totalPenalty))
    }
    
    // MARK: - Quality Score Calculation
    
    /// Calculate overall prediction quality score
    private func calculateQualityScore(conformalResults: [ConformalResult]) -> Double {
        guard !conformalResults.isEmpty else { return 0.5 }
        
        let reliabilityScores = conformalResults.map { $0.reliability }
        let avgReliability = reliabilityScores.reduce(0, +) / Double(reliabilityScores.count)
        
        // Gate passage rate
        let passedCount = conformalResults.filter { $0.passesGate }.count
        let passageRate = Double(passedCount) / Double(conformalResults.count)
        
        // Risk level assessment
        let lowRiskCount = conformalResults.filter { $0.riskLevel == .low }.count
        let riskScore = Double(lowRiskCount) / Double(conformalResults.count)
        
        // Combine quality metrics
        let qualityScore = 0.4 * avgReliability + 0.4 * passageRate + 0.2 * riskScore
        
        return max(0.0, min(1.0, qualityScore))
    }
    
    // MARK: - Timeframe Score Calculation
    
    /// Calculate timeframe diversity and strength score
    private func calculateTimeframeScore(predictions: [PredictionResult]) -> Double {
        guard !predictions.isEmpty else { return 0.5 }
        
        // Count unique timeframes
        let timeframes = Set(predictions.map { extractTimeframe($0.modelName) })
        let timeframeDiversity = Double(timeframes.count) / 3.0 // Assuming max 3 timeframes
        
        // Calculate weighted confidence by timeframe priority
        var weightedConfidenceSum = 0.0
        var totalWeight = 0.0
        
        for prediction in predictions {
            let timeframe = extractTimeframe(prediction.modelName)
            let weight = getTimeframePriority(timeframe)
            weightedConfidenceSum += prediction.confidence * weight
            totalWeight += weight
        }
        
        let weightedAvgConfidence = totalWeight > 0 ? weightedConfidenceSum / totalWeight : 0.5
        
        // Combine diversity and weighted confidence
        let timeframeScore = 0.3 * timeframeDiversity + 0.7 * weightedAvgConfidence
        
        return max(0.0, min(1.0, timeframeScore))
    }
    
    /// Extract timeframe from model name
    private func extractTimeframe(_ modelName: String) -> String {
        if modelName.contains("5m") {
            return "5m"
        } else if modelName.contains("1h") {
            return "1h"
        } else if modelName.contains("4h") || modelName.contains("4H") {
            return "4h"
        } else {
            return "unknown"
        }
    }
    
    /// Get priority weight for timeframe
    private func getTimeframePriority(_ timeframe: String) -> Double {
        switch timeframe {
        case "4h": return 1.0
        case "1h": return 0.8
        case "5m": return 0.6
        default: return 0.5
        }
    }
    
    // MARK: - Mode Adjustments
    
    /// Apply mode-specific confidence adjustments
    private func applyModeAdjustments(
        rawConfidence: Double,
        modeResult: ModeProcessingResult
    ) -> Double {
        
        var adjustedConfidence = rawConfidence
        
        // Mode-specific scaling
        switch modeResult.mode {
        case .demo, .paper:
            // Normal mode: moderate adjustments
            adjustedConfidence *= 0.95
            
        case .live:
            // Precision mode: conservative adjustments
            adjustedConfidence *= 0.85
            
            // Additional penalty if not all models agree
            if modeResult.qualifiedPredictions.count < 3 {
                let penalty = 0.1 * Double(3 - modeResult.qualifiedPredictions.count)
                adjustedConfidence *= (1.0 - penalty)
            }
        }
        
        // Consensus strength adjustment
        if modeResult.consensusDetails.contains("unanimous") {
            adjustedConfidence *= 1.05 // Bonus for unanimous agreement
        } else if modeResult.consensusDetails.contains("majority") {
            adjustedConfidence *= 0.95 // Slight penalty for majority only
        }
        
        return max(0.0, min(1.0, adjustedConfidence))
    }
    
    // MARK: - Confidence Mapping
    
    /// Map confidence to target range with realistic scaling
    private func mapToTargetRange(
        confidence: Double,
        targetRange: ClosedRange<Double>
    ) -> Double {
        
        // Apply sigmoid-like mapping for realistic distribution
        let sigmoidInput = (confidence - 0.5) * 6.0 // Scale input
        let sigmoidOutput = 1.0 / (1.0 + exp(-sigmoidInput))
        
        // Map to target range
        let mappedConfidence = targetRange.lowerBound + 
            sigmoidOutput * (targetRange.upperBound - targetRange.lowerBound)
        
        return max(targetRange.lowerBound, min(targetRange.upperBound, mappedConfidence))
    }
    
    // MARK: - Components Breakdown
    
    /// Create detailed breakdown of confidence components
    private func createComponentsBreakdown(
        agreement: Double,
        uncertainty: Double,
        quality: Double,
        timeframe: Double
    ) -> ConfidenceComponents {
        
        return ConfidenceComponents(
            agreementContribution: agreement * agreementWeight,
            uncertaintyContribution: (1.0 - uncertainty) * uncertaintyWeight,
            qualityContribution: quality * qualityWeight,
            timeframeContribution: timeframe * timeframeWeight,
            weights: ComponentWeights(
                agreement: agreementWeight,
                uncertainty: uncertaintyWeight,
                quality: qualityWeight,
                timeframe: timeframeWeight
            )
        )
    }
}

// MARK: - Supporting Data Structures

public struct MetaConfidenceResult {
    public let finalConfidence: Double
    public let agreementScore: Double
    public let uncertaintyPenalty: Double
    public let qualityScore: Double
    public let timeframeScore: Double
    public let rawMetaConfidence: Double
    public let modeAdjustedConfidence: Double
    public let components: ConfidenceComponents
    
    public var summary: String {
        return """
        Meta-Confidence: \(String(format: "%.1f%%", finalConfidence * 100))
        ├─ Agreement: \(String(format: "%.1f%%", agreementScore * 100))
        ├─ Uncertainty: \(String(format: "%.1f%%", (1.0 - uncertaintyPenalty) * 100))
        ├─ Quality: \(String(format: "%.1f%%", qualityScore * 100))
        └─ Timeframe: \(String(format: "%.1f%%", timeframeScore * 100))
        """
    }
}

public struct ConfidenceComponents {
    public let agreementContribution: Double
    public let uncertaintyContribution: Double
    public let qualityContribution: Double
    public let timeframeContribution: Double
    public let weights: ComponentWeights
}

public struct ComponentWeights {
    public let agreement: Double
    public let uncertainty: Double
    public let quality: Double
    public let timeframe: Double
}