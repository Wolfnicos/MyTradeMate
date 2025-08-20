import SwiftUI

/// A component that provides explanations for different chart types
struct ChartExplanation: View {
    let type: ChartType
    let isCompact: Bool
    
    init(type: ChartType, isCompact: Bool = false) {
        self.type = type
        self.isCompact = isCompact
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 4 : 8) {
            HStack {
                Image(systemName: type.icon)
                    .font(.system(size: isCompact ? 12 : 14))
                    .foregroundColor(.blue)
                
                Text(type.title)
                    .font(isCompact ? .caption : .caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !isCompact {
                    Text("ⓘ")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if !isCompact {
                Text(type.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, isCompact ? 8 : 12)
        .padding(.vertical, isCompact ? 4 : 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(isCompact ? 6 : 8)
    }
}

/// Chart types with their explanations
enum ChartType {
    case candlestick
    case pnl
    case price
    case volume
    
    var title: String {
        switch self {
        case .candlestick:
            return "Candlestick Chart"
        case .pnl:
            return "P&L Chart"
        case .price:
            return "Price Chart"
        case .volume:
            return "Volume Chart"
        }
    }
    
    var description: String {
        switch self {
        case .candlestick:
            return "Shows open, high, low, close prices and volume for each time period"
        case .pnl:
            return "Displays your profit and loss over time, showing account equity changes"
        case .price:
            return "Shows price movement over time with trend visualization"
        case .volume:
            return "Displays trading volume for each time period"
        }
    }
    
    var icon: String {
        switch self {
        case .candlestick:
            return "chart.bar"
        case .pnl:
            return "dollarsign.circle"
        case .price:
            return "chart.line.uptrend.xyaxis"
        case .volume:
            return "chart.bar.fill"
        }
    }
}

// MARK: - Convenience Extensions

extension ChartExplanation {
    static func candlestick(compact: Bool = false) -> ChartExplanation {
        ChartExplanation(type: .candlestick, isCompact: compact)
    }
    
    static func pnl(compact: Bool = false) -> ChartExplanation {
        ChartExplanation(type: .pnl, isCompact: compact)
    }
    
    static func price(compact: Bool = false) -> ChartExplanation {
        ChartExplanation(type: .price, isCompact: compact)
    }
    
    static func volume(compact: Bool = false) -> ChartExplanation {
        ChartExplanation(type: .volume, isCompact: compact)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ChartExplanation.candlestick()
        ChartExplanation.pnl()
        ChartExplanation.price(compact: true)
        ChartExplanation.volume(compact: true)
    }
    .padding()
}