import SwiftUI

/// Preview view to test all standardized toggle styles
struct ToggleStylePreview: View {
    @State private var defaultToggle = false
    @State private var prominentToggle = true
    @State private var successToggle = true
    @State private var warningToggle = false
    @State private var dangerToggle = false
    @State private var minimalToggle = true
    @State private var disabledToggle = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Individual Toggle Components
                    toggleSection(title: "Individual Toggle Components") {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Default Toggle")
                                    .font(.body)
                                Spacer()
                                DefaultToggle(isOn: $defaultToggle)
                            }
                            
                            HStack {
                                Text("Prominent Toggle")
                                    .font(.body)
                                Spacer()
                                ProminentToggle(isOn: $prominentToggle)
                            }
                            
                            HStack {
                                Text("Success Toggle")
                                    .font(.body)
                                Spacer()
                                SuccessToggle(isOn: $successToggle)
                            }
                            
                            HStack {
                                Text("Warning Toggle")
                                    .font(.body)
                                Spacer()
                                WarningToggle(isOn: $warningToggle)
                            }
                            
                            HStack {
                                Text("Danger Toggle")
                                    .font(.body)
                                Spacer()
                                DangerToggle(isOn: $dangerToggle)
                            }
                            
                            HStack {
                                Text("Minimal Toggle")
                                    .font(.body)
                                Spacer()
                                MinimalToggle(isOn: $minimalToggle)
                            }
                            
                            HStack {
                                Text("Disabled Toggle")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                Spacer()
                                DefaultToggle(isOn: $disabledToggle, isDisabled: true)
                            }
                        }
                    }
                    
                    // Size Variations
                    toggleSection(title: "Size Variations") {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Small")
                                    .font(.body)
                                Spacer()
                                StandardToggle(
                                    isOn: $defaultToggle,
                                    style: .default,
                                    size: .small
                                )
                            }
                            
                            HStack {
                                Text("Medium")
                                    .font(.body)
                                Spacer()
                                StandardToggle(
                                    isOn: $defaultToggle,
                                    style: .default,
                                    size: .medium
                                )
                            }
                            
                            HStack {
                                Text("Large")
                                    .font(.body)
                                Spacer()
                                StandardToggle(
                                    isOn: $defaultToggle,
                                    style: .default,
                                    size: .large
                                )
                            }
                        }
                    }
                    
                    // Toggle Rows
                    toggleSection(title: "Toggle Rows") {
                        VStack(spacing: 8) {
                            StandardToggleRow(
                                title: "Demo Mode",
                                description: "Use simulated trading environment for testing strategies without real money.",
                                helpText: "Demo Mode creates a completely simulated trading environment where you can test strategies without any risk. All trades are virtual and no real money is involved.",
                                isOn: $warningToggle,
                                style: .warning
                            )
                            
                            StandardToggleRow(
                                title: "Auto Trading",
                                description: "Allow AI strategies to automatically place trades when conditions are met.",
                                isOn: $successToggle,
                                style: .success
                            )
                            
                            StandardToggleRow(
                                title: "Haptic Feedback",
                                description: "Enable tactile feedback for interactions.",
                                isOn: $defaultToggle,
                                style: .default
                            )
                            
                            StandardToggleRow(
                                title: "Verbose Logging",
                                description: "Enable detailed logging. May impact performance.",
                                isOn: $dangerToggle,
                                style: .danger
                            )
                            
                            StandardToggleRow(
                                title: "Disabled Setting",
                                description: "This setting is currently disabled.",
                                isOn: $disabledToggle,
                                style: .default,
                                isDisabled: true
                            )
                        }
                    }
                    
                    // Style Comparison
                    toggleSection(title: "Style Comparison (All On)") {
                        VStack(spacing: 12) {
                            ForEach([
                                ("Default", ToggleStyle.default),
                                ("Prominent", ToggleStyle.prominent),
                                ("Success", ToggleStyle.success),
                                ("Warning", ToggleStyle.warning),
                                ("Danger", ToggleStyle.danger),
                                ("Minimal", ToggleStyle.minimal)
                            ], id: \.0) { name, style in
                                HStack {
                                    Text(name)
                                        .font(.body)
                                    Spacer()
                                    StandardToggle(
                                        isOn: .constant(true),
                                        style: style,
                                        size: .medium
                                    )
                                }
                            }
                        }
                    }
                    
                    // Style Comparison (All Off)
                    toggleSection(title: "Style Comparison (All Off)") {
                        VStack(spacing: 12) {
                            ForEach([
                                ("Default", ToggleStyle.default),
                                ("Prominent", ToggleStyle.prominent),
                                ("Success", ToggleStyle.success),
                                ("Warning", ToggleStyle.warning),
                                ("Danger", ToggleStyle.danger),
                                ("Minimal", ToggleStyle.minimal)
                            ], id: \.0) { name, style in
                                HStack {
                                    Text(name)
                                        .font(.body)
                                    Spacer()
                                    StandardToggle(
                                        isOn: .constant(false),
                                        style: style,
                                        size: .medium
                                    )
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Toggle Styles")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func toggleSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    ToggleStylePreview()
}