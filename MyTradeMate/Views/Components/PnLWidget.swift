import SwiftUI

struct PnLWidget: View {
    let snapshot: PnLSnapshot
    let isDemoMode: Bool
    
    init(snapshot: PnLSnapshot, isDemoMode: Bool = false) {
        self.snapshot = snapshot
        self.isDemoMode = isDemoMode
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Equity: \(snapshot.equity, format: .currency(code: "USD"))")
                    .font(.headline)
                
                Spacer()
                
                if isDemoMode {
                    Text("DEMO")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Realized Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatPnL(snapshot.realizedToday))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(snapshot.realizedToday >= 0 ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Unrealized")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatPnL(snapshot.unrealized))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(snapshot.unrealized >= 0 ? .green : .red)
                }
            }
            
            if isDemoMode {
                Text("Demo mode simulating real-time PnL changes")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.3), value: snapshot.equity)
    }
    
    private func formatPnL(_ v: Double) -> String {
        let sign = v >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", v))"
    }
}
