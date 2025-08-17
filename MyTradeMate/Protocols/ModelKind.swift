import Foundation

    /// Identifies each bundled CoreML model and exposes names/metadata used across the app.
public enum ModelKind: String, CaseIterable, Hashable {
    case m5 = "BitcoinAI_5m_enhanced"
    case h1 = "BitcoinAI_1h_enhanced"
    case h4 = "BTC_4H_Model"

        /// Filename / display name used in logs & UI
    public var modelName: String { rawValue }

        /// Human-friendly timeframe label for UI
    public var timeframeLabel: String {
        switch self {
        case .m5: return "5m"
        case .h1: return "1h"
        case .h4: return "4h"
        }
    }

        /// Expected CoreML input key for dense models.
        /// (4h model uses explicit features; the manager handles those separately.)
    public var inputKey: String? {
        switch self {
        case .m5: return "dense_input"
        case .h1: return "dense_4_input"
        case .h4: return nil
        }
    }

        // MARK: - Helpers to map from legacy strings
        /// Accept both exact rawValue and relaxed names like "BitcoinAI_4h_enhanced" or "4h".
    public static func fromLegacyName(_ s: String) -> ModelKind? {
        let x = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if x.contains("5m") { return .m5 }
        if x.contains("1h") { return .h1 }
        if x.contains("4h") { return .h4 }
            // direct rawValue match fallback
        return ModelKind(rawValue: s)
    }
}
