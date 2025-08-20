import Foundation

// MARK: - Performance Metrics
public struct PerformanceMetrics: Codable, Sendable {
    public let totalTrades: Int
    public let winningTrades: Int
    public let losingTrades: Int
    public let winRate: Double
    public let averageWin: Double
    public let averageLoss: Double
    public let profitFactor: Double
    public let maxDrawdown: Double
    public let maxDrawdownPercent: Double
    public let totalReturn: Double
    public let totalReturnPercent: Double
    public let sharpeRatio: Double
    public let sortinoRatio: Double
    public let calmarRatio: Double
    public let averageTradeReturn: Double
    public let averageTradeReturnPercent: Double
    public let bestTrade: Double
    public let worstTrade: Double
    public let consecutiveWins: Int
    public let consecutiveLosses: Int
    public let averageHoldingPeriod: TimeInterval
    public let volatility: Double
    public let beta: Double
    public let alpha: Double
    public let informationRatio: Double
    public let treynorRatio: Double
    public let jensenAlpha: Double
    public let trackingError: Double
    public let upCaptureRatio: Double
    public let downCaptureRatio: Double
    public let battingAverage: Double
    public let gainToLossRatio: Double
    public let expectancy: Double
    public let kellyPercentage: Double
    public let optimalF: Double
    public let recoveryFactor: Double
    public let payoffRatio: Double
    public let riskAdjustedReturn: Double
    public let ulcerIndex: Double
    public let martinRatio: Double
    public let burkeRatio: Double
    public let modifiedSharpeRatio: Double
    public let sterlingRatio: Double
    public let kestnerRatio: Double
    
    public init(
        totalTrades: Int = 0,
        winningTrades: Int = 0,
        losingTrades: Int = 0,
        winRate: Double = 0.0,
        averageWin: Double = 0.0,
        averageLoss: Double = 0.0,
        profitFactor: Double = 0.0,
        maxDrawdown: Double = 0.0,
        maxDrawdownPercent: Double = 0.0,
        totalReturn: Double = 0.0,
        totalReturnPercent: Double = 0.0,
        sharpeRatio: Double = 0.0,
        sortinoRatio: Double = 0.0,
        calmarRatio: Double = 0.0,
        averageTradeReturn: Double = 0.0,
        averageTradeReturnPercent: Double = 0.0,
        bestTrade: Double = 0.0,
        worstTrade: Double = 0.0,
        consecutiveWins: Int = 0,
        consecutiveLosses: Int = 0,
        averageHoldingPeriod: TimeInterval = 0.0,
        volatility: Double = 0.0,
        beta: Double = 0.0,
        alpha: Double = 0.0,
        informationRatio: Double = 0.0,
        treynorRatio: Double = 0.0,
        jensenAlpha: Double = 0.0,
        trackingError: Double = 0.0,
        upCaptureRatio: Double = 0.0,
        downCaptureRatio: Double = 0.0,
        battingAverage: Double = 0.0,
        gainToLossRatio: Double = 0.0,
        expectancy: Double = 0.0,
        kellyPercentage: Double = 0.0,
        optimalF: Double = 0.0,
        recoveryFactor: Double = 0.0,
        payoffRatio: Double = 0.0,
        riskAdjustedReturn: Double = 0.0,
        ulcerIndex: Double = 0.0,
        martinRatio: Double = 0.0,
        burkeRatio: Double = 0.0,
        modifiedSharpeRatio: Double = 0.0,
        sterlingRatio: Double = 0.0,
        kestnerRatio: Double = 0.0
    ) {
        self.totalTrades = totalTrades
        self.winningTrades = winningTrades
        self.losingTrades = losingTrades
        self.winRate = winRate
        self.averageWin = averageWin
        self.averageLoss = averageLoss
        self.profitFactor = profitFactor
        self.maxDrawdown = maxDrawdown
        self.maxDrawdownPercent = maxDrawdownPercent
        self.totalReturn = totalReturn
        self.totalReturnPercent = totalReturnPercent
        self.sharpeRatio = sharpeRatio
        self.sortinoRatio = sortinoRatio
        self.calmarRatio = calmarRatio
        self.averageTradeReturn = averageTradeReturn
        self.averageTradeReturnPercent = averageTradeReturnPercent
        self.bestTrade = bestTrade
        self.worstTrade = worstTrade
        self.consecutiveWins = consecutiveWins
        self.consecutiveLosses = consecutiveLosses
        self.averageHoldingPeriod = averageHoldingPeriod
        self.volatility = volatility
        self.beta = beta
        self.alpha = alpha
        self.informationRatio = informationRatio
        self.treynorRatio = treynorRatio
        self.jensenAlpha = jensenAlpha
        self.trackingError = trackingError
        self.upCaptureRatio = upCaptureRatio
        self.downCaptureRatio = downCaptureRatio
        self.battingAverage = battingAverage
        self.gainToLossRatio = gainToLossRatio
        self.expectancy = expectancy
        self.kellyPercentage = kellyPercentage
        self.optimalF = optimalF
        self.recoveryFactor = recoveryFactor
        self.payoffRatio = payoffRatio
        self.riskAdjustedReturn = riskAdjustedReturn
        self.ulcerIndex = ulcerIndex
        self.martinRatio = martinRatio
        self.burkeRatio = burkeRatio
        self.modifiedSharpeRatio = modifiedSharpeRatio
        self.sterlingRatio = sterlingRatio
        self.kestnerRatio = kestnerRatio
    }
    
    // MARK: - Computed Properties
    public var winRatePercentage: String {
        return String(format: "%.1f%%", winRate * 100)
    }
    
    public var profitFactorFormatted: String {
        return String(format: "%.2f", profitFactor)
    }
    
    public var maxDrawdownFormatted: String {
        return String(format: "%.2f%%", maxDrawdownPercent * 100)
    }
    
    public var sharpeRatioFormatted: String {
        return String(format: "%.2f", sharpeRatio)
    }
    
    public var totalReturnFormatted: String {
        return String(format: "%.2f%%", totalReturnPercent * 100)
    }
    
    public var expectancyFormatted: String {
        return String(format: "%.2f", expectancy)
    }
    
    // MARK: - Risk Assessment
    public var riskLevel: RiskLevel {
        if maxDrawdownPercent > 0.3 { return .high }
        if maxDrawdownPercent > 0.15 { return .medium }
        return .low
    }
    
    public var performanceGrade: PerformanceGrade {
        let score = calculatePerformanceScore()
        if score >= 80 { return .excellent }
        if score >= 60 { return .good }
        if score >= 40 { return .average }
        if score >= 20 { return .poor }
        return .terrible
    }
    
    private func calculatePerformanceScore() -> Double {
        var score = 0.0
        
        // Win rate component (0-25 points)
        score += min(winRate * 25, 25)
        
        // Profit factor component (0-25 points)
        score += min(profitFactor * 5, 25)
        
        // Sharpe ratio component (0-25 points)
        score += min(max(sharpeRatio, 0) * 12.5, 25)
        
        // Drawdown component (0-25 points, inverted)
        score += max(25 - (maxDrawdownPercent * 100), 0)
        
        return score
    }
}

// MARK: - Supporting Enums
public enum RiskLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    public var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        }
    }
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

public enum PerformanceGrade: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case average = "average"
    case poor = "poor"
    case terrible = "terrible"
    
    public var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .average: return "Average"
        case .poor: return "Poor"
        case .terrible: return "Terrible"
        }
    }
    
    public var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .average: return "orange"
        case .poor: return "red"
        case .terrible: return "purple"
        }
    }
    
    public var emoji: String {
        switch self {
        case .excellent: return "🏆"
        case .good: return "👍"
        case .average: return "👌"
        case .poor: return "👎"
        case .terrible: return "💀"
        }
    }
}