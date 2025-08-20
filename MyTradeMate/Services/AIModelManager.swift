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

        // MARK: - Încărcare/validare
    @discardableResult
    func validateModels() async throws -> Bool {
        var loaded: [ModelKey: MLModel] = [:]

        for key in ModelKey.allCases {
                // Acceptă .mlmodelc / .mlmodel / .mlpackage
            if let url =
                Bundle.main.url(forResource: key.rawValue, withExtension: "mlmodelc")
                ?? Bundle.main.url(forResource: key.rawValue, withExtension: "mlmodel")
                ?? Bundle.main.url(forResource: key.rawValue, withExtension: "mlpackage")
            {
            let compiledURL: URL
            if url.pathExtension == "mlmodel" {
                compiledURL = try await MLModel.compileModel(at: url)
            } else {
                compiledURL = url
            }

            let cfg = MLModelConfiguration()
            let model = try MLModel(contentsOf: compiledURL, configuration: cfg)
            loaded[key] = model
            Log.ai.info("✅ Loaded model: \(key.rawValue)")
            } else {
                Log.ai.warning("⚠️ Model \(key.rawValue) not found in bundle")
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
        /// DOAR H4 folosește AI. Pentru m5/h1 întoarce `nil` (decid strategiile în DashboardVM).
    func predictSafely(timeframe: Timeframe, candles: [Candle]) -> PredictionResult? {
        switch timeframe {
        case .h4:
            return predict4HSafely(candles: candles)
        case .m1, .m5, .m15, .h1:
                // Lăsăm strategiile să decidă pentru timeframe-urile scurte
            return nil
        }
    }

        /// Overload compat: unele call-site-uri trimit și `mode:`. Ignorăm param-ul.
    func predictSafely(timeframe: Timeframe, candles: [Candle], mode: TradingMode) -> PredictionResult? {
        return predictSafely(timeframe: timeframe, candles: candles)
    }

        // MARK: - 4H model with explicit features
    private func predict4HSafely(candles: [Candle]) -> PredictionResult? {
            // Suficient istoric pentru indicatori
        guard candles.count >= 60 else {
            Log.ai.warning("Insufficient candles for 4H features: \(candles.count)")
            return nil
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

            Log.ai.warning("No recognized output from 4H model")
            return nil

        } catch {
            Log.ai.error("4H prediction error: \(error.localizedDescription)")
            return nil
        }
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
