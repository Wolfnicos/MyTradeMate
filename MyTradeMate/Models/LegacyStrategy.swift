import Foundation

enum StrategyKind: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case rsiDivergence = "RSI Divergence"
    case emaCross = "EMA Cross"
    case breakoutATR = "ATR Breakout"
    case meanReversion = "Mean Reversion"
}

struct StrategyConfig: Identifiable {
    let id = UUID()
    var kind: StrategyKind
    var enabled: Bool
    var params: [String: Double] // simple param map
}

final class StrategyStore: ObservableObject {
    static let shared = StrategyStore()
    
    @Published var strategies: [StrategyConfig] = [
        .init(kind: .rsiDivergence, enabled: true, params: ["rsiFast": 14, "rsiSlow": 28]),
        .init(kind: .emaCross, enabled: false, params: ["fast": 9, "slow": 21]),
        .init(kind: .breakoutATR, enabled: false, params: ["atr": 14, "mult": 2.0]),
        .init(kind: .meanReversion, enabled: false, params: ["lookback": 20, "z": 2.0])
    ]
    
    private init() {}
    
    func evaluateStrategies(candles: [Candle]) -> String? {
        let enabledStrategies = strategies.filter { $0.enabled }
        
        for strategy in enabledStrategies {
            switch strategy.kind {
            case .rsiDivergence:
                if let signal = evaluateRSIDivergence(candles: candles, params: strategy.params) {
                    return signal
                }
            case .emaCross:
                if let signal = evaluateEMACross(candles: candles, params: strategy.params) {
                    return signal
                }
            case .breakoutATR:
                if let signal = evaluateATRBreakout(candles: candles, params: strategy.params) {
                    return signal
                }
            case .meanReversion:
                if let signal = evaluateMeanReversion(candles: candles, params: strategy.params) {
                    return signal
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Strategy Implementations
    
    private func evaluateRSIDivergence(candles: [Candle], params: [String: Double]) -> String? {
        guard candles.count >= 50 else { return nil }
        
        let rsiFast = Int(params["rsiFast"] ?? 14)
        let rsiSlow = Int(params["rsiSlow"] ?? 28)
        
        // Simple RSI calculation (placeholder)
        let prices = candles.suffix(rsiFast * 2).map { $0.close }
        let currentRSI = calculateRSI(prices: prices, period: rsiFast)
        
        if currentRSI < 30 {
            return "BUY (RSI Oversold)"
        } else if currentRSI > 70 {
            return "SELL (RSI Overbought)"
        }
        
        return nil
    }
    
    private func evaluateEMACross(candles: [Candle], params: [String: Double]) -> String? {
        guard candles.count >= 50 else { return nil }
        
        let fast = Int(params["fast"] ?? 9)
        let slow = Int(params["slow"] ?? 21)
        
        let prices = candles.suffix(slow + 10).map { $0.close }
        let emaFast = calculateEMA(prices: prices, period: fast)
        let emaSlow = calculateEMA(prices: prices, period: slow)
        
        guard let currentFast = emaFast.last,
              let currentSlow = emaSlow.last,
              emaFast.count >= 2,
              emaSlow.count >= 2 else { return nil }
        
        let prevFast = emaFast[emaFast.count - 2]
        let prevSlow = emaSlow[emaSlow.count - 2]
        
        if currentFast > currentSlow && prevFast <= prevSlow {
            return "BUY (EMA Cross Up)"
        } else if currentFast < currentSlow && prevFast >= prevSlow {
            return "SELL (EMA Cross Down)"
        }
        
        return nil
    }
    
    private func evaluateATRBreakout(candles: [Candle], params: [String: Double]) -> String? {
        guard candles.count >= 50 else { return nil }
        
        let atrPeriod = Int(params["atr"] ?? 14)
        let multiplier = params["mult"] ?? 2.0
        
        let recent = candles.suffix(atrPeriod + 1)
        let atr = calculateATR(candles: Array(recent), period: atrPeriod)
        guard let currentCandle = candles.last,
              candles.count >= 2 else { return nil }
        let currentPrice = currentCandle.close
        let prevClose = candles[candles.count - 2].close
        
        let breakoutThreshold = atr * multiplier
        
        if currentPrice > prevClose + breakoutThreshold {
            return "BUY (ATR Breakout Up)"
        } else if currentPrice < prevClose - breakoutThreshold {
            return "SELL (ATR Breakout Down)"
        }
        
        return nil
    }
    
    private func evaluateMeanReversion(candles: [Candle], params: [String: Double]) -> String? {
        guard candles.count >= 50 else { return nil }
        
        let lookback = Int(params["lookback"] ?? 20)
        let zScore = params["z"] ?? 2.0
        
        let prices = candles.suffix(lookback + 5).map { $0.close }
        let mean = prices.suffix(lookback).reduce(0, +) / Double(lookback)
        let std = calculateStandardDeviation(prices: Array(prices.suffix(lookback)))
        
        guard let currentPrice = prices.last else { return nil }
        let z = std > 0 ? (currentPrice - mean) / std : 0
        
        if z < -zScore {
            return "BUY (Mean Reversion)"
        } else if z > zScore {
            return "SELL (Mean Reversion)"
        }
        
        return nil
    }
    
    // MARK: - Helper Calculations
    
    private func calculateRSI(prices: [Double], period: Int) -> Double {
        guard prices.count >= period + 1 else { return 50 }
        
        var gains: [Double] = []
        var losses: [Double] = []
        
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            if change > 0 {
                gains.append(change)
                losses.append(0)
            } else {
                gains.append(0)
                losses.append(-change)
            }
        }
        
        let avgGain = gains.suffix(period).reduce(0, +) / Double(period)
        let avgLoss = losses.suffix(period).reduce(0, +) / Double(period)
        
        guard avgLoss != 0 else { return 100 }
        
        let rs = avgGain / avgLoss
        return 100 - (100 / (1 + rs))
    }
    
    private func calculateEMA(prices: [Double], period: Int) -> [Double] {
        guard prices.count >= period else { return prices }
        
        let multiplier = 2.0 / Double(period + 1)
        var ema: [Double] = []
        
        // Start with SMA
        let sma = prices.prefix(period).reduce(0, +) / Double(period)
        ema.append(sma)
        
        // Calculate EMA
        for i in period..<prices.count {
            guard let lastEMA = ema.last else { break }
            let value = (prices[i] - lastEMA) * multiplier + lastEMA
            ema.append(value)
        }
        
        return ema
    }
    
    private func calculateATR(candles: [Candle], period: Int) -> Double {
        guard candles.count >= period else { return 0 }
        
        var trueRanges: [Double] = []
        
        for i in 1..<candles.count {
            let high = candles[i].high
            let low = candles[i].low
            let prevClose = candles[i-1].close
            
            let tr = max(high - low, abs(high - prevClose), abs(low - prevClose))
            trueRanges.append(tr)
        }
        
        return trueRanges.suffix(period).reduce(0, +) / Double(period)
    }
    
    private func calculateStandardDeviation(prices: [Double]) -> Double {
        guard prices.count > 1 else { return 0 }
        
        let mean = prices.reduce(0, +) / Double(prices.count)
        let variance = prices.map { pow($0 - mean, 2) }.reduce(0, +) / Double(prices.count)
        return sqrt(variance)
    }
}