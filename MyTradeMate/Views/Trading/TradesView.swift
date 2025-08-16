import SwiftUI

struct TradesView: View {
    @StateObject private var vm = TradesVM()
    @EnvironmentObject private var settings: AppSettings
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if vm.isLoading {
                        loadingView
                    } else if vm.trades.isEmpty {
                        emptyStateView
                    } else {
                        tradesListView
                    }
                }
                .padding()
            }
            .navigationTitle("Trades")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await vm.refreshTrades()
                        }
                    }
                }
            }
            .refreshable {
                await vm.refreshTrades()
            }
        }
        .onAppear {
            Task {
                await vm.loadTrades()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading trades...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Trades Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start trading to see performance here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if settings.demoMode {
                Text("Currently in demo mode")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var tradesListView: some View {
        ForEach(vm.trades) { trade in
            TradeRowView(trade: trade)
        }
    }
}

struct TradeRowView: View {
    let trade: Trade
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(trade.symbol)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(trade.side.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(trade.side == .buy ? .green : .red)
                        .cornerRadius(4)
                }
                
                HStack {
                    Text("Qty: \(trade.quantity, specifier: "%.4f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("$\(trade.price, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text(trade.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let pnl = trade.pnl {
                        Text("\(pnl >= 0 ? "+" : "")\(pnl, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(pnl >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Mock Trade Model

struct Trade: Identifiable {
    let id = UUID()
    let symbol: String
    let side: OrderSide
    let quantity: Double
    let price: Double
    let timestamp: Date
    let pnl: Double?
}

#Preview {
    NavigationStack {
        TradesView()
            .environmentObject(AppSettings.shared)
    }
}