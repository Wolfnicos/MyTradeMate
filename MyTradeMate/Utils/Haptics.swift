import UIKit
import SwiftUI

enum Haptics {
    static func play(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    static func playSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    static func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // Convenience methods for trading
    static func buyFeedback() {
        play(.success)
    }
    
    static func sellFeedback() {
        play(.warning)
    }
    
    static func errorFeedback() {
        play(.error)
    }
}

// MARK: - Theme Management

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("settings.darkMode") 
    public var isDarkMode: Bool = false {
        didSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("settings.haptics")
    public var isHapticsEnabled: Bool = true {
        didSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("settings.confirmTrades")
    public var isConfirmTradesEnabled: Bool = true {
        didSet {
            objectWillChange.send()
        }
    }
    
    private init() {}
    
    var colorScheme: ColorScheme? {
        isDarkMode ? .dark : .light
    }
}
