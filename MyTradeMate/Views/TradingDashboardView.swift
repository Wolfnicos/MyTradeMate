import SwiftUI

struct TradingDashboardView: View {
    @StateObject private var vm = TradingDashboardViewModel()
    var body: some View {
        List {
            Section("Positions") {
                ForEach(vm.positions, id: \.id) { p in
                    HStack {
                        Text(p.symbol).bold()
                        Spacer()
                        Text(String(format: "%.4f", p.qty))
                        Text("@ \(String(format: "%.2f", p.avgPrice))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            Section("Actions") {
                Button("Refresh Tickers") { Task { await vm.refreshTickers() } }
            }
        }
        .navigationTitle("Dashboard")
        .task { await vm.refreshTickers() }
    }
}
