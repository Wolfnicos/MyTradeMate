import SwiftUI

// Import spacing constants from DesignSystem
extension CGFloat {
    static let spacingXXS: CGFloat = 2
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 20
    static let spacingXXL: CGFloat = 24
    static let spacingXXXL: CGFloat = 32
    static let spacingHuge: CGFloat = 48
}

// Temporary Spacing struct for this file until DesignSystem is properly imported
private struct Spacing {
    static let xs: CGFloat = .spacingXS
    static let sm: CGFloat = .spacingSM
    static let md: CGFloat = .spacingMD
    static let lg: CGFloat = .spacingLG
    static let xl: CGFloat = .spacingXL
    static let xxl: CGFloat = .spacingXXL
}

/// A reusable empty state view component for charts and other content
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionButton: (() -> Void)?
    let actionButtonTitle: String?
    
    init(
        icon: String,
        title: String,
        description: String,
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionButton = actionButton
        self.actionButtonTitle = actionButtonTitle
    }
    
    var body: some View {
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
}

// MARK: - Convenience Initializers

extension EmptyStateView {
    /// Empty state for charts when no data is available
    static func chartNoData(
        title: String = "No Chart Data",
        description: String = "Market data is loading or unavailable",
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: title,
            description: description,
            actionButton: actionButton,
            actionButtonTitle: actionButtonTitle
        )
    }
    
    /// Empty state for P&L charts when no trading data exists
    static func pnlNoData(
        title: String = "No Trading Data",
        description: String = "Start trading to see performance here",
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "dollarsign.circle",
            title: title,
            description: description,
            actionButton: actionButton,
            actionButtonTitle: actionButtonTitle
        )
    }
    
    /// Empty state for trade history
    static func tradesNoData(
        title: String = "No Trades Yet",
        description: String = "Start trading to see performance here",
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "list.bullet.rectangle",
            title: title,
            description: description,
            actionButton: actionButton,
            actionButtonTitle: actionButtonTitle
        )
    }
    
    /// Empty state for strategies list
    static func strategiesNoData(
        title: String = "No Strategies Available",
        description: String = "Trading strategies will appear here when loaded",
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "brain.head.profile",
            title: title,
            description: description,
            actionButton: actionButton,
            actionButtonTitle: actionButtonTitle
        )
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