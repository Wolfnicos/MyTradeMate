import Foundation
import Combine

/// Manages trading risks and position sizing
@MainActor
final class RiskManager: ObservableObject {
    static let shared = RiskManager()
    
    @Published var maxRiskPerTrade: Double = 0.02 // 2% of portfolio
    @Published var maxDailyRisk: Double = 0.06 // 6% of portfolio per day
    @Published var maxPortfolioRisk: Double = 0.20 // 20% of portfolio at risk
    @Published var maxPositionSize: Double = 0.10 // 10% of portfolio per position
    @Published var stopLossPercentage: Double = 0.03 // 3% stop loss
    @Published var takeProfitRatio: Double = 2.0 // 2:1 reward to risk ratio
    
    @Published var currentDailyRisk: Double = 0.0
    @Published var currentPortfolioRisk: Double = 0.0
    @Published var activePositions: [RiskPosition] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadConfiguration()
        setupRiskMonitoring()
    }
    
    // MARK: - Position Sizing
    
    func calculatePositionSize(
        accountBalance: Double,
        entryPrice: Double,
        stopLossPrice: Double,
        riskAmount: Double? = nil
    ) -> PositionSizeResult {
        
        let riskPerTrade = riskAmount ?? (accountBalance * maxRiskPerTrade)
        let priceRisk = abs(entryPrice - stopLossPrice)
        
        guard priceRisk > 0 else {
            return PositionSizeResult(
                size: 0,
                riskAmount: 0,
                reason: "Invalid stop loss price"
            )
        }
        
        // Calculate base position size
        let baseSize = riskPerTrade / priceRisk
        
        // Apply maximum position size constraint
        let maxSizeByPortfolio = accountBalance * maxPositionSize / entryPrice
        let constrainedSize = min(baseSize, maxSizeByPortfolio)
        
        // Check daily risk limit
        let positionRisk = constrainedSize * priceRisk
        if currentDailyRisk + positionRisk > accountBalance * maxDailyRisk {
            let remainingDailyRisk = max(0, accountBalance * maxDailyRisk - currentDailyRisk)
            let adjustedSize = remainingDailyRisk / priceRisk
            
            return PositionSizeResult(
                size: adjustedSize,
                riskAmount: adjustedSize * priceRisk,
                reason: adjustedSize < constrainedSize ? "Limited by daily risk" : "Optimal size"
            )
        }
        
        // Check portfolio risk limit
        if currentPortfolioRisk + positionRisk > accountBalance * maxPortfolioRisk {
            let remainingPortfolioRisk = max(0, accountBalance * maxPortfolioRisk - currentPortfolioRisk)
            let adjustedSize = remainingPortfolioRisk / priceRisk
            
            return PositionSizeResult(
                size: adjustedSize,
                riskAmount: adjustedSize * priceRisk,
                reason: adjustedSize < constrainedSize ? "Limited by portfolio risk" : "Optimal size"
            )
        }
        
        return PositionSizeResult(
            size: constrainedSize,
            riskAmount: constrainedSize * priceRisk,
            reason: constrainedSize < baseSize ? "Limited by position size" : "Optimal size"
        )
    }
    
    // MARK: - Risk Assessment
    
    func assessTradeRisk(
        signal: StrategySignal,
        currentPrice: Double,
        accountBalance: Double,
        marketVolatility: Double
    ) -> TradeRiskAssessment {
        
        var riskScore: Double = 0.0
        var riskFactors: [String] = []
        
        // Signal confidence factor
        let confidenceRisk = 1.0 - signal.confidence
        riskScore += confidenceRisk * 0.3
        if signal.confidence < 0.6 {
            riskFactors.append("Low signal confidence")
        }
        
        // Market volatility factor
        let volatilityRisk = min(1.0, marketVolatility / 0.05) // Normalize to 5% volatility
        riskScore += volatilityRisk * 0.2
        if marketVolatility > 0.03 {
            riskFactors.append("High market volatility")
        }
        
        // Portfolio concentration risk
        let concentrationRisk = currentPortfolioRisk / maxPortfolioRisk
        riskScore += concentrationRisk * 0.2
        if concentrationRisk > 0.8 {
            riskFactors.append("High portfolio concentration")
        }
        
        // Daily risk utilization
        let dailyRiskUtilization = currentDailyRisk / (accountBalance * maxDailyRisk)
        riskScore += dailyRiskUtilization * 0.15
        if dailyRiskUtilization > 0.8 {
            riskFactors.append("High daily risk utilization")
        }
        
        // Time-based risk (avoid trading near market close, etc.)
        let timeRisk = assessTimeBasedRisk()
        riskScore += timeRisk * 0.15
        if timeRisk > 0.5 {
            riskFactors.append("Unfavorable trading time")
        }
        
        // Normalize risk score
        riskScore = min(1.0, riskScore)
        
        let riskLevel: RiskLevel
        if riskScore < 0.3 {
            riskLevel = .low
        } else if riskScore < 0.6 {
            riskLevel = .medium
        } else {
            riskLevel = .high
        }
        
        return TradeRiskAssessment(
            riskLevel: riskLevel,
            riskScore: riskScore,
            riskFactors: riskFactors,
            recommendedAction: determineRecommendedAction(riskLevel: riskLevel, riskScore: riskScore)
        )
    }
    
    // MARK: - Stop Loss and Take Profit
    
    func calculateStopLossAndTakeProfit(
        entryPrice: Double,
        direction: StrategySignal.Direction,
        atr: Double? = nil
    ) -> (stopLoss: Double, takeProfit: Double) {
        
        let stopLossDistance: Double
        
        if let atr = atr {
            // Use ATR-based stop loss (more dynamic)
            stopLossDistance = atr * 2.0
        } else {
            // Use percentage-based stop loss
            stopLossDistance = entryPrice * stopLossPercentage
        }
        
        let takeProfitDistance = stopLossDistance * takeProfitRatio
        
        switch direction {
        case .buy:
            let stopLoss = entryPrice - stopLossDistance
            let takeProfit = entryPrice + takeProfitDistance
            return (stopLoss, takeProfit)
            
        case .sell:
            let stopLoss = entryPrice + stopLossDistance
            let takeProfit = entryPrice - takeProfitDistance
            return (stopLoss, takeProfit)
            
        case .hold:
            return (entryPrice, entryPrice)
        }
    }
    
    // MARK: - Position Management
    
    func addPosition(_ position: RiskPosition) {
        activePositions.append(position)
        updateRiskMetrics()
        
        Log.userAction("Position added", parameters: [
            "symbol": position.symbol,
            "size": position.size,
            "risk": position.riskAmount
        ])
    }
    
    func removePosition(id: UUID) {
        activePositions.removeAll { $0.id == id }
        updateRiskMetrics()
        
        Log.userAction("Position removed", parameters: ["positionId": id.uuidString])
    }
    
    func updatePosition(id: UUID, currentPrice: Double) {
        guard let index = activePositions.firstIndex(where: { $0.id == id }) else { return }
        
        activePositions[index].currentPrice = currentPrice
        activePositions[index].unrealizedPnL = calculateUnrealizedPnL(position: activePositions[index])
        
        updateRiskMetrics()
    }
    
    // MARK: - Risk Monitoring
    
    private func setupRiskMonitoring() {
        // Monitor positions every minute
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.monitorPositions()
            }
            .store(in: &cancellables)
    }
    
    private func monitorPositions() {
        for position in activePositions {
            checkStopLossAndTakeProfit(position: position)
            checkPositionRisk(position: position)
        }
    }
    
    private func checkStopLossAndTakeProfit(position: RiskPosition) {
        let currentPrice = position.currentPrice
        
        // Check stop loss
        let stopLossTriggered = (position.direction == .buy && currentPrice <= position.stopLoss) ||
                               (position.direction == .sell && currentPrice >= position.stopLoss)
        
        if stopLossTriggered {
            Log.warning("Stop loss triggered for position \(position.symbol)", category: .ai)
            // Trigger stop loss order
            NotificationCenter.default.post(
                name: .stopLossTriggered,
                object: position
            )
        }
        
        // Check take profit
        let takeProfitTriggered = (position.direction == .buy && currentPrice >= position.takeProfit) ||
                                 (position.direction == .sell && currentPrice <= position.takeProfit)
        
        if takeProfitTriggered {
            Log.ai.info("Take profit triggered for position \(position.symbol)")
            // Trigger take profit order
            NotificationCenter.default.post(
                name: .takeProfitTriggered,
                object: position
            )
        }
    }
    
    private func checkPositionRisk(position: RiskPosition) {
        let riskMultiple = abs(position.unrealizedPnL) / position.riskAmount
        
        if riskMultiple > 2.0 && position.unrealizedPnL < 0 {
            Log.warning("Position risk exceeded 2x for \(position.symbol)", category: .ai)
            // Consider emergency exit
        }
    }
    
    // MARK: - Private Methods
    
    private func updateRiskMetrics() {
        currentPortfolioRisk = activePositions.reduce(0) { $0 + $1.riskAmount }
        
        // Calculate daily risk (positions opened today)
        let today = Calendar.current.startOfDay(for: Date())
        currentDailyRisk = activePositions
            .filter { Calendar.current.startOfDay(for: $0.openTime) == today }
            .reduce(0) { $0 + $1.riskAmount }
    }
    
    private func calculateUnrealizedPnL(position: RiskPosition) -> Double {
        switch position.direction {
        case .buy:
            return (position.currentPrice - position.entryPrice) * position.size
        case .sell:
            return (position.entryPrice - position.currentPrice) * position.size
        case .hold:
            return 0
        }
    }
    
    private func assessTimeBasedRisk() -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        // Higher risk during low liquidity hours
        if hour < 6 || hour > 22 {
            return 0.7
        } else if hour < 8 || hour > 20 {
            return 0.4
        } else {
            return 0.1
        }
    }
    
    private func determineRecommendedAction(riskLevel: RiskLevel, riskScore: Double) -> String {
        switch riskLevel {
        case .low:
            return "Proceed with trade"
        case .medium:
            return "Reduce position size or wait for better setup"
        case .high:
            return "Avoid trade or wait for risk reduction"
        }
    }
    
    // MARK: - Configuration
    
    private func saveConfiguration() {
        let config = RiskConfiguration(
            maxRiskPerTrade: maxRiskPerTrade,
            maxDailyRisk: maxDailyRisk,
            maxPortfolioRisk: maxPortfolioRisk,
            maxPositionSize: maxPositionSize,
            stopLossPercentage: stopLossPercentage,
            takeProfitRatio: takeProfitRatio
        )
        
        do {
            let data = try JSONEncoder().encode(config)
            UserDefaults.standard.set(data, forKey: "riskConfiguration")
            Log.verbose("Risk configuration saved", category: .ai)
        } catch {
            Log.error(error, context: "Saving risk configuration", category: .ai)
        }
    }
    
    private func loadConfiguration() {
        guard let data = UserDefaults.standard.data(forKey: "riskConfiguration") else { return }
        
        do {
            let config = try JSONDecoder().decode(RiskConfiguration.self, from: data)
            
            maxRiskPerTrade = config.maxRiskPerTrade
            maxDailyRisk = config.maxDailyRisk
            maxPortfolioRisk = config.maxPortfolioRisk
            maxPositionSize = config.maxPositionSize
            stopLossPercentage = config.stopLossPercentage
            takeProfitRatio = config.takeProfitRatio
            
            Log.verbose("Risk configuration loaded", category: .ai)
        } catch {
            Log.error(error, context: "Loading risk configuration", category: .ai)
        }
    }
    
    // MARK: - Public Configuration Methods
    
    func updateRiskParameters(
        maxRiskPerTrade: Double? = nil,
        maxDailyRisk: Double? = nil,
        maxPortfolioRisk: Double? = nil,
        maxPositionSize: Double? = nil,
        stopLossPercentage: Double? = nil,
        takeProfitRatio: Double? = nil
    ) {
        if let value = maxRiskPerTrade {
            self.maxRiskPerTrade = max(0.005, min(0.05, value))
        }
        if let value = maxDailyRisk {
            self.maxDailyRisk = max(0.02, min(0.15, value))
        }
        if let value = maxPortfolioRisk {
            self.maxPortfolioRisk = max(0.1, min(0.5, value))
        }
        if let value = maxPositionSize {
            self.maxPositionSize = max(0.05, min(0.25, value))
        }
        if let value = stopLossPercentage {
            self.stopLossPercentage = max(0.01, min(0.1, value))
        }
        if let value = takeProfitRatio {
            self.takeProfitRatio = max(1.0, min(5.0, value))
        }
        
        saveConfiguration()
    }
}

// MARK: - Supporting Types

struct PositionSizeResult {
    let size: Double
    let riskAmount: Double
    let reason: String
}

struct TradeRiskAssessment {
    let riskLevel: RiskLevel
    let riskScore: Double
    let riskFactors: [String]
    let recommendedAction: String
}

enum RiskLevel {
    case low, medium, high
}

struct RiskPosition: Identifiable {
    let id = UUID()
    let symbol: String
    let direction: StrategySignal.Direction
    let size: Double
    let entryPrice: Double
    var currentPrice: Double
    let stopLoss: Double
    let takeProfit: Double
    let riskAmount: Double
    let openTime: Date
    var unrealizedPnL: Double = 0.0
}

private struct RiskConfiguration: Codable {
    let maxRiskPerTrade: Double
    let maxDailyRisk: Double
    let maxPortfolioRisk: Double
    let maxPositionSize: Double
    let stopLossPercentage: Double
    let takeProfitRatio: Double
}

// MARK: - Notifications

extension Notification.Name {
    static let stopLossTriggered = Notification.Name("stopLossTriggered")
    static let takeProfitTriggered = Notification.Name("takeProfitTriggered")
}