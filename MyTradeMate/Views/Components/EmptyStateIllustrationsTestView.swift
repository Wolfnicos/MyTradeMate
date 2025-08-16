import SwiftUI

/// A test view to verify that empty state illustrations are working correctly
struct EmptyStateIllustrationsTestView: View {
    @State private var selectedIllustration = 0
    
    private let illustrations = [
        ("Chart", "chart.line.uptrend.xyaxis"),
        ("P&L", "dollarsign.circle"),
        ("Trades", "list.bullet.rectangle"),
        ("Strategies", "brain.head.profile"),
        ("AI Signal", "antenna.radiowaves.left.and.right")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Picker to switch between illustrations
                Picker("Illustration Type", selection: $selectedIllustration) {
                    ForEach(0..<illustrations.count, id: \.self) { index in
                        Text(illustrations[index].0).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Display the selected illustration
                Group {
                    switch selectedIllustration {
                    case 0:
                        EmptyStateView.chartNoData(
                            title: "No Chart Data",
                            description: "Market data is loading or temporarily unavailable. Check your connection and try again.",
                            useIllustration: true
                        )
                    case 1:
                        EmptyStateView.pnlNoData(
                            title: "No Trading Data",
                            description: "Start trading to see your performance metrics and profit & loss charts here.",
                            actionButton: { print("Start Trading tapped") },
                            actionButtonTitle: "Start Trading",
                            useIllustration: true
                        )
                    case 2:
                        EmptyStateView.tradesNoData(
                            title: "No Trades Yet",
                            description: "Your trading history will appear here once you start placing orders.",
                            useIllustration: true
                        )
                    case 3:
                        EmptyStateView.strategiesNoData(
                            title: "No Strategies Available",
                            description: "AI trading strategies will appear here when they're loaded and ready to use.",
                            useIllustration: true
                        )
                    case 4:
                        EmptyStateView(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "No Signal Available",
                            description: "The AI is analyzing market conditions. No clear trading signal at the moment.",
                            useIllustration: true
                        )
                    default:
                        EmptyView()
                    }
                }
                .frame(height: 300)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Information about the current illustration
                VStack(spacing: 8) {
                    Text("Current: \(illustrations[selectedIllustration].0)")
                        .font(.headline)
                    
                    Text("Icon: \(illustrations[selectedIllustration].1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Features: Animated illustration, dark mode support, screen size optimization")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            .navigationTitle("Empty State Illustrations")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    EmptyStateIllustrationsTestView()
}