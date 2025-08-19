import Foundation
import SwiftUI
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "UIAdapter")

// MARK: - UI Adapter for Production Signal Display

/// Enforces UI display rules and confidence capping for production system
public class UIAdapter {
    
    // MARK: - Display Configuration
    
    private let maxDisplayConfidence: Double = 0.9 // Never show above 90%
    private let minDisplayConfidence: Double = 0.5 // Never show below 50%
    private let holdSignalThreshold: Double = 0.6  // Minimum for showing HOLD
    
    public init() {}
    
    // MARK: - Main Interface
    
    /// Adapt production prediction for UI display
    public func adaptForDisplay(
        metaConfidence: MetaConfidenceResult,
        modeResult: ModeProcessingResult,
        conformalResults: [ConformalResult]
    ) -> UIDisplayResult {
        
        // Determine final signal for display
        let displaySignal = determineDisplaySignal(
            consensusSignal: modeResult.consensusSignal,
            confidence: metaConfidence.finalConfidence,
            shouldExecute: modeResult.shouldExecute
        )
        
        // Cap confidence according to UI rules
        let cappedConfidence = capConfidenceForDisplay(metaConfidence.finalConfidence)
        
        // Generate appropriate display text
        let displayText = generateDisplayText(
            signal: displaySignal,
            confidence: cappedConfidence,
            mode: modeResult.mode
        )
        
        // Determine color coding
        let colorCoding = determineColorCoding(
            signal: displaySignal,
            confidence: cappedConfidence,
            riskLevel: assessOverallRisk(conformalResults: conformalResults)
        )
        
        // Create detailed information for advanced users
        let detailedInfo = generateDetailedInfo(
            metaConfidence: metaConfidence,
            modeResult: modeResult,
            conformalResults: conformalResults
        )
        
        // Generate confidence display string
        let confidenceDisplay = generateConfidenceDisplay(
            confidence: cappedConfidence,
            signal: displaySignal
        )
        
        return UIDisplayResult(
            signal: displaySignal,
            displayText: displayText,
            confidence: cappedConfidence,
            confidenceDisplay: confidenceDisplay,
            colorCoding: colorCoding,
            detailedInfo: detailedInfo,
            shouldShowDetails: shouldShowDetailedInfo(modeResult: modeResult),
            timestamp: Date()
        )
    }
    
    // MARK: - Signal Determination
    
    /// Determine final signal for UI display with conservative rules
    private func determineDisplaySignal(
        consensusSignal: String,
        confidence: Double,
        shouldExecute: Bool
    ) -> String {
        
        // Override weak signals with HOLD
        if consensusSignal == "HOLD" || !shouldExecute {
            return "HOLD"
        }
        
        // Require minimum confidence for BUY/SELL display
        if consensusSignal == "BUY" || consensusSignal == "SELL" {
            if confidence >= minDisplayConfidence {
                return consensusSignal
            } else {
                return "HOLD"
            }
        }
        
        return "HOLD" // Default fallback
    }
    
    // MARK: - Confidence Capping
    
    /// Cap confidence for realistic display (50% - 90% range)
    private func capConfidenceForDisplay(_ confidence: Double) -> Double {
        return max(minDisplayConfidence, min(maxDisplayConfidence, confidence))
    }
    
    // MARK: - Display Text Generation
    
    /// Generate user-friendly display text
    private func generateDisplayText(
        signal: String,
        confidence: Double,
        mode: TradingMode
    ) -> String {
        
        let modePrefix = mode == .live ? "[PRECISION]" : ""
        
        switch signal {
        case "BUY":
            if confidence >= 0.8 {
                return "\(modePrefix) Strong BUY signal"
            } else if confidence >= 0.7 {
                return "\(modePrefix) BUY signal"
            } else {
                return "\(modePrefix) Weak BUY signal"
            }
            
        case "SELL":
            if confidence >= 0.8 {
                return "\(modePrefix) Strong SELL signal"
            } else if confidence >= 0.7 {
                return "\(modePrefix) SELL signal"
            } else {
                return "\(modePrefix) Weak SELL signal"
            }
            
        case "HOLD":
            if confidence >= holdSignalThreshold {
                return "\(modePrefix) HOLD / Neutral"
            } else {
                return "No clear signal right now"
            }
            
        default:
            return "No clear signal right now"
        }
    }
    
    // MARK: - Color Coding
    
    /// Determine appropriate color coding for signal
    private func determineColorCoding(
        signal: String,
        confidence: Double,
        riskLevel: RiskLevel
    ) -> UIColorCoding {
        
        let baseColor: Color
        let intensity: Double
        
        switch signal {
        case "BUY":
            baseColor = .green
            intensity = min(1.0, confidence * 1.2) // Slightly boost intensity
            
        case "SELL":
            baseColor = .red
            intensity = min(1.0, confidence * 1.2)
            
        case "HOLD":
            baseColor = .orange
            intensity = max(0.5, confidence) // Ensure visible for HOLD
            
        default:
            baseColor = .secondary
            intensity = 0.5
        }
        
        // Adjust for risk level
        let riskAdjustment: Double
        switch riskLevel {
        case .low: riskAdjustment = 1.0
        case .medium: riskAdjustment = 0.8
        case .high: riskAdjustment = 0.6
        }
        
        let finalIntensity = intensity * riskAdjustment
        
        return UIColorCoding(
            primaryColor: baseColor,
            intensity: finalIntensity,
            shouldPulse: signal != "HOLD" && confidence >= 0.8,
            riskIndicator: riskLevel != .low
        )
    }
    
    // MARK: - Detailed Information
    
    /// Generate detailed information for advanced display
    private func generateDetailedInfo(
        metaConfidence: MetaConfidenceResult,
        modeResult: ModeProcessingResult,
        conformalResults: [ConformalResult]
    ) -> DetailedInfo {
        
        let modelAgreement = generateModelAgreementSummary(modeResult: modeResult)
        let uncertaintyAnalysis = generateUncertaintyAnalysis(metaConfidence: metaConfidence)
        let riskAssessment = generateRiskAssessment(conformalResults: conformalResults)
        let qualityMetrics = generateQualityMetrics(metaConfidence: metaConfidence)
        
        return DetailedInfo(
            modelAgreement: modelAgreement,
            uncertaintyAnalysis: uncertaintyAnalysis,
            riskAssessment: riskAssessment,
            qualityMetrics: qualityMetrics,
            consensusDetails: modeResult.consensusDetails,
            confidenceBreakdown: metaConfidence.summary
        )
    }
    
    /// Generate model agreement summary
    private func generateModelAgreementSummary(modeResult: ModeProcessingResult) -> String {
        let qualified = modeResult.qualifiedPredictions.count
        let total = 3 // Assuming 3 timeframes maximum
        
        let signals = modeResult.qualifiedPredictions.map { $0.prediction.signal }
        let uniqueSignals = Set(signals).count
        
        if uniqueSignals == 1 {
            return "All \(qualified)/\(total) models agree"
        } else {
            return "\(qualified)/\(total) models qualified, \(uniqueSignals) different signals"
        }
    }
    
    /// Generate uncertainty analysis
    private func generateUncertaintyAnalysis(metaConfidence: MetaConfidenceResult) -> String {
        let uncertainty = metaConfidence.uncertaintyPenalty
        
        if uncertainty <= 0.2 {
            return "Low uncertainty (high reliability)"
        } else if uncertainty <= 0.4 {
            return "Moderate uncertainty"
        } else {
            return "High uncertainty (low reliability)"
        }
    }
    
    /// Generate risk assessment
    private func generateRiskAssessment(conformalResults: [ConformalResult]) -> String {
        let overallRisk = assessOverallRisk(conformalResults: conformalResults)
        let passedGates = conformalResults.filter { $0.passesGate }.count
        let total = conformalResults.count
        
        return "\(overallRisk.displayName) - \(passedGates)/\(total) gates passed"
    }
    
    /// Generate quality metrics summary
    private func generateQualityMetrics(metaConfidence: MetaConfidenceResult) -> String {
        let quality = metaConfidence.qualityScore
        let agreement = metaConfidence.agreementScore
        
        return "Quality: \(String(format: "%.1f%%", quality * 100)), Agreement: \(String(format: "%.1f%%", agreement * 100))"
    }
    
    // MARK: - Confidence Display
    
    /// Generate confidence percentage display
    private func generateConfidenceDisplay(confidence: Double, signal: String) -> String {
        let percentage = Int(confidence * 100)
        
        switch signal {
        case "BUY", "SELL":
            return "\(percentage)% confidence"
        case "HOLD":
            if confidence >= holdSignalThreshold {
                return "Neutral (\(percentage)%)"
            } else {
                return "Monitoring market conditions"
            }
        default:
            return "Monitoring market conditions"
        }
    }
    
    // MARK: - Utility Functions
    
    /// Assess overall risk from conformal results
    private func assessOverallRisk(conformalResults: [ConformalResult]) -> RiskLevel {
        guard !conformalResults.isEmpty else { return .medium }
        
        let riskLevels = conformalResults.map { $0.riskLevel }
        let highRiskCount = riskLevels.filter { $0 == .high }.count
        let lowRiskCount = riskLevels.filter { $0 == .low }.count
        
        if highRiskCount > conformalResults.count / 2 {
            return .high
        } else if lowRiskCount > conformalResults.count / 2 {
            return .low
        } else {
            return .medium
        }
    }
    
    /// Determine if detailed info should be shown
    private func shouldShowDetailedInfo(modeResult: ModeProcessingResult) -> Bool {
        // Show details for precision mode or when there are qualified predictions
        return modeResult.mode == .live || !modeResult.qualifiedPredictions.isEmpty
    }
}

// MARK: - Supporting Data Structures

public struct UIDisplayResult {
    public let signal: String
    public let displayText: String
    public let confidence: Double
    public let confidenceDisplay: String
    public let colorCoding: UIColorCoding
    public let detailedInfo: DetailedInfo
    public let shouldShowDetails: Bool
    public let timestamp: Date
}

public struct UIColorCoding {
    public let primaryColor: Color
    public let intensity: Double
    public let shouldPulse: Bool
    public let riskIndicator: Bool
}

public struct DetailedInfo {
    public let modelAgreement: String
    public let uncertaintyAnalysis: String
    public let riskAssessment: String
    public let qualityMetrics: String
    public let consensusDetails: String
    public let confidenceBreakdown: String
}