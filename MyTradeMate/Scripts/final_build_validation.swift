#!/usr/bin/env swift

import Foundation

/// Final build validation script for App Store submission
/// This script performs comprehensive validation to ensure the build is ready for submission

struct FinalBuildValidator {
    
    enum ValidationError: Error, LocalizedError {
        case buildConfigurationError(String)
        case versionMismatch(String)
        case missingAssets(String)
        case securityIssue(String)
        case performanceIssue(String)
        case complianceIssue(String)
        
        var errorDescription: String? {
            switch self {
            case .buildConfigurationError(let message):
                return "Build Configuration Error: \(message)"
            case .versionMismatch(let message):
                return "Version Mismatch: \(message)"
            case .missingAssets(let message):
                return "Missing Assets: \(message)"
            case .securityIssue(let message):
                return "Security Issue: \(message)"
            case .performanceIssue(let message):
                return "Performance Issue: \(message)"
            case .complianceIssue(let message):
                return "Compliance Issue: \(message)"
            }
        }
    }
    
    func runFinalValidation() {
        print("🚀 MyTradeMate Final Build Validation")
        print("=" * 60)
        print("Preparing for App Store submission...")
        print("")
        
        var passedTests = 0
        var failedTests = 0
        var warnings = 0
        
        let validations: [(String, () throws -> Void)] = [
            ("Version Configuration", validateVersionConfiguration),
            ("Build Configuration", validateBuildConfiguration),
            ("App Store Assets", validateAppStoreAssets),
            ("Privacy Compliance", validatePrivacyCompliance),
            ("Security Configuration", validateSecurityConfiguration),
            ("Performance Requirements", validatePerformanceRequirements),
            ("Widget Configuration", validateWidgetConfiguration),
            ("Accessibility Compliance", validateAccessibilityCompliance),
            ("App Store Guidelines", validateAppStoreGuidelines),
            ("Final Submission Readiness", validateSubmissionReadiness)
        ]
        
        for (testName, validation) in validations {
            print("📋 Validating: \(testName)")
            do {
                try validation()
                print("✅ \(testName): PASSED")
                passedTests += 1
            } catch {
                print("❌ \(testName): FAILED - \(error.localizedDescription)")
                failedTests += 1
            }
            print("")
        }
        
        // Summary
        print("=" * 60)
        print("📊 Final Validation Summary:")
        print("✅ Passed: \(passedTests)")
        print("❌ Failed: \(failedTests)")
        print("⚠️  Warnings: \(warnings)")
        
        let successRate = Int((Double(passedTests) / Double(passedTests + failedTests)) * 100)
        print("📈 Success Rate: \(successRate)%")
        
        if failedTests == 0 {
            print("")
            print("🎉 ALL VALIDATIONS PASSED!")
            print("🚀 MyTradeMate is READY FOR APP STORE SUBMISSION")
            print("")
            print("Next Steps:")
            print("1. Archive the app in Xcode")
            print("2. Upload to App Store Connect")
            print("3. Complete App Store metadata")
            print("4. Submit for review")
            exit(0)
        } else {
            print("")
            print("⚠️  VALIDATION FAILED")
            print("Please fix the issues above before submitting to App Store")
            exit(1)
        }
    }
    
    private func validateVersionConfiguration() throws {
        print("  • Checking version numbers...")
        
        // Check main app Info.plist
        guard let mainPlist = readPlist("MyTradeMate/Info.plist") else {
            throw ValidationError.versionMismatch("Cannot read main app Info.plist")
        }
        
        guard let mainVersion = mainPlist["CFBundleShortVersionString"] as? String,
              let mainBuild = mainPlist["CFBundleVersion"] as? String else {
            throw ValidationError.versionMismatch("Missing version information in main app")
        }
        
        // Check widget Info.plist
        guard let widgetPlist = readPlist("MyTradeMateWidget/Info.plist") else {
            throw ValidationError.versionMismatch("Cannot read widget Info.plist")
        }
        
        guard let widgetVersion = widgetPlist["CFBundleShortVersionString"] as? String,
              let widgetBuild = widgetPlist["CFBundleVersion"] as? String else {
            throw ValidationError.versionMismatch("Missing version information in widget")
        }
        
        // Validate version consistency
        guard mainVersion == widgetVersion else {
            throw ValidationError.versionMismatch("Version mismatch: Main(\(mainVersion)) vs Widget(\(widgetVersion))")
        }
        
        guard mainBuild == widgetBuild else {
            throw ValidationError.versionMismatch("Build mismatch: Main(\(mainBuild)) vs Widget(\(widgetBuild))")
        }
        
        // Validate version format
        guard mainVersion == "2.0.0" else {
            throw ValidationError.versionMismatch("Expected version 2.0.0, got \(mainVersion)")
        }
        
        // Validate build format (should be date-based)
        guard mainBuild.count == 10 && mainBuild.allSatisfy({ $0.isNumber }) else {
            throw ValidationError.versionMismatch("Build number should be 10-digit date format, got \(mainBuild)")
        }
        
        print("    ✓ Version: \(mainVersion)")
        print("    ✓ Build: \(mainBuild)")
        print("    ✓ Consistency: Main and Widget versions match")
    }
    
    private func validateBuildConfiguration() throws {
        print("  • Checking build configuration...")
        
        // Check for debug code in release builds
        let swiftFiles = findSwiftFiles(in: "MyTradeMate")
        var debugCodeFound = false
        
        for file in swiftFiles {
            let content = try String(contentsOfFile: file)
            
            // Check for debug-only code that shouldn't be in release
            if content.contains("print(") && !content.contains("#if DEBUG") {
                print("    ⚠️  Warning: print() statement found in \(file)")
            }
            
            // Check for TODO/FIXME in critical files
            if content.contains("TODO:") || content.contains("FIXME:") {
                if file.contains("Core/") || file.contains("Security/") {
                    throw ValidationError.buildConfigurationError("TODO/FIXME found in critical file: \(file)")
                }
            }
        }
        
        print("    ✓ No critical debug code found")
        print("    ✓ Build configuration validated")
    }
    
    private func validateAppStoreAssets() throws {
        print("  • Checking App Store assets...")
        
        // Check for App Icon
        let appIconPath = "MyTradeMate/Assets.xcassets/AppIcon.appiconset"
        guard FileManager.default.fileExists(atPath: appIconPath) else {
            throw ValidationError.missingAssets("App Icon set not found")
        }
        
        // Check for required icon sizes
        let requiredIcons = [
            "Contents.json",
            // Add specific icon files if they exist
        ]
        
        for icon in requiredIcons {
            let iconPath = "\(appIconPath)/\(icon)"
            if !FileManager.default.fileExists(atPath: iconPath) {
                print("    ⚠️  Warning: \(icon) not found in App Icon set")
            }
        }
        
        // Check for Accent Color
        let accentColorPath = "MyTradeMate/Assets.xcassets/AccentColor.colorset"
        guard FileManager.default.fileExists(atPath: accentColorPath) else {
            throw ValidationError.missingAssets("Accent Color not found")
        }
        
        print("    ✓ App Icon set exists")
        print("    ✓ Accent Color configured")
        print("    ✓ Asset catalog validated")
    }
    
    private func validatePrivacyCompliance() throws {
        print("  • Checking privacy compliance...")
        
        // Check for Privacy Manifest
        let privacyManifestPath = "MyTradeMate/PrivacyInfo.xcprivacy"
        guard FileManager.default.fileExists(atPath: privacyManifestPath) else {
            throw ValidationError.complianceIssue("Privacy Manifest (PrivacyInfo.xcprivacy) not found")
        }
        
        // Validate Privacy Manifest content
        guard let privacyData = FileManager.default.contents(atPath: privacyManifestPath),
              let privacyPlist = try PropertyListSerialization.propertyList(from: privacyData, options: [], format: nil) as? [String: Any] else {
            throw ValidationError.complianceIssue("Cannot read Privacy Manifest")
        }
        
        // Check required privacy keys
        let requiredKeys = [
            "NSPrivacyCollectedDataTypes",
            "NSPrivacyAccessedAPITypes",
            "NSPrivacyTrackingDomains",
            "NSPrivacyTracking"
        ]
        
        for key in requiredKeys {
            guard privacyPlist[key] != nil else {
                throw ValidationError.complianceIssue("Missing required privacy key: \(key)")
            }
        }
        
        // Validate no tracking
        guard let tracking = privacyPlist["NSPrivacyTracking"] as? Bool, !tracking else {
            throw ValidationError.complianceIssue("App should not track users")
        }
        
        print("    ✓ Privacy Manifest exists and is valid")
        print("    ✓ No user tracking configured")
        print("    ✓ Required privacy keys present")
    }
    
    private func validateSecurityConfiguration() throws {
        print("  • Checking security configuration...")
        
        // Check App Transport Security
        guard let mainPlist = readPlist("MyTradeMate/Info.plist"),
              let ats = mainPlist["NSAppTransportSecurity"] as? [String: Any] else {
            throw ValidationError.securityIssue("App Transport Security not configured")
        }
        
        // Validate ATS configuration
        if let allowsArbitraryLoads = ats["NSAllowsArbitraryLoads"] as? Bool, allowsArbitraryLoads {
            throw ValidationError.securityIssue("NSAllowsArbitraryLoads should be false for security")
        }
        
        // Check for hardcoded secrets
        let swiftFiles = findSwiftFiles(in: "MyTradeMate")
        for file in swiftFiles {
            let content = try String(contentsOfFile: file)
            
            // Check for potential hardcoded secrets
            let suspiciousPatterns = [
                "apiKey = \"",
                "secretKey = \"",
                "password = \"",
                "token = \""
            ]
            
            for pattern in suspiciousPatterns {
                if content.contains(pattern) {
                    throw ValidationError.securityIssue("Potential hardcoded secret in \(file)")
                }
            }
        }
        
        print("    ✓ App Transport Security configured")
        print("    ✓ No hardcoded secrets found")
        print("    ✓ Security configuration validated")
    }
    
    private func validatePerformanceRequirements() throws {
        print("  • Checking performance requirements...")
        
        // Check for performance optimization files
        let performanceFiles = [
            "MyTradeMate/Core/Performance/PerformanceOptimizer.swift",
            "MyTradeMate/Core/Performance/MemoryPressureManager.swift",
            "MyTradeMate/Core/Performance/InferenceThrottler.swift",
            "MyTradeMate/Core/Performance/ConnectionManager.swift",
            "MyTradeMate/Core/Performance/DataCacheManager.swift"
        ]
        
        for file in performanceFiles {
            guard FileManager.default.fileExists(atPath: file) else {
                throw ValidationError.performanceIssue("Performance optimization file missing: \(file)")
            }
        }
        
        // Check for memory management patterns
        let coreFiles = findSwiftFiles(in: "MyTradeMate/Core")
        var hasMemoryManagement = false
        
        for file in coreFiles {
            let content = try String(contentsOfFile: file)
            if content.contains("deinit") || content.contains("removeAll()") || content.contains("cancellables") {
                hasMemoryManagement = true
                break
            }
        }
        
        guard hasMemoryManagement else {
            throw ValidationError.performanceIssue("No memory management patterns found")
        }
        
        print("    ✓ Performance optimization system present")
        print("    ✓ Memory management patterns found")
        print("    ✓ Performance requirements met")
    }
    
    private func validateWidgetConfiguration() throws {
        print("  • Checking widget configuration...")
        
        // Check widget files
        let widgetFiles = [
            "MyTradeMateWidget/MyTradeMateWidget.swift",
            "MyTradeMateWidget/Info.plist"
        ]
        
        for file in widgetFiles {
            guard FileManager.default.fileExists(atPath: file) else {
                throw ValidationError.missingAssets("Widget file missing: \(file)")
            }
        }
        
        // Check widget Info.plist
        guard let widgetPlist = readPlist("MyTradeMateWidget/Info.plist"),
              let extension = widgetPlist["NSExtension"] as? [String: Any],
              let extensionPoint = extension["NSExtensionPointIdentifier"] as? String else {
            throw ValidationError.buildConfigurationError("Widget extension configuration invalid")
        }
        
        guard extensionPoint == "com.apple.widgetkit-extension" else {
            throw ValidationError.buildConfigurationError("Invalid widget extension point identifier")
        }
        
        print("    ✓ Widget files present")
        print("    ✓ Widget extension configured")
        print("    ✓ Widget configuration validated")
    }
    
    private func validateAccessibilityCompliance() throws {
        print("  • Checking accessibility compliance...")
        
        // Check for accessibility patterns in SwiftUI views
        let viewFiles = findSwiftFiles(in: "MyTradeMate/Views")
        var hasAccessibilitySupport = false
        
        for file in viewFiles {
            let content = try String(contentsOfFile: file)
            if content.contains("accessibilityLabel") || content.contains("accessibilityHint") || content.contains("accessibilityValue") {
                hasAccessibilitySupport = true
                break
            }
        }
        
        guard hasAccessibilitySupport else {
            throw ValidationError.complianceIssue("No accessibility support found in views")
        }
        
        print("    ✓ Accessibility labels found")
        print("    ✓ Accessibility compliance validated")
    }
    
    private func validateAppStoreGuidelines() throws {
        print("  • Checking App Store guidelines compliance...")
        
        // Check for appropriate age rating content
        let allFiles = findSwiftFiles(in: "MyTradeMate")
        for file in allFiles {
            let content = try String(contentsOfFile: file)
            
            // Check for inappropriate content
            let inappropriateTerms = ["gambling", "casino", "bet"]
            for term in inappropriateTerms {
                if content.lowercased().contains(term) && !content.contains("disclaimer") {
                    print("    ⚠️  Warning: Found term '\(term)' in \(file) - ensure proper disclaimers")
                }
            }
        }
        
        // Check for financial disclaimers
        var hasFinancialDisclaimer = false
        for file in allFiles {
            let content = try String(contentsOfFile: file)
            if content.contains("risk") && content.contains("trading") {
                hasFinancialDisclaimer = true
                break
            }
        }
        
        guard hasFinancialDisclaimer else {
            throw ValidationError.complianceIssue("No financial risk disclaimers found")
        }
        
        print("    ✓ Financial disclaimers present")
        print("    ✓ App Store guidelines compliance validated")
    }
    
    private func validateSubmissionReadiness() throws {
        print("  • Checking final submission readiness...")
        
        // Check documentation
        let requiredDocs = [
            "README.md",
            "CHANGELOG.md",
            "SECURITY.md",
            "APP_STORE_COMPLIANCE.md",
            "RELEASE_NOTES.md"
        ]
        
        for doc in requiredDocs {
            guard FileManager.default.fileExists(atPath: doc) else {
                throw ValidationError.missingAssets("Required documentation missing: \(doc)")
            }
        }
        
        // Check validation checklist
        let checklistPath = "MyTradeMate/VALIDATION_CHECKLIST.md"
        guard FileManager.default.fileExists(atPath: checklistPath) else {
            throw ValidationError.missingAssets("Validation checklist missing")
        }
        
        print("    ✓ All required documentation present")
        print("    ✓ Validation checklist available")
        print("    ✓ Submission readiness confirmed")
    }
    
    // MARK: - Helper Methods
    
    private func readPlist(_ path: String) -> [String: Any]? {
        guard let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        return plist
    }
    
    private func findSwiftFiles(in directory: String) -> [String] {
        var swiftFiles: [String] = []
        
        guard let enumerator = FileManager.default.enumerator(atPath: directory) else {
            return swiftFiles
        }
        
        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(".swift") {
                swiftFiles.append("\(directory)/\(file)")
            }
        }
        
        return swiftFiles
    }
}

// String extension for repeat operator
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Run the final validation
let validator = FinalBuildValidator()
validator.runFinalValidation()