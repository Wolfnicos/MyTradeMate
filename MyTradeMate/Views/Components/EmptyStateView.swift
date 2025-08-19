import SwiftUI

/// A reusable empty state view component for charts and other content
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionButton: (() -> Void)?
    let actionButtonTitle: String?
    let useIllustration: Bool
    
    init(
        icon: String,
        title: String,
        description: String,
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil,
        useIllustration: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionButton = actionButton
        self.actionButtonTitle = actionButtonTitle
        self.useIllustration = useIllustration
    }
    
    var body: some View {
        if useIllustration {
            // Use the illustrated version when requested
            illustratedVersion
        } else {
            // Use the original simple version
            simpleVersion
        }
    }
    
    private var simpleVersion: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .headlineStyle()
                
                Text(description)
                    .bodyStyle()
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            if let action = actionButton, let buttonTitle = actionButtonTitle {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
    
    @ViewBuilder
    private var illustratedVersion: some View {
        // Map to appropriate illustrated empty state based on icon
        switch icon {
        case "chart.line.uptrend.xyaxis":
            IllustratedEmptyStateView.chartNoData(
                title: title,
                description: description,
                actionButton: actionButton,
                actionButtonTitle: actionButtonTitle
            )
        case "dollarsign.circle":
            IllustratedEmptyStateView.pnlNoData(
                title: title,
                description: description,
                actionButton: actionButton,
                actionButtonTitle: actionButtonTitle
            )
        case "list.bullet.rectangle":
            IllustratedEmptyStateView.tradesNoData(
                title: title,
                description: description,
                actionButton: actionButton,
                actionButtonTitle: actionButtonTitle
            )
        case "brain.head.profile":
            IllustratedEmptyStateView.strategiesNoData(
                title: title,
                description: description,
                actionButton: actionButton,
                actionButtonTitle: actionButtonTitle
            )
        case "antenna.radiowaves.left.and.right":
            IllustratedEmptyStateView.aiSignalNoData(
                title: title,
                description: description,
                actionButton: actionButton,
                actionButtonTitle: actionButtonTitle
            )
        default:
            simpleVersion
        }
    }
}

// MARK: - Convenience Initializers

extension EmptyStateView {
    /// Empty state for charts when no data is available
    static func chartNoData(
        title: String = "No Chart Data",
        description: String = "Market data is loading or unavailable",
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil,
        useIllustration: Bool = false
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: title,
            description: description,
            actionButton: actionButton,
            actionButtonTitle: actionButtonTitle,
            useIllustration: useIllustration
        )
    }
    
    /// Empty state for P&L charts when no trading data exists
    static func pnlNoData(
        title: String = "No Trading Data",
        description: String = "Start trading to see performance here",
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil,
        useIllustration: Bool = false
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "dollarsign.circle",
            title: title,
            description: description,
            actionButton: actionButton,
            actionButtonTitle: actionButtonTitle,
            useIllustration: useIllustration
        )
    }
    
    /// Empty state for trade history
    static func tradesNoData(
        title: String = "No Trades Yet",
        description: String = "Start trading to see performance here",
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil,
        useIllustration: Bool = false
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "list.bullet.rectangle",
            title: title,
            description: description,
            actionButton: actionButton,
            actionButtonTitle: actionButtonTitle,
            useIllustration: useIllustration
        )
    }
    
    /// Empty state for strategies list
    static func strategiesNoData(
        title: String = "No Strategies Available",
        description: String = "Trading strategies will appear here when loaded",
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil,
        useIllustration: Bool = false
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "brain.head.profile",
            title: title,
            description: description,
            actionButton: actionButton,
            actionButtonTitle: actionButtonTitle,
            useIllustration: useIllustration
        )
    }
    
    /// Alias for strategiesNoData for backward compatibility
    static func strategies(
        title: String = "No Strategies Available",
        description: String = "Trading strategies will appear here when loaded",
        useIllustration: Bool = false
    ) -> EmptyStateView {
        strategiesNoData(title: title, description: description, useIllustration: useIllustration)
    }
}

#Preview {
    VStack(spacing: 32) {
        EmptyStateView.chartNoData()
            .frame(height: 200)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        
        EmptyStateView.pnlNoData(
            actionButton: { print("Get started tapped") },
            actionButtonTitle: "Get Started"
        )
        .frame(height: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        
        EmptyStateView.tradesNoData()
            .frame(height: 200)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        
        EmptyStateView.strategiesNoData()
            .frame(height: 200)
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
    .padding()
}