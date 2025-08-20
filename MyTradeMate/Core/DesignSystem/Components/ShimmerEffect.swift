import SwiftUI

/// Modern shimmer loading effect for 2025 iOS design
/// Provides skeleton loading states with smooth animations
struct ShimmerEffect: View {
    @State private var isAnimating = false
    
    let gradient = LinearGradient(
        colors: [
            Color.gray.opacity(0.3),
            Color.gray.opacity(0.1),
            Color.gray.opacity(0.3)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        gradient
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .black, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(70))
                    .offset(x: isAnimating ? 300 : -300)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

/// Shimmer modifier for any view
struct Shimmer: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ShimmerEffect()
                    .blendMode(.multiply)
            )
    }
}

extension View {
    func shimmer() -> some View {
        modifier(Shimmer())
    }
}

// MARK: - Skeleton Loading Components

/// Skeleton loading for chart area
struct ChartSkeleton: View {
    let height: CGFloat
    
    init(height: CGFloat = 300) {
        self.height = height
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Chart header skeleton
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 20)
                    .cornerRadius(4)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 16)
                    .cornerRadius(4)
            }
            
            // Chart area skeleton
            VStack(spacing: DesignTokens.Spacing.xs) {
                // Simulated candlestick chart
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<20, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: CGFloat.random(in: 20...60))
                            .cornerRadius(1)
                    }
                }
                .frame(height: height - 80)
            }
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .shimmer()
    }
}

/// Skeleton loading for metric rows
struct MetricRowSkeleton: View {
    let showIcon: Bool
    
    init(showIcon: Bool = true) {
        self.showIcon = showIcon
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Icon skeleton
            if showIcon {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
            }
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 14)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 140, height: 12)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Value skeleton
            VStack(alignment: .trailing, spacing: 4) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 16)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 12)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .shimmer()
    }
}

/// Skeleton loading for cards
struct CardSkeleton: View {
    let height: CGFloat
    let showHeader: Bool
    
    init(height: CGFloat = 120, showHeader: Bool = true) {
        self.height = height
        self.showHeader = showHeader
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Header skeleton
            if showHeader {
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 18)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 16)
                        .cornerRadius(4)
                }
            }
            
            // Content skeleton
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 180, height: 14)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 220, height: 12)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 160, height: 12)
                    .cornerRadius(4)
            }
            
            Spacer()
        }
        .frame(height: height)
        .padding(DesignTokens.Spacing.lg)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(DesignTokens.Radius.lg)
        .shimmer()
    }
}

/// Loading overlay for existing content
struct LoadingOverlay: View {
    let isLoading: Bool
    
    var body: some View {
        if isLoading {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    VStack(spacing: DesignTokens.Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Loading...")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(.secondary)
                    }
                )
                .transition(.opacity)
        }
    }
}

// MARK: - Preview
#Preview("Skeleton Components") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Chart Skeleton")
                    .font(DesignTokens.Typography.headlineSmall)
                
                ChartSkeleton()
            }
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Metric Row Skeletons")
                    .font(DesignTokens.Typography.headlineSmall)
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    MetricRowSkeleton()
                    Divider()
                    MetricRowSkeleton()
                    Divider()
                    MetricRowSkeleton(showIcon: false)
                }
            }
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Card Skeletons")
                    .font(DesignTokens.Typography.headlineSmall)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: DesignTokens.Spacing.md) {
                    CardSkeleton()
                    CardSkeleton(showHeader: false)
                    CardSkeleton(height: 80)
                    CardSkeleton(height: 140)
                }
            }
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Loading Overlay")
                    .font(DesignTokens.Typography.headlineSmall)
                
                ZStack {
                    Rectangle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(height: 100)
                        .cornerRadius(DesignTokens.Radius.md)
                    
                    LoadingOverlay(isLoading: true)
                        .cornerRadius(DesignTokens.Radius.md)
                }
            }
        }
        .padding()
    }
    .background(DesignTokens.Colors.surface)
}