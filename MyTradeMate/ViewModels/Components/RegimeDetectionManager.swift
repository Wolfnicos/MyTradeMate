import Foundation
import Combine
import SwiftUI

// MARK: - Market Regime
enum MarketRegime: String, CaseIterable {
    case trendingUp = "Trending Up"
    case trendingDown = "Trending Down"
    case ranging = "Ranging"
    case volatile = "Volatile"
    case consolidating = "Consolidating"
    
    var color: Color {
        switch self {
        case .trendingUp:
            return .green
        case .trendingDown:
            return .red
        case .ranging:
            return .blue
        case .volatile:
            return .orange
        case .consolidating:
            return .gray
        }
    }
    
    var description: String {
        switch self {
        case .trendingUp:
            return "Strong upward price movement"
        case .trendingDown:
            return "Strong downward price movement"
        case .ranging:
            return "Price moving sideways within a range"
        case .volatile:
            return "High price volatility with no clear direction"
        case .consolidating:
            return "Price consolidating after a move"
        }
    }
}

// MARK: - Regime Detection Manager
@MainActor
final class RegimeDetectionManager: ObservableObject {
    // MARK: - Dependencies
    // Settings would be injected here if needed
    
    // MARK: - Published Properties
    @Published var currentRegime: MarketRegime = .ranging
    @Published var regimeConfidence: Double = 0.0
    @Published var recommendedStrategies: [String] = []
    @Published var regimeHistory: [RegimeRecord] = []
    
    // MARK: - Private Properties
    private let maxHistoryCount = 100
    
    // MARK: - Initialization
    init() {
        // Initialize with default values
    }
    
    // MARK: - Public Methods
    func detectRegime(from candles: [Candle]) {
        guard candles.count >= 20 else {
            currentRegime = .ranging
            regimeConfidence = 0.0
            return
        }
        
        let regime = analyzeMarketRegime(candles: candles)
        let confidence = calculateRegimeConfidence(candles: candles, regime: regime)
        
        // Only update if confidence is high enough or regime has changed significantly
        if confidence > 0.6 || regime != currentRegime {
            currentRegime = regime
            regimeConfidence = confidence
            recommendedStrategies = getRecommendedStrategies(for: regime)
            
            // Add to history
            let record = RegimeRecord(
                regime: regime,
                confidence: confidence,
                timestamp: Date()
            )
            addToHistory(record)
            
            Log.ai.info("Market regime detected: \(regime.rawValue) (confidence: \(String(format: "%.1f%%", confidence * 100)))")
        }
    }
    
    func getRegimeAnalysis(for candles: [Candle]) -> RegimeAnalysis {
        guard candles.count >= 20 else {
            return RegimeAnalysis(
                regime: .ranging,
                confidence: 0.0,
                trendStrength: 0.0,
                volatility: 0.0,
                momentum: 0.0
            )
        }
        
        let regime = analyzeMarketRegime(candles: candles)
        let confidence = calculateRegimeConfidence(candles: candles, regime: regime)
        let trendStrength = calculateTrendStrength(candles: candles)
        let volatility = calculateVolatility(candles: candles)
        let momentum = calculateMomentum(candles: candles)
        
        return RegimeAnalysis(
            regime: regime,
            confidence: confidence,
            trendStrength: trendStrength,
            volatility: volatility,
            momentum: momentum
        )
    }
    
    // MARK: - Private Methods
    private func analyzeMarketRegime(candles: [Candle]) -> MarketRegime {
        let recentCandles = Array(candles.suffix(20))
        
        // Calculate trend indicators
        let trendStrength = calculateTrendStrength(candles: recentCandles)
        let volatility = calculateVolatility(candles: recentCandles)
        let momentum = calculateMomentum(candles: recentCandles)
        
        // Determine regime based on indicators
        if abs(trendStrength) > 0.7 {
            return trendStrength > 0 ? .trendingUp : .trendingDown
        } else if volatility > 0.8 {
            return .volatile
        } else if abs(momentum) < 0.3 && volatility < 0.4 {
            return .consolidating
        } else {
            return .ranging
        }
    }
    
    private func calculateTrendStrength(candles: [Candle]) -> Double {
        guard candles.count >= 10 else { return 0.0 }
        
        let closes = candles.map { $0.close }
        let firstPrice = closes.first!
        let lastPrice = closes.last!
        
        // Simple trend calculation
        let priceChange = (lastPrice - firstPrice) / firstPrice
        
        // Normalize to -1 to 1 range
        return max(-1.0, min(1.0, priceChange * 10))
    }
    
    private func calculateVolatility(candles: [Candle]) -> Double {
        guard candles.count >= 2 else { return 0.0 }
        
        let returns = zip(candles.dropFirst(), candles.dropLast()).map { current, previous in
            (current.close - previous.close) / previous.close
        }
        
        let mean = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - mean, 2) }.reduce(0, +) / Double(returns.count)
        let volatility = sqrt(variance)
        
        // Normalize to 0-1 range (multiply by 100 to get reasonable scale)
        return min(1.0, volatility * 100)
    }
    
    private func calculateMomentum(candles: [Candle]) -> Double {
        guard candles.count >= 5 else { return 0.0 }
        
        let recentCandles = Array(candles.suffix(5))
        let olderCandles = Array(candles.dropLast(5).suffix(5))
        
        let recentAvg = recentCandles.map { $0.close }.reduce(0, +) / Double(recentCandles.count)
        let olderAvg = olderCandles.map { $0.close }.reduce(0, +) / Double(olderCandles.count)
        
        let momentum = (recentAvg - olderAvg) / olderAvg
        
        // Normalize to -1 to 1 range
        return max(-1.0, min(1.0, momentum * 10))
    }
    
    private func calculateRegimeConfidence(candles: [Candle], regime: MarketRegime) -> Double {
        let analysis = getRegimeAnalysis(for: candles)
        
        switch regime {
        case .trendingUp, .trendingDown:
            return abs(analysis.trendStrength) * 0.7 + (1.0 - analysis.volatility) * 0.3
        case .ranging:
            return (1.0 - abs(analysis.trendStrength)) * 0.6 + (1.0 - analysis.volatility) * 0.4
        case .volatile:
            return analysis.volatility * 0.8 + abs(analysis.momentum) * 0.2
        case .consolidating:
            return (1.0 - abs(analysis.momentum)) * 0.7 + (1.0 - analysis.volatility) * 0.3
        }
    }
    
    private func getRecommendedStrategies(for regime: MarketRegime) -> [String] {
        switch regime {
        case .trendingUp, .trendingDown:
            return ["MACD", "EMA Crossover", "Breakout"]
        case .ranging:
            return ["RSI", "Bollinger Bands", "Mean Reversion"]
        case .volatile:
            return ["Bollinger Bands", "Stochastic"]
        case .consolidating:
            return ["Breakout", "Williams %R"]
        }
    }
    
    private func addToHistory(_ record: RegimeRecord) {
        regimeHistory.append(record)
        
        // Keep only recent history
        if regimeHistory.count > maxHistoryCount {
            regimeHistory.removeFirst(regimeHistory.count - maxHistoryCount)
        }
    }
}

// MARK: - Supporting Models
struct RegimeAnalysis {
    let regime: MarketRegime
    let confidence: Double
    let trendStrength: Double
    let volatility: Double
    let momentum: Double
}

struct RegimeRecord {
    let regime: MarketRegime
    let confidence: Double
    let timestamp: Date
}