import SwiftUI
import Charts

struct PnLDetailView: View {
    @StateObject private var vm = PnLVM()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Equity").font(.caption)
                    Text(vm.equity, format: .currency(code: "USD")).font(.title2).bold()
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Today (realized)").font(.caption)
                    Text(formatPnL(vm.today)).font(.title3).bold().foregroundStyle(vm.today >= 0 ? .green : .red)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Unrealized").font(.caption)
                Text(formatPnL(vm.unrealized))
                    .font(.headline)
                    .foregroundStyle(vm.unrealized >= 0 ? .green : .red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Chart {
                ForEach(Array(vm.history.enumerated()), id: \.offset) { _, item in
                    LineMark(x: .value("Time", item.0), y: .value("Equity", item.1))
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("PnL")
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
    
    private func formatPnL(_ v: Double) -> String {
        let sign = v >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", v))"
    }
}
