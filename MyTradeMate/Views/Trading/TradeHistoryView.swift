import SwiftUI

struct TradeHistoryView: View {
    @StateObject private var vm = TradeHistoryVM()
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var isExporting = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var exportRange: ExportRange = .all
    @State private var selectedSymbol: String = "All"
    @State private var availableSymbols: [String] = ["All"]
    
    enum ExportRange: String, CaseIterable, Identifiable {
        case all = "All", today = "Today", week = "7 Days", month = "30 Days"
        var id: String { rawValue }
    }
    
    var body: some View {
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
                
                // Export controls (condensed)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Export")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Picker("Range", selection: $exportRange) {
                            ForEach(ExportRange.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 100)
                        
                        Picker("Symbol", selection: $selectedSymbol) {
                            ForEach(availableSymbols, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 100)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            List {
                if vm.fills.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("No Trade History")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text("Start trading to see performance here")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(vm.fills) { fill in
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                // Side indicator with icon
                                HStack(spacing: 6) {
                                    Image(systemName: fill.side == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                        .foregroundColor(fill.side == .buy ? .green : .red)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text(fill.side == .buy ? "BUY" : "SELL")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(fill.side == .buy ? .green : .red)
                                }
                                .frame(width: 70, alignment: .leading)
                                
                                // Symbol
                                Text(fill.pair.symbol)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Price and quantity info
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(String(format: "%.2f", fill.quantity))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text("@ \(String(format: "%.2f", fill.price))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Second row with timestamp and total value
                            HStack {
                                Text(fill.timestamp.tradeDateString)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Text(fill.timestamp.tradeTimeString)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("Total: \(String(format: "%.2f", fill.quantity * fill.price))")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .onAppear { vm.loadMoreIfNeeded(current: fill) }
                    }
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Export CSV") {
                        exportCSV()
                    }
                    Button("Export Daily PnL CSV") {
                        exportDailyPnL()
                    }
                    Button("Export PnL Metrics CSV") {
                        exportPnLMetrics()
                    }
                    Button("Export JSON") {
                        exportJSON()
                    }
                } label: {
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Export Failed", isPresented: $showError, actions: {}) {
            Text(errorMessage ?? "Unknown error")
        }
        .onAppear {
            vm.onAppear()
            Task {
                let fills = await TradeManager.shared.fillsSnapshot()
                await MainActor.run { availableSymbols = symbolsFromFills(fills) }
            }
        }
    }
    
    private func symbolsFromFills(_ fills: [OrderFill]) -> [String] {
        let syms = Set(fills.map { $0.pair.symbol })
        return ["All"] + syms.sorted()
    }
    
    private func rangeDates(_ r: ExportRange) -> (Date?, Date?) {
        let cal = Calendar.current
        let now = Date()
        switch r {
        case .all: return (nil, nil)
        case .today:
            let start = cal.startOfDay(for: now)
            return (start, now)
        case .week:
            return (cal.date(byAdding: .day, value: -7, to: now), now)
        case .month:
            return (cal.date(byAdding: .day, value: -30, to: now), now)
        }
    }
    
    private func filterFills(_ fills: [OrderFill]) -> [OrderFill] {
        let (from, to) = rangeDates(exportRange)
        return fills.filter { f in
            if let from = from, f.timestamp < from { return false }
            if let to = to, f.timestamp > to { return false }
            if selectedSymbol != "All" && f.pair.symbol != selectedSymbol { return false }
            return true
        }
    }
    
    private func exportCSV() {
        Task { @MainActor in
            isExporting = true
            defer { isExporting = false }
            
            do {
                let fills = await TradeManager.shared.fillsSnapshot()
                let filtered = filterFills(fills)
                let url = try await CSVExporter.exportFills(filtered, fileName: "trades")
                shareURL = url
                showShare = true
                await Haptics.success()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                await Haptics.error()
            }
        }
    }
    
    private func exportDailyPnL() {
        Task { @MainActor in
            isExporting = true
            defer { isExporting = false }
            
            do {
                let fills = await TradeManager.shared.fillsSnapshot()
                let filtered = filterFills(fills)
                let rows = PnLAggregator.aggregateDaily(fills: filtered)
                let url = try PnLCSVExporter.exportDaily(rows)
                shareURL = url
                showShare = true
                await Haptics.success()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                await Haptics.error()
            }
        }
    }
    
    private func exportPnLMetrics() {
        Task { @MainActor in
            isExporting = true
            defer { isExporting = false }
            
            do {
                let fills = await TradeManager.shared.fillsSnapshot()
                let filtered = filterFills(fills)
                let metrics = PnLMetricsAggregator.compute(from: filtered)
                let url = try PnLMetricsCSVExporter.export(metrics)
                shareURL = url
                showShare = true
                await Haptics.success()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                await Haptics.error()
            }
        }
    }
    
    private func exportJSON() {
        Task { @MainActor in
            isExporting = true
            defer { isExporting = false }
            
            do {
                let fills = await TradeManager.shared.fillsSnapshot()
                let filtered = filterFills(fills)
                let url = try await JSONExporter.exportFills(filtered, fileName: "trades")
                shareURL = url
                showShare = true
                await Haptics.success()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                await Haptics.error()
            }
        }
    }
}