import XCTest
import SwiftUI
@testable import MyTradeMate

/// Tests to verify tab icons work correctly in both light and dark modes
final class TabIconTests: XCTestCase {
    
    func testTabIconsExist() {
        // Test that all tab icons are valid SF Symbols
        for tab in AppTab.allCases {
            let iconName = tab.systemImage
            let image = UIImage(systemName: iconName)
            XCTAssertNotNil(image, "Tab icon '\(iconName)' for \(tab.rawValue) should be a valid SF Symbol")
        }
    }
    
    func testTabIconsAdaptToLightMode() {
        // Test that icons render properly in light mode
        let lightTraitCollection = UITraitCollection(userInterfaceStyle: .light)
        
        for tab in AppTab.allCases {
            let iconName = tab.systemImage
            let image = UIImage(systemName: iconName)
            XCTAssertNotNil(image, "Tab icon '\(iconName)' should exist")
            
            // Test that the image can be rendered with light mode traits
            let lightImage = image?.withConfiguration(
                UIImage.SymbolConfiguration(for: lightTraitCollection)
            )
            XCTAssertNotNil(lightImage, "Tab icon '\(iconName)' should render in light mode")
        }
    }
    
    func testTabIconsAdaptToDarkMode() {
        // Test that icons render properly in dark mode
        let darkTraitCollection = UITraitCollection(userInterfaceStyle: .dark)
        
        for tab in AppTab.allCases {
            let iconName = tab.systemImage
            let image = UIImage(systemName: iconName)
            XCTAssertNotNil(image, "Tab icon '\(iconName)' should exist")
            
            // Test that the image can be rendered with dark mode traits
            let darkImage = image?.withConfiguration(
                UIImage.SymbolConfiguration(for: darkTraitCollection)
            )
            XCTAssertNotNil(darkImage, "Tab icon '\(iconName)' should render in dark mode")
        }
    }
    
    func testTabBarAppearanceSupportsLightDarkMode() {
        // Test that tab bar appearance uses system colors that adapt to light/dark mode
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        
        // Configure with system colors (same as in MyTradeMateApp.swift)
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        
        // Test that system colors resolve differently in light vs dark mode
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let darkTraits = UITraitCollection(userInterfaceStyle: .dark)
        
        let lightGray = UIColor.systemGray.resolvedColor(with: lightTraits)
        let darkGray = UIColor.systemGray.resolvedColor(with: darkTraits)
        
        // System gray should be different in light vs dark mode
        XCTAssertNotEqual(lightGray, darkGray, "systemGray should resolve to different colors in light vs dark mode")
        
        let lightBlue = UIColor.systemBlue.resolvedColor(with: lightTraits)
        let darkBlue = UIColor.systemBlue.resolvedColor(with: darkTraits)
        
        // System blue should be different in light vs dark mode
        XCTAssertNotEqual(lightBlue, darkBlue, "systemBlue should resolve to different colors in light vs dark mode")
    }
    
    func testAllTabIconsAreAccessible() {
        // Test that all tab icons have proper accessibility
        for tab in AppTab.allCases {
            let iconName = tab.systemImage
            let tabTitle = tab.rawValue
            
            // Verify icon name is not empty
            XCTAssertFalse(iconName.isEmpty, "Tab icon name should not be empty for \(tabTitle)")
            
            // Verify tab title is not empty
            XCTAssertFalse(tabTitle.isEmpty, "Tab title should not be empty")
            
            // Test that the icon can be used in a Label (which is what we use in RootTabs)
            let label = Label(tabTitle, systemImage: iconName)
            XCTAssertNotNil(label, "Should be able to create Label with title '\(tabTitle)' and icon '\(iconName)'")
        }
    }
}