import SwiftUI

struct PnLWidget: View {
    let snapshot: PnLSnapshot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Equity: \(snapshot.equity, format: .currency(code: "USD"))")
                .font(.headline)
            HStack {
                Text("Realized (Today): \(formatPnL(snapshot.realizedToday))")
                Spacer()
                Text("Unrealized: \(formatPnL(snapshot.unrealized))")
            }
            .font(.subheadline)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatPnL(_ v: Double) -> String {
        let sign = v >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", v))"
    }
}
