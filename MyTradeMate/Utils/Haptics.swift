import UIKit
import SwiftUI

final class Haptics {
    static let shared = Haptics()
    private init() {}
    
    @MainActor
    static func play(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard ThemeManager.shared.isHapticsEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    @MainActor
    static func playSelection() {
        guard ThemeManager.shared.isHapticsEnabled else { return }
        
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    @MainActor
    static func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard ThemeManager.shared.isHapticsEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // Convenience methods for trading
    @MainActor
    static func success() {
        play(.success)
    }
    
    @MainActor
    static func warning() {
        play(.warning)
    }
    
    @MainActor
    static func error() {
        play(.error)
    }
    
    // Legacy methods (keeping for backward compatibility)
    @MainActor
    static func buyFeedback() {
        success()
    }
    
    @MainActor
    static func sellFeedback() {
        warning()
    }
    
    @MainActor
    static func errorFeedback() {
        error()
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
