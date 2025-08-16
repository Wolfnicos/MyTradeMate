import SwiftUI

struct TradesView: View {
    @StateObject private var vm = TradesVM()
    @EnvironmentObject private var settings: AppSettings
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search symbols...", text: $vm.searchText)
                        .textFieldStyle(.plain)
                        .onChange(of: vm.searchText) { _, newValue in
                            vm.updateSearch(newValue)
                        }
                    
                    if !vm.searchText.isEmpty {
                        Button(action: { vm.updateSearch("") }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Filter and Sort controls
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Filter")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Filter", selection: $vm.filterOption) {
                            ForEach(TradeFilterOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: vm.filterOption) { _, newValue in
                            vm.updateFilter(newValue)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sort by")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Sort", selection: $vm.sortOption) {
                            ForEach(TradeSortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: vm.sortOption) { _, newValue in
                            vm.updateSort(newValue)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if vm.isLoading {
                            loadingView
                        } else if vm.filteredTrades.isEmpty {
                            emptyStateView
                        } else {
                            tradesListView
                        }
                    }
                    .padding()
                }
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
            EmptyStateView.tradesNoData(
                title: "No Trades Yet",
                description: "Start trading to see performance here",
                useIllustration: true
            )
            
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
        ForEach(vm.filteredTrades) { trade in
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