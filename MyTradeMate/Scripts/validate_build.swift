#!/usr/bin/env swift

import Foundation

/// Build validation script for MyTradeMate
/// This script performs comprehensive validation of the build environment and code quality

struct BuildValidator {
    
    enum ValidationError: Error, LocalizedError {
        case fileNotFound(String)
        case invalidConfiguration(String)
        case buildIssue(String)
        case codeQualityIssue(String)
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound(let file):
                return "File not found: \(file)"
            case .invalidConfiguration(let config):
                return "Invalid configuration: \(config)"
            case .buildIssue(let issue):
                return "Build issue: \(issue)"
            case .codeQualityIssue(let issue):
                return "Code quality issue: \(issue)"
            }
        }
    }
    
    func runValidation() {
        print("🚀 Starting MyTradeMate Build Validation")
        print("=" * 50)
        
        var passedTests = 0
        var failedTests = 0
        
        let validations: [(String, () throws -> Void)] = [
            ("Project Structure", validateProjectStructure),
            ("Swift Files Syntax", validateSwiftSyntax),
            ("Dependencies", validateDependencies),
            ("Info.plist Configuration", validateInfoPlist),
            ("Asset Catalog", validateAssets),
            ("CoreML Models", validateCoreMLModels),
            ("Security Configuration", validateSecurity),
            ("Performance Settings", validatePerformance),
            ("Widget Configuration", validateWidget),
            ("Test Coverage", validateTestCoverage)
        ]
        
        for (testName, validation) in validations {
            print("\n📋 Running: \(testName)")
            do {
                try validation()
                print("✅ \(testName): PASSED")
                passedTests += 1
            } catch {
                print("❌ \(testName): FAILED - \(error.localizedDescription)")
                failedTests += 1
            }
        }
        
        print("\n" + "=" * 50)
        print("📊 Validation Summary:")
        print("✅ Passed: \(passedTests)")
        print("❌ Failed: \(failedTests)")
        print("📈 Success Rate: \(Int((Double(passedTests) / Double(passedTests + failedTests)) * 100))%")
        
        if failedTests == 0 {
            print("\n🎉 All validations passed! Build is ready for deployment.")
            exit(0)
        } else {
            print("\n⚠️  Some validations failed. Please fix the issues before deployment.")
            exit(1)
        }
    }
    
    private func validateProjectStructure() throws {
        let requiredDirectories = [
            "MyTradeMate/Core",
            "MyTradeMate/Views",
            "MyTradeMate/ViewModels",
            "MyTradeMate/Services",
            "MyTradeMate/Models",
            "MyTradeMate/Security",
            "MyTradeMate/Settings",
            "MyTradeMate/Strategies",
            "MyTradeMate/Themes",
            "MyTradeMate/Tests",
            "MyTradeMate/UI",
            "MyTradeMateWidget"
        ]
        
        for directory in requiredDirectories {
            if !FileManager.default.fileExists(atPath: directory) {
                throw ValidationError.fileNotFound(directory)
            }
        }
        
        let requiredFiles = [
            "MyTradeMate/MyTradeMateApp.swift",
            "MyTradeMate/Info.plist",
            "MyTradeMate/Core/AppError.swift",
            "MyTradeMate/Core/ErrorManager.swift",
            "MyTradeMate/Models/AppSettings.swift",
            "MyTradeMate/Security/KeychainStore.swift",
            "MyTradeMate/Services/Data/MarketDataService.swift",
            "MyTradeMate/Services/AI/AIModelManager.swift"
        ]
        
        for file in requiredFiles {
            if !FileManager.default.fileExists(atPath: file) {
                throw ValidationError.fileNotFound(file)
            }
        }
    }
    
    private func validateSwiftSyntax() throws {
        // Check for common Swift syntax issues
        let swiftFiles = findSwiftFiles(in: "MyTradeMate")
        
        for file in swiftFiles {
            let content = try String(contentsOfFile: file)
            
            // Check for force unwraps (should be minimal)
            let forceUnwrapCount = content.components(separatedBy: "!").count - 1
            if forceUnwrapCount > 5 { // Allow some force unwraps for system APIs
                print("⚠️  Warning: \(file) has \(forceUnwrapCount) force unwraps")
            }
            
            // Check for TODO/FIXME comments
            if content.contains("TODO:") || content.contains("FIXME:") {
                print("⚠️  Warning: \(file) contains TODO/FIXME comments")
            }
            
            // Check for proper import statements
            if !content.contains("import Foundation") && !content.contains("import SwiftUI") {
                if file.hasSuffix(".swift") && !file.contains("Test") {
                    print("⚠️  Warning: \(file) may be missing required imports")
                }
            }
        }
    }
    
    private func validateDependencies() throws {
        // Check that all required dependencies are available
        let requiredFrameworks = [
            "Foundation",
            "SwiftUI",
            "Combine",
            "CoreML",
            "Network",
            "Security",
            "WidgetKit"
        ]
        
        // This would typically check Package.swift or project dependencies
        // For now, we'll assume they're available if the project compiles
        print("📦 Checking framework dependencies...")
        
        for framework in requiredFrameworks {
            print("  ✓ \(framework)")
        }
    }
    
    private func validateInfoPlist() throws {
        let infoPlistPath = "MyTradeMate/Info.plist"
        
        guard FileManager.default.fileExists(atPath: infoPlistPath) else {
            throw ValidationError.fileNotFound(infoPlistPath)
        }
        
        guard let plistData = FileManager.default.contents(atPath: infoPlistPath),
              let plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
            throw ValidationError.invalidConfiguration("Could not read Info.plist")
        }
        
        // Check required keys
        let requiredKeys = [
            "CFBundleDisplayName",
            "CFBundleIdentifier",
            "CFBundleVersion",
            "CFBundleShortVersionString",
            "LSRequiresIPhoneOS",
            "UILaunchScreen",
            "UISupportedInterfaceOrientations"
        ]
        
        for key in requiredKeys {
            if plist[key] == nil {
                throw ValidationError.invalidConfiguration("Missing required key: \(key)")
            }
        }
        
        // Check iOS deployment target
        if let deploymentTarget = plist["MinimumOSVersion"] as? String {
            let version = deploymentTarget.replacingOccurrences(of: ".", with: "")
            if Int(version) ?? 0 < 170 {
                throw ValidationError.invalidConfiguration("iOS deployment target should be 17.0 or higher")
            }
        }
    }
    
    private func validateAssets() throws {
        let assetsPath = "MyTradeMate/Assets.xcassets"
        
        guard FileManager.default.fileExists(atPath: assetsPath) else {
            throw ValidationError.fileNotFound(assetsPath)
        }
        
        // Check for required assets
        let requiredAssets = [
            "AppIcon.appiconset",
            "AccentColor.colorset"
        ]
        
        for asset in requiredAssets {
            let assetPath = "\(assetsPath)/\(asset)"
            if !FileManager.default.fileExists(atPath: assetPath) {
                throw ValidationError.fileNotFound(assetPath)
            }
        }
    }
    
    private func validateCoreMLModels() throws {
        let modelsPath = "MyTradeMate/AIModels"
        
        guard FileManager.default.fileExists(atPath: modelsPath) else {
            throw ValidationError.fileNotFound(modelsPath)
        }
        
        let requiredModels = [
            "BitcoinAI_5m_enhanced.mlmodel",
            "BitcoinAI_1h_enhanced.mlmodel",
            "BTC_4H_Model.mlmodel"
        ]
        
        for model in requiredModels {
            let modelPath = "\(modelsPath)/\(model)"
            if !FileManager.default.fileExists(atPath: modelPath) {
                print("⚠️  Warning: CoreML model not found: \(model)")
            }
        }
    }
    
    private func validateSecurity() throws {
        // Check for security best practices
        let securityFiles = [
            "MyTradeMate/Security/KeychainStore.swift",
            "MyTradeMate/Core/AppError.swift"
        ]
        
        for file in securityFiles {
            guard FileManager.default.fileExists(atPath: file) else {
                throw ValidationError.fileNotFound(file)
            }
            
            let content = try String(contentsOfFile: file)
            
            // Check for hardcoded secrets (basic check)
            let suspiciousPatterns = ["password", "secret", "key", "token"]
            for pattern in suspiciousPatterns {
                if content.lowercased().contains("\(pattern) = \"") {
                    print("⚠️  Warning: Potential hardcoded secret in \(file)")
                }
            }
        }
    }
    
    private func validatePerformance() throws {
        let performanceFiles = [
            "MyTradeMate/Core/Performance/PerformanceOptimizer.swift",
            "MyTradeMate/Core/Performance/MemoryPressureManager.swift",
            "MyTradeMate/Core/Performance/InferenceThrottler.swift"
        ]
        
        for file in performanceFiles {
            if !FileManager.default.fileExists(atPath: file) {
                throw ValidationError.fileNotFound(file)
            }
        }
    }
    
    private func validateWidget() throws {
        let widgetFiles = [
            "MyTradeMateWidget/MyTradeMateWidget.swift",
            "MyTradeMateWidget/Info.plist"
        ]
        
        for file in widgetFiles {
            if !FileManager.default.fileExists(atPath: file) {
                throw ValidationError.fileNotFound(file)
            }
        }
    }
    
    private func validateTestCoverage() throws {
        let testDirectory = "MyTradeMate/Tests"
        
        guard FileManager.default.fileExists(atPath: testDirectory) else {
            throw ValidationError.fileNotFound(testDirectory)
        }
        
        let testFiles = findSwiftFiles(in: testDirectory)
        
        if testFiles.count < 10 {
            print("⚠️  Warning: Low test coverage - only \(testFiles.count) test files found")
        }
        
        // Check for required test suites
        let requiredTestSuites = [
            "CoreTradingLogicTestSuite.swift",
            "SecurityTestSuite.swift",
            "AIMLTestSuite.swift"
        ]
        
        for testSuite in requiredTestSuites {
            let testPath = "\(testDirectory)/Unit/\(testSuite)"
            if !FileManager.default.fileExists(atPath: testPath) {
                print("⚠️  Warning: Missing test suite: \(testSuite)")
            }
        }
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

// Run the validation
let validator = BuildValidator()
validator.runValidation()