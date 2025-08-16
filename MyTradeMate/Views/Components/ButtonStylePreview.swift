import SwiftUI

/// Preview view to test all standardized button styles
struct ButtonStylePreview: View {
    @State private var isLoading = false
    @State private var isDisabled = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Controls
                    VStack(spacing: 16) {
                        StandardToggleRow(
                            title: "Loading State",
                            isOn: $isLoading,
                            style: .default,
                            showDivider: false
                        )
                        
                        StandardToggleRow(
                            title: "Disabled State",
                            isOn: $isDisabled,
                            style: .default,
                            showDivider: false
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Primary Buttons
                    buttonSection(title: "Primary Buttons") {
                        VStack(spacing: 12) {
                            PrimaryButton(
                                "Primary Button",
                                icon: "star.fill",
                                isDisabled: isDisabled,
                                isLoading: isLoading,
                                action: { print("Primary button tapped") }
                            )
                            
                            PrimaryButton(
                                "Small Primary",
                                size: .small,
                                isDisabled: isDisabled,
                                isLoading: isLoading,
                                fullWidth: false,
                                action: { print("Small primary tapped") }
                            )
                        }
                    }
                    
                    // Secondary Buttons
                    buttonSection(title: "Secondary Buttons") {
                        VStack(spacing: 12) {
                            SecondaryButton(
                                "Secondary Button",
                                icon: "gear",
                                isDisabled: isDisabled,
                                isLoading: isLoading,
                                action: { print("Secondary button tapped") }
                            )
                            
                            SecondaryButton(
                                "Medium Secondary",
                                size: .medium,
                                isDisabled: isDisabled,
                                isLoading: isLoading,
                                fullWidth: false,
                                action: { print("Medium secondary tapped") }
                            )
                        }
                    }
                    
                    // Destructive Buttons
                    buttonSection(title: "Destructive Buttons") {
                        VStack(spacing: 12) {
                            DestructiveButton(
                                "Delete Account",
                                icon: "trash",
                                isDisabled: isDisabled,
                                isLoading: isLoading,
                                action: { print("Destructive button tapped") }
                            )
                            
                            DestructiveButton(
                                "Remove",
                                size: .medium,
                                isDisabled: isDisabled,
                                isLoading: isLoading,
                                fullWidth: false,
                                action: { print("Remove tapped") }
                            )
                        }
                    }
                    
                    // Success & Warning Buttons
                    buttonSection(title: "Success & Warning Buttons") {
                        VStack(spacing: 12) {
                            SuccessButton(
                                "Success Action",
                                icon: "checkmark.circle",
                                isDisabled: isDisabled,
                                isLoading: isLoading,
                                action: { print("Success button tapped") }
                            )
                            
                            WarningButton(
                                "Warning Action",
                                icon: "exclamationmark.triangle",
                                isDisabled: isDisabled,
                                isLoading: isLoading,
                                action: { print("Warning button tapped") }
                            )
                        }
                    }
                    
                    // Ghost & Outline Buttons
                    buttonSection(title: "Ghost & Outline Buttons") {
                        VStack(spacing: 12) {
                            GhostButton(
                                "Ghost Button",
                                icon: "eye",
                                isDisabled: isDisabled,
                                isLoading: isLoading,
                                action: { print("Ghost button tapped") }
                            )
                            
                            OutlineButton(
                                "Outline Button",
                                icon: "square.and.arrow.up",
                                isDisabled: isDisabled,
                                isLoading: isLoading,
                                action: { print("Outline button tapped") }
                            )
                        }
                    }
                    
                    // Trading Buttons
                    buttonSection(title: "Trading Buttons") {
                        HStack(spacing: 12) {
                            BuyButton(
                                isDisabled: isDisabled,
                                isLoading: isLoading,
                                isDemoMode: true,
                                action: { print("Buy button tapped") }
                            )
                            
                            SellButton(
                                isDisabled: isDisabled,
                                isLoading: isLoading,
                                isDemoMode: false,
                                action: { print("Sell button tapped") }
                            )
                        }
                    }
                    
                    // Size Variations
                    buttonSection(title: "Size Variations") {
                        VStack(spacing: 12) {
                            PrimaryButton(
                                "Small",
                                size: .small,
                                fullWidth: false,
                                action: { print("Small tapped") }
                            )
                            
                            PrimaryButton(
                                "Medium",
                                size: .medium,
                                fullWidth: false,
                                action: { print("Medium tapped") }
                            )
                            
                            PrimaryButton(
                                "Large",
                                size: .large,
                                fullWidth: false,
                                action: { print("Large tapped") }
                            )
                            
                            PrimaryButton(
                                "Extra Large",
                                size: .extraLarge,
                                fullWidth: false,
                                action: { print("Extra large tapped") }
                            )
                        }
                    }
                    
                    // Standard Button with Custom Styles
                    buttonSection(title: "Standard Button Variations") {
                        VStack(spacing: 12) {
                            StandardButton(
                                "Tertiary Style",
                                icon: "info.circle",
                                style: .tertiary,
                                size: .medium,
                                fullWidth: false,
                                action: { print("Tertiary tapped") }
                            )
                            
                            StandardButton(
                                "Custom Style",
                                icon: "wand.and.stars",
                                style: .primary,
                                size: .large,
                                isDisabled: isDisabled,
                                isLoading: isLoading,
                                fullWidth: true,
                                action: { print("Custom tapped") }
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Button Styles")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func buttonSection<Content: View>(
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
    ButtonStylePreview()
}