import SwiftUI

struct DashboardView: View {
    @StateObject private var vm = DashboardVM()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Picker("Exchange", selection: $vm.exchange) {
                    ForEach(Exchange.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.menu)
                .onChange(of: vm.exchange) { ex in vm.changeExchange(ex) }
                
                Text(vm.symbol.display).font(.headline)
                Spacer()
            }
            
            Text(String(format: "$%.2f", vm.price))
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(vm.priceUp ? .green : .red)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: vm.price)
            
            PnLWidget(snapshot: vm.pnl)
            
            HStack {
                Picker("TF", selection: $vm.timeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                
                Picker("Mode", selection: $vm.aiMode) {
                    Text("Normal").tag(AIModelManager.Mode.normal)
                    Text("Precision").tag(AIModelManager.Mode.precision)
                }
                .pickerStyle(.segmented)
            }
            
            if let s = vm.lastSignal {
                Text("Signal: \(s.type?.rawValue.uppercased() ?? "UNKNOWN") • \(Int(s.confidence * 100))% • \(s.modelName ?? "N/A")")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .id(s.timestamp ?? Date())
            }
            
            HStack(spacing: 12) {
                Button { vm.generateSignal() } label: {
                    Label("New Signal", systemImage: "bolt.fill")
                }
                .buttonStyle(.borderedProminent)
                
                Toggle("Auto", isOn: $vm.autoTrading)
                    .toggleStyle(.switch)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Button { vm.buy() } label: { Text("BUY").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent)
                
                Button { vm.sell() } label: { Text("SELL").frame(maxWidth: .infinity) }
                    .buttonStyle(.bordered)
                    .tint(.red)
            }
        }
        .padding()
        .onAppear { vm.onAppear() }
        .navigationTitle("Dashboard")
        .navigationBarItems(trailing: NavigationLink(destination: PnLDetailView()) { Text("PnL") })
    }
}