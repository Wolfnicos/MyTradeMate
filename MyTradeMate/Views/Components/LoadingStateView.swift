import SwiftUI

// Temporary Spacing struct for this file until DesignSystem is properly imported
private struct LoadingSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

struct LoadingStateView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: LoadingSpacing.md) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text(message)
                .bodyStyle()
        }
        .padding(LoadingSpacing.lg)
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingStateView(message: "Analyzing market...")
        LoadingStateView(message: "Loading signal...")
        LoadingStateView(message: "Calculating performance...")
    }
    .padding()
}