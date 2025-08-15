import SwiftUI

struct InterfaceSection: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        Section {
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
                .help("Enable haptic feedback")
            
            Toggle("Dark Mode", isOn: $settings.darkMode)
                .help("Use dark appearance")
        }
    }
}