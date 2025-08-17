import Foundation
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "ConformalGate")

// MARK: - Conformal Prediction Gate

/// Risk-aware execution filtering using conformal prediction intervals
public class ConformalGate {
    
    // MARK: - Properties
    
    private let alpha: Double // Significance level (1-α confidence)
    private let calibrationData: [(predicted: Double, actual: Double)]
    private var conformityScores: [Double] = []
    
    // MARK: - Initialization
    
    public init(alpha: Double = 0.1, calibrationData: [(Double, Double)] = []) {
        self.alpha = alpha // 90% confidence intervals by default
        self.calibrationData = calibrationData.isEmpty ? generateSampleCalibrationData() : calibrationData
        self.conformityScores = calculateConformityScores()
    }
    
    // MARK: - Main Interface
    
    /// Apply conformal prediction to determine if prediction should pass through gate
    public func evaluate(prediction: PredictionResult, uncertainty: UncertaintyResult) -> ConformalResult {
        let predictionInterval = calculatePredictionInterval(
            pointEstimate: prediction.confidence,
            uncertainty: uncertainty
        )
        
        let passesGate = shouldPassGate(
            prediction: prediction,
            interval: predictionInterval,
            uncertainty: uncertainty
        )
        
        let riskLevel = assessRiskLevel(
            prediction: prediction,
            interval: predictionInterval,
            uncertainty: uncertainty
        )
        
        return ConformalResult(
            prediction: prediction,
            predictionInterval: predictionInterval,
            passesGate: passesGate,
            riskLevel: riskLevel,
            conformityScore: calculateConformityScore(prediction.confidence),
            reliability: calculateReliability(interval: predictionInterval)
        )
    }
    
    /// Batch evaluation for multiple predictions
    public func evaluateBatch(predictions: [PredictionResult], uncertainties: [UncertaintyResult]) -> [ConformalResult] {
        guard predictions.count == uncertainties.count else {
            logger.error("Predictions and uncertainties count mismatch")
            return []
        }
        
        return zip(predictions, uncertainties).map { prediction, uncertainty in
            evaluate(prediction: prediction, uncertainty: uncertainty)
        }
    }
    
    // MARK: - Prediction Intervals
    
    /// Calculate conformal prediction interval
    private func calculatePredictionInterval(pointEstimate: Double, uncertainty: UncertaintyResult) -> ClosedRange<Double> {
        let quantileIndex = Int(ceil((Double(conformityScores.count + 1)) * (1 - alpha))) - 1
        let quantile = conformityScores.sorted()[min(quantileIndex, conformityScores.count - 1)]
        
        // Adjust interval width based on uncertainty
        let baseWidth = quantile
        let uncertaintyAdjustment = uncertainty.total * 0.5
        let adjustedWidth = baseWidth + uncertaintyAdjustment
        
        let lower = max(0.0, pointEstimate - adjustedWidth)
        let upper = min(1.0, pointEstimate + adjustedWidth)
        
        return lower...upper
    }
    
    /// Calculate conformity scores from calibration data
    private func calculateConformityScores() -> [Double] {
        return calibrationData.map { data in
            abs(data.predicted - data.actual)
        }
    }
    
    /// Calculate conformity score for new prediction
    private func calculateConformityScore(_ prediction: Double) -> Double {
        // In production, this would use actual outcomes
        // For now, simulate based on historical variance
        let historicalVariance = conformityScores.isEmpty ? 0.1 : 
            conformityScores.map { pow($0, 2) }.reduce(0, +) / Double(conformityScores.count)
        
        return sqrt(historicalVariance)
    }
    
    // MARK: - Gate Logic
    
    /// Determine if prediction should pass through the gate
    private func shouldPassGate(
        prediction: PredictionResult,
        interval: ClosedRange<Double>,
        uncertainty: UncertaintyResult
    ) -> Bool {
        // Multiple criteria for gate passage
        
        // 1. Interval width criterion (narrower intervals are more reliable)
        let intervalWidth = interval.upperBound - interval.lowerBound
        let widthThreshold: Double = 0.4 // Maximum allowed interval width
        
        // 2. Uncertainty criterion
        let uncertaintyThreshold: Double = 0.35
        
        // 3. Confidence criterion (minimum confidence for passage)
        let confidenceThreshold: Double = 0.55
        
        // 4. Signal strength criterion (avoid weak HOLD signals)
        let signalStrengthOK = prediction.signal != "HOLD" || prediction.confidence >= 0.6
        
        let criteria = [
            intervalWidth <= widthThreshold,
            uncertainty.total <= uncertaintyThreshold,
            prediction.confidence >= confidenceThreshold,
            signalStrengthOK
        ]
        
        // Gate passes if majority of criteria are met
        let passedCriteria = criteria.filter { $0 }.count
        let shouldPass = passedCriteria >= 3 // At least 3 out of 4 criteria
        
        if !shouldPass {
            logger.info("Gate blocked: width=\(String(format: "%.3f", intervalWidth)), uncertainty=\(String(format: "%.3f", uncertainty.total)), confidence=\(String(format: "%.3f", prediction.confidence)), signal=\(prediction.signal)")
        }
        
        return shouldPass
    }
    
    /// Assess risk level of prediction
    private func assessRiskLevel(
        prediction: PredictionResult,
        interval: ClosedRange<Double>,
        uncertainty: UncertaintyResult
    ) -> RiskLevel {
        let intervalWidth = interval.upperBound - interval.lowerBound
        let totalUncertainty = uncertainty.total
        
        // Combined risk score
        let riskScore = 0.6 * totalUncertainty + 0.4 * intervalWidth
        
        if riskScore <= 0.2 {
            return .low
        } else if riskScore <= 0.4 {
            return .moderate
        } else {
            return .high
        }
    }
    
    /// Calculate reliability metric from interval
    private func calculateReliability(interval: ClosedRange<Double>) -> Double {
        let width = interval.upperBound - interval.lowerBound
        // Narrower intervals are more reliable
        return max(0.0, 1.0 - width)
    }
    
    // MARK: - Calibration Data
    
    /// Generate sample calibration data for initial setup
    private func generateSampleCalibrationData() -> [(Double, Double)] {
        return [
            (0.55, 0.52), (0.60, 0.58), (0.65, 0.62), (0.70, 0.68),
            (0.75, 0.73), (0.80, 0.77), (0.85, 0.82), (0.90, 0.88),
            (0.58, 0.55), (0.62, 0.60), (0.67, 0.64), (0.72, 0.70),
            (0.77, 0.75), (0.82, 0.79), (0.87, 0.84), (0.92, 0.89)
        ]
    }
    
    // MARK: - Statistics and Monitoring
    
    /// Get gate statistics for monitoring
    public func getGateStatistics() -> GateStatistics {
        let recentResults = getRecentResults() // Would be stored in production
        let totalEvaluations = recentResults.count
        let passedEvaluations = recentResults.filter { $0.passesGate }.count
        let passRate = totalEvaluations > 0 ? Double(passedEvaluations) / Double(totalEvaluations) : 0.0
        
        let averageIntervalWidth = recentResults.isEmpty ? 0.0 :
            recentResults.map { $0.predictionInterval.upperBound - $0.predictionInterval.lowerBound }
                        .reduce(0, +) / Double(recentResults.count)
        
        return GateStatistics(
            totalEvaluations: totalEvaluations,
            passedEvaluations: passedEvaluations,
            passRate: passRate,
            averageIntervalWidth: averageIntervalWidth,
            alpha: alpha
        )
    }
    
    private func getRecentResults() -> [ConformalResult] {
        // In production, this would retrieve recent results from storage
        return []
    }
}

// MARK: - Supporting Data Structures

public struct ConformalResult {
    public let prediction: PredictionResult
    public let predictionInterval: ClosedRange<Double>
    public let passesGate: Bool
    public let riskLevel: RiskLevel
    public let conformityScore: Double
    public let reliability: Double
    
    public init(
        prediction: PredictionResult,
        predictionInterval: ClosedRange<Double>,
        passesGate: Bool,
        riskLevel: RiskLevel,
        conformityScore: Double,
        reliability: Double
    ) {
        self.prediction = prediction
        self.predictionInterval = predictionInterval
        self.passesGate = passesGate
        self.riskLevel = riskLevel
        self.conformityScore = conformityScore
        self.reliability = reliability
    }
}

public struct GateStatistics {
    public let totalEvaluations: Int
    public let passedEvaluations: Int
    public let passRate: Double
    public let averageIntervalWidth: Double
    public let alpha: Double
    
    public init(
        totalEvaluations: Int,
        passedEvaluations: Int,
        passRate: Double,
        averageIntervalWidth: Double,
        alpha: Double
    ) {
        self.totalEvaluations = totalEvaluations
        self.passedEvaluations = passedEvaluations
        self.passRate = passRate
        self.averageIntervalWidth = averageIntervalWidth
        self.alpha = alpha
    }
}

public enum RiskLevel {
    case low
    case moderate
    case high
    
    public var description: String {
        switch self {
        case .low: return "Low Risk"
        case .moderate: return "Moderate Risk"  
        case .high: return "High Risk"
        }
    }
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .moderate: return "orange"
        case .high: return "red"
        }
    }
}