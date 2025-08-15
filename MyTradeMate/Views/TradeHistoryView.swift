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
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Export range")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $exportRange) {
                        ForEach(ExportRange.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                
                Spacer(minLength: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Symbol")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $selectedSymbol) {
                        ForEach(availableSymbols, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 160)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            List {
                ForEach(vm.fills) { fill in
                    HStack {
                        Text(fill.symbol.display).font(.headline)
                        Spacer()
                        Text(fill.side == .buy ? "BUY" : "SELL")
                            .foregroundStyle(fill.side == .buy ? .green : .red)
                        Text(String(format: "@ %.2f", fill.price))
                            .foregroundStyle(.secondary)
                    }
                    .onAppear { vm.loadMoreIfNeeded(current: fill) }
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
                    } else {
                        Image(systemName: "square.and.arrow.up")
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
        let syms = Set(fills.map { $0.symbol.raw })
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
            if selectedSymbol != "All" && f.symbol.raw != selectedSymbol { return false }
            return true
        }
    }
    
    private func exportCSV() {
        Task { @MainActor in
            isExporting = true
            let fills = await TradeManager.shared.fillsSnapshot()
            let filtered = filterFills(fills)
            do {
                let url = try await CSVExporter.exportFills(filtered, fileName: "trades")
                shareURL = url
                showShare = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isExporting = false
        }
    }
    
    private func exportDailyPnL() {
        isExporting = true
        BackgroundExporter.runAsync(work: {
            let all = await TradeManager.shared.fillsSnapshot()
            let filtered = filterFills(all)
            let rows = PnLAggregator.aggregateDaily(fills: filtered)
            return try PnLCSVExporter.exportDaily(rows)
        }, completion: { result in
            isExporting = false
            switch result {
            case .success(let url):
                shareURL = url
                showShare = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .failure(let err):
                errorMessage = err.localizedDescription
                showError = true
            }
        })
    }
    
    private func exportPnLMetrics() {
        isExporting = true
        BackgroundExporter.runAsync(work: {
            let all = await TradeManager.shared.fillsSnapshot()
            let filtered = filterFills(all)
            let metrics = PnLMetricsAggregator.compute(from: filtered)
            return try PnLMetricsCSVExporter.export(metrics)
        }, completion: { result in
            isExporting = false
            switch result {
            case .success(let url):
                shareURL = url
                showShare = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .failure(let err):
                errorMessage = err.localizedDescription
                showError = true
            }
        })
    }
    
    private func exportJSON() {
        isExporting = true
        BackgroundExporter.runAsync(work: {
            let all = await TradeManager.shared.fillsSnapshot()
            let filtered = filterFills(all)
            return try JSONExporter.export(filtered, fileName: "trades")
        }, completion: { result in
            isExporting = false
            switch result {
            case .success(let url):
                shareURL = url
                showShare = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .failure(let err):
                errorMessage = err.localizedDescription
                showError = true
            }
        })
    }
}