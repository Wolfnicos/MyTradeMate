import SwiftUI

/// A tooltip component for displaying chart data on hover/tap
struct ChartTooltip: View {
    let data: TooltipData
    let position: CGPoint
    let isVisible: Bool
    
    var body: some View {
        if isVisible {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                ForEach(data.values, id: \.label) { value in
                    HStack {
                        Text(value.label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(value.value)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(value.color ?? .primary)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .position(x: position.x, y: position.y)
            .animation(.easeInOut(duration: 0.2), value: isVisible)
        }
    }
}

/// Data structure for tooltip content
struct TooltipData {
    let title: String
    let values: [TooltipValue]
}

struct TooltipValue {
    let label: String
    let value: String
    let color: Color?
    
    init(label: String, value: String, color: Color? = nil) {
        self.label = label
        self.value = value
        self.color = color
    }
}

// MARK: - Tooltip Extensions for Chart Data

extension TooltipData {
    /// Create tooltip data for candlestick chart
    static func candlestick(candle: Candle) -> TooltipData {
        TooltipData(
            title: "Candlestick Data",
            values: [
                TooltipValue(label: "Open", value: String(format: "%.2f", candle.open)),
                TooltipValue(label: "High", value: String(format: "%.2f", candle.high)),
                TooltipValue(label: "Low", value: String(format: "%.2f", candle.low)),
                TooltipValue(
                    label: "Close", 
                    value: String(format: "%.2f", candle.close),
                    color: candle.close >= candle.open ? .green : .red
                ),
                TooltipValue(label: "Volume", value: formatVolume(candle.volume))
            ]
        )
    }
    
    /// Create tooltip data for P&L chart
    static func pnl(equity: Double, timestamp: Date, change: Double) -> TooltipData {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        return TooltipData(
            title: "P&L Data",
            values: [
                TooltipValue(label: "Time", value: formatter.string(from: timestamp)),
                TooltipValue(label: "Equity", value: String(format: "%.2f", equity)),
                TooltipValue(
                    label: "Change", 
                    value: String(format: "%+.2f", change),
                    color: change >= 0 ? .green : .red
                ),
                TooltipValue(
                    label: "% Change", 
                    value: String(format: "%+.1f%%", (change / equity) * 100),
                    color: change >= 0 ? .green : .red
                )
            ]
        )
    }
    
    /// Create tooltip data for price chart
    static func price(price: Double, timestamp: Date, change: Double? = nil) -> TooltipData {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        var values = [
            TooltipValue(label: "Time", value: formatter.string(from: timestamp)),
            TooltipValue(label: "Price", value: String(format: "%.2f", price))
        ]
        
        if let change = change {
            values.append(TooltipValue(
                label: "Change", 
                value: String(format: "%+.2f", change),
                color: change >= 0 ? .green : .red
            ))
        }
        
        return TooltipData(
            title: "Price Data",
            values: values
        )
    }
}

// MARK: - Helper Functions

private func formatVolume(_ volume: Double) -> String {
    if volume >= 1_000_000 {
        return String(format: "%.1fM", volume / 1_000_000)
    } else if volume >= 1_000 {
        return String(format: "%.1fK", volume / 1_000)
    } else {
        return String(format: "%.0f", volume)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Rectangle()
            .fill(Color(.systemGroupedBackground))
            .frame(width: 300, height: 200)
        
        ChartTooltip(
            data: TooltipData.candlestick(
                candle: Candle(
                    openTime: Date(),
                    open: 45000,
                    high: 46000,
                    low: 44500,
                    close: 45500,
                    volume: 1250000
                )
            ),
            position: CGPoint(x: 150, y: 100),
            isVisible: true
        )
    }
}