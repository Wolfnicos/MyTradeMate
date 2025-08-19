import SwiftUI

struct TradesView: View {
    @StateObject private var viewModel = TradesVM()
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.trades.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No Trades Yet",
                        description: "Your trading history will appear here once you start trading.",
                        useIllustration: true
                    )
                } else {
                    List {
                        ForEach(viewModel.trades, id: \.id) { trade in
                            TradeRowView(trade: trade)
                        }
                    }
                }
            }
            .navigationTitle("Trades")
            .refreshable {
                await viewModel.loadTrades()
            }
        }
    }
}

struct TradeRowView: View {
    let trade: TradeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trade.symbol)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(trade.side.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trade.side == .buy ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(trade.side == .buy ? .green : .red)
                    .cornerRadius(4)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quantity: \(String(format: "%.4f", trade.qty))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Price: $\(String(format: "%.2f", trade.price))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("P&L: $\(String(format: "%.2f", trade.pnl))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(trade.pnl >= 0 ? .green : .red)
                    
                    Text(trade.date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
