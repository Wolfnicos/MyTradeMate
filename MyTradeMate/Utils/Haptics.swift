import UIKit

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
