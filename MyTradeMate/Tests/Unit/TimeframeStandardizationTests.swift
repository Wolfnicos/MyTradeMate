import XCTest
@testable import MyTradeMate

/// Tests to ensure timeframe labels remain standardized throughout the app
final class TimeframeStandardizationTests: XCTestCase {
    
    func testTimeframeDisplayNamesAreStandardized() {
        // Test that all timeframes use the expected standard format
        XCTAssertEqual(Timeframe.m5.displayName, "5m", "5-minute timeframe should display as '5m'")
        XCTAssertEqual(Timeframe.h1.displayName, "1h", "1-hour timeframe should display as '1h'")
        XCTAssertEqual(Timeframe.h4.displayName, "4h", "4-hour timeframe should display as '4h'")
    }
    
    func testTimeframeValidatorStandards() {
        // Test that the validator recognizes all timeframes as standard
        XCTAssertTrue(TimeframeValidator.validateAllTimeframes(), "All timeframes should use standard formats")
        
        // Test individual timeframes
        for timeframe in Timeframe.allCases {
            XCTAssertTrue(timeframe.isStandardFormat, "Timeframe \(timeframe.rawValue) should use standard format")
        }
    }
    
    func testTimeframeValidatorMapping() {
        // Test that the validator can map display strings back to timeframes
        XCTAssertEqual(TimeframeValidator.timeframe(from: "5m"), .m5)
        XCTAssertEqual(TimeframeValidator.timeframe(from: "1h"), .h1)
        XCTAssertEqual(TimeframeValidator.timeframe(from: "4h"), .h4)
        
        // Test that non-standard formats return nil
        XCTAssertNil(TimeframeValidator.timeframe(from: "5min"))
        XCTAssertNil(TimeframeValidator.timeframe(from: "1hr"))
        XCTAssertNil(TimeframeValidator.timeframe(from: "4hour"))
        XCTAssertNil(TimeframeValidator.timeframe(from: "5 min"))
        XCTAssertNil(TimeframeValidator.timeframe(from: "1 hour"))
    }
    
    func testStandardDisplayNames() {
        // Test that standard display names match the timeframe's displayName
        for timeframe in Timeframe.allCases {
            XCTAssertEqual(
                timeframe.standardDisplayName,
                timeframe.displayName,
                "Standard display name should match timeframe's displayName for \(timeframe.rawValue)"
            )
        }
    }
    
    func testTimeframeConsistencyAcrossComponents() {
        // This test ensures that if we add new timeframes, they follow the standard
        let expectedFormats: [Timeframe: String] = [
            .m5: "5m",
            .h1: "1h",
            .h4: "4h"
        ]
        
        for (timeframe, expectedFormat) in expectedFormats {
            XCTAssertEqual(
                timeframe.displayName,
                expectedFormat,
                "Timeframe \(timeframe.rawValue) should display as '\(expectedFormat)'"
            )
        }
    }
    
    func testTimeframeDocumentation() {
        // Ensure documentation exists and is not empty
        XCTAssertFalse(TimeframeValidator.documentation.isEmpty, "Timeframe documentation should not be empty")
        XCTAssertTrue(TimeframeValidator.documentation.contains("5m"), "Documentation should mention 5m format")
        XCTAssertTrue(TimeframeValidator.documentation.contains("1h"), "Documentation should mention 1h format")
        XCTAssertTrue(TimeframeValidator.documentation.contains("4h"), "Documentation should mention 4h format")
    }
    
    func testNoHardcodedTimeframeStrings() {
        // This is a documentation test - in practice, code review should catch hardcoded strings
        // The test serves as a reminder to use Timeframe.displayName instead of hardcoded strings
        
        let validTimeframeStrings = ["5m", "1h", "4h"]
        let invalidTimeframeStrings = ["5min", "1hr", "4hr", "5 min", "1 hour", "4 hour", "5-min", "1-hour", "4-hour"]
        
        // Test that our validator correctly identifies valid vs invalid formats
        for validString in validTimeframeStrings {
            XCTAssertNotNil(TimeframeValidator.timeframe(from: validString), "'\(validString)' should be recognized as valid")
        }
        
        for invalidString in invalidTimeframeStrings {
            XCTAssertNil(TimeframeValidator.timeframe(from: invalidString), "'\(invalidString)' should not be recognized as valid")
        }
    }
}

// MARK: - Performance Tests

extension TimeframeStandardizationTests {
    
    func testTimeframeValidationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = TimeframeValidator.validateAllTimeframes()
            }
        }
    }
    
    func testTimeframeDisplayNamePerformance() {
        measure {
            for _ in 0..<1000 {
                for timeframe in Timeframe.allCases {
                    _ = timeframe.displayName
                }
            }
        }
    }
}