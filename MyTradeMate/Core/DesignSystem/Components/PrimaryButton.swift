import SwiftUI

/// Modern primary button component with consistent styling and states
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let size: ButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(style.foregroundColor)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .medium))
                }
                
                Text(title)
                    .font(size.font)
                    .fontWeight(.semibold)
            }
            .foregroundColor(effectiveForegroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(effectiveBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .cornerRadius(size.cornerRadius)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity(effectiveOpacity)
    }
    
    @State private var isPressed = false
    
    private var effectiveBackgroundColor: Color {
        if isDisabled {
            return style.backgroundColor.opacity(0.3)
        }
        return style.backgroundColor
    }
    
    private var effectiveForegroundColor: Color {
        if isDisabled {
            return style.foregroundColor.opacity(0.5)
        }
        return style.foregroundColor
    }
    
    private var effectiveOpacity: Double {
        return (isDisabled || isLoading) ? 0.6 : 1.0
    }
}

/// Button styling variants
enum ButtonStyle {
    case primary
    case secondary
    case outline
    case ghost
    case success
    case warning
    case error
    case buy
    case sell
    
    var backgroundColor: Color {
        switch self {
        case .primary:
            return DesignTokens.Colors.primary
        case .secondary:
            return DesignTokens.Colors.secondary
        case .outline, .ghost:
            return .clear
        case .success:
            return DesignTokens.Colors.success
        case .warning:
            return DesignTokens.Colors.warning
        case .error:
            return DesignTokens.Colors.error
        case .buy:
            return DesignTokens.Colors.gain
        case .sell:
            return DesignTokens.Colors.loss
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary, .secondary, .success, .warning, .error, .buy, .sell:
            return .white
        case .outline:
            return DesignTokens.Colors.primary
        case .ghost:
            return DesignTokens.Colors.textPrimary
        }
    }
    
    var borderColor: Color {
        switch self {
        case .outline:
            return DesignTokens.Colors.primary
        case .ghost:
            return DesignTokens.Colors.border
        default:
            return .clear
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .outline, .ghost:
            return 1
        default:
            return 0
        }
    }
}

/// Button size variants
enum ButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small:
            return DesignTokens.ComponentSize.buttonHeightSmall
        case .medium:
            return DesignTokens.ComponentSize.buttonHeight
        case .large:
            return 56
        }
    }
    
    var font: Font {
        switch self {
        case .small:
            return DesignTokens.Typography.labelMedium
        case .medium:
            return DesignTokens.Typography.bodyMedium
        case .large:
            return DesignTokens.Typography.bodyLarge
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small:
            return DesignTokens.Radius.sm
        case .medium:
            return DesignTokens.Radius.md
        case .large:
            return DesignTokens.Radius.lg
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small:
            return DesignTokens.IconSize.sm
        case .medium:
            return DesignTokens.IconSize.md
        case .large:
            return DesignTokens.IconSize.lg
        }
    }
}

/// Custom button style for press animations
struct PressableButtonStyle: SwiftUI.ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DesignTokens.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - Specialized Trading Buttons

/// Trading action buttons with consistent styling
struct TradingActionButtons: View {
    let onBuy: () -> Void
    let onSell: () -> Void
    let isLoading: Bool
    
    init(
        onBuy: @escaping () -> Void,
        onSell: @escaping () -> Void,
        isLoading: Bool = false
    ) {
        self.onBuy = onBuy
        self.onSell = onSell
        self.isLoading = isLoading
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            PrimaryButton(
                "Buy",
                icon: "arrow.up.circle.fill",
                style: .buy,
                isLoading: isLoading,
                action: onBuy
            )
            
            PrimaryButton(
                "Sell",
                icon: "arrow.down.circle.fill",
                style: .sell,
                isLoading: isLoading,
                action: onSell
            )
        }
    }
}

// MARK: - Preview
#Preview("Buttons") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Primary buttons
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Primary Buttons")
                    .font(DesignTokens.Typography.headlineSmall)
                
                PrimaryButton("Primary", action: {})
                PrimaryButton("With Icon", icon: "star.fill", action: {})
                PrimaryButton("Loading", isLoading: true, action: {})
                PrimaryButton("Disabled", isDisabled: true, action: {})
            }
            
            // Button styles
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Button Styles")
                    .font(DesignTokens.Typography.headlineSmall)
                
                PrimaryButton("Secondary", style: .secondary, action: {})
                PrimaryButton("Outline", style: .outline, action: {})
                PrimaryButton("Ghost", style: .ghost, action: {})
                PrimaryButton("Success", style: .success, action: {})
                PrimaryButton("Warning", style: .warning, action: {})
                PrimaryButton("Error", style: .error, action: {})
            }
            
            // Button sizes
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Button Sizes")
                    .font(DesignTokens.Typography.headlineSmall)
                
                PrimaryButton("Small", size: .small, action: {})
                PrimaryButton("Medium", size: .medium, action: {})
                PrimaryButton("Large", size: .large, action: {})
            }
            
            // Trading buttons
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Trading Buttons")
                    .font(DesignTokens.Typography.headlineSmall)
                
                TradingActionButtons(
                    onBuy: {},
                    onSell: {}
                )
            }
        }
        .padding()
    }
    .background(DesignTokens.Colors.surface)
}