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
                VStack(alignment: .leading, spacing: 2) {
                    Text("Equity: \(snapshot.equity, format: .currency(code: "USD"))")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("Total account value")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
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
            .padding(.horizontal)
            .padding(.top, 8)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Realized Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(snapshot.realizedToday, format: .currency(code: "USD"))
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(snapshot.realizedToday >= 0 ? .green : .red)
                    Text("Closed positions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unrealized")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(snapshot.unrealized, format: .currency(code: "USD"))
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(snapshot.unrealized >= 0 ? .green : .red)
                    Text("Open positions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Updated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(snapshot.ts, style: .time)
                        .font(.subheadline.monospacedDigit())
                    Text("Live data")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        // Use safeAreaInset to ensure proper spacing
        .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
    }
}

#Preview {
    PnLWidget(snapshot: PnLSnapshot(
        equity: 10500.0,
        realizedToday: 250.0,
        unrealized: 500.0,
        ts: Date()
    ), isDemoMode: true)
    .padding()
    .background(Color(.systemGroupedBackground))
}