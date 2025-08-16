import SwiftUI

/// A reusable chart legend component that explains chart meanings
struct ChartLegend: View {
    let items: [LegendItem]
    let title: String?
    
    init(items: [LegendItem], title: String? = nil) {
        self.items = items
        self.title = title
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], alignment: .leading, spacing: 8) {
                ForEach(items, id: \.id) { item in
                    HStack(spacing: 6) {
                        // Legend indicator
                        Group {
                            if let color = item.color {
                                Circle()
                                    .fill(color)
                                    .frame(width: 8, height: 8)
                            } else if let systemImage = item.systemImage {
                                Image(systemName: systemImage)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(item.label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

/// Legend item data structure
struct LegendItem {
    let id = UUID()
    let label: String
    let color: Color?
    let systemImage: String?
    
    init(label: String, color: Color) {
        self.label = label
        self.color = color
        self.systemImage = nil
    }
    
    init(label: String, systemImage: String) {
        self.label = label
        self.color = nil
        self.systemImage = systemImage
    }
}

// MARK: - Predefined Legend Sets

extension ChartLegend {
    /// Legend for candlestick charts
    static func candlestickLegend() -> ChartLegend {
        ChartLegend(
            items: [
                LegendItem(label: "Bullish Candle", color: .green),
                LegendItem(label: "Bearish Candle", color: .red),
                LegendItem(label: "Volume", color: .blue.opacity(0.6)),
                LegendItem(label: "Price Range", systemImage: "arrow.up.arrow.down")
            ],
            title: "Chart Legend"
        )
    }
    
    /// Legend for P&L charts
    static func pnlLegend() -> ChartLegend {
        ChartLegend(
            items: [
                LegendItem(label: "Profit", color: .green),
                LegendItem(label: "Loss", color: .red),
                LegendItem(label: "Equity Over Time", systemImage: "chart.line.uptrend.xyaxis"),
                LegendItem(label: "Break Even", color: .secondary)
            ],
            title: "Profit & Loss Chart"
        )
    }
    
    /// Legend for price charts
    static func priceLegend() -> ChartLegend {
        ChartLegend(
            items: [
                LegendItem(label: "Price Movement", color: .blue),
                LegendItem(label: "Current Price", systemImage: "circle.fill"),
                LegendItem(label: "Time Period", systemImage: "clock"),
                LegendItem(label: "Price Trend", systemImage: "arrow.up.right")
            ],
            title: "Price Chart"
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ChartLegend.candlestickLegend()
        ChartLegend.pnlLegend()
        ChartLegend.priceLegend()
    }
    .padding()
}