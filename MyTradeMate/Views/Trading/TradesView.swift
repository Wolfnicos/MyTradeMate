import SwiftUI

struct TradesView: View {
    @StateObject private var viewModel = ViewModelFactory.shared.makeTradesViewModel()
    @ObservedObject private var appSettings: AppSettings
    
    init(appSettings: AppSettings = AppSettings.shared) {
        self.appSettings = appSettings
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search symbols...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .onChange(of: viewModel.searchText) { _, newValue in
                            viewModel.updateSearch(newValue)
                        }
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.updateSearch("") }) {
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
                        
                        Picker("Filter", selection: $viewModel.filterOption) {
                            ForEach(TradeFilterOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: viewModel.filterOption) { _, newValue in
                            viewModel.updateFilter(newValue)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sort by")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Sort", selection: $viewModel.sortOption) {
                            ForEach(TradeSortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: viewModel.sortOption) { _, newValue in
                            viewModel.updateSort(newValue)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.isLoading {
                            loadingView
                        } else if viewModel.filteredTrades.isEmpty {
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
                            await viewModel.refreshTrades()
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refreshTrades()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadTrades()
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
            
            if appSettings.demoMode {
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
        ForEach(viewModel.filteredTrades) { trade in
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

#Preview {
    NavigationStack {
        TradesView()
            .environmentObject(AppSettings.shared)
    }
}