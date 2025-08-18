import SwiftUI

struct PnLSnapshot {
    let equity: Double
    let realizedToday: Double
    let unrealized: Double
    let totalPnL: Double
    let totalPnLPercent: Double
    let timestamp: Date
    
    init(equity: Double, realizedToday: Double, unrealized: Double) {
        self.equity = equity
        self.realizedToday = realizedToday
        self.unrealized = unrealized
        self.totalPnL = realizedToday + unrealized
        self.totalPnLPercent = equity > 0 ? (totalPnL / equity) * 100 : 0
        self.timestamp = Date()
    }
}

struct PnLWidget: View {
    let snapshot: PnLSnapshot
    let isDemoMode: Bool
    
    private let spacing: CGFloat = 12
    private let cardPadding: CGFloat = 16
    private let cornerRadius: CGFloat = 12
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio P&L")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if isDemoMode {
                        Text("DEMO MODE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                Text(snapshot.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Main metrics
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                PnLMetricCard(
                    title: "Total Equity",
                    value: String(format: "$%.2f", snapshot.equity),
                    change: nil,
                    changeColor: .primary
                )
                
                PnLMetricCard(
                    title: "Today's P&L",
                    value: String(format: "$%.2f", snapshot.realizedToday),
                    change: snapshot.realizedToday,
                    changeColor: snapshot.realizedToday >= 0 ? .green : .red
                )
                
                PnLMetricCard(
                    title: "Unrealized P&L",
                    value: String(format: "$%.2f", snapshot.unrealized),
                    change: snapshot.unrealized,
                    changeColor: snapshot.unrealized >= 0 ? .green : .red
                )
                
                PnLMetricCard(
                    title: "Total P&L",
                    value: String(format: "$%.2f", snapshot.totalPnL),
                    change: snapshot.totalPnL,
                    changeColor: snapshot.totalPnL >= 0 ? .green : .red,
                    showPercent: true,
                    percentValue: snapshot.totalPnLPercent
                )
            }
        }
        .padding(cardPadding)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(cornerRadius)
    }
}

struct PnLMetricCard: View {
    let title: String
    let value: String
    let change: Double?
    let changeColor: Color
    let showPercent: Bool
    let percentValue: Double?
    
    init(title: String, value: String, change: Double?, changeColor: Color, showPercent: Bool = false, percentValue: Double? = nil) {
        self.title = title
        self.value = value
        self.change = change
        self.changeColor = changeColor
        self.showPercent = showPercent
        self.percentValue = percentValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(changeColor)
            
            if let change = change {
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                        .foregroundColor(changeColor)
                    
                    if showPercent, let percent = percentValue {
                        Text(String(format: "%.2f%%", percent))
                            .font(.caption2)
                            .foregroundColor(changeColor)
                    } else {
                        Text(abs(change), format: .currency(code: "USD"))
                            .font(.caption2)
                            .foregroundColor(changeColor)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(6)
    }
}

#Preview {
    VStack(spacing: 16) {
        PnLWidget(
            snapshot: PnLSnapshot(
                equity: 10250.75,
                realizedToday: 125.50,
                unrealized: -45.20
            ),
            isDemoMode: false
        )
        
        PnLWidget(
            snapshot: PnLSnapshot(
                equity: 9875.30,
                realizedToday: -124.70,
                unrealized: 89.15
            ),
            isDemoMode: true
        )
    }
    .padding()
}