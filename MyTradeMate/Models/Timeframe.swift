import Foundation

public enum Timeframe: String, Codable, CaseIterable, Sendable {
    case m5  = "5m"
    case h1  = "1h"
    case h4  = "4h"
}
