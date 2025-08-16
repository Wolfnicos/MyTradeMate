import SwiftUI

struct StrategiesView: View {
    @StateObject private var strategyManager = StrategyManager.shared
    @EnvironmentObject private var settings: AppSettings
    @State private var selectedStrategy: (any Strategy)?
    @State private var showingParameterSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if strategyManager.strategies.isEmpty {
                        emptyStateView
                    } else {
                        strategiesListView
                        ensembleSignalView
                    }
                }
                .padding()
            }
            .navigationTitle("Strategies")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh") {
                        // Refresh strategy signals
                        Log.userAction("Strategies refreshed")
                    }
                }
            }
        }
        .sheet(item: Binding<StrategyWrapper?>(
            get: { selectedStrategy.map(StrategyWrapper.init) },
            set: { selectedStrategy = $0?.strategy }
        )) { wrapper in
            StrategyParametersView(strategy: wrapper.strategy)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            EmptyStateView.strategiesNoData(
                title: "No Strategies Available",
                description: "Trading strategies will be loaded here",
                useIllustration: true
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var strategiesListView: some View {
        VStack(spacing: 12) {
            ForEach(Array(strategyManager.strategies.enumerated()), id: \.offset) { index, strategy in
                StrategyRowView(
                    strategy: strategy,
                    lastSignal: strategyManager.lastSignals[strategy.name],
                    onToggle: {
                        if strategy.isEnabled {
                            strategyManager.disableStrategy(named: strategy.name)
                        } else {
                            strategyManager.enableStrategy(named: strategy.name)
                        }
                    },
                    onConfigure: {
                        selectedStrategy = strategy
                    }
                )
            }
        }
    }
    
    private var ensembleSignalView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ensemble Signal")
                .font(.headline)
                .fontWeight(.semibold)
            
            if strategyManager.isGeneratingSignals {
                LoadingStateView(message: "Generating strategy signals...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else if let ensembleSignal = strategyManager.ensembleSignal {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ensembleSignal.direction.description.uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(signalColor(for: ensembleSignal.direction))
                        
                        Text("\(Int(ensembleSignal.confidence * 100))% confidence")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(ensembleSignal.contributingStrategies.count) strategies")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(ensembleSignal.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(ensembleSignal.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } else {
                EmptyStateView(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "No Ensemble Signal",
                    description: "Enable strategies to generate signals",
                    useIllustration: true
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func signalColor(for direction: StrategySignal.Direction) -> Color {
        switch direction {
        case .buy: return .green
        case .sell: return .red
        case .hold: return .secondary
        }
    }
}

struct StrategyRowView: View {
    let strategy: any Strategy
    let lastSignal: StrategySignal?
    let onToggle: () -> Void
    let onConfigure: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(strategy.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    StandardToggle(
                        isOn: Binding(
                            get: { strategy.isEnabled },
                            set: { _ in onToggle() }
                        ),
                        style: strategy.isEnabled ? .success : .default,
                        size: .medium
                    )
                }
                
                Text(strategy.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let signal = lastSignal {
                    HStack {
                        Text(signal.direction.description.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(signalColor(for: signal.direction))
                        
                        Text("(\(Int(signal.confidence * 100))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Configure") {
                            onConfigure()
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(strategy.isEnabled ? 1.0 : 0.6)
    }
    
    private func signalColor(for direction: StrategySignal.Direction) -> Color {
        switch direction {
        case .buy: return .green
        case .sell: return .red
        case .hold: return .secondary
        }
    }
}

struct StrategyParametersView: View {
    let strategy: any Strategy
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Strategy Information")
                            .font(.headline)
                        
                        Text(strategy.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Parameters")
                            .font(.headline)
                        
                        Text("Parameter configuration will be available in a future update")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(strategy.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Types

private struct StrategyWrapper: Identifiable {
    let id = UUID()
    let strategy: any Strategy
}

extension StrategySignal.Direction {
    var description: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        case .hold: return "Hold"
        }
    }
}

#Preview {
    NavigationStack {
        StrategiesView()
            .environmentObject(AppSettings.shared)
    }
}