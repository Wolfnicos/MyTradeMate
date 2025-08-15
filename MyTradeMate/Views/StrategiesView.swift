import SwiftUI

struct StrategiesView: View {
    @StateObject private var vm = StrategiesVM()
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                masterToggleSection
                strategiesSection
                regimeSection
            }
            .padding()
        }
        .background(Bg.primary)
        .navigationTitle("Strategies")
        .onAppear {
            vm.loadStrategies()
        }
    }
    
    // MARK: - Master Toggle
    private var masterToggleSection: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Brain (Auto)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(TextColor.primary)
                    
                    Text("Ensemble strategy engine")
                        .font(.system(size: 13))
                        .foregroundColor(TextColor.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.autoTrading)
                    .labelsHidden()
                    .tint(Accent.green)
            }
        }
    }
    
    // MARK: - Strategies Section
    private var strategiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Strategies")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(TextColor.primary)
                .padding(.horizontal)
            
            ForEach(vm.strategies) { strategy in
                StrategyCard(strategy: strategy, vm: vm)
            }
        }
    }
    
    // MARK: - Regime Section
    private var regimeSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Market Regime")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(TextColor.primary)
                    
                    Spacer()
                    
                    Pill(
                        text: vm.currentRegime,
                        color: vm.regimeColor
                    )
                }
                
                Text("The regime detector analyzes volatility and trend to select optimal strategies")
                    .font(.system(size: 13))
                    .foregroundColor(TextColor.secondary)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Strategies")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(TextColor.primary)
                    
                    HStack(spacing: 8) {
                        ForEach(vm.recommendedStrategies, id: \.self) { name in
                            Pill(text: name, color: Brand.blue.opacity(0.8))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Strategy Card
struct StrategyCard: View {
    let strategy: StrategyInfo
    @ObservedObject var vm: StrategiesVM
    @State private var isExpanded = false
    
    var body: some View {
        Card {
            VStack(spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(strategy.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(TextColor.primary)
                        
                        Text(strategy.description)
                            .font(.system(size: 12))
                            .foregroundColor(TextColor.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { strategy.isEnabled },
                        set: { vm.toggleStrategy(strategy.id, enabled: $0) }
                    ))
                    .labelsHidden()
                    .tint(Accent.green)
                }
                
                // Expand/Collapse button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("Parameters")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Brand.blue)
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(Brand.blue)
                    }
                }
                
                // Parameters (when expanded)
                if isExpanded {
                    Divider()
                    
                    ForEach(strategy.parameters) { param in
                        ParameterRow(
                            parameter: param,
                            onUpdate: { value in
                                vm.updateParameter(
                                    strategyId: strategy.id,
                                    paramId: param.id,
                                    value: value
                                )
                            }
                        )
                    }
                    
                    // Weight slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight: \(String(format: "%.1f", strategy.weight))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(TextColor.primary)
                        
                        Slider(
                            value: Binding(
                                get: { strategy.weight },
                                set: { vm.updateWeight(strategy.id, weight: $0) }
                            ),
                            in: 0...2,
                            step: 0.1
                        )
                        .tint(Brand.blue)
                    }
                }
            }
        }
    }
}

// MARK: - Parameter Row
struct ParameterRow: View {
    let parameter: StrategyParameter
    let onUpdate: (Double) -> Void
    
    var body: some View {
        HStack {
            Text(parameter.name)
                .font(.system(size: 13))
                .foregroundColor(TextColor.primary)
            
            Spacer()
            
            switch parameter.type {
            case .slider:
                HStack(spacing: 8) {
                    Text(String(format: "%.0f", parameter.value))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Brand.blue)
                        .frame(width: 40)
                    
                    Slider(
                        value: Binding(
                            get: { parameter.value },
                            set: { onUpdate($0) }
                        ),
                        in: parameter.min...parameter.max,
                        step: parameter.step
                    )
                    .frame(width: 120)
                    .tint(Brand.blue)
                }
                
            case .stepper:
                Stepper(
                    value: Binding(
                        get: { parameter.value },
                        set: { onUpdate($0) }
                    ),
                    in: parameter.min...parameter.max,
                    step: parameter.step
                ) {
                    Text(String(format: "%.0f", parameter.value))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Brand.blue)
                }
                
            case .textField:
                TextField(
                    "",
                    value: Binding(
                        get: { parameter.value },
                        set: { onUpdate($0) }
                    ),
                    format: .number
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
                .font(.system(size: 13))
            }
        }
    }
}

// MARK: - Preview
struct StrategiesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StrategiesView()
                .environmentObject(AppSettings.shared)
        }
    }
}
