import Foundation

/// Utility for validating and ensuring consistent timeframe label usage throughout the app
enum TimeframeValidator {
    
    /// Standard timeframe display formats that should be used consistently
    static let standardFormats: [Timeframe: String] = [
        .m5: "5m",
        .h1: "1h", 
        .h4: "4h"
    ]
    
    /// Validates that a timeframe uses the standard display format
    /// - Parameter timeframe: The timeframe to validate
    /// - Returns: True if the timeframe uses the standard format
    static func isStandardFormat(_ timeframe: Timeframe) -> Bool {
        return timeframe.displayName == standardFormats[timeframe]
    }
    
    /// Validates all timeframes use standard formats
    /// - Returns: True if all timeframes use standard formats
    static func validateAllTimeframes() -> Bool {
        return Timeframe.allCases.allSatisfy { isStandardFormat($0) }
    }
    
    /// Gets the standard display name for a timeframe
    /// - Parameter timeframe: The timeframe
    /// - Returns: The standard display name
    static func standardDisplayName(for timeframe: Timeframe) -> String {
        return standardFormats[timeframe] ?? timeframe.displayName
    }
    
    /// Validates that a string matches the expected timeframe format
    /// - Parameter displayString: The string to validate
    /// - Returns: The corresponding timeframe if valid, nil otherwise
    static func timeframe(from displayString: String) -> Timeframe? {
        return standardFormats.first { $0.value == displayString }?.key
    }
    
    /// Documentation of the timeframe standards
    static let documentation = """
    Timeframe Display Standards:
    
    - 5-minute timeframe: "5m" (not "5min", "5 min", "5-min")
    - 1-hour timeframe: "1h" (not "1hr", "1 hour", "1-hour") 
    - 4-hour timeframe: "4h" (not "4hr", "4 hour", "4-hour")
    
    These formats should be used consistently across:
    - UI picker labels
    - Chart displays
    - API requests
    - Documentation
    - User-facing text
    
    Always use Timeframe.displayName property instead of hardcoded strings.
    """
}

// MARK: - Validation Extensions

extension Timeframe {
    /// Validates that this timeframe uses the standard display format
    var isStandardFormat: Bool {
        return TimeframeValidator.isStandardFormat(self)
    }
    
    /// Gets the standard display name (same as displayName, but validated)
    var standardDisplayName: String {
        return TimeframeValidator.standardDisplayName(for: self)
    }
}