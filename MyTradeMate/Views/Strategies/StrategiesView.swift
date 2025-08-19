import SwiftUI

struct StrategiesView: View {
    @StateObject private var viewModel = ViewModelFactory.shared.makeStrategiesViewModel()
    @ObservedObject private var appSettings: AppSettings
    
    init(appSettings: AppSettings = AppSettings.shared) {
        self.appSettings = appSettings
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 16) {
                    if viewModel.strategies.isEmpty {
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
        }
        .sheet(item: Binding<StrategyInfoWrapper?>(
            get: { viewModel.selectedStrategy.map(StrategyInfoWrapper.init) },
            set: { viewModel.selectedStrategy = $0?.strategyInfo }
        )) { wrapper in
            StrategyParametersView(strategyInfo: wrapper.strategyInfo)
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
            ForEach(viewModel.strategies) { strategy in
                StrategyRowView(
                    strategy: strategy,
                    lastSignal: viewModel.lastSignals[strategy.name],
                    onToggle: {
                        if strategy.isEnabled {
                            viewModel.disableStrategy(named: strategy.name)
                        } else {
                            viewModel.enableStrategy(named: strategy.name)
                        }
                    },
                    onConfigure: {
                        viewModel.selectedStrategy = strategy
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
            
            if viewModel.isGeneratingSignals {
                LoadingStateView(message: "Generating strategy signals...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else if let ensembleSignal = viewModel.ensembleSignal {
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
    let strategy: StrategyInfo
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
    let strategyInfo: StrategyInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Strategy Information")
                            .font(.headline)
                        
                        Text(strategyInfo.description)
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
            .navigationTitle(strategyInfo.name)
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

private struct StrategyInfoWrapper: Identifiable {
    let id = UUID()
    let strategyInfo: StrategyInfo
    
    init(_ strategyInfo: StrategyInfo) {
        self.strategyInfo = strategyInfo
    }
}

// Using description from StrategySignal.Direction in Strategy.swift

#Preview {
    NavigationStack {
        StrategiesView()
            .environmentObject(AppSettings.shared)
    }
}