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
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(settings.demoMode ? .orange : .green)
                            .frame(width: 6, height: 6)
                        
                        Text(settings.demoMode ? "DEMO" : "LIVE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(settings.demoMode ? .orange : .green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((settings.demoMode ? Color.orange : Color.green).opacity(0.15))
                    )
                }
                
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
            
            // Enhanced trading mode indicator
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(settings.demoMode ? .orange : .green)
                        .frame(width: 8, height: 8)
                    
                    Text(settings.demoMode ? "Demo Mode Active" : "Live Trading Mode")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(settings.demoMode ? .orange : .green)
                }
                
                Text(settings.demoMode ? "Trades will be simulated" : "Real trades with actual funds")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill((settings.demoMode ? Color.orange : Color.green).opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(settings.demoMode ? .orange : .green, lineWidth: 1)
                    )
            )
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
    @EnvironmentObject private var settings: AppSettings
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(trade.symbol)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        // Trading mode indicator for individual trades
                        Text(settings.demoMode ? "DEMO" : "LIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(settings.demoMode ? .orange : .green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill((settings.demoMode ? Color.orange : Color.green).opacity(0.15))
                            )
                        
                        Text(trade.side.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(trade.side == .buy ? .green : .red)
                            .cornerRadius(4)
                    }
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(settings.demoMode ? .orange.opacity(0.3) : .clear, lineWidth: 1)
        )
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