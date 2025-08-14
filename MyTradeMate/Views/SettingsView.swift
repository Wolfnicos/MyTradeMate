import SwiftUI

struct SettingsView: View {
    @StateObject private var vm = SettingsVM()
    
    var body: some View {
        Form {
            Section("Mode") {
                Picker("Trading Mode", selection: $vm.mode) {
                    Text("Paper").tag(TradingMode.paper)
                    Text("Live").tag(TradingMode.live)
                }
                .onChange(of: vm.mode) { _, m in vm.applyMode(m) }
            }
            
            Section("Exchange") {
                Picker("Exchange", selection: $vm.selectedExchange) {
                    ForEach(Exchange.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                .onChange(of: vm.selectedExchange) { _, ex in vm.applyExchange(ex) }
            }
            
            Section("Risk") {
                Stepper("Max Risk / Trade: \(vm.risk.maxRiskPercentPerTrade, specifier: "%.1f")%",
                        value: $vm.risk.maxRiskPercentPerTrade, in: 0.1...5, step: 0.1)
                Stepper("Max Daily Loss: \(vm.risk.maxDailyLossPercent, specifier: "%.1f")%",
                        value: $vm.risk.maxDailyLossPercent, in: 1...20, step: 0.5)
                Stepper("Default SL: \(vm.risk.defaultSLPercent, specifier: "%.1f")%",
                        value: $vm.risk.defaultSLPercent, in: 0.2...5, step: 0.1)
                Stepper("Default TP: \(vm.risk.defaultTPPercent, specifier: "%.1f")%",
                        value: $vm.risk.defaultTPPercent, in: 0.5...10, step: 0.1)
                Button("Save Risk Settings") { vm.saveRisk() }
            }
            
            Section("Trial") {
                Text(vm.trial.isActive ? "Trial active. Days left: \(vm.trial.daysRemaining)" : "Trial ended.")
            }
            
            Section("Support") {
                Link("Email Support", destination: URL(string: "mailto:MyTradeMate.app@gmail.com")!)
            }
            
            Section("About") {
                Text("MyTradeMate v1.0.0")
                Text("© 2025 MyTradeMate")
            }
        }
        .navigationTitle("Settings")
    }
}