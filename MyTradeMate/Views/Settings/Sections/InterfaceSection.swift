import SwiftUI

struct InterfaceSection: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        Section {
            StandardToggleRow(
                title: "Haptics",
                description: "Enable tactile feedback for button presses, trade confirmations, and other interactions.",
                isOn: $settings.hapticsEnabled,
                style: .default
            )
            
            StandardToggleRow(
                title: "Dark Mode",
                description: "Use dark color scheme throughout the app. Follows system setting when disabled.",
                isOn: $settings.darkMode,
                style: .minimal
            )
        }
    }
}