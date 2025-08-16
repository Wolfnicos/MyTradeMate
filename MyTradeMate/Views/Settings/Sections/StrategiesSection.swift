import SwiftUI

struct StrategiesSection: View {
    @StateObject private var strategyStore = StrategyStore.shared
    
    var body: some View {
        Section {
            ForEach(strategyStore.strategies) { strategy in
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        StandardToggleRow(
                            title: strategy.kind.rawValue,
                            description: "Enable this AI trading strategy. Parameters can be adjusted when enabled.",
                            isOn: Binding(
                                get: { strategy.enabled },
                                set: { newValue in
                                    if let index = strategyStore.strategies.firstIndex(where: { $0.id == strategy.id }) {
                                        strategyStore.strategies[index].enabled = newValue
                                    }
                                }
                            ),
                            style: strategy.enabled ? .success : .default,
                            showDivider: false
                        )

                    }
                    
                    if strategy.enabled {
                        ForEach(Array(strategy.params.keys.sorted()), id: \.self) { key in
                            if let value = strategy.params[key] {
                                HStack {
                                    Text(key.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Stepper(
                                        value: Binding(
                                            get: { value },
                                            set: { newValue in
                                                if let index = strategyStore.strategies.firstIndex(where: { $0.id == strategy.id }) {
                                                    strategyStore.strategies[index].params[key] = newValue
                                                }
                                            }
                                        ),
                                        in: 1...100,
                                        step: key.contains("mult") || key.contains("z") ? 0.1 : 1
                                    ) {
                                        Text("\(value, specifier: key.contains("mult") || key.contains("z") ? "%.1f" : "%.0f")")
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}