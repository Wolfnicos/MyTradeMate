import Foundation

/// Grid Trading strategy implementation
public final class GridTradingStrategy: BaseStrategy {
    public static let shared = GridTradingStrategy()
    public var gridLevels: Int = 10
    public var gridSpacing: Double = 0.01 // 1% spacing between levels
    public var baseOrderSize: Double = 100.0
    public var maxPositionSize: Double = 1000.0
    public var volatilityPeriod: Int = 20
    public var maxVolatility: Double = 0.03 // 3% max volatility for grid trading
    
    private var gridBuyLevels: [Double] = []
    private var gridSellLevels: [Double] = []
    private var centerPrice: Double = 0.0
    
    public init() {
        super.init(
            name: "Grid Trading",
            description: "Automated grid trading for range-bound markets"
        )
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= requiredCandles() else {
            // ✅ FALLBACK: Use range analysis when insufficient data
            let recentPrices = candles.map(\.close)
            let high = candles.map(\.high).max() ?? 0.0
            let low = candles.map(\.low).min() ?? 0.0
            let currentPrice = recentPrices.last ?? 0.0
            let rangePosition = (high - low) > 0 ? (currentPrice - low) / (high - low) : 0.5
            
            return StrategySignal(
                direction: rangePosition > 0.6 ? .sell : (rangePosition < 0.4 ? .buy : .hold),
                confidence: 0.35,
                reason: "Insufficient data - range position fallback",
                strategyName: name
            )
        }
        
        guard let currentPrice = candles.last?.close else { 
            return StrategySignal(direction: .hold, confidence: 0.33, reason: "Grid setup invalid - neutral fallback", strategyName: name)
        }
        
        // Check market volatility
        let volatility = calculateVolatility(candles: Array(candles.suffix(volatilityPeriod)))
        if volatility > maxVolatility {
            return StrategySignal(
                direction: .hold,
                confidence: 0.2,
                reason: "Market too volatile for grid trading (\(String(format: "%.2f%%", volatility * 100)))",
                strategyName: name
            )
        }
        
        // Initialize or update grid if needed
        if gridBuyLevels.isEmpty || shouldUpdateGrid(currentPrice: currentPrice, candles: candles) {
            updateGrid(currentPrice: currentPrice, candles: candles)
        }
        
        // Find the closest grid levels
        let closestBuyLevel = findClosestLevel(price: currentPrice, levels: gridBuyLevels, below: true)
        let closestSellLevel = findClosestLevel(price: currentPrice, levels: gridSellLevels, below: false)
        
        // Check for grid trading opportunities
        if let buyLevel = closestBuyLevel {
            let distanceToBuy = (currentPrice - buyLevel) / buyLevel
            if distanceToBuy <= 0.002 { // Within 0.2% of buy level
                let confidence = calculateGridConfidence(
                    currentPrice: currentPrice,
                    targetLevel: buyLevel,
                    volatility: volatility,
                    isBuy: true
                )
                
                return StrategySignal(
                    direction: .buy,
                    confidence: confidence,
                    reason: "Grid buy level reached (\(String(format: "%.2f", buyLevel)))",
                    strategyName: name
                )
            }
        }
        
        if let sellLevel = closestSellLevel {
            let distanceToSell = (sellLevel - currentPrice) / currentPrice
            if distanceToSell <= 0.002 { // Within 0.2% of sell level
                let confidence = calculateGridConfidence(
                    currentPrice: currentPrice,
                    targetLevel: sellLevel,
                    volatility: volatility,
                    isBuy: false
                )
                
                return StrategySignal(
                    direction: .sell,
                    confidence: confidence,
                    reason: "Grid sell level reached (\(String(format: "%.2f", sellLevel)))",
                    strategyName: name
                )
            }
        }
        
        // Check for range breakout (stop grid trading)
        let priceRange = calculatePriceRange(candles: Array(candles.suffix(50)))
        let breakoutThreshold = priceRange * 1.5
        
        if currentPrice > centerPrice + breakoutThreshold {
            return StrategySignal(
                direction: .hold,
                confidence: 0.3,
                reason: "Upward breakout detected - pausing grid trading",
                strategyName: name
            )
        } else if currentPrice < centerPrice - breakoutThreshold {
            return StrategySignal(
                direction: .hold,
                confidence: 0.3,
                reason: "Downward breakout detected - pausing grid trading",
                strategyName: name
            )
        }
        
        return StrategySignal(
            direction: .hold,
            confidence: 0.30,
            reason: "Waiting for grid level approach",
            strategyName: name
        )
    }
    
    private func updateGrid(currentPrice: Double, candles: [Candle]) {
        // Calculate center price based on recent trading range
        let recentCandles = Array(candles.suffix(50))
        let high = recentCandles.map { $0.high }.max() ?? currentPrice
        let low = recentCandles.map { $0.low }.min() ?? currentPrice
        centerPrice = (high + low) / 2
        
        // Clear existing grid
        gridBuyLevels.removeAll()
        gridSellLevels.removeAll()
        
        // Create buy levels below center
        for i in 1...gridLevels/2 {
            let level = centerPrice * (1 - gridSpacing * Double(i))
            gridBuyLevels.append(level)
        }
        
        // Create sell levels above center
        for i in 1...gridLevels/2 {
            let level = centerPrice * (1 + gridSpacing * Double(i))
            gridSellLevels.append(level)
        }
        
        // Sort levels
        gridBuyLevels.sort(by: >) // Highest buy level first
        gridSellLevels.sort() // Lowest sell level first
    }
    
    private func shouldUpdateGrid(currentPrice: Double, candles: [Candle]) -> Bool {
        // Update grid if price has moved significantly from center
        let distanceFromCenter = abs(currentPrice - centerPrice) / centerPrice
        
        // Or if volatility has changed significantly
        let currentVolatility = calculateVolatility(candles: Array(candles.suffix(volatilityPeriod)))
        
        return distanceFromCenter > gridSpacing * 3 || currentVolatility > maxVolatility * 0.8
    }
    
    private func findClosestLevel(price: Double, levels: [Double], below: Bool) -> Double? {
        if below {
            // Find highest level below current price
            return levels.filter { $0 < price }.max()
        } else {
            // Find lowest level above current price
            return levels.filter { $0 > price }.min()
        }
    }
    
    private func calculateGridConfidence(currentPrice: Double, targetLevel: Double, volatility: Double, isBuy: Bool) -> Double {
        var confidence: Double = 0.6
        
        // Distance factor - closer to level = higher confidence
        let distance = abs(currentPrice - targetLevel) / targetLevel
        let distanceFactor = max(0, 0.3 - (distance * 100)) // Max 0.3 bonus for being very close
        confidence += distanceFactor
        
        // Volatility factor - lower volatility = higher confidence for grid
        let volatilityFactor = max(0, 0.2 - (volatility * 10))
        confidence += volatilityFactor
        
        // Grid position factor - levels closer to center are more reliable
        let centerDistance = abs(targetLevel - centerPrice) / centerPrice
        let positionFactor = max(0, 0.1 - centerDistance)
        confidence += positionFactor
        
        return min(0.8, confidence) // Cap at 0.8 for grid trading
    }
    
    private func calculateVolatility(candles: [Candle]) -> Double {
        guard candles.count > 1 else { return 0 }
        
        let returns = (1..<candles.count).map { i in
            (candles[i].close - candles[i-1].close) / candles[i-1].close
        }
        
        let mean = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - mean, 2) }.reduce(0, +) / Double(returns.count)
        
        return sqrt(variance)
    }
    
    private func calculatePriceRange(candles: [Candle]) -> Double {
        guard !candles.isEmpty else { return 0 }
        
        let high = candles.map { $0.high }.max() ?? 0
        let low = candles.map { $0.low }.min() ?? 0
        
        return high - low
    }
    
    public override func requiredCandles() -> Int {
        return max(volatilityPeriod, 50) + 10
    }
    
    public func updateParameter(key: String, value: Any) {
        switch key {
        case "gridLevels":
            if let intValue = value as? Int {
                gridLevels = max(4, min(20, intValue))
                // Clear grid to force recalculation
                gridBuyLevels.removeAll()
                gridSellLevels.removeAll()
            }
        case "gridSpacing":
            if let doubleValue = value as? Double {
                gridSpacing = max(0.005, min(0.05, doubleValue))
                // Clear grid to force recalculation
                gridBuyLevels.removeAll()
                gridSellLevels.removeAll()
            }
        case "baseOrderSize":
            if let doubleValue = value as? Double {
                baseOrderSize = max(10, min(1000, doubleValue))
            }
        case "maxPositionSize":
            if let doubleValue = value as? Double {
                maxPositionSize = max(100, min(10000, doubleValue))
            }
        case "maxVolatility":
            if let doubleValue = value as? Double {
                maxVolatility = max(0.01, min(0.1, doubleValue))
            }
        default:
            break
        }
    }
    
    // Public methods for external access to grid levels
    public func getCurrentGridLevels() -> (buyLevels: [Double], sellLevels: [Double], center: Double) {
        return (gridBuyLevels, gridSellLevels, centerPrice)
    }
    
    public func getRecommendedOrderSize(for level: Double) -> Double {
        // Adjust order size based on distance from center
        let distanceFromCenter = abs(level - centerPrice) / centerPrice
        let sizeMultiplier = 1.0 + (distanceFromCenter / gridSpacing) * 0.1 // Increase size for levels further from center
        
        return min(maxPositionSize, baseOrderSize * sizeMultiplier)
    }
}