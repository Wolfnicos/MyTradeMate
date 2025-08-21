import Foundation
import CoreML

    /// Manager pentru încărcarea modelelor CoreML și inferență.
    /// - expune: `shared`, `validateModels()`, `predict4H(...)`
    /// - compat: `predictSafely(timeframe:candles:)` (+ overload cu `mode`)
    /// - IMPORTANT: AI este folosit DOAR pe H4; pentru m5/h1 returnează `nil` ca să decidă strategiile în VM.
@MainActor
final class AIModelManager: AIModelManagerProtocol {

        // MARK: - 4H feature schema (trebuie să corespundă modelului antrenat)
    private static let H4_FEATURES: [String] = [
        "return_1","return_3","return_5",
        "volatility","rsi","macd_hist","ema_ratio",
        "volume_z","high_low_range","price_position",
        "atr_14","stoch_k","stoch_d","bb_percent"
    ]

        // MARK: - Chei interne (numele fișierelor mlmodel/mlpackage)
    enum ModelKey: String, CaseIterable, Hashable {
        case m5 = "BitcoinAI_5m_enhanced"   // input: "dense_input"    → [1, 10] (NEUTILIZAT momentan)
        case h1 = "BitcoinAI_1h_enhanced"   // input: "dense_4_input"  → [1, 10] (NEUTILIZAT momentan)
        case h4 = "BTC_4H_Model"            // input: explicit 14 features (vezi H4_FEATURES)

        var modelName: String { rawValue }

        var inputKey: String? {
            switch self {
            case .m5: return "dense_input"
            case .h1: return "dense_4_input"
            case .h4: return nil
            }
        }
    }

        // MARK: - Singleton
    static let shared = AIModelManager()
    private init() {}

        // MARK: - Stocare modele
    private(set) var modelsByKey: [ModelKey: MLModel] = [:]

        /// Map public (read-only): `AnyHashable` → `MLModel` (protocol conformance)
    public var models: [AnyHashable: MLModel] {
        modelsByKey.reduce(into: [:]) { dict, pair in
            dict[pair.key.asPublicKind] = pair.value
        }
    }
    
    // ✅ ADD: Standardized cache keys for model predictions
    private enum CacheKey {
        case prediction(timeframe: Timeframe, candleHash: Int)
        case modelValidation(modelKey: ModelKey)
        
        var stringValue: String {
            switch self {
            case .prediction(let timeframe, let candleHash):
                return "prediction_\(timeframe.rawValue)_\(candleHash)"
            case .modelValidation(let modelKey):
                return "model_validation_\(modelKey.rawValue)"
            }
        }
    }
    
    // ✅ ADD: Simple in-memory cache for predictions
    private var predictionCache: [String: (result: PredictionResult, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 30.0 // 30 seconds
    
    // ✅ ADD: Model loading retry configuration
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 0.5

        // MARK: - Încărcare/validare
    
    // ✅ ADD: Model loading with retry logic and explicit bundle verification
    private func loadModelWithRetry(key: ModelKey) async throws -> MLModel {
        let cacheKey = CacheKey.modelValidation(modelKey: key).stringValue
        
        // ✅ EXPLICIT BUNDLE VERIFICATION with detailed logging
        let mlmodelcPath = Bundle.main.path(forResource: key.rawValue, ofType: "mlmodelc")
        let mlmodelPath = Bundle.main.path(forResource: key.rawValue, ofType: "mlmodel") 
        let mlpackagePath = Bundle.main.path(forResource: key.rawValue, ofType: "mlpackage")
        
        Log.ai.info("🔍 Checking bundle for model \(key.rawValue):")
        Log.ai.info("   .mlmodelc: \(mlmodelcPath != nil ? "✅ Found" : "❌ Missing")")
        Log.ai.info("   .mlmodel: \(mlmodelPath != nil ? "✅ Found" : "❌ Missing")")
        Log.ai.info("   .mlpackage: \(mlpackagePath != nil ? "✅ Found" : "❌ Missing")")
        
        for attempt in 1...maxRetries {
            do {
                // Check if model file exists with explicit error messages
                guard let url = Bundle.main.url(forResource: key.rawValue, withExtension: "mlmodelc")
                    ?? Bundle.main.url(forResource: key.rawValue, withExtension: "mlmodel")
                    ?? Bundle.main.url(forResource: key.rawValue, withExtension: "mlpackage")
                else {
                    Log.ai.error("❌ Missing \(key.rawValue) in app bundle - check Build Phases → Copy Bundle Resources")
                    Log.ai.error("   Expected files: \(key.rawValue).mlmodelc, \(key.rawValue).mlmodel, or \(key.rawValue).mlpackage")
                    throw PredictionError.modelNotFound(key.rawValue)
                }
                
                let compiledURL: URL
                if url.pathExtension == "mlmodel" {
                    compiledURL = try await MLModel.compileModel(at: url)
                } else {
                    compiledURL = url
                }
                
                let cfg = MLModelConfiguration()
                let model = try MLModel(contentsOf: compiledURL, configuration: cfg)
                
                if attempt > 1 {
                    Log.ai.info("✅ Model \(key.rawValue) loaded successfully on attempt \(attempt)")
                }
                
                return model
                
            } catch {
                Log.ai.warning("⚠️ Model loading attempt \(attempt)/\(maxRetries) failed for \(key.rawValue): \(error.localizedDescription)")
                
                if attempt < maxRetries {
                    let delay = retryDelay * Double(attempt) // Exponential backoff
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    Log.ai.error("❌ Model \(key.rawValue) loading failed after \(maxRetries) attempts: \(error)")
                    throw PredictionError.modelLoadingFailed(key.rawValue, error)
                }
            }
        }
        
        // This should never be reached due to the logic above, but just in case
        throw PredictionError.modelLoadingFailed(key.rawValue, NSError(domain: "AIModelManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown loading failure"]))
    }
    
    @discardableResult
    func validateModels() async throws -> Bool {
        var loaded: [ModelKey: MLModel] = [:]

        for key in ModelKey.allCases {
            // ✅ ADD: Proper error handling for model loading
            do {
                let model = try await loadModelWithRetry(key: key)
                loaded[key] = model
                Log.ai.info("✅ Loaded model: \(key.rawValue)")
            } catch let error as PredictionError {
                Log.ai.error("❌ Failed to load \(key.rawValue): \(error.description)")
                // Continue loading other models even if one fails
            } catch {
                Log.ai.error("❌ Unexpected error loading \(key.rawValue): \(error.localizedDescription)")
            }
        }

        self.modelsByKey = loaded

            // Dump IO shapes pentru debugging
        for (key, model) in loaded {
            let inputs  = model.modelDescription.inputDescriptionsByName
            let outputs = model.modelDescription.outputDescriptionsByName

            Log.ai.debug("📊 Model: \(key.rawValue)")
            for (k, d) in inputs {
                let shape = (d.multiArrayConstraint?.shape ?? []).map { $0.intValue }
                Log.ai.debug("🐛   Input: \(k) → \(shape)")
            }
            for (k, d) in outputs {
                let shape = (d.multiArrayConstraint?.shape ?? []).map { $0.intValue }
                Log.ai.debug("🐛   Output: \(k) → \(shape)")
            }
        }

        return !loaded.isEmpty
    }

        // MARK: - Inferență: model 4H (14 features explicite)
    func predict4H(explicitInputs: [String: NSNumber]) throws -> MLFeatureProvider {
        guard let model = modelsByKey[ .h4 ] else {
            throw NSError(
                domain: "AIModelManager", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Model \(ModelKey.h4.rawValue) not loaded"]
            )
        }

            // Asigură toate cheile cerute de model
        var dict: [String: MLFeatureValue] = [:]
        for key in Self.H4_FEATURES {
            let val = explicitInputs[key]?.doubleValue ?? 0.0
            dict[key] = MLFeatureValue(double: val)
        }
        let input = try MLDictionaryFeatureProvider(dictionary: dict)

            // Unele exporturi sunt pipeline; încearcă single + batch
        do {
            return try model.prediction(from: input)
        } catch {
            if (error as NSError).localizedDescription.lowercased().contains("pipeline") {
                Log.ai.warning("4H model pipeline error, trying batch prediction…")
                let batch = MLArrayBatchProvider(array: [input])
                let batchResult = try model.predictions(from: batch, options: MLPredictionOptions())
                if batchResult.count > 0 { return batchResult.features(at: 0) }
            }
            throw error
        }
    }

        // MARK: - Public API: Unified prediction interface
        /// AI folosit pentru toate timeframe-urile cu fallback la strategie
    func predictSafely(timeframe: Timeframe, candles: [Candle]) -> PredictionResult? {
        // ✅ ADD: Check cache first with standardized key
        let candleHash = calculateCandleHash(candles)
        let cacheKey = CacheKey.prediction(timeframe: timeframe, candleHash: candleHash).stringValue
        
        if let cached = getCachedPrediction(key: cacheKey) {
            Log.ai.debug("📦 Using cached prediction for \(timeframe.rawValue)")
            return cached
        }
        
        // Perform prediction
        let result: PredictionResult?
        switch timeframe {
        case .h4:
            result = predict4HSafely(candles: candles)
        case .h1:
            result = predictH1Safely(candles: candles)
        case .m5, .m15:
            result = predictM5Safely(candles: candles)
        case .m1:
            // M1 încă pe strategie (prea volatil pentru AI)
            result = nil
        case .d1:
            // D1 uses 4H model as fallback
            result = predict4HSafely(candles: candles)
        }
        
        // ✅ ADD: Cache the result if valid
        if let result = result {
            cachePrediction(key: cacheKey, result: result)
        }
        
        return result
    }

        /// Overload compat: unele call-site-uri trimit și `mode:`. Ignorăm param-ul.
    func predictSafely(timeframe: Timeframe, candles: [Candle], mode: TradingMode) -> PredictionResult? {
        return predictSafely(timeframe: timeframe, candles: candles)
    }

        // MARK: - 4H model with explicit features
    private func predict4HSafely(candles: [Candle]) -> PredictionResult? {
        // ✅ CHECK: Model availability first - return fallback if missing
        guard modelsByKey[.h4] != nil else {
            Log.ai.warning("H4 model not available - using fallback")
            return createFallbackSignal(timeframe: "4h", candles: candles)
        }
        
            // Suficient istoric pentru indicatori
        guard candles.count >= 60 else {
            Log.ai.warning("Insufficient candles for 4H features: \(candles.count)")
            return createFallbackSignal(timeframe: "4h", candles: candles)
        }

        let inputs = build4HExplicitInputs(from: candles)

        do {
            let out = try predict4H(explicitInputs: inputs)

                // A) RandomForest (sklearn) → classProbability sunt VOTURI; normalizează la 0..1
            if let dict = out.featureValue(for: "classProbability")?.dictionaryValue {
                let (buyVotes, sellVotes, holdVotes) = extractClassVotes(dict)
                let total = buyVotes + sellVotes + holdVotes
                let pBuy  = total > 0 ? buyVotes/total  : 1.0/3.0
                let pSell = total > 0 ? sellVotes/total : 1.0/3.0
                let pHold = total > 0 ? holdVotes/total : 1.0/3.0

                let maxP = max(pBuy, pSell, pHold)
                let signal = (maxP == pBuy) ? "BUY" : ((maxP == pSell) ? "SELL" : "HOLD")
                    // Confidence 0.55–0.95 din probabilitatea normalizată
                let confidence = max(0.55, min(0.95, maxP))

                Log.ai.debug(String(
                    format: "🐛 4H votes→probs BUY:%.3f SELL:%.3f HOLD:%.3f → %@ (conf=%.2f)",
                    pBuy, pSell, pHold, signal, confidence
                ))

                return PredictionResult(
                    signal: signal,
                    confidence: confidence,
                    model: .h4,
                    timestamp: Date()
                )
            }

                // B) Fallback: classLabel / prediction (string sau int)
            if let labelStr = out.featureValue(for: "classLabel")?.stringValue
                ?? out.featureValue(for: "prediction")?.stringValue
            {
            let sig = normalizeLabel(labelStr)
            return PredictionResult(signal: sig, confidence: 0.70, model: .h4, timestamp: Date())
            }
            if let labelInt = out.featureValue(for: "prediction")?.int64Value {
                let sig = (labelInt == 2) ? "BUY" : (labelInt == 0 ? "SELL" : "HOLD")
                return PredictionResult(signal: sig, confidence: 0.70, model: .h4, timestamp: Date())
            }

            Log.ai.warning("No recognized output from 4H model - using fallback")
            return createFallbackSignal(timeframe: "4h", candles: candles)

        } catch {
            Log.ai.error("4H prediction error: \(error.localizedDescription) - using fallback")
            return createFallbackSignal(timeframe: "4h", candles: candles)
        }
    }

        // MARK: - H1 model prediction
    private func predictH1Safely(candles: [Candle]) -> PredictionResult? {
        guard let model = modelsByKey[.h1] else {
            Log.ai.warning("H1 model not available")
            return createFallbackSignal(timeframe: "1h", candles: candles)
        }
        
        guard candles.count >= 30 else {
            Log.ai.warning("Insufficient candles for H1 prediction: \(candles.count)")
            return createFallbackSignal(timeframe: "1h", candles: candles)
        }
        
        do {
            let inputs = buildSimpleFeatures(candles: candles, featureCount: 10)
            let input = try make2DFloatArray(values: inputs, count: 10)
            let dict = ["dense_4_input": MLFeatureValue(multiArray: input)]
            let featureProvider = try MLDictionaryFeatureProvider(dictionary: dict)
            
            let output = try model.prediction(from: featureProvider)
            return parseModelOutput(output: output, modelKey: .h1)
            
        } catch {
            Log.ai.error("H1 prediction error: \(error)")
            return createFallbackSignal(timeframe: "1h", candles: candles)
        }
    }
    
        // MARK: - M5 model prediction  
    private func predictM5Safely(candles: [Candle]) -> PredictionResult? {
        guard let model = modelsByKey[.m5] else {
            Log.ai.warning("M5 model not available")
            return createFallbackSignal(timeframe: "5m", candles: candles)
        }
        
        guard candles.count >= 20 else {
            Log.ai.warning("Insufficient candles for M5 prediction: \(candles.count)")
            return createFallbackSignal(timeframe: "5m", candles: candles)
        }
        
        do {
            let inputs = buildSimpleFeatures(candles: candles, featureCount: 10)
            let input = try make2DFloatArray(values: inputs, count: 10)
            let dict = ["dense_input": MLFeatureValue(multiArray: input)]
            let featureProvider = try MLDictionaryFeatureProvider(dictionary: dict)
            
            let output = try model.prediction(from: featureProvider)
            return parseModelOutput(output: output, modelKey: .m5)
            
        } catch {
            Log.ai.error("M5 prediction error: \(error)")
            return createFallbackSignal(timeframe: "5m", candles: candles)
        }
    }
    
        // MARK: - ✅ ENHANCED: Fallback signal creation with better logic
    private func createFallbackSignal(timeframe: String, candles: [Candle]) -> PredictionResult? {
        guard let lastCandle = candles.last else { return nil }
        
        // ✅ Enhanced momentum analysis based on timeframe
        let lookbackPeriod = timeframe == "4h" ? 10 : (timeframe == "1h" ? 7 : 5)
        let recentCandles = Array(candles.suffix(lookbackPeriod))
        
        // Calculate multiple momentum indicators
        let shortMomentum = recentCandles.last!.close - recentCandles.first!.close
        let priceMomentumPercent = (shortMomentum / recentCandles.first!.close) * 100
        
        // Simple volume analysis if available
        let avgVolume = recentCandles.map { $0.volume }.reduce(0, +) / Double(recentCandles.count)
        let currentVolumeRatio = lastCandle.volume / avgVolume
        
        // Enhanced signal logic
        let signal: String
        let confidence: Double
        
        if abs(priceMomentumPercent) < 0.1 {
            // Very low momentum - neutral signal
            signal = "HOLD"
            confidence = 0.35
        } else if priceMomentumPercent > 0.5 {
            // Strong positive momentum
            signal = "BUY"
            confidence = min(0.65, 0.45 + (currentVolumeRatio > 1.2 ? 0.15 : 0.0))
        } else if priceMomentumPercent < -0.5 {
            // Strong negative momentum
            signal = "SELL"
            confidence = min(0.65, 0.45 + (currentVolumeRatio > 1.2 ? 0.15 : 0.0))
        } else if priceMomentumPercent > 0 {
            // Weak positive momentum
            signal = "BUY"
            confidence = 0.40
        } else {
            // Weak negative momentum
            signal = "SELL"
            confidence = 0.40
        }
        
        // Map timeframe to model type
        let modelType: ModelKind
        switch timeframe {
        case "4h": modelType = .h4
        case "1h": modelType = .h1
        default: modelType = .m5
        }
        
        Log.ai.info("🔄 AI Fallback [\(timeframe)]: \(signal) @ \(String(format: "%.1f%%", confidence * 100)) (momentum: \(String(format: "%.2f%%", priceMomentumPercent)))")
        
        return PredictionResult(
            signal: signal,
            confidence: confidence,
            model: modelType,
            timestamp: Date()
        )
    }
    
        // MARK: - Simple feature engineering for m5/h1
    private func buildSimpleFeatures(candles: [Candle], featureCount: Int) -> [Float] {
        guard !candles.isEmpty else { return Array(repeating: 0.0, count: featureCount) }
        
        let prices = candles.map { $0.close }
        var features: [Float] = []
        
        // Price returns (last 3)
        let returns = (1..<min(4, prices.count)).map { i in
            Float(safePctChange(prices[prices.count - 1 - i], prices[prices.count - 1]))
        }
        features.append(contentsOf: returns)
        
        // RSI
        features.append(Float(calculateRSI(candles: candles, period: min(14, candles.count - 1))))
        
        // Moving averages ratio
        let shortMA = prices.suffix(min(5, prices.count)).reduce(0, +) / Double(min(5, prices.count))
        let longMA = prices.suffix(min(10, prices.count)).reduce(0, +) / Double(min(10, prices.count))
        features.append(Float(longMA > 0 ? shortMA / longMA : 1.0))
        
        // Volume ratio
        let volumes = candles.map { $0.volume }
        let avgVolume = volumes.suffix(min(10, volumes.count)).reduce(0, +) / Double(min(10, volumes.count))
        let currentVolume = volumes.last ?? 0
        features.append(Float(avgVolume > 0 ? currentVolume / avgVolume : 1.0))
        
        // Volatility
        features.append(Float(calculateVolatility(candles: candles, period: min(20, candles.count - 1))))
        
        // Price position in range
        let recentCandles = Array(candles.suffix(min(20, candles.count)))
        let high = recentCandles.map { $0.high }.max() ?? candles.last!.close
        let low = recentCandles.map { $0.low }.min() ?? candles.last!.close
        let position = high > low ? Float((candles.last!.close - low) / (high - low)) : 0.5
        features.append(position)
        
        // Pad or truncate to required count
        return normalizeToCount(features, count: featureCount)
    }
    
        // MARK: - Model output parsing
    private func parseModelOutput(output: MLFeatureProvider, modelKey: ModelKey) -> PredictionResult? {
        // Try class probabilities first
        if let dict = output.featureValue(for: "classProbability")?.dictionaryValue {
            let (buyVotes, sellVotes, holdVotes) = extractClassVotes(dict)
            let total = buyVotes + sellVotes + holdVotes
            let pBuy = total > 0 ? buyVotes/total : 1.0/3.0
            let pSell = total > 0 ? sellVotes/total : 1.0/3.0
            let pHold = total > 0 ? holdVotes/total : 1.0/3.0
            
            let maxP = max(pBuy, pSell, pHold)
            let signal = (maxP == pBuy) ? "BUY" : ((maxP == pSell) ? "SELL" : "HOLD")
            let confidence = max(0.55, min(0.95, maxP))
            
            return PredictionResult(signal: signal, confidence: confidence, model: modelKey.asPublicKind, timestamp: Date())
        }
        
        // Try string labels
        if let labelStr = output.featureValue(for: "classLabel")?.stringValue
            ?? output.featureValue(for: "prediction")?.stringValue {
            let sig = normalizeLabel(labelStr)
            return PredictionResult(signal: sig, confidence: 0.70, model: modelKey.asPublicKind, timestamp: Date())
        }
        
        // Try integer prediction
        if let labelInt = output.featureValue(for: "prediction")?.int64Value {
            let sig = (labelInt == 2) ? "BUY" : (labelInt == 0 ? "SELL" : "HOLD")
            return PredictionResult(signal: sig, confidence: 0.70, model: modelKey.asPublicKind, timestamp: Date())
        }
        
        Log.ai.warning("No recognized output from \(modelKey.rawValue) model")
        return nil
    }

        // MARK: - Feature building helpers (H4)

        /// 14 engineered features pentru H4 — numele trebuie să corespundă `H4_FEATURES`
    private func build4HExplicitInputs(from candles: [Candle]) -> [String: NSNumber] {
        let arr = candles
        let n = arr.count
        let last = arr[n-1]

            // Returns
        let r1 = safePctChange(arr[n-2].close, arr[n-1].close)
        let r3 = safePctChange(arr[n-4].close, arr[n-1].close)
        let r5 = safePctChange(arr[n-6].close, arr[n-1].close)

            // Volatility(20)
        let vol20 = calculateVolatility(candles: Array(arr.suffix(21)), period: 20)

            // RSI(14)
        let rsi = calculateRSI(candles: arr, period: 14)

            // MACD 12-26-9 hist
        let macdHist = macdHistogram(prices: arr.map{$0.close}, fast: 12, slow: 26, signal: 9)

            // EMA ratio (close / EMA20)
        let ema20 = ema(Array(arr.suffix(21)).map{$0.close}, period: 20).last ?? last.close
        let emaRatio = ema20 > 0 ? last.close/ema20 : 1.0

            // Volume Z (last 20)
        let volZ = zscore(Array(arr.suffix(20)).map{$0.volume})

            // High-low range (relative la close)
        let hlRange = (last.close > 0) ? (last.high - last.low)/last.close : 0.0

            // Price position (ultimele 20)
        let win20 = Array(arr.suffix(20))
        let maxH = win20.map{$0.high}.max() ?? last.close
        let minL = win20.map{$0.low}.min() ?? last.close
        let pricePos = (maxH > minL) ? (last.close - minL)/(maxH - minL) : 0.5

            // ATR(14) normalizat cu close
        let atr = atrNormalized(candles: arr, period: 14)

            // Stochastic %K, %D (14,3) – simplificat
        let (kVal, dVal) = stochasticKD(candles: arr, lookback: 14, smoothK: 1, smoothD: 3)

            // Bollinger %B (20, 2 std)
        let bbp = bollingerPercentB(prices: arr.map{$0.close}, period: 20, stdK: 2.0)

            // Assemble map cu exact aceste nume
        let nums: [String: Double] = [
            "return_1": r1,
            "return_3": r3,
            "return_5": r5,
            "volatility": vol20,
            "rsi": rsi,
            "macd_hist": macdHist,
            "ema_ratio": emaRatio,
            "volume_z": volZ,
            "high_low_range": hlRange,
            "price_position": pricePos,
            "atr_14": atr,
            "stoch_k": kVal,
            "stoch_d": dVal,
            "bb_percent": bbp
        ]

            // Clamp + NSNumber
        var out: [String: NSNumber] = [:]
        for key in Self.H4_FEATURES {
            let v = nums[key] ?? 0.0
            let clamped: Double
            switch key {
            case "rsi":            clamped = clamp(v, 0, 100)
            case "ema_ratio":      clamped = clamp(v, 0.1, 10.0)
            case "volume_z":       clamped = clamp(v, -5, 5)
            case "price_position": clamped = clamp(v, 0, 1)
            case "bb_percent":     clamped = clamp(v, 0, 1)
            default:               clamped = clamp(v, -1e6, 1e6)
            }
            out[key] = NSNumber(value: clamped.isFinite ? clamped : 0.0)
        }

        Log.ai.debug(
            "🐛 4H Features built: " +
            out.map { "\($0.key)=\(String(format:"%.4f", $0.value.doubleValue))" }
                .sorted().joined(separator: ", ")
        )
        return out
    }

        // MARK: - Indicator utils

    private func safePctChange(_ prev: Double, _ curr: Double) -> Double {
        guard prev != 0, prev.isFinite, curr.isFinite else { return 0 }
        return (curr - prev) / prev
    }

    private func calculateRSI(candles: [Candle], period: Int) -> Double {
        guard candles.count >= period + 1 else { return 50.0 }
        var gains = 0.0, losses = 0.0
        for i in (candles.count - period)..<candles.count {
            let ch = candles[i].close - candles[i-1].close
            gains += max(0, ch)
            losses += max(0, -ch)
        }
        let avgG = gains / Double(period)
        let avgL = losses / Double(period)
        guard avgL > 0 else { return 50.0 }
        let rs = avgG / avgL
        return 100 - (100 / (1 + rs))
    }

    private func calculateVolatility(candles: [Candle], period: Int) -> Double {
        guard candles.count >= period + 1 else { return 0.02 }
        let recent = Array(candles.suffix(period + 1))
        let rets = (1..<recent.count).map { i in
            safePctChange(recent[i-1].close, recent[i].close)
        }
        let mean = rets.reduce(0, +) / Double(rets.count)
        let varc = rets.map { pow($0 - mean, 2) }.reduce(0, +) / Double(rets.count)
        return sqrt(varc)
    }

    private func ema(_ values: [Double], period: Int) -> [Double] {
        guard !values.isEmpty, period > 0 else { return [] }
        let k = 2.0 / (Double(period) + 1.0)
        var out: [Double] = []
        var ema = values[0]
        out.append(ema)
        for i in 1..<values.count {
            ema = values[i] * k + ema * (1 - k)
            out.append(ema)
        }
        return out
    }

    private func macdHistogram(prices: [Double], fast: Int, slow: Int, signal: Int) -> Double {
        guard prices.count >= slow + signal else { return 0 }
        let emaFast = ema(prices, period: fast)
        let emaSlow = ema(prices, period: slow)
            // aliniază capetele
        let count = min(emaFast.count, emaSlow.count)
        let macdLine = (0..<count).map {
            emaFast[$0 + (emaFast.count - count)] - emaSlow[$0 + (emaSlow.count - count)]
        }
        let sig = ema(macdLine, period: signal)
        guard !sig.isEmpty else { return 0 }
        let macd = macdLine.last ?? 0
        let signalV = sig.last ?? 0
        return macd - signalV
    }

    private func zscore(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0,+)/Double(values.count)
        let varc = values.map { pow($0 - mean, 2) }.reduce(0,+)/Double(values.count)
        let sd = sqrt(varc)
        guard sd > 0 else { return 0 }
        guard let lastValue = values.last else { return 0.0 }
        return (lastValue - mean)/sd
    }

    private func atrNormalized(candles: [Candle], period: Int) -> Double {
        guard candles.count >= period + 1 else { return 0 }
        var trs: [Double] = []
        for i in 1..<candles.count {
            let c0 = candles[i-1]
            let c1 = candles[i]
            let tr = max(c1.high - c1.low, max(abs(c1.high - c0.close), abs(c1.low - c0.close)))
            trs.append(tr)
        }
        let recent = Array(trs.suffix(period))
        let atr = recent.reduce(0,+)/Double(recent.count)
        guard let lastClose = candles.last?.close else { return 0.0 }
        return lastClose > 0 ? atr/lastClose : 0
    }

    private func stochasticKD(candles: [Candle], lookback: Int, smoothK: Int, smoothD: Int) -> (Double, Double) {
        guard candles.count >= lookback + smoothD else { return (50, 50) }
        let lastLB = Array(candles.suffix(lookback))
        guard let lastCandle = candles.last else { return (50.0, 50.0) }
        let hh = lastLB.map{$0.high}.max() ?? lastCandle.high
        let ll = lastLB.map{$0.low}.min() ?? lastCandle.low
        let close = lastCandle.close
        let rawK = (hh > ll) ? (close - ll) / (hh - ll) * 100.0 : 50.0
            // simplificat: fără smoothing real pe fereastră (pentru viteză și robustețe)
        let K = rawK
        let D = K
        return (K, D)
    }

    private func bollingerPercentB(prices: [Double], period: Int, stdK: Double) -> Double {
        guard prices.count >= period else { return 0.5 }
        let win = Array(prices.suffix(period))
        let mean = win.reduce(0,+)/Double(win.count)
        let varc = win.map { pow($0 - mean, 2) }.reduce(0,+)/Double(win.count)
        let sd = sqrt(varc)
        if sd == 0 { return 0.5 }
        let upper = mean + stdK*sd
        let lower = mean - stdK*sd
        guard let p = prices.last else { return 0.0 }
        return (p - lower) / (upper - lower)
    }

        // MARK: - Helpers for outputs

        /// Extrage VOTURILE BUY/SELL/HOLD din `classProbability` (sklearn RF export).
    private func extractClassVotes(_ dict: [AnyHashable: NSNumber]) -> (buy: Double, sell: Double, hold: Double) {
        var buy = 0.0, sell = 0.0, hold = 0.0
        for (k, v) in dict {
            if let s = k as? String {
                let up = s.uppercased()
                if up == "BUY"  { buy  = v.doubleValue }
                if up == "SELL" { sell = v.doubleValue }
                if up == "HOLD" { hold = v.doubleValue }
            } else if let i = k as? Int {
                    // unele exporturi folosesc 0:SELL,1:HOLD,2:BUY
                if i == 0 { sell = v.doubleValue }
                if i == 1 { hold = v.doubleValue }
                if i == 2 { buy  = v.doubleValue }
            }
        }
        return (buy, sell, hold)
    }

    private func normalizeLabel(_ s: String) -> String {
        switch s.uppercased() {
        case "BUY":  return "BUY"
        case "SELL": return "SELL"
        default:     return "HOLD"
        }
    }

        // MARK: - Clamp & safe helpers

    private func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        return Swift.max(lo, Swift.min(hi, v))
    }

        // MARK: - (NEUTILIZATE momentan) Dense utils pentru m5/h1

        /// Lăsate aici doar pentru compatibilitate viitoare dacă vei adăuga modele m5/h1.
    private func make2DFloatArray(values: [Float], count: Int) throws -> MLMultiArray {
        let shape: [NSNumber] = [1, count].map { NSNumber(value: $0) }
        let arr = try MLMultiArray(shape: shape, dataType: .float32)
        for (i, v) in values.enumerated() where i < count {
            arr[i] = NSNumber(value: v)
        }
        return arr
    }

    private func normalizeToCount(_ values: [Float], count: Int) -> [Float] {
        if values.count == count { return values }
        if values.count > count { return Array(values.prefix(count)) }
        return values + Array(repeating: 0, count: count - values.count)
    }
    
    // ✅ ADD: Cache management methods
    private func calculateCandleHash(_ candles: [Candle]) -> Int {
        // Create a simple hash from the last few candles for caching
        guard !candles.isEmpty else { return 0 }
        
        let relevantCandles = Array(candles.suffix(min(5, candles.count)))
        var hasher = 0
        
        for candle in relevantCandles {
            hasher = hasher &* 31 &+ Int(candle.close * 10000)
            hasher = hasher &* 31 &+ Int(candle.volume / 1000)
            hasher = hasher &* 31 &+ Int(candle.openTime.timeIntervalSince1970)
        }
        
        return hasher
    }
    
    private func getCachedPrediction(key: String) -> PredictionResult? {
        guard let cached = predictionCache[key] else { return nil }
        
        // Check if cache is still valid
        let now = Date()
        if now.timeIntervalSince(cached.timestamp) > cacheTimeout {
            predictionCache.removeValue(forKey: key)
            return nil
        }
        
        return cached.result
    }
    
    private func cachePrediction(key: String, result: PredictionResult) {
        // Clean up old cache entries periodically
        let now = Date()
        if predictionCache.count > 100 { // Limit cache size
            predictionCache = predictionCache.filter { 
                now.timeIntervalSince($0.value.timestamp) <= cacheTimeout 
            }
        }
        
        predictionCache[key] = (result: result, timestamp: now)
        Log.ai.debug("📦 Cached prediction with key: \(key)")
    }
}

    // MARK: - Bridge intern → enum public
private extension AIModelManager.ModelKey {
    var asPublicKind: ModelKind {
        switch self {
        case .m5: return .m5
        case .h1: return .h1
        case .h4: return .h4
        }
    }
}
