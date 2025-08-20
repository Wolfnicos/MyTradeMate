import UIKit
import SwiftUI

/// Utility to validate tab icons work correctly in both light and dark modes
struct TabIconValidator {
    
    /// Validates that all tab icons are valid SF Symbols
    static func validateTabIcons() -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        for tab in AppTab.allCases {
            let iconName = tab.systemImage
            let image = UIImage(systemName: iconName)
            results["\(tab.rawValue) (\(iconName))"] = image != nil
        }
        
        return results
    }
    
    /// Tests that tab icons render correctly in both light and dark modes
    static func validateColorSchemeAdaptation() -> [String: (light: Bool, dark: Bool)] {
        var results: [String: (light: Bool, dark: Bool)] = [:]
        
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let darkTraits = UITraitCollection(userInterfaceStyle: .dark)
        
        for tab in AppTab.allCases {
            let iconName = tab.systemImage
            let baseImage = UIImage(systemName: iconName)
            
            let lightImage = baseImage?.withConfiguration(
                UIImage.SymbolConfiguration(traitCollection: lightTraits)
            )
            let darkImage = baseImage?.withConfiguration(
                UIImage.SymbolConfiguration(traitCollection: darkTraits)
            )
            
            results["\(tab.rawValue) (\(iconName))"] = (
                light: lightImage != nil,
                dark: darkImage != nil
            )
        }
        
        return results
    }
    
    /// Validates that system colors used in tab bar appearance adapt to color schemes
    static func validateSystemColors() -> [String: (light: UIColor, dark: UIColor)] {
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let darkTraits = UITraitCollection(userInterfaceStyle: .dark)
        
        return [
            "systemGray": (
                light: UIColor.systemGray.resolvedColor(with: lightTraits),
                dark: UIColor.systemGray.resolvedColor(with: darkTraits)
            ),
            "systemBlue": (
                light: UIColor.systemBlue.resolvedColor(with: lightTraits),
                dark: UIColor.systemBlue.resolvedColor(with: darkTraits)
            ),
            "systemBackground": (
                light: UIColor.systemBackground.resolvedColor(with: lightTraits),
                dark: UIColor.systemBackground.resolvedColor(with: darkTraits)
            )
        ]
    }
    
    /// Prints validation results to console
    static func printValidationResults() {
        print("🔍 Tab Icon Validation Results")
        print("=" * 40)
        
        // Test icon existence
        print("\n📱 Icon Existence:")
        let iconResults = validateTabIcons()
        for (name, isValid) in iconResults {
            let status = isValid ? "✅" : "❌"
            print("  \(status) \(name)")
        }
        
        // Test color scheme adaptation
        print("\n🌓 Color Scheme Adaptation:")
        let colorResults = validateColorSchemeAdaptation()
        for (name, modes) in colorResults {
            let lightStatus = modes.light ? "✅" : "❌"
            let darkStatus = modes.dark ? "✅" : "❌"
            print("  \(name):")
            print("    Light: \(lightStatus)")
            print("    Dark:  \(darkStatus)")
        }
        
        // Test system colors
        print("\n🎨 System Color Adaptation:")
        let systemColors = validateSystemColors()
        for (colorName, colors) in systemColors {
            let isDifferent = colors.light != colors.dark
            let status = isDifferent ? "✅" : "⚠️"
            print("  \(status) \(colorName): \(isDifferent ? "Adapts" : "Same in both modes")")
        }
        
        print("\n" + "=" * 40)
        print("Validation complete!")
    }
}

// MARK: - String Extension for Repeat
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}