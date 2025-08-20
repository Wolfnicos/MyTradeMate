import SwiftUI

/// Modern card component following 2025 design standards
/// Provides consistent styling for content containers across the app
struct Card<Content: View>: View {
    let content: Content
    let style: CardStyle
    let elevation: DesignTokens.Elevation.ShadowStyle
    
    init(
        style: CardStyle = .default,
        elevation: DesignTokens.Elevation.ShadowStyle = .sm,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.elevation = elevation
    }
    
    var body: some View {
        content
            .padding(DesignTokens.Spacing.cardPadding)
            .background(style.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .cornerRadius(DesignTokens.Radius.lg)
            .designTokenShadow(elevation)
    }
}

/// Card styling variants
enum CardStyle {
    case `default`
    case elevated
    case outlined
    case filled(Color)
    
    var backgroundColor: Color {
        switch self {
        case .default:
            return DesignTokens.Colors.cardBackground
        case .elevated:
            return DesignTokens.Colors.surfaceElevated
        case .outlined:
            return DesignTokens.Colors.surface
        case .filled(let color):
            return color.opacity(0.1)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .default, .elevated, .filled:
            return .clear
        case .outlined:
            return DesignTokens.Colors.border
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .default, .elevated, .filled:
            return 0
        case .outlined:
            return 1
        }
    }
}

// MARK: - Specialized Card Variants

/// Metric display card with title and value
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let trend: TrendDirection?
    let icon: String?
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        trend: TrendDirection? = nil,
        icon: String? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.trend = trend
        self.icon = icon
    }
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Header with icon and title
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: DesignTokens.IconSize.md))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    Text(title)
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                    
                    if let trend = trend {
                        TrendIndicator(direction: trend)
                    }
                }
                
                // Value
                Text(value)
                    .font(DesignTokens.Typography.metric)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                // Subtitle
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                }
            }
        }
    }
}

/// Trend direction for metrics
enum TrendDirection {
    case up
    case down
    case neutral
    
    var color: Color {
        switch self {
        case .up: return DesignTokens.Colors.gain
        case .down: return DesignTokens.Colors.loss
        case .neutral: return DesignTokens.Colors.neutral
        }
    }
    
    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .neutral: return "minus"
        }
    }
}

/// Small trend indicator component
struct TrendIndicator: View {
    let direction: TrendDirection
    
    var body: some View {
        Image(systemName: direction.icon)
            .font(.system(size: DesignTokens.IconSize.xs, weight: .medium))
            .foregroundColor(direction.color)
    }
}

// MARK: - Preview
#Preview("Cards") {
    VStack(spacing: DesignTokens.Spacing.lg) {
        Card {
            VStack(alignment: .leading) {
                Text("Basic Card")
                    .font(DesignTokens.Typography.headlineSmall)
                Text("This is a standard card with default styling")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        
        Card(style: .outlined) {
            Text("Outlined Card")
                .font(DesignTokens.Typography.headlineSmall)
        }
        
        Card(style: .filled(DesignTokens.Colors.gain)) {
            Text("Filled Card")
                .font(DesignTokens.Typography.headlineSmall)
        }
        
        MetricCard(
            title: "Portfolio Value",
            value: "$12,345.67",
            subtitle: "+2.5% today",
            trend: .up,
            icon: "dollarsign.circle"
        )
    }
    .padding()
    .background(DesignTokens.Colors.surface)
}