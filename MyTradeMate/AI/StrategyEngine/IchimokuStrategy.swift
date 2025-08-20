import Foundation

/// Ichimoku Cloud strategy implementation
public final class IchimokuStrategy: BaseStrategy {
    public static let shared = IchimokuStrategy()
    public var tenkanPeriod: Int = 9
    public var kijunPeriod: Int = 26
    public var senkouBPeriod: Int = 52
    public var displacement: Int = 26
    
    public init() {
        super.init(
            name: "Ichimoku Cloud",
            description: "Comprehensive trend analysis using Ichimoku Kinko Hyo"
        )
    }
    
    public override func signal(candles: [Candle]) -> StrategySignal {
        guard candles.count >= requiredCandles() else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Insufficient data for Ichimoku",
                strategyName: name
            )
        }
        
        let ichimokuData = calculateIchimoku(candles: candles)
        
        guard let currentPrice = candles.last?.close,
              let tenkanSen = ichimokuData.tenkanSen.last,
              let kijunSen = ichimokuData.kijunSen.last,
              let senkouSpanA = ichimokuData.senkouSpanA.last,
              let senkouSpanB = ichimokuData.senkouSpanB.last else {
            return StrategySignal(
                direction: .hold,
                confidence: 0.0,
                reason: "Unable to calculate Ichimoku values",
                strategyName: name
            )
        }
        
        let previousTenkan = ichimokuData.tenkanSen.count > 1 ? ichimokuData.tenkanSen[ichimokuData.tenkanSen.count - 2] : tenkanSen
        let previousKijun = ichimokuData.kijunSen.count > 1 ? ichimokuData.kijunSen[ichimokuData.kijunSen.count - 2] : kijunSen
        
        // Determine cloud position
        let cloudTop = max(senkouSpanA, senkouSpanB)
        let cloudBottom = min(senkouSpanA, senkouSpanB)
        let priceAboveCloud = currentPrice > cloudTop
        let priceBelowCloud = currentPrice < cloudBottom
        let priceInCloud = !priceAboveCloud && !priceBelowCloud
        
        // Cloud color (bullish if Senkou Span A > Senkou Span B)
        let bullishCloud = senkouSpanA > senkouSpanB
        
        var signals: [String] = []
        var confidence: Double = 0.0
        var direction: StrategySignal.Direction = .hold
        
        // Tenkan-Kijun crossover
        if tenkanSen > kijunSen && previousTenkan <= previousKijun {
            signals.append("Tenkan-Kijun bullish cross")
            confidence += 0.3
            direction = .buy
        } else if tenkanSen < kijunSen && previousTenkan >= previousKijun {
            signals.append("Tenkan-Kijun bearish cross")
            confidence += 0.3
            direction = .sell
        }
        
        // Price vs Kumo (cloud)
        if priceAboveCloud {
            if direction == .buy || direction == .hold {
                signals.append("Price above cloud")
                confidence += bullishCloud ? 0.4 : 0.2
                direction = .buy
            }
        } else if priceBelowCloud {
            if direction == .sell || direction == .hold {
                signals.append("Price below cloud")
                confidence += bullishCloud ? 0.2 : 0.4
                direction = .sell
            }
        } else {
            signals.append("Price in cloud (neutral)")
            confidence *= 0.5 // Reduce confidence when in cloud
        }
        
        // Price vs Tenkan and Kijun
        if currentPrice > tenkanSen && currentPrice > kijunSen {
            if direction == .buy || direction == .hold {
                signals.append("Price above Tenkan and Kijun")
                confidence += 0.2
                direction = .buy
            }
        } else if currentPrice < tenkanSen && currentPrice < kijunSen {
            if direction == .sell || direction == .hold {
                signals.append("Price below Tenkan and Kijun")
                confidence += 0.2
                direction = .sell
            }
        }
        
        // Cloud twist (future cloud direction change)
        if ichimokuData.senkouSpanA.count > 1 && ichimokuData.senkouSpanB.count > 1 {
            let previousSpanA = ichimokuData.senkouSpanA[ichimokuData.senkouSpanA.count - 2]
            let previousSpanB = ichimokuData.senkouSpanB[ichimokuData.senkouSpanB.count - 2]
            
            if senkouSpanA > senkouSpanB && previousSpanA <= previousSpanB {
                signals.append("Cloud twist bullish")
                confidence += 0.2
                if direction == .hold { direction = .buy }
            } else if senkouSpanA < senkouSpanB && previousSpanA >= previousSpanB {
                signals.append("Cloud twist bearish")
                confidence += 0.2
                if direction == .hold { direction = .sell }
            }
        }
        
        confidence = min(0.95, confidence)
        
        let reason = signals.isEmpty ? "Ichimoku neutral" : signals.joined(separator: ", ")
        
        return StrategySignal(
            direction: direction,
            confidence: confidence,
            reason: reason,
            strategyName: name
        )
    }
    
    private func calculateIchimoku(candles: [Candle]) -> IchimokuData {
        var tenkanSen: [Double] = []
        var kijunSen: [Double] = []
        var senkouSpanA: [Double] = []
        var senkouSpanB: [Double] = []
        var chikouSpan: [Double] = []
        
        // Calculate Tenkan-sen (Conversion Line)
        for i in (tenkanPeriod - 1)..<candles.count {
            let period = Array(candles[(i - tenkanPeriod + 1)...i])
            let high = period.map { $0.high }.max() ?? 0
            let low = period.map { $0.low }.min() ?? 0
            tenkanSen.append((high + low) / 2)
        }
        
        // Calculate Kijun-sen (Base Line)
        for i in (kijunPeriod - 1)..<candles.count {
            let period = Array(candles[(i - kijunPeriod + 1)...i])
            let high = period.map { $0.high }.max() ?? 0
            let low = period.map { $0.low }.min() ?? 0
            kijunSen.append((high + low) / 2)
        }
        
        // Calculate Senkou Span A (Leading Span A)
        let startIndex = max(tenkanPeriod - 1, kijunPeriod - 1)
        for i in 0..<min(tenkanSen.count, kijunSen.count) {
            let tenkanIndex = i - (startIndex - (tenkanPeriod - 1))
            let kijunIndex = i - (startIndex - (kijunPeriod - 1))
            
            if tenkanIndex >= 0 && kijunIndex >= 0 {
                senkouSpanA.append((tenkanSen[tenkanIndex] + kijunSen[kijunIndex]) / 2)
            }
        }
        
        // Calculate Senkou Span B (Leading Span B)
        for i in (senkouBPeriod - 1)..<candles.count {
            let period = Array(candles[(i - senkouBPeriod + 1)...i])
            let high = period.map { $0.high }.max() ?? 0
            let low = period.map { $0.low }.min() ?? 0
            senkouSpanB.append((high + low) / 2)
        }
        
        // Calculate Chikou Span (Lagging Span)
        for i in displacement..<candles.count {
            chikouSpan.append(candles[i].close)
        }
        
        return IchimokuData(
            tenkanSen: tenkanSen,
            kijunSen: kijunSen,
            senkouSpanA: senkouSpanA,
            senkouSpanB: senkouSpanB,
            chikouSpan: chikouSpan
        )
    }
    
    public override func requiredCandles() -> Int {
        return senkouBPeriod + displacement + 10
    }
    
    public func updateParameter(key: String, value: Any) {
        switch key {
        case "tenkanPeriod":
            if let intValue = value as? Int {
                tenkanPeriod = max(3, min(20, intValue))
            }
        case "kijunPeriod":
            if let intValue = value as? Int {
                kijunPeriod = max(10, min(50, intValue))
            }
        case "senkouBPeriod":
            if let intValue = value as? Int {
                senkouBPeriod = max(20, min(100, intValue))
            }
        case "displacement":
            if let intValue = value as? Int {
                displacement = max(10, min(50, intValue))
            }
        default:
            break
        }
    }
}

private struct IchimokuData {
    let tenkanSen: [Double]
    let kijunSen: [Double]
    let senkouSpanA: [Double]
    let senkouSpanB: [Double]
    let chikouSpan: [Double]
}