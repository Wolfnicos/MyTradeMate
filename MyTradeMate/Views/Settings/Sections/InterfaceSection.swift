import SwiftUI

struct InterfaceSection: View {
    @EnvironmentObject var settings: SettingsRepository
    
    var body: some View {
        Section("Interface") {
            StandardToggleRow(
                title: "Verbose Logging",
                description: "Enable detailed logging for debugging.",
                isOn: $settings.verboseLogging,
                style: .default
            )
            
            Picker("Theme", selection: $settings.preferredTheme) {
                Text("System").tag(AppTheme.system)
                Text("Light").tag(AppTheme.light)
                Text("Dark").tag(AppTheme.dark)
            }
            .pickerStyle(.segmented)
        }
    }
}