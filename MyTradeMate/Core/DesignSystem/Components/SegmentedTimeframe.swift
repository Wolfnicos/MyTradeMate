import SwiftUI

/// Modern segmented control for timeframe selection
/// Provides smooth animations and consistent styling
struct SegmentedTimeframe: View {
    @Binding var selectedTimeframe: Timeframe
    let timeframes: [Timeframe]
    let isCompact: Bool
    
    init(
        selection: Binding<Timeframe>,
        timeframes: [Timeframe] = Timeframe.allCases,
        isCompact: Bool = false
    ) {
        self._selectedTimeframe = selection
        self.timeframes = timeframes
        self.isCompact = isCompact
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(timeframes, id: \.self) { timeframe in
                TimeframeSegment(
                    timeframe: timeframe,
                    isSelected: selectedTimeframe == timeframe,
                    isCompact: isCompact
                ) {
                    withAnimation(DesignTokens.Animation.fast) {
                        selectedTimeframe = timeframe
                    }
                }
            }
        }
        .background(DesignTokens.Colors.chipBackground)
        .cornerRadius(DesignTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(DesignTokens.Colors.border, lineWidth: 1)
        )
    }
}

/// Individual timeframe segment
private struct TimeframeSegment: View {
    let timeframe: Timeframe
    let isSelected: Bool
    let isCompact: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(timeframe.displayName)
                    .font(isCompact ? DesignTokens.Typography.labelSmall : DesignTokens.Typography.labelMedium)
                    .fontWeight(isSelected ? .semibold : .medium)
                
                if !isCompact && isSelected {
                    Rectangle()
                        .fill(DesignTokens.Colors.primary)
                        .frame(height: 2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundColor(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isCompact ? DesignTokens.Spacing.xs : DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                    .fill(isSelected ? DesignTokens.Colors.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timeframe Extensions
extension Timeframe {
    var displayName: String {
        switch self {
        case .m1: return "1M"
        case .m5: return "5M"
        case .m15: return "15M"
        case .h1: return "1H"
        case .h4: return "4H"
        }
    }
    
    var fullName: String {
        switch self {
        case .m1: return "1 Minute"
        case .m5: return "5 Minutes"
        case .m15: return "15 Minutes"
        case .h1: return "1 Hour"
        case .h4: return "4 Hours"
        }
    }
}

// MARK: - Loading State Variant
struct SegmentedTimeframeWithLoading: View {
    @Binding var selectedTimeframe: Timeframe
    let isLoading: Bool
    let timeframes: [Timeframe]
    
    init(
        selection: Binding<Timeframe>,
        isLoading: Bool = false,
        timeframes: [Timeframe] = Timeframe.allCases
    ) {
        self._selectedTimeframe = selection
        self.isLoading = isLoading
        self.timeframes = timeframes
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            SegmentedTimeframe(
                selection: $selectedTimeframe,
                timeframes: timeframes
            )
            .disabled(isLoading)
            .opacity(isLoading ? 0.6 : 1.0)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }
}

// MARK: - Preview
#Preview("Timeframe Controls") {
    VStack(spacing: DesignTokens.Spacing.xxl) {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Standard Timeframe Selector")
                .font(DesignTokens.Typography.headlineSmall)
            
            SegmentedTimeframe(
                selection: .constant(.m5)
            )
        }
        
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Compact Timeframe Selector")
                .font(DesignTokens.Typography.headlineSmall)
            
            SegmentedTimeframe(
                selection: .constant(.h1),
                isCompact: true
            )
        }
        
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("With Loading State")
                .font(DesignTokens.Typography.headlineSmall)
            
            SegmentedTimeframeWithLoading(
                selection: .constant(.h4),
                isLoading: true
            )
        }
        
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Limited Timeframes")
                .font(DesignTokens.Typography.headlineSmall)
            
            SegmentedTimeframe(
                selection: .constant(.m15),
                timeframes: [.m5, .m15, .h1]
            )
        }
    }
    .padding()
    .background(DesignTokens.Colors.surface)
}