import SwiftUI

struct StrategiesView: View {
    @EnvironmentObject var settings: SettingsRepository
    @EnvironmentObject var strategyManager: StrategyManager
    
    var body: some View {
        NavigationStack {
            List {
                Section("Active Strategies") {
                    ForEach(strategyManager.availableStrategies, id: \.name) { strategy in
                        StrategyRow(strategy: strategy)
                    }
                }
            }
            .navigationTitle("Strategies")
        }
    }
}

struct StrategyRow: View {
    let strategy: Strategy
    @EnvironmentObject var settings: SettingsRepository
    @EnvironmentObject var strategyManager: StrategyManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(strategy.name)
                    .font(.headline)
                
                Text(strategy.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { settings.isStrategyEnabled(strategy.name) },
                set: { enabled in
                    if enabled {
                        strategyManager.enableStrategy(named: strategy.name)
                    } else {
                        strategyManager.disableStrategy(named: strategy.name)
                    }
                }
            ))
        }
        .padding(.vertical, 4)
    }
}