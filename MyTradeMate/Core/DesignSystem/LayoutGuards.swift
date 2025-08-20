import SwiftUI

/// Layout guards to prevent text overlap and clipping across Dynamic Type sizes
/// Enforces consistent truncation and scaling behavior for financial data
struct LayoutGuards {
    
    // MARK: - Configuration
    
    static let defaultMinimumScaleFactor: CGFloat = 0.7
    static let defaultLineLimit: Int = 1
    static let compactMinimumScaleFactor: CGFloat = 0.6
    static let multilineLineLimit: Int = 2
    
    // MARK: - Text Scaling Guards
    
    /// Standard text scaling for financial values
    static func textScaling(
        minimumScaleFactor: CGFloat = defaultMinimumScaleFactor,
        lineLimit: Int = defaultLineLimit
    ) -> some ViewModifier {
        SafeTextScaling(
            minimumScaleFactor: minimumScaleFactor,
            lineLimit: lineLimit,
            truncationMode: .tail
        )
    }
    
    /// Compact text scaling for tight spaces (widgets, chips)
    static func compactTextScaling(
        minimumScaleFactor: CGFloat = compactMinimumScaleFactor
    ) -> some ViewModifier {
        SafeTextScaling(
            minimumScaleFactor: minimumScaleFactor,
            lineLimit: 1,
            truncationMode: .middle
        )
    }
    
    /// Multiline text scaling for descriptive content
    static func multilineTextScaling(
        lineLimit: Int = multilineLineLimit,
        minimumScaleFactor: CGFloat = defaultMinimumScaleFactor
    ) -> some ViewModifier {
        SafeTextScaling(
            minimumScaleFactor: minimumScaleFactor,
            lineLimit: lineLimit,
            truncationMode: .tail
        )
    }
    
    // MARK: - Financial Value Guards
    
    /// Guards for large financial values that might overflow
    static func moneyValueGuard() -> some ViewModifier {
        MoneyValueGuard()
    }
    
    /// Guards for percentage changes
    static func percentageGuard() -> some ViewModifier {
        PercentageGuard()
    }
    
    /// Guards for trading pair displays
    static func tradingPairGuard() -> some ViewModifier {
        TradingPairGuard()
    }
    
    // MARK: - Container Guards
    
    /// Container guard for dashboard metrics
    static func dashboardContainer() -> some ViewModifier {
        DashboardContainerGuard()
    }
    
    /// Container guard for widget content
    static func widgetContainer() -> some ViewModifier {
        WidgetContainerGuard()
    }
    
    /// Container guard for table cells
    static func tableCellContainer() -> some ViewModifier {
        TableCellGuard()
    }
}

// MARK: - Core Modifiers

/// Safe text scaling with consistent truncation behavior
private struct SafeTextScaling: ViewModifier {
    let minimumScaleFactor: CGFloat
    let lineLimit: Int
    let truncationMode: Text.TruncationMode
    
    func body(content: Content) -> some View {
        content
            .minimumScaleFactor(minimumScaleFactor)
            .lineLimit(lineLimit)
            .truncationMode(truncationMode)
            .allowsTightening(true)
    }
}

/// Money value guard with smart truncation
private struct MoneyValueGuard: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    func body(content: Content) -> some View {
        content
            .minimumScaleFactor(scaleFactor)
            .lineLimit(1)
            .truncationMode(.tail)
            .allowsTightening(true)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var scaleFactor: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large:
            return 1.0
        case .xLarge, .xxLarge:
            return 0.9
        case .xxxLarge:
            return 0.8
        default:
            return 0.7
        }
    }
}

/// Percentage change guard with color-aware truncation
private struct PercentageGuard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .minimumScaleFactor(0.8)
            .lineLimit(1)
            .truncationMode(.tail)
            .allowsTightening(true)
            .fixedSize(horizontal: true, vertical: false)
    }
}

/// Trading pair guard with intelligent splitting
private struct TradingPairGuard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .minimumScaleFactor(0.75)
            .lineLimit(1)
            .truncationMode(.middle)
            .allowsTightening(true)
    }
}

// MARK: - Container Guards

/// Dashboard container with responsive sizing
private struct DashboardContainerGuard: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(containerBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    private var horizontalPadding: CGFloat {
        switch horizontalSizeClass {
        case .compact:
            return DesignTokens.Spacing.md
        default:
            return DesignTokens.Spacing.lg
        }
    }
    
    private var verticalPadding: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large:
            return DesignTokens.Spacing.md
        case .xLarge, .xxLarge:
            return DesignTokens.Spacing.lg
        default:
            return DesignTokens.Spacing.xl
        }
    }
    
    private var cornerRadius: CGFloat {
        DesignTokens.Radius.md
    }
    
    private var containerBackground: Color {
        DesignTokens.Colors.surface
    }
}

/// Widget container with compact sizing
private struct WidgetContainerGuard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignTokens.Spacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            .minimumScaleFactor(0.6)
            .allowsTightening(true)
    }
}

/// Table cell guard with overflow protection
private struct TableCellGuard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .minimumScaleFactor(0.8)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

// MARK: - View Extensions

extension View {
    
    // MARK: - Text Scaling
    
    /// Apply safe text scaling with standard parameters
    func safeTextScaling(
        minimumScaleFactor: CGFloat = LayoutGuards.defaultMinimumScaleFactor,
        lineLimit: Int = LayoutGuards.defaultLineLimit
    ) -> some View {
        self.modifier(LayoutGuards.textScaling(
            minimumScaleFactor: minimumScaleFactor,
            lineLimit: lineLimit
        ))
    }
    
    /// Apply compact text scaling for tight spaces
    func compactTextScaling(
        minimumScaleFactor: CGFloat = LayoutGuards.compactMinimumScaleFactor
    ) -> some View {
        self.modifier(LayoutGuards.compactTextScaling(
            minimumScaleFactor: minimumScaleFactor
        ))
    }
    
    /// Apply multiline text scaling for descriptions
    func multilineTextScaling(
        lineLimit: Int = LayoutGuards.multilineLineLimit,
        minimumScaleFactor: CGFloat = LayoutGuards.defaultMinimumScaleFactor
    ) -> some View {
        self.modifier(LayoutGuards.multilineTextScaling(
            lineLimit: lineLimit,
            minimumScaleFactor: minimumScaleFactor
        ))
    }
    
    // MARK: - Financial Guards
    
    /// Apply guards for money values
    func moneyValueGuard() -> some View {
        self.modifier(LayoutGuards.moneyValueGuard())
    }
    
    /// Apply guards for percentage displays
    func percentageGuard() -> some View {
        self.modifier(LayoutGuards.percentageGuard())
    }
    
    /// Apply guards for trading pair displays
    func tradingPairGuard() -> some View {
        self.modifier(LayoutGuards.tradingPairGuard())
    }
    
    // MARK: - Container Guards
    
    /// Apply dashboard container styling with guards
    func dashboardContainer() -> some View {
        self.modifier(LayoutGuards.dashboardContainer())
    }
    
    /// Apply widget container styling with guards
    func widgetContainer() -> some View {
        self.modifier(LayoutGuards.widgetContainer())
    }
    
    /// Apply table cell styling with guards
    func tableCellContainer() -> some View {
        self.modifier(LayoutGuards.tableCellContainer())
    }
}

// MARK: - Dynamic Type Helpers

extension View {
    /// Conditionally modify based on dynamic type size
    @ViewBuilder
    func adaptForDynamicType<Content: View>(
        @ViewBuilder transform: @escaping (DynamicTypeSize) -> Content
    ) -> some View {
        self.modifier(DynamicTypeAdapter(transform: transform))
    }
}

private struct DynamicTypeAdapter<Transform: View>: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let transform: (DynamicTypeSize) -> Transform
    
    func body(content: Content) -> some View {
        content.overlay(transform(dynamicTypeSize))
    }
}

// MARK: - Preview

#if DEBUG
struct LayoutGuards_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Text scaling examples
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Scaling Examples")
                        .font(.headline)
                    
                    Text("$1,234,567,890.12")
                        .font(.title2)
                        .moneyValueGuard()
                    
                    Text("+23.45% (+$1,234.56)")
                        .font(.subheadline)
                        .percentageGuard()
                    
                    Text("BTC/USDT")
                        .font(.caption)
                        .tradingPairGuard()
                }
                .dashboardContainer()
                
                // Widget example
                VStack(spacing: 12) {
                    Text("Widget Preview")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("BTC/USD")
                                .tradingPairGuard()
                            Text("$43,256.78")
                                .moneyValueGuard()
                        }
                        
                        Spacer()
                        
                        Text("+2.34%")
                            .percentageGuard()
                    }
                    .font(.caption)
                }
                .widgetContainer()
                
                // Table cell examples
                VStack(spacing: 0) {
                    ForEach(0..<3) { _ in
                        HStack {
                            Text("BTC/USDT")
                                .tradingPairGuard()
                            
                            Spacer()
                            
                            Text("$43,256.78")
                                .moneyValueGuard()
                            
                            Text("+2.34%")
                                .percentageGuard()
                        }
                        .tableCellContainer()
                        
                        Divider()
                    }
                }
                .background(DesignTokens.Colors.surface)
                .cornerRadius(DesignTokens.Radius.md)
            }
            .padding()
        }
        .background(DesignTokens.Colors.background)
    }
}
#endif