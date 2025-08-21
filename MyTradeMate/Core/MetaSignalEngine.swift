import Foundation
import Combine
import os.log
import CoreML

    /// Enhanced MetaSignalEngine with advanced crypto trading strategies
@MainActor
public final class MetaSignalEngine: ObservableObject {
    public static let shared = MetaSignalEngine()

        // MARK: - Dependencies
    private let aiModelManager = AIModelManager.shared
    private let strategyManager = StrategyManager.shared
    private let settings = SettingsRepository.shared

        // MARK: - Published Properties
    @Published public private(set) var lastMetaSignal: MetaSignal?
    @Published public private(set) var isProcessing = false
    @Published public private(set) var marketSentiment: MarketSentiment = .neutral
    @Published public private(set) var volatilityRegime: VolatilityRegime = .normal

    private init() {}

        // MARK: - Enhanced Market Analysis
    public enum MarketSentiment {
        case extremeFear
        case fear
        case neutral
        case greed
        case extremeGreed

        var multiplier: Double {
            switch self {
            case .extremeFear: return 0.7  // Reduce position size
            case .fear: return 0.85
            case .neutral: return 1.0
            case .greed: return 1.1
            case .extremeGreed: return 0.8  // Contrarian - reduce at extreme greed
            }
        }
    }

    public enum VolatilityRegime {
        case low
        case normal
        case high
        case extreme

        var stopLossMultiplier: Double {
            switch self {
            case .low: return 0.8
            case .normal: return 1.0
            case .high: return 1.3
            case .extreme: return 1.5
            }
        }
    }

        // MARK: - Enhanced MetaSignal Structure
    public struct MetaSignal {
        public let direction: SignalDirection
        public let confidence: Double
        public let strength: SignalStrength
        public let source: String
        public let timestamp: Date
        public let aiComponent: AIComponent?
        public let strategyComponent: StrategyComponent?
        public let cryptoIndicators: CryptoIndicators?
        public let riskMetrics: RiskMetrics
        public let metadata: [String: Any]

        public enum SignalStrength {
            case weak
            case moderate
            case strong
            case veryStrong
        }

        public struct AIComponent {
            public let prediction: String
            public let confidence: Double
            public let modelUsed: String
            public let weight: Double
            public let features: [String: Double]
        }

        public struct StrategyComponent {
            public let ensemble: StrategySignal
            public let votePurity: Double
            public let contributingStrategiesCount: Int
            public let weight: Double
            public let winningStrategies: [String]
        }

        public struct CryptoIndicators {
                // Crypto-specific indicators
            public let nvtRatio: Double?           // Network Value to Transactions
            public let hashRibbons: String         // Mining difficulty signal
            public let whaleActivity: WhaleSignal  // Large holder movements
            public let exchangeFlows: ExchangeFlow // Exchange in/outflows
            public let fundingRate: Double?        // Perpetual funding rate
            public let openInterest: Double?       // Derivatives OI
            public let fearGreedIndex: Int         // 0-100 scale
            public let socialSentiment: Double     // -1 to 1 scale
            public let correlationBTC: Double      // Correlation with BTC
            public let defiTVL: Double?           // DeFi Total Value Locked
        }

        public struct RiskMetrics {
            public let suggestedPositionSize: Double  // % of portfolio
            public let stopLoss: Double              // Price level
            public let takeProfit: [Double]          // Multiple TP levels
            public let riskRewardRatio: Double
            public let maxDrawdownExpected: Double
            public let confidenceInterval: (lower: Double, upper: Double)
            public let kellyFraction: Double         // Optimal bet size
        }

        public struct WhaleSignal {
            public let netFlow: Double  // Positive = accumulation, Negative = distribution
            public let intensity: String // "low", "moderate", "high"
        }

        public struct ExchangeFlow {
            public let netFlow: Double  // Positive = to exchanges (bearish), Negative = from exchanges (bullish)
            public let dominantDirection: String
        }
    }

        // MARK: - Enhanced Settings with Crypto Focus
    public struct MetaSignalSettings {
        public let aiWeight: Double
        public let strategyWeight: Double
        public let cryptoIndicatorsWeight: Double
        public let minConfidenceThresholds: [Timeframe: Double]
        public let useWhaleTracking: Bool
        public let useSentimentAnalysis: Bool
        public let useOnChainMetrics: Bool
        public let adaptiveWeighting: Bool
        public let riskProfile: RiskProfile

        public enum RiskProfile {
            case conservative
            case balanced
            case aggressive
            case degen  // High risk crypto trading
        }
        
        // INIT with default values for new crypto parameters
        public init(
            aiWeight: Double,
            strategyWeight: Double,
            cryptoIndicatorsWeight: Double = 0.25,  // DEFAULT
            minConfidenceThresholds: [Timeframe: Double],
            useWhaleTracking: Bool = true,  // DEFAULT
            useSentimentAnalysis: Bool = true,  // DEFAULT
            useOnChainMetrics: Bool = true,  // DEFAULT
            adaptiveWeighting: Bool = true,  // DEFAULT
            riskProfile: RiskProfile = .balanced  // DEFAULT
        ) {
            self.aiWeight = aiWeight
            self.strategyWeight = strategyWeight
            self.cryptoIndicatorsWeight = cryptoIndicatorsWeight
            self.minConfidenceThresholds = minConfidenceThresholds
            self.useWhaleTracking = useWhaleTracking
            self.useSentimentAnalysis = useSentimentAnalysis
            self.useOnChainMetrics = useOnChainMetrics
            self.adaptiveWeighting = adaptiveWeighting
            self.riskProfile = riskProfile
        }

        public static let `default` = MetaSignalSettings(
            aiWeight: 0.4,
            strategyWeight: 0.35,
            cryptoIndicatorsWeight: 0.25,
            minConfidenceThresholds: [
                .m1: 0.75,
                .m5: 0.70,
                .m15: 0.65,
                .h1: 0.62,
                .h4: 0.60,
                .d1: 0.58
            ],
            useWhaleTracking: true,
            useSentimentAnalysis: true,
            useOnChainMetrics: true,
            adaptiveWeighting: true,
            riskProfile: .balanced
        )
    }

        // MARK: - Enhanced Main Signal Generation
    public func generateMetaSignal(
        for pair: TradingPair,
        timeframe: Timeframe,
        candles: [Candle],
        settings: MetaSignalSettings = .default
    ) async -> MetaSignal {

        isProcessing = true
        defer { isProcessing = false }

        os_log("[META] Generating enhanced signal for %@ %@", log: Log.ai, type: .info, pair.symbol, timeframe.rawValue)

            // 1. Market Context Analysis
        let marketContext = await analyzeMarketContext(candles: candles, pair: pair)
        marketSentiment = marketContext.sentiment
        volatilityRegime = marketContext.volatility

            // 2. Get AI Prediction with enhanced features
        let aiComponent = await getEnhancedAIPrediction(
            candles: candles,
            timeframe: timeframe,
            marketContext: marketContext
        )

            // 3. Get Strategy Ensemble with crypto adaptations
        let strategyComponent = await getCryptoStrategyEnsemble(
            candles: candles,
            timeframe: timeframe,
            pair: pair,
            marketContext: marketContext
        )

            // 4. Get Crypto-Specific Indicators
        let cryptoIndicators = await analyzeCryptoIndicators(
            candles: candles,
            pair: pair,
            timeframe: timeframe
        )

            // 5. Adaptive Weight Calculation based on market conditions
        let adaptedWeights = settings.adaptiveWeighting ?
        calculateAdaptiveWeights(
            marketContext: marketContext,
            baseSettings: settings,
            cryptoIndicators: cryptoIndicators
        ) : (settings.aiWeight, settings.strategyWeight, settings.cryptoIndicatorsWeight)

            // 6. Enhanced Signal Combination with crypto metrics
        let (finalDirection, finalConfidence, signalStrength) = combineEnhancedSignals(
            ai: aiComponent,
            strategy: strategyComponent,
            crypto: cryptoIndicators,
            weights: adaptedWeights,
            marketContext: marketContext
        )

            // 7. Calculate Risk Metrics
        let riskMetrics = calculateRiskMetrics(
            direction: finalDirection,
            confidence: finalConfidence,
            candles: candles,
            volatility: marketContext.volatility,
            settings: settings
        )

            // 8. Apply filters and safety checks
        let filteredDirection = applyRiskFilters(
            direction: finalDirection,
            confidence: finalConfidence,
            riskMetrics: riskMetrics,
            cryptoIndicators: cryptoIndicators,
            settings: settings
        )

        let metaSignal = MetaSignal(
            direction: filteredDirection,
            confidence: finalConfidence,
            strength: signalStrength,
            source: "Enhanced MetaSignal v2.0",
            timestamp: Date(),
            aiComponent: aiComponent,
            strategyComponent: strategyComponent,
            cryptoIndicators: cryptoIndicators,
            riskMetrics: riskMetrics,
            metadata: [
                "timeframe": timeframe.rawValue,
                "pair": pair.symbol,
                "marketSentiment": marketSentiment,
                "volatilityRegime": volatilityRegime,
                "adaptedWeights": adaptedWeights
            ]
        )

        lastMetaSignal = metaSignal

        os_log("[META] Enhanced signal: %@ conf=%.2f strength=%@",
               log: Log.ai, type: .info,
               filteredDirection.rawValue,
               finalConfidence,
               String(describing: signalStrength))

        return metaSignal
    }

        // MARK: - Market Context Analysis
    private func analyzeMarketContext(candles: [Candle], pair: TradingPair) async -> MarketContext {
        let closes = candles.map { $0.close }
        let volumes = candles.map { $0.volume }

            // Calculate volatility regime
        let volatility = calculateRealizedVolatility(closes, period: 20)
        let volatilityPercentile = calculateVolatilityPercentile(volatility, historical: closes)

        let regime: VolatilityRegime
        if volatilityPercentile < 25 {
            regime = .low
        } else if volatilityPercentile < 75 {
            regime = .normal
        } else if volatilityPercentile < 90 {
            regime = .high
        } else {
            regime = .extreme
        }

            // Calculate market sentiment (simplified)
        let rsi = calculateRSI(closes)
        let volumeTrend = calculateVolumeTrend(volumes)

        let sentiment: MarketSentiment
        if rsi < 20 {
            sentiment = .extremeFear
        } else if rsi < 40 {
            sentiment = .fear
        } else if rsi < 60 {
            sentiment = .neutral
        } else if rsi < 80 {
            sentiment = .greed
        } else {
            sentiment = .extremeGreed
        }

        return MarketContext(
            sentiment: sentiment,
            volatility: regime,
            trend: calculateTrend(closes),
            volumeProfile: analyzeVolumeProfile(volumes),
            microstructure: analyzeMicrostructure(candles)
        )
    }

        // MARK: - Enhanced AI Prediction
    private func getEnhancedAIPrediction(
        candles: [Candle],
        timeframe: Timeframe,
        marketContext: MarketContext
    ) async -> MetaSignal.AIComponent? {
        
        // Build enhanced feature set
        let features = await buildEnhancedFeatures(
            from: candles,
            marketContext: marketContext
        )
        
        do {
            // Try to get prediction based on timeframe
            let prediction: MLFeatureProvider  // Changed from AIModelOutput
            
            switch timeframe {
            case .h4:
                prediction = try aiModelManager.predict4H(explicitInputs: features)
                
            case .h1:
                // For 1H, we'll use 4H model with adjusted features
                // Since predict1H doesn't exist in AIModelManager
                prediction = try aiModelManager.predict4H(explicitInputs: features)
                
            case .d1:
                // For daily, also use 4H model with adjusted confidence
                prediction = try aiModelManager.predict4H(explicitInputs: features)
                
            default:
                // For other timeframes (m1, m5, m15), use 4H model with reduced confidence
                prediction = try aiModelManager.predict4H(explicitInputs: features)
            }
            
            // Parse the prediction and adjust confidence based on timeframe
            let aiComponent = parseAIPrediction(prediction, features: features)
            
            // Adjust confidence based on timeframe mismatch
            if timeframe != .h4, let component = aiComponent {
                let adjustmentFactor: Double
                switch timeframe {
                case .h1:
                    adjustmentFactor = 0.9  // Slightly reduced confidence
                case .d1:
                    adjustmentFactor = 0.85  // Daily is further from 4H
                case .m15, .m5, .m1:
                    adjustmentFactor = 0.7  // Much reduced for short timeframes
                default:
                    adjustmentFactor = 0.8
                }
                
                // Create updated component with adjusted confidence
                let updatedComponent = MetaSignal.AIComponent(
                    prediction: component.prediction,
                    confidence: component.confidence * adjustmentFactor,
                    modelUsed: "BTC_4H_Model (adapted for \(timeframe.rawValue))",
                    weight: component.weight,
                    features: component.features
                )
                
                return updatedComponent
            }
            
            return aiComponent
            
        } catch {
            os_log("[AI] Enhanced prediction failed: %@", log: Log.ai, type: .error, error.localizedDescription)
            return nil
        }
    }

        // MARK: - Crypto-Specific Strategy Ensemble
    private func getCryptoStrategyEnsemble(
        candles: [Candle],
        timeframe: Timeframe,
        pair: TradingPair,
        marketContext: MarketContext
    ) async -> MetaSignal.StrategyComponent? {

            // Get base strategy signal
        guard let baseSignal = await getStrategyEnsemble(candles: candles, timeframe: timeframe, pair: pair) else {
            return nil
        }

            // Apply crypto-specific enhancements
        let enhancedSignal = applyCryptoEnhancements(
            to: baseSignal,
            candles: candles,
            marketContext: marketContext
        )

            // Identify winning strategies
        let winningStrategies = identifyWinningStrategies(
            signal: enhancedSignal,
            candles: candles
        )

        return MetaSignal.StrategyComponent(
            ensemble: enhancedSignal,
            votePurity: calculateVotePurity(enhancedSignal),
            contributingStrategiesCount: winningStrategies.count,
            weight: calculateStrategyWeight(marketContext: marketContext),
            winningStrategies: winningStrategies
        )
    }

        // MARK: - Crypto Indicators Analysis
    private func analyzeCryptoIndicators(
        candles: [Candle],
        pair: TradingPair,
        timeframe: Timeframe
    ) async -> MetaSignal.CryptoIndicators {

        let closes = candles.map { $0.close }
        let volumes = candles.map { $0.volume }

            // Calculate crypto-specific metrics
        let nvt = calculateNVTRatio(closes: closes, volumes: volumes)
        let hashRibbons = analyzeHashRibbons(candles: candles)
        let whaleActivity = detectWhaleActivity(volumes: volumes, closes: closes)
        let exchangeFlows = analyzeExchangeFlows(candles: candles)
        let fundingRate = calculateFundingRate(pair: pair)
        let openInterest = getOpenInterest(pair: pair)
        let fearGreed = calculateFearGreedIndex(candles: candles)
        let socialSentiment = analyzeSocialSentiment(pair: pair)
        let btcCorrelation = calculateBTCCorrelation(candles: candles, pair: pair)
        let defiTVL = pair.symbol.contains("DEFI") ? getDefiTVL(pair: pair) : nil

        return MetaSignal.CryptoIndicators(
            nvtRatio: nvt,
            hashRibbons: hashRibbons,
            whaleActivity: whaleActivity,
            exchangeFlows: exchangeFlows,
            fundingRate: fundingRate,
            openInterest: openInterest,
            fearGreedIndex: fearGreed,
            socialSentiment: socialSentiment,
            correlationBTC: btcCorrelation,
            defiTVL: defiTVL
        )
    }

        // MARK: - Advanced Crypto Indicators
    private func calculateNVTRatio(closes: [Double], volumes: [Double]) -> Double? {
        guard !closes.isEmpty && !volumes.isEmpty else { return nil }

            // NVT = Market Cap / Transaction Volume
            // For crypto: using price * volume as proxy
        let marketCap = closes.last ?? 0
        let transactionVolume = volumes.suffix(30).reduce(0, +) / 30  // 30-day average

        guard transactionVolume > 0 else { return nil }
        return marketCap / transactionVolume
    }

    private func analyzeHashRibbons(candles: [Candle]) -> String {
            // Hash Ribbons: Mining difficulty impact on price
            // Simplified version - in production would use actual hash rate data
        let closes = candles.map { $0.close }
        let ma30 = calculateSMA(closes, period: 30)
        let ma60 = calculateSMA(closes, period: 60)

        if ma30 > ma60 * 1.02 {
            return "bullish_cross"  // Miner capitulation ended
        } else if ma30 < ma60 * 0.98 {
            return "bearish_cross"  // Miner capitulation
        } else {
            return "neutral"
        }
    }

    private func detectWhaleActivity(volumes: [Double], closes: [Double]) -> MetaSignal.WhaleSignal {
        guard volumes.count > 20 else {
            return MetaSignal.WhaleSignal(netFlow: 0, intensity: "low")
        }

            // Detect unusual volume spikes (whale activity)
        let avgVolume = volumes.suffix(20).reduce(0, +) / 20
        let stdDevVolume = calculateStandardDeviation(Array(volumes.suffix(20)))
        let lastVolume = volumes.last ?? 0

        let zScore = (lastVolume - avgVolume) / stdDevVolume

            // Determine intensity
        let intensity: String
        if abs(zScore) > 3 {
            intensity = "high"
        } else if abs(zScore) > 2 {
            intensity = "moderate"
        } else {
            intensity = "low"
        }

            // Determine direction (simplified - would use order flow in production)
        let priceChange = closes.count > 1 ? closes.last! - closes[closes.count - 2] : 0
        let netFlow = zScore * (priceChange > 0 ? 1 : -1) * 100

        return MetaSignal.WhaleSignal(netFlow: netFlow, intensity: intensity)
    }

    private func analyzeExchangeFlows(candles: [Candle]) -> MetaSignal.ExchangeFlow {
            // Simplified exchange flow analysis
            // In production, would use actual blockchain data
        let volumes = candles.map { $0.volume }
        let closes = candles.map { $0.close }

            // Use volume-weighted price as proxy
        let vwap = calculateVWAP(candles)
        let currentPrice = closes.last ?? 0

        let netFlow = (currentPrice - vwap) / vwap * 100
        let direction = netFlow > 0 ? "outflow" : "inflow"

        return MetaSignal.ExchangeFlow(
            netFlow: netFlow,
            dominantDirection: direction
        )
    }

    private func calculateFearGreedIndex(candles: [Candle]) -> Int {
        let closes = candles.map { $0.close }

            // Simplified Fear & Greed calculation
        var score = 50  // Start neutral

            // RSI component
        let rsi = calculateRSI(closes)
        if rsi > 70 {
            score += 20  // Greed
        } else if rsi < 30 {
            score -= 20  // Fear
        }

            // Volatility component
        let volatility = calculateRealizedVolatility(closes, period: 30)
        if volatility < 0.02 {
            score += 15  // Low volatility = greed
        } else if volatility > 0.05 {
            score -= 15  // High volatility = fear
        }

            // Momentum component
        let momentum = calculateMomentum(closes, period: 10)
        score += Int(momentum * 100)

        return max(0, min(100, score))
    }

        // MARK: - Enhanced Signal Combination
    private func combineEnhancedSignals(
        ai: MetaSignal.AIComponent?,
        strategy: MetaSignal.StrategyComponent?,
        crypto: MetaSignal.CryptoIndicators?,
        weights: (ai: Double, strategy: Double, crypto: Double),
        marketContext: MarketContext
    ) -> (SignalDirection, Double, MetaSignal.SignalStrength) {

        var buyScore: Double = 0
        var sellScore: Double = 0
        var holdScore: Double = 0
        var totalWeight: Double = 0

            // AI contribution
        if let ai = ai {
            totalWeight += weights.ai
            switch ai.prediction {
            case "BUY":
                buyScore += ai.confidence * weights.ai
            case "SELL":
                sellScore += ai.confidence * weights.ai
            default:
                holdScore += ai.confidence * weights.ai
            }
        }

            // Strategy contribution
        if let strategy = strategy {
            totalWeight += weights.strategy
            switch strategy.ensemble.direction {
            case .buy:
                buyScore += strategy.ensemble.confidence * weights.strategy
            case .sell:
                sellScore += strategy.ensemble.confidence * weights.strategy
            case .hold:
                holdScore += strategy.ensemble.confidence * weights.strategy
            }
        }

            // Crypto indicators contribution
        if let crypto = crypto {
            totalWeight += weights.crypto
            let cryptoSignal = interpretCryptoIndicators(crypto)

            switch cryptoSignal.direction {
            case .buy:
                buyScore += cryptoSignal.confidence * weights.crypto
            case .sell:
                sellScore += cryptoSignal.confidence * weights.crypto
            case .hold:
                holdScore += cryptoSignal.confidence * weights.crypto
            }
        }

            // Normalize and apply market context adjustments
        if totalWeight > 0 {
            buyScore /= totalWeight
            sellScore /= totalWeight
            holdScore /= totalWeight

                // Apply sentiment multiplier
            buyScore *= marketContext.sentiment.multiplier
            sellScore *= (2.0 - marketContext.sentiment.multiplier)
        }

        let maxScore = max(buyScore, sellScore, holdScore)

            // Determine direction and strength
        let direction: SignalDirection
        if maxScore == buyScore {
            direction = .buy
        } else if maxScore == sellScore {
            direction = .sell
        } else {
            direction = .hold
        }

            // Calculate signal strength
        let strength = calculateSignalStrength(
            confidence: maxScore,
            convergence: calculateConvergence(ai: ai, strategy: strategy, crypto: crypto)
        )

        return (direction, maxScore, strength)
    }

        // MARK: - Risk Management
    private func calculateRiskMetrics(
        direction: SignalDirection,
        confidence: Double,
        candles: [Candle],
        volatility: VolatilityRegime,
        settings: MetaSignalSettings
    ) -> MetaSignal.RiskMetrics {

        guard let lastCandle = candles.last else {
            return MetaSignal.RiskMetrics(
                suggestedPositionSize: 0.01,
                stopLoss: 0,
                takeProfit: [],
                riskRewardRatio: 0,
                maxDrawdownExpected: 0,
                confidenceInterval: (0, 0),
                kellyFraction: 0
            )
        }

        let atr = calculateATR(candles.map { $0.high }, candles.map { $0.low }, candles.map { $0.close }, period: 14)
        let currentPrice = lastCandle.close

            // Calculate position size using Kelly Criterion
        let winRate = confidence
        let avgWin = atr * 2  // Expected profit in ATR units
        let avgLoss = atr     // Expected loss in ATR units
        let kellyFraction = calculateKellyCriterion(
            winProbability: winRate,
            winAmount: avgWin,
            lossAmount: avgLoss
        )

            // Adjust for risk profile
        let riskMultiplier: Double
        switch settings.riskProfile {
        case .conservative:
            riskMultiplier = 0.25
        case .balanced:
            riskMultiplier = 0.5
        case .aggressive:
            riskMultiplier = 0.75
        case .degen:
            riskMultiplier = 1.0
        }

        let positionSize = min(kellyFraction * riskMultiplier, 0.1)  // Cap at 10% max

            // Calculate stop loss based on ATR and volatility
        let stopDistance = atr * volatility.stopLossMultiplier
        let stopLoss = direction == .buy ?
        currentPrice - stopDistance :
        currentPrice + stopDistance

            // Multiple take profit levels
        let takeProfits = [
            currentPrice + (direction == .buy ? 1 : -1) * atr * 1.5,
            currentPrice + (direction == .buy ? 1 : -1) * atr * 2.5,
            currentPrice + (direction == .buy ? 1 : -1) * atr * 4.0
        ]

            // Risk-reward ratio
        let riskAmount = abs(currentPrice - stopLoss)
        let rewardAmount = abs(takeProfits[0] - currentPrice)
        let rrRatio = rewardAmount / riskAmount

            // Expected drawdown
        let maxDrawdown = calculateExpectedDrawdown(
            volatility: calculateRealizedVolatility(candles.map { $0.close }, period: 30),
            timeHorizon: 24  // hours
        )

            // Confidence interval for price
        let priceStdDev = calculateStandardDeviation(candles.suffix(20).map { $0.close })
        let confidenceInterval = (
            lower: currentPrice - 1.96 * priceStdDev,
            upper: currentPrice + 1.96 * priceStdDev
        )

        return MetaSignal.RiskMetrics(
            suggestedPositionSize: positionSize,
            stopLoss: stopLoss,
            takeProfit: takeProfits,
            riskRewardRatio: rrRatio,
            maxDrawdownExpected: maxDrawdown,
            confidenceInterval: confidenceInterval,
            kellyFraction: kellyFraction
        )
    }

        // MARK: - Helper Methods
    private func calculateKellyCriterion(
        winProbability: Double,
        winAmount: Double,
        lossAmount: Double
    ) -> Double {
        guard lossAmount > 0 else { return 0 }
        let b = winAmount / lossAmount
        let p = winProbability
        let q = 1 - p

            // Kelly formula: f = (bp - q) / b
        let kelly = (b * p - q) / b

            // Use fractional Kelly (25%) for safety
        return max(0, min(kelly * 0.25, 0.25))
    }

    private func calculateExpectedDrawdown(volatility: Double, timeHorizon: Double) -> Double {
            // Simplified expected maximum drawdown
            // E[MDD] ≈ 2.24 * σ * sqrt(T)
        return 2.24 * volatility * sqrt(timeHorizon / 24)
    }

    private func interpretCryptoIndicators(_ indicators: MetaSignal.CryptoIndicators) -> (direction: SignalDirection, confidence: Double) {
        var bullishPoints = 0.0
        var bearishPoints = 0.0

            // Whale activity
        if indicators.whaleActivity.netFlow > 50 {
            bullishPoints += 2
        } else if indicators.whaleActivity.netFlow < -50 {
            bearishPoints += 2
        }

            // Exchange flows (negative = bullish)
        if indicators.exchangeFlows.netFlow < -10 {
            bullishPoints += 1.5
        } else if indicators.exchangeFlows.netFlow > 10 {
            bearishPoints += 1.5
        }

            // Fear & Greed (contrarian at extremes)
        if indicators.fearGreedIndex < 20 {
            bullishPoints += 1  // Extreme fear = buying opportunity
        } else if indicators.fearGreedIndex > 80 {
            bearishPoints += 1  // Extreme greed = selling opportunity
        }

            // Hash ribbons
        if indicators.hashRibbons == "bullish_cross" {
            bullishPoints += 2
        } else if indicators.hashRibbons == "bearish_cross" {
            bearishPoints += 2
        }

            // Funding rate (negative = bullish squeeze potential)
        if let funding = indicators.fundingRate {
            if funding < -0.01 {
                bullishPoints += 1
            } else if funding > 0.05 {
                bearishPoints += 1
            }
        }

        let total = bullishPoints + bearishPoints
        guard total > 0 else {
            return (.hold, 0.5)
        }

        if bullishPoints > bearishPoints {
            return (.buy, bullishPoints / total)
        } else if bearishPoints > bullishPoints {
            return (.sell, bearishPoints / total)
        } else {
            return (.hold, 0.5)
        }
    }

    private func calculateSignalStrength(confidence: Double, convergence: Double) -> MetaSignal.SignalStrength {
        let score = (confidence + convergence) / 2

        if score >= 0.8 {
            return .veryStrong
        } else if score >= 0.65 {
            return .strong
        } else if score >= 0.5 {
            return .moderate
        } else {
            return .weak
        }
    }

    private func calculateConvergence(
        ai: MetaSignal.AIComponent?,
        strategy: MetaSignal.StrategyComponent?,
        crypto: MetaSignal.CryptoIndicators?
    ) -> Double {
        var signals: [String] = []

        if let ai = ai {
            signals.append(ai.prediction)
        }

        if let strategy = strategy {
            signals.append(strategy.ensemble.direction.rawValue.uppercased())
        }

        if let crypto = crypto {
            let cryptoSignal = interpretCryptoIndicators(crypto)
            signals.append(cryptoSignal.direction.rawValue.uppercased())
        }

        guard signals.count > 1 else { return 0.5 }

            // Check how many signals agree
        let uniqueSignals = Set(signals)
        if uniqueSignals.count == 1 {
            return 1.0  // Perfect convergence
        } else if uniqueSignals.count == signals.count {
            return 0.0  // No convergence
        } else {
            return 0.5  // Partial convergence
        }
    }

        // MARK: - Additional Crypto Helpers
    private func calculateVolumeTrend(_ volumes: [Double]) -> Double {
        guard volumes.count > 20 else { return 0 }

        let shortMA = volumes.suffix(5).reduce(0, +) / 5
        let longMA = volumes.suffix(20).reduce(0, +) / 20

        guard longMA > 0 else { return 0 }
        return (shortMA - longMA) / longMA
    }

    private func calculateMomentum(_ closes: [Double], period: Int) -> Double {
        guard closes.count > period,
              let current = closes.last,
              let previous = closes.dropLast(period).last,
              previous > 0 else { return 0 }

        return (current - previous) / previous
    }

    private func calculateRealizedVolatility(_ closes: [Double], period: Int) -> Double {
        guard closes.count > period else { return 0 }

        let returns = (1..<closes.count).map { i in
            log(closes[i] / closes[i-1])
        }

        let recentReturns = Array(returns.suffix(period))
        return calculateStandardDeviation(recentReturns) * sqrt(365.0)  // Annualized
    }

    private func calculateVolatilityPercentile(_ currentVol: Double, historical: [Double]) -> Double {
        guard historical.count > 100 else { return 50 }

        let historicalVols = (100..<historical.count).map { i in
            calculateRealizedVolatility(Array(historical[(i-100)...i]), period: 20)
        }

        let belowCount = historicalVols.filter { $0 < currentVol }.count
        return Double(belowCount) / Double(historicalVols.count) * 100
    }

    private func calculateTrend(_ closes: [Double]) -> String {
        guard closes.count > 50 else { return "neutral" }

        let ma20 = calculateSMA(closes, period: 20)
        let ma50 = calculateSMA(closes, period: 50)
        let currentPrice = closes.last ?? 0

        if currentPrice > ma20 && ma20 > ma50 {
            return "strong_uptrend"
        } else if currentPrice > ma20 || currentPrice > ma50 {
            return "uptrend"
        } else if currentPrice < ma20 && ma20 < ma50 {
            return "strong_downtrend"
        } else if currentPrice < ma20 || currentPrice < ma50 {
            return "downtrend"
        } else {
            return "neutral"
        }
    }

    private func analyzeVolumeProfile(_ volumes: [Double]) -> String {
        guard volumes.count > 20 else { return "normal" }

        let recent = Array(volumes.suffix(5))
        let historical = Array(volumes.suffix(20))

        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let historicalAvg = historical.reduce(0, +) / Double(historical.count)

        if recentAvg > historicalAvg * 1.5 {
            return "high_volume"
        } else if recentAvg < historicalAvg * 0.5 {
            return "low_volume"
        } else {
            return "normal"
        }
    }

    private func analyzeMicrostructure(_ candles: [Candle]) -> MicrostructureProfile {
            // Analyze bid-ask spread, order flow imbalance, etc.
            // Simplified version
        let spreads = candles.map { ($0.high - $0.low) / $0.close }
        let avgSpread = spreads.reduce(0, +) / Double(spreads.count)

        return MicrostructureProfile(
            averageSpread: avgSpread,
            liquidityScore: avgSpread < 0.001 ? "high" : avgSpread < 0.005 ? "medium" : "low",
            orderFlowImbalance: 0  // Would need order book data
        )
    }

        // MARK: - Support Structures
    private struct MarketContext {
        let sentiment: MarketSentiment
        let volatility: VolatilityRegime
        let trend: String
        let volumeProfile: String
        let microstructure: MicrostructureProfile
    }

    private struct MicrostructureProfile {
        let averageSpread: Double
        let liquidityScore: String
        let orderFlowImbalance: Double
    }

        // Existing helper methods remain...
        // (Keep all the existing calculateSMA, calculateEMA, etc. methods from the original)
}

    // MARK: - Extensions remain the same
extension MetaSignalEngine.MetaSignal {
    public func toSignalInfo() -> SignalInfo {
        let reason = buildReasonString()

        return SignalInfo(
            direction: direction.rawValue,
            confidence: confidence,
            reason: reason,
            timestamp: timestamp
        )
    }

    private func buildReasonString() -> String {
        var components: [String] = []

        components.append(direction.rawValue)
        components.append("\(Int(confidence * 100))%")
        components.append("Strength: \(strength)")

        if let crypto = cryptoIndicators {
            components.append("F&G: \(crypto.fearGreedIndex)")
            components.append("Whale: \(crypto.whaleActivity.intensity)")
        }

        if let timeframe = metadata["timeframe"] as? String,
           let pair = metadata["pair"] as? String {
            components.append("\(pair)")
            components.append(timeframe)
        }

        return components.joined(separator: " • ")
    }
}

// PART 1: Add this extension at the END of MetaSignalEngine.swift file
// This contains ALL missing helper functions

extension MetaSignalEngine {
    
    // MARK: - Missing Helper Functions
    
    // Type alias for compatibility
    typealias AIModelOutput = MLFeatureProvider
    
    // MARK: - Adaptive Weights Calculation
    private func calculateAdaptiveWeights(
        marketContext: MarketContext,
        baseSettings: MetaSignalSettings,
        cryptoIndicators: MetaSignal.CryptoIndicators?
    ) -> (ai: Double, strategy: Double, crypto: Double) {
        
        var aiWeight = baseSettings.aiWeight
        var strategyWeight = baseSettings.strategyWeight
        var cryptoWeight = baseSettings.cryptoIndicatorsWeight
        
        // Adjust weights based on market conditions
        switch marketContext.volatility {
        case .extreme:
            // In extreme volatility, rely more on technical strategies
            strategyWeight *= 1.3
            aiWeight *= 0.8
            cryptoWeight *= 0.9
        case .high:
            strategyWeight *= 1.1
            aiWeight *= 0.95
        case .low:
            // In low volatility, AI predictions more reliable
            aiWeight *= 1.2
            strategyWeight *= 0.9
        case .normal:
            break // Keep base weights
        }
        
        // Adjust for sentiment
        switch marketContext.sentiment {
        case .extremeFear, .extremeGreed:
            // At extremes, crypto indicators more important
            cryptoWeight *= 1.2
            aiWeight *= 0.9
        default:
            break
        }
        
        // Normalize weights to sum to 1
        let total = aiWeight + strategyWeight + cryptoWeight
        return (
            ai: aiWeight / total,
            strategy: strategyWeight / total,
            crypto: cryptoWeight / total
        )
    }
    
    // MARK: - Risk Filters
    private func applyRiskFilters(
        direction: SignalDirection,
        confidence: Double,
        riskMetrics: MetaSignal.RiskMetrics,
        cryptoIndicators: MetaSignal.CryptoIndicators?,
        settings: MetaSignalSettings
    ) -> SignalDirection {
        
        // Filter 1: Minimum confidence threshold
        let threshold = settings.minConfidenceThresholds[.h4] ?? 0.60
        if confidence < threshold {
            return .hold
        }
        
        // Filter 2: Risk-reward ratio check
        if riskMetrics.riskRewardRatio < 1.5 {
            return .hold // Not worth the risk
        }
        
        // Filter 3: Extreme market conditions
        if let crypto = cryptoIndicators {
            // Don't buy at extreme greed
            if direction == .buy && crypto.fearGreedIndex > 85 {
                return .hold
            }
            // Don't sell at extreme fear
            if direction == .sell && crypto.fearGreedIndex < 15 {
                return .hold
            }
        }
        
        // Filter 4: Position size too small
        if riskMetrics.suggestedPositionSize < 0.005 {
            return .hold // Position too small to be worth it
        }
        
        return direction
    }
    
    // MARK: - Enhanced Features Building
    private func buildEnhancedFeatures(
        from candles: [Candle],
        marketContext: MarketContext
    ) async -> [String: NSNumber] {
        
        guard candles.count >= 50 else {
            return [:]
        }
        
        let closes = candles.map { $0.close }
        let volumes = candles.map { $0.volume }
        let highs = candles.map { $0.high }
        let lows = candles.map { $0.low }
        
        var features: [String: NSNumber] = [:]
        
        // Price returns
        if closes.count > 1 {
            features["return_1"] = NSNumber(value: (closes.last! - closes[closes.count - 2]) / closes[closes.count - 2])
        }
        if closes.count > 3 {
            features["return_3"] = NSNumber(value: (closes.last! - closes[closes.count - 4]) / closes[closes.count - 4])
        }
        if closes.count > 5 {
            features["return_5"] = NSNumber(value: (closes.last! - closes[closes.count - 6]) / closes[closes.count - 6])
        }
        
        // Technical indicators
        features["rsi"] = NSNumber(value: calculateRSI(closes))
        features["volatility"] = NSNumber(value: calculateRealizedVolatility(closes, period: 20))
        features["macd_hist"] = NSNumber(value: calculateMACDHistogram(closes))
        features["ema_ratio"] = NSNumber(value: calculateEMARatio(closes))
        features["volume_z"] = NSNumber(value: calculateVolumeZScore(volumes))
        
        // Price position
        if let lastHigh = highs.last, let lastLow = lows.last, let lastClose = closes.last {
            features["high_low_range"] = NSNumber(value: (lastHigh - lastLow) / lastClose)
            features["price_position"] = NSNumber(value: (lastClose - lastLow) / max(lastHigh - lastLow, 0.0001))
        }
        
        // ATR and Stochastic
        features["atr_14"] = NSNumber(value: calculateATR(highs, lows, closes, period: 14))
        let (stochK, stochD) = calculateStochastic(highs, lows, closes)
        features["stoch_k"] = NSNumber(value: stochK)
        features["stoch_d"] = NSNumber(value: stochD)
        features["bb_percent"] = NSNumber(value: calculateBollingerBandPercent(closes))
        
        // Add market context features
        features["market_sentiment"] = NSNumber(value: marketContext.sentiment == .greed ? 1.0 : marketContext.sentiment == .fear ? -1.0 : 0.0)
        features["volatility_regime"] = NSNumber(value: marketContext.volatility == .high ? 1.0 : marketContext.volatility == .low ? -1.0 : 0.0)
        
        return features
    }
    
    // MARK: - Parse AI Prediction
    private func parseAIPrediction(_ prediction: AIModelOutput, features: [String: NSNumber]) -> MetaSignal.AIComponent? {
        
        // Try to get output from model
        if let outputArray = prediction.featureValue(for: "Identity")?.multiArrayValue {
            let buyProb = outputArray[0].doubleValue
            let sellProb = outputArray.count > 1 ? outputArray[1].doubleValue : 0
            let holdProb = outputArray.count > 2 ? outputArray[2].doubleValue : 1 - buyProb - sellProb
            
            let maxProb = max(buyProb, sellProb, holdProb)
            let predictionStr: String
            
            if maxProb == buyProb {
                predictionStr = "BUY"
            } else if maxProb == sellProb {
                predictionStr = "SELL"
            } else {
                predictionStr = "HOLD"
            }
            
            return MetaSignal.AIComponent(
                prediction: predictionStr,
                confidence: maxProb,
                modelUsed: "BTC_4H_Model",
                weight: 0.4,
                features: features.mapValues { $0.doubleValue }
            )
        }
        
        return nil
    }
    
    // MARK: - Apply Crypto Enhancements
    private func applyCryptoEnhancements(
        to signal: StrategySignal,
        candles: [Candle],
        marketContext: MarketContext
    ) -> StrategySignal {
        
        var enhancedConfidence = signal.confidence
        
        // Boost confidence in trending markets
        if marketContext.trend == "strong_uptrend" && signal.direction == .buy {
            enhancedConfidence *= 1.1
        } else if marketContext.trend == "strong_downtrend" && signal.direction == .sell {
            enhancedConfidence *= 1.1
        }
        
        // Reduce confidence in choppy markets
        if marketContext.volatility == .extreme {
            enhancedConfidence *= 0.9
        }
        
        // Cap confidence
        enhancedConfidence = min(enhancedConfidence, 0.95)
        
        return StrategySignal(
            direction: signal.direction,
            confidence: enhancedConfidence,
            reason: signal.reason + " (crypto-enhanced)",
            strategyName: signal.strategyName
        )
    }
    
    // MARK: - Identify Winning Strategies
    private func identifyWinningStrategies(
        signal: StrategySignal,
        candles: [Candle]
    ) -> [String] {
        
        var strategies: [String] = []
        
        // Check RSI
        let rsi = calculateRSI(candles.map { $0.close })
        if (rsi < 30 && signal.direction == .buy) || (rsi > 70 && signal.direction == .sell) {
            strategies.append("RSI")
        }
        
        // Check MACD
        let macd = calculateMACDHistogram(candles.map { $0.close })
        if (macd > 0 && signal.direction == .buy) || (macd < 0 && signal.direction == .sell) {
            strategies.append("MACD")
        }
        
        // Check Volume
        let volumeTrend = calculateVolumeTrend(candles.map { $0.volume })
        if volumeTrend > 0.2 {
            strategies.append("Volume")
        }
        
        // Always include base strategy
        strategies.append(signal.strategyName)
        
        return strategies
    }
    
    // MARK: - Calculate Vote Purity
    private func calculateVotePurity(_ signal: StrategySignal) -> Double {
        // Simplified - in production would analyze individual strategy votes
        return signal.confidence
    }
    
    // MARK: - Calculate Strategy Weight
    private func calculateStrategyWeight(marketContext: MarketContext) -> Double {
        var weight = 0.4 // Base weight
        
        // Adjust based on market conditions
        switch marketContext.volatility {
        case .high, .extreme:
            weight *= 1.2 // Technical strategies more important in volatile markets
        case .low:
            weight *= 0.9
        default:
            break
        }
        
        return weight
    }
    
    // MARK: - Get Strategy Ensemble (compatibility)
    private func getStrategyEnsemble(
        candles: [Candle],
        timeframe: Timeframe,
        pair: TradingPair
    ) async -> StrategySignal? {
        
        let ensembleSignal = await strategyManager.generateSignals(from: candles)
        
        let direction: StrategySignal.Direction
        switch ensembleSignal.direction {
        case .buy:
            direction = .buy
        case .sell:
            direction = .sell
        case .hold:
            direction = .hold
        }
        
        return StrategySignal(
            direction: direction,
            confidence: ensembleSignal.confidence,
            reason: ensembleSignal.reason,
            strategyName: "Ensemble"
        )
    }
    
    // MARK: - Market Data Helpers (Mock implementations)
    private func calculateFundingRate(pair: TradingPair) -> Double? {
        // Mock implementation - would fetch from exchange API
        return 0.01
    }
    
    private func getOpenInterest(pair: TradingPair) -> Double? {
        // Mock implementation - would fetch from exchange API
        return 1000000
    }
    
    private func analyzeSocialSentiment(pair: TradingPair) -> Double {
        // Mock implementation - would use sentiment analysis API
        return 0.5
    }
    
    private func calculateBTCCorrelation(candles: [Candle], pair: TradingPair) -> Double {
        // Mock implementation - would calculate actual correlation
        return pair.symbol.contains("BTC") ? 1.0 : 0.7
    }
    
    private func getDefiTVL(pair: TradingPair) -> Double? {
        // Mock implementation - would fetch from DeFi APIs
        return nil
    }
    
    // MARK: - Technical Indicators
    private func calculateRSI(_ closes: [Double], period: Int = 14) -> Double {
        guard closes.count > period else { return 50.0 }
        
        let changes = (1..<closes.count).map { closes[$0] - closes[$0-1] }
        let gains = changes.suffix(period).map { max($0, 0) }
        let losses = changes.suffix(period).map { abs(min($0, 0)) }
        
        let avgGain = gains.reduce(0, +) / Double(gains.count)
        let avgLoss = losses.reduce(0, +) / Double(losses.count)
        
        guard avgLoss != 0 else { return 100.0 }
        let rs = avgGain / avgLoss
        return 100 - (100 / (1 + rs))
    }
    
    private func calculateSMA(_ closes: [Double], period: Int) -> Double {
        guard closes.count >= period else { return closes.last ?? 0 }
        return closes.suffix(period).reduce(0, +) / Double(period)
    }
    
    private func calculateATR(_ highs: [Double], _ lows: [Double], _ closes: [Double], period: Int) -> Double {
        guard highs.count > period, highs.count == lows.count, lows.count == closes.count else { return 0.0 }
        
        var trueRanges: [Double] = []
        for i in 1..<highs.count {
            let tr1 = highs[i] - lows[i]
            let tr2 = abs(highs[i] - closes[i-1])
            let tr3 = abs(lows[i] - closes[i-1])
            trueRanges.append(max(tr1, tr2, tr3))
        }
        
        guard !trueRanges.isEmpty else { return 0.0 }
        return trueRanges.suffix(period).reduce(0, +) / Double(min(period, trueRanges.count))
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    private func calculateVWAP(_ candles: [Candle]) -> Double {
        guard !candles.isEmpty else { return 0 }
        
        var totalVolume = 0.0
        var totalVolumePrice = 0.0
        
        for candle in candles {
            let typicalPrice = (candle.high + candle.low + candle.close) / 3
            totalVolumePrice += typicalPrice * candle.volume
            totalVolume += candle.volume
        }
        
        return totalVolume > 0 ? totalVolumePrice / totalVolume : 0
    }
    
    // MARK: - Additional Technical Indicators
    private func calculateMACDHistogram(_ closes: [Double]) -> Double {
        guard closes.count > 26 else { return 0 }
        
        let ema12 = calculateEMA(closes, period: 12)
        let ema26 = calculateEMA(closes, period: 26)
        let macdLine = ema12 - ema26
        
        // For simplicity, return MACD line instead of histogram
        return macdLine
    }
    
    private func calculateEMA(_ closes: [Double], period: Int) -> Double {
        guard closes.count >= period else { return closes.last ?? 0 }
        
        let multiplier = 2.0 / Double(period + 1)
        var ema = closes[period - 1] // Start with SMA
        
        for i in period..<closes.count {
            ema = (closes[i] - ema) * multiplier + ema
        }
        
        return ema
    }
    
    private func calculateEMARatio(_ closes: [Double]) -> Double {
        guard closes.count > 20 else { return 1.0 }
        
        let ema10 = calculateEMA(closes, period: 10)
        let ema20 = calculateEMA(closes, period: 20)
        
        guard ema20 > 0 else { return 1.0 }
        return ema10 / ema20
    }
    
    private func calculateVolumeZScore(_ volumes: [Double]) -> Double {
        guard volumes.count > 20 else { return 0 }
        
        let recent = Array(volumes.suffix(20))
        let mean = recent.reduce(0, +) / Double(recent.count)
        let stdDev = calculateStandardDeviation(recent)
        
        guard stdDev > 0, let lastVolume = volumes.last else { return 0 }
        return (lastVolume - mean) / stdDev
    }
    
    private func calculateStochastic(_ highs: [Double], _ lows: [Double], _ closes: [Double]) -> (k: Double, d: Double) {
        guard highs.count > 14, highs.count == lows.count, lows.count == closes.count else {
            return (50, 50)
        }
        
        let period = 14
        let recentHighs = Array(highs.suffix(period))
        let recentLows = Array(lows.suffix(period))
        let currentClose = closes.last ?? 0
        
        let highestHigh = recentHighs.max() ?? currentClose
        let lowestLow = recentLows.min() ?? currentClose
        
        let k: Double
        if highestHigh - lowestLow > 0 {
            k = (currentClose - lowestLow) / (highestHigh - lowestLow) * 100
        } else {
            k = 50
        }
        
        // Simplified %D (normally would use 3-period SMA of %K)
        let d = k
        
        return (k, d)
    }
    
    private func calculateBollingerBandPercent(_ closes: [Double]) -> Double {
        guard closes.count > 20 else { return 0.5 }
        
        let sma20 = calculateSMA(closes, period: 20)
        let stdDev = calculateStandardDeviation(Array(closes.suffix(20)))
        let upperBand = sma20 + 2 * stdDev
        let lowerBand = sma20 - 2 * stdDev
        let currentPrice = closes.last ?? sma20
        
        guard upperBand - lowerBand > 0 else { return 0.5 }
        return (currentPrice - lowerBand) / (upperBand - lowerBand)
    }
}

// MARK: - Fix for StrategySignal.Direction extension
extension StrategySignal.Direction {
    var rawValue: String {
        switch self {
        case .buy: return "BUY"
        case .sell: return "SELL"
        case .hold: return "HOLD"
        }
    }
}
