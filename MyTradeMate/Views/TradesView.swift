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
                await vm.refreshTrades()
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
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Trades Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Your trading history will appear here")
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
                    Text("Qty: \(trade.qty, specifier: "%.4f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("$\(trade.price, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text(trade.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(trade.pnl >= 0 ? "+" : "")\(trade.pnl, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(trade.pnl >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Mock Trade Model

// Using Trade from Core/TradeStore.swift

#Preview {
    NavigationStack {
        TradesView()
            .environmentObject(AppSettings.shared)
    }
}