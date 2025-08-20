import SwiftUI

/// Modern mode chip component with consistent styling
/// Displays trading mode, status, or any categorical information
struct ModeChip: View {
    let text: String
    let style: ChipStyle
    let size: ChipSize
    
    init(_ text: String, style: ChipStyle = .default, size: ChipSize = .medium) {
        self.text = text
        self.style = style
        self.size = size
    }
    
    var body: some View {
        Text(text.uppercased())
            .font(size.font)
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(style.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .cornerRadius(DesignTokens.Radius.sm)
    }
}

/// Chip styling variants
enum ChipStyle {
    case `default`
    case primary
    case secondary
    case success
    case warning
    case error
    case demo
    case paper
    case live
    case neutral
    case custom(backgroundColor: Color, foregroundColor: Color, borderColor: Color? = nil)
    
    var backgroundColor: Color {
        switch self {
        case .default:
            return DesignTokens.Colors.chipBackground
        case .primary:
            return DesignTokens.Colors.primary.opacity(0.15)
        case .secondary:
            return DesignTokens.Colors.secondary.opacity(0.15)
        case .success:
            return DesignTokens.Colors.success.opacity(0.15)
        case .warning:
            return DesignTokens.Colors.warning.opacity(0.15)
        case .error:
            return DesignTokens.Colors.error.opacity(0.15)
        case .demo:
            return DesignTokens.Colors.demoMode.opacity(0.15)
        case .paper:
            return DesignTokens.Colors.paperMode.opacity(0.15)
        case .live:
            return DesignTokens.Colors.liveMode.opacity(0.15)
        case .neutral:
            return DesignTokens.Colors.neutral.opacity(0.15)
        case .custom(let backgroundColor, _, _):
            return backgroundColor
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .default:
            return DesignTokens.Colors.textPrimary
        case .primary:
            return DesignTokens.Colors.primary
        case .secondary:
            return DesignTokens.Colors.secondary
        case .success:
            return DesignTokens.Colors.success
        case .warning:
            return DesignTokens.Colors.warning
        case .error:
            return DesignTokens.Colors.error
        case .demo:
            return DesignTokens.Colors.demoMode
        case .paper:
            return DesignTokens.Colors.paperMode
        case .live:
            return DesignTokens.Colors.liveMode
        case .neutral:
            return DesignTokens.Colors.neutral
        case .custom(_, let foregroundColor, _):
            return foregroundColor
        }
    }
    
    var borderColor: Color {
        switch self {
        case .custom(_, _, let borderColor):
            return borderColor ?? .clear
        default:
            return foregroundColor
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .custom(_, _, let borderColor):
            return borderColor != nil ? 1 : 0
        case .demo, .paper, .live:
            return 1 // Trading modes have borders
        default:
            return 0
        }
    }
}

/// Chip size variants
enum ChipSize {
    case small
    case medium
    case large
    
    var font: Font {
        switch self {
        case .small:
            return DesignTokens.Typography.overline
        case .medium:
            return DesignTokens.Typography.chipText
        case .large:
            return DesignTokens.Typography.labelMedium
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small:
            return DesignTokens.Spacing.xs
        case .medium:
            return DesignTokens.Spacing.sm
        case .large:
            return DesignTokens.Spacing.md
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small:
            return 2
        case .medium:
            return DesignTokens.Spacing.xs
        case .large:
            return DesignTokens.Spacing.sm
        }
    }
}

// MARK: - Specialized Mode Chips

/// Trading mode chip that automatically styles based on mode
struct TradingModeChip: View {
    let mode: TradingMode
    let size: ChipSize
    
    init(_ mode: TradingMode, size: ChipSize = .medium) {
        self.mode = mode
        self.size = size
    }
    
    var body: some View {
        ModeChip(mode.title, style: chipStyle, size: size)
    }
    
    private var chipStyle: ChipStyle {
        switch mode {
        case .demo:
            return .demo
        case .paper:
            return .paper
        case .live:
            return .live
        }
    }
}

/// Status chip for various states
struct StatusChip: View {
    let status: String
    let isActive: Bool
    
    init(_ status: String, isActive: Bool = false) {
        self.status = status
        self.isActive = isActive
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            if isActive {
                Circle()
                    .fill(DesignTokens.Colors.success)
                    .frame(width: 6, height: 6)
            }
            
            Text(status)
        }
        .chipStyle(color: isActive ? DesignTokens.Colors.success : DesignTokens.Colors.neutral)
    }
}

// MARK: - Preview
#Preview("Mode Chips") {
    VStack(spacing: DesignTokens.Spacing.lg) {
        // Trading mode chips
        HStack(spacing: DesignTokens.Spacing.md) {
            TradingModeChip(.demo)
            TradingModeChip(.paper)
            TradingModeChip(.live)
        }
        
        // Status chips
        HStack(spacing: DesignTokens.Spacing.md) {
            ModeChip("Active", style: .success)
            ModeChip("Paused", style: .warning)
            ModeChip("Error", style: .error)
        }
        
        // Size variants
        VStack(spacing: DesignTokens.Spacing.sm) {
            ModeChip("Small", style: .primary, size: .small)
            ModeChip("Medium", style: .primary, size: .medium)
            ModeChip("Large", style: .primary, size: .large)
        }
        
        // Status with indicator
        HStack(spacing: DesignTokens.Spacing.md) {
            StatusChip("Running", isActive: true)
            StatusChip("Stopped", isActive: false)
        }
    }
    .padding()
    .background(DesignTokens.Colors.surface)
}