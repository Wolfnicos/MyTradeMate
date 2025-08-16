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
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Strategies Available")
                    .headlineStyle()
                
                Text("Trading strategies will appear here when loaded")
                    .bodyStyle()
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No Strategies Available. Trading strategies will appear here when loaded")
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
        Group {
            if let ensembleSignal = strategyManager.ensembleSignal {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ensemble Signal")
                        .headlineStyle()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ensembleSignal.direction.description.uppercased())
                                .title2Style()
                                .foregroundColor(signalColor(for: ensembleSignal.direction))
                            
                            Text("\(Int(ensembleSignal.confidence * 100))% confidence")
                                .subheadlineStyle()
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(ensembleSignal.contributingStrategies.count) strategies")
                                .caption1Style()
                            
                            Text(ensembleSignal.timestamp.formatted(date: .omitted, time: .shortened))
                                .caption1Style()
                        }
                    }
                    
                    Text(ensembleSignal.reason)
                        .caption1Style()
                        .padding(.top, 4)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
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
                        .headlineStyle()
                    
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
                    .caption1Style()
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