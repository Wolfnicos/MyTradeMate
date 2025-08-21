import Foundation
import Accelerate

// MARK: - Calibration Utilities for Production AI System

public class CalibrationUtils {
    
    // MARK: - Temperature Scaling
    
    /// Calibrates raw model outputs using temperature scaling
    /// Maps raw logits/probabilities to calibrated probabilities in [50%, 90%] range
    public static func temperatureScale(
        rawConfidence: Double,
        temperature: Double = 1.5,
        targetRange: ClosedRange<Double> = 0.5...0.9
    ) -> Double {
        // Apply temperature scaling: p_calibrated = σ(z/T) where z is logit
        // Convert confidence to logit space for scaling
        let logit = logitFromProbability(rawConfidence)
        let scaledLogit = logit / temperature
        let calibratedProb = probabilityFromLogit(scaledLogit)
        
        // Map to target range [50%, 90%]
        let mappedProb = targetRange.lowerBound + calibratedProb * (targetRange.upperBound - targetRange.lowerBound)
        
        return clamp(mappedProb, to: targetRange)
    }
    
    /// Convert probability to logit space
    private static func logitFromProbability(_ p: Double) -> Double {
        let clampedP = clamp(p, to: 0.01...0.99) // Avoid log(0)
        return log(clampedP / (1.0 - clampedP))
    }
    
    /// Convert logit to probability space
    private static func probabilityFromLogit(_ logit: Double) -> Double {
        let exp_logit = exp(logit)
        return exp_logit / (1.0 + exp_logit)
    }
    
    // MARK: - Isotonic Regression
    
    /// Calibrates probabilities using isotonic regression
    /// Ensures monotonic relationship between raw and calibrated probabilities
    public static func isotonicCalibration(
        rawConfidences: [Double],
        targetProbabilities: [Double]
    ) -> (Double) -> Double {
        guard rawConfidences.count == targetProbabilities.count,
              rawConfidences.count >= 2 else {
            // Fallback to identity function
            return { x in clamp(x, to: 0.5...0.9) }
        }
        
        // Sort by raw confidence
        let sortedPairs = zip(rawConfidences, targetProbabilities)
            .sorted { $0.0 < $1.0 }
        
        let sortedRaw = sortedPairs.map { $0.0 }
        let sortedTarget = sortedPairs.map { $0.1 }
        
        // Apply isotonic regression (simplified version)
        let calibratedTargets = applyIsotonicRegression(sortedTarget)
        
        // Return interpolation function
        return { rawValue in
            interpolateCalibrated(
                rawValue: rawValue,
                rawPoints: sortedRaw,
                calibratedPoints: calibratedTargets
            )
        }
    }
    
    /// Apply isotonic regression to ensure monotonicity
    private static func applyIsotonicRegression(_ values: [Double]) -> [Double] {
        var result = values
        let n = result.count
        
        // Pool adjacent violators algorithm (simplified)
        for i in 1..<n {
            if result[i] < result[i-1] {
                // Find the extent of violation
                var j = i
                var sum = result[i]
                var count = 1
                
                while j > 0 && result[j-1] > sum/Double(count) {
                    j -= 1
                    sum += result[j]
                    count += 1
                }
                
                // Set all values in violation range to their average
                let average = sum / Double(count)
                for k in j...i {
                    result[k] = average
                }
            }
        }
        
        return result
    }
    
    /// Interpolate calibrated probability for a given raw value
    private static func interpolateCalibrated(
        rawValue: Double,
        rawPoints: [Double],
        calibratedPoints: [Double]
    ) -> Double {
        // Clamp to bounds
        guard let firstRawPoint = rawPoints.first,
              let firstCalibratedPoint = calibratedPoints.first else { return 0.5 }
        
        if rawValue <= firstRawPoint {
            return clamp(firstCalibratedPoint, to: 0.5...0.9)
        }
        guard let lastRawPoint = rawPoints.last,
              let lastCalibratedPoint = calibratedPoints.last else { return 0.5 }
        
        if rawValue >= lastRawPoint {
            return clamp(lastCalibratedPoint, to: 0.5...0.9)
        }
        
        // Find interpolation points
        for i in 1..<rawPoints.count {
            if rawValue <= rawPoints[i] {
                let x0 = rawPoints[i-1]
                let x1 = rawPoints[i]
                let y0 = calibratedPoints[i-1]
                let y1 = calibratedPoints[i]
                
                // Linear interpolation
                let t = (rawValue - x0) / (x1 - x0)
                let interpolated = y0 + t * (y1 - y0)
                return clamp(interpolated, to: 0.5...0.9)
            }
        }
        
        guard let lastCalibratedPoint = calibratedPoints.last else { return 0.5 }
        return clamp(lastCalibratedPoint, to: 0.5...0.9)
    }
    
    // MARK: - Utility Functions
    
    /// Clamp value to specified range
    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        return max(range.lowerBound, min(range.upperBound, value))
    }
    
    /// Generate sample calibration data for demonstration
    public static func generateSampleCalibrationData() -> ([Double], [Double]) {
        let rawConfidences = [0.1, 0.3, 0.5, 0.7, 0.9, 0.95, 0.99]
        let targetProbabilities = [0.52, 0.58, 0.65, 0.75, 0.85, 0.88, 0.90]
        return (rawConfidences, targetProbabilities)
    }
}

// MARK: - Calibration Evaluator

public class AICalibrationEvaluator {
    private let temperatureScaler: (Double) -> Double
    private let isotonicCalibrator: (Double) -> Double
    
    public init() {
        // Initialize with sample data (in production, use historical model performance)
        let (rawData, targetData) = CalibrationUtils.generateSampleCalibrationData()
        
        self.temperatureScaler = { raw in
            CalibrationUtils.temperatureScale(rawConfidence: raw)
        }
        
        self.isotonicCalibrator = CalibrationUtils.isotonicCalibration(
            rawConfidences: rawData,
            targetProbabilities: targetData
        )
    }
    
    /// Calibrate raw model confidence using both methods and return Direct Fusion result
    public func calibrate(rawConfidence: Double, method: CalibrationMethod = .directFusion) -> Double {
        switch method {
        case .temperature:
            return temperatureScaler(rawConfidence)
        case .isotonic:
            return isotonicCalibrator(rawConfidence)
        case .directFusion:
            // Weighted combination of both methods
            let tempScore = temperatureScaler(rawConfidence)
            let isoScore = isotonicCalibrator(rawConfidence)
            return 0.6 * tempScore + 0.4 * isoScore // Temperature scaling weighted higher
        }
    }
}

// MARK: - Supporting Enums

public enum CalibrationMethod: String, CaseIterable {
    case temperature = "temperature"
    case isotonic = "isotonic"
    case directFusion = "directfusion"
}