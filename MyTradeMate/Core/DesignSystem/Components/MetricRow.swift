import SwiftUI

/// Standardized metric display component
/// Provides consistent formatting for key-value pairs throughout the app
struct MetricRow: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    let trend: MetricTrend?
    let style: MetricStyle
    let accessoryView: AnyView?
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String? = nil,
        trend: MetricTrend? = nil,
        style: MetricStyle = .default,
        accessoryView: AnyView? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.trend = trend
        self.style = style
        self.accessoryView = accessoryView
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.md) {
            // Leading icon
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.IconSize.md))
                    .foregroundColor(style.iconColor)
                    .frame(width: DesignTokens.IconSize.lg)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(style.titleFont)
                    .foregroundColor(style.titleColor)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                }
            }
            
            Spacer()
            
            // Value with trend
            HStack(alignment: .center, spacing: DesignTokens.Spacing.xs) {
                if let trend = trend {
                    MetricTrendIndicator(trend: trend)
                }
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(value)
                        .font(style.valueFont)
                        .foregroundColor(effectiveValueColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if let trend = trend, let changeText = trend.changeText {
                        Text(changeText)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(trend.color)
                    }
                }
            }
            
            // Accessory view
            if let accessoryView = accessoryView {
                accessoryView
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
    
    private var effectiveValueColor: Color {
        if let trend = trend {
            return trend.color
        }
        return style.valueColor
    }
}

/// Metric display styles
enum MetricStyle {
    case `default`
    case prominent
    case compact
    case currency
    case percentage
    
    var titleFont: Font {
        switch self {
        case .default, .currency, .percentage:
            return DesignTokens.Typography.bodyMedium
        case .prominent:
            return DesignTokens.Typography.headlineSmall
        case .compact:
            return DesignTokens.Typography.labelMedium
        }
    }
    
    var valueFont: Font {
        switch self {
        case .default:
            return DesignTokens.Typography.bodyMedium
        case .prominent:
            return DesignTokens.Typography.metric
        case .compact:
            return DesignTokens.Typography.labelMedium
        case .currency:
            return DesignTokens.Typography.price
        case .percentage:
            return DesignTokens.Typography.bodyMedium
        }
    }
    
    var titleColor: Color {
        switch self {
        case .prominent:
            return DesignTokens.Colors.textPrimary
        default:
            return DesignTokens.Colors.textSecondary
        }
    }
    
    var valueColor: Color {
        return DesignTokens.Colors.textPrimary
    }
    
    var iconColor: Color {
        return DesignTokens.Colors.textSecondary
    }
}

/// Metric trend information
struct MetricTrend {
    let direction: TrendDirection
    let changeText: String?
    
    init(direction: TrendDirection, changeText: String? = nil) {
        self.direction = direction
        self.changeText = changeText
    }
    
    var color: Color {
        return direction.color
    }
    
    var icon: String {
        return direction.icon
    }
}

/// Trend indicator component
struct MetricTrendIndicator: View {
    let trend: MetricTrend
    
    var body: some View {
        Image(systemName: trend.icon)
            .font(.system(size: DesignTokens.IconSize.xs, weight: .semibold))
            .foregroundColor(trend.color)
    }
}

// MARK: - Specialized Metric Row Variants

/// Currency metric with automatic formatting
struct CurrencyMetricRow: View {
    let title: String
    let amount: Double
    let currency: String
    let change: Double?
    let icon: String?
    
    init(
        title: String,
        amount: Double,
        currency: String = "USD",
        change: Double? = nil,
        icon: String? = nil
    ) {
        self.title = title
        self.amount = amount
        self.currency = currency
        self.change = change
        self.icon = icon
    }
    
    var body: some View {
        MetricRow(
            title: title,
            value: formattedAmount,
            icon: icon,
            trend: change.map { createTrend(from: $0) },
            style: .currency
        )
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    private func createTrend(from change: Double) -> MetricTrend {
        let direction: TrendDirection = change > 0 ? .up : (change < 0 ? .down : .neutral)
        let changeText = change > 0 ? "+\(abs(change), specifier: "%.2f")" : "\(change, specifier: "%.2f")"
        return MetricTrend(direction: direction, changeText: changeText)
    }
}

/// Percentage metric with trend
struct PercentageMetricRow: View {
    let title: String
    let percentage: Double
    let icon: String?
    
    init(title: String, percentage: Double, icon: String? = nil) {
        self.title = title
        self.percentage = percentage
        self.icon = icon
    }
    
    var body: some View {
        MetricRow(
            title: title,
            value: "\(percentage, specifier: "%.1f")%",
            icon: icon,
            trend: createTrend(),
            style: .percentage
        )
    }
    
    private func createTrend() -> MetricTrend {
        let direction: TrendDirection = percentage > 0 ? .up : (percentage < 0 ? .down : .neutral)
        return MetricTrend(direction: direction)
    }
}

// MARK: - Metric Group Component

struct MetricGroup<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(title)
                .font(DesignTokens.Typography.headlineSmall)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .padding(.horizontal, DesignTokens.Spacing.lg)
            
            VStack(spacing: 0) {
                content
            }
            .background(DesignTokens.Colors.cardBackground)
            .cornerRadius(DesignTokens.Radius.lg)
        }
    }
}

// MARK: - Preview
#Preview("Metric Rows") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            MetricGroup("Portfolio Overview") {
                CurrencyMetricRow(
                    title: "Total Balance",
                    amount: 12345.67,
                    change: 234.56,
                    icon: "dollarsign.circle"
                )
                
                Divider()
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                
                PercentageMetricRow(
                    title: "Win Rate",
                    percentage: 68.5,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                Divider()
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                
                MetricRow(
                    title: "Active Positions",
                    value: "3",
                    subtitle: "2 profitable",
                    icon: "list.bullet",
                    style: .default
                )
            }
            
            MetricGroup("Trading Performance") {
                MetricRow(
                    title: "Best Trade",
                    value: "+$1,234.56",
                    trend: MetricTrend(direction: .up, changeText: "+15.2%"),
                    style: .prominent
                )
                
                Divider()
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                
                MetricRow(
                    title: "Worst Trade",
                    value: "-$456.78",
                    trend: MetricTrend(direction: .down, changeText: "-8.1%"),
                    style: .prominent
                )
                
                Divider()
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                
                MetricRow(
                    title: "Average Trade",
                    value: "+$123.45",
                    style: .compact,
                    accessoryView: AnyView(
                        TradingModeChip(.demo, size: .small)
                    )
                )
            }
        }
        .padding()
    }
    .background(DesignTokens.Colors.surface)
}