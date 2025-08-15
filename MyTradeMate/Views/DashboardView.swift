import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @StateObject private var vm = DashboardVM()
    @StateObject private var aiManager = AIModelManager.shared
    
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
            
            PnLWidget(snapshot: vm.pnl, isDemoMode: vm.isDemoPnL)
            
            HStack {
                Picker("TF", selection: $vm.timeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: vm.timeframe) { _ in
                    Task { await vm.refreshSignal(reason: "timeframe_changed") }
                }
                
                Picker("Mode", selection: $vm.aiMode) {
                    Text("Normal").tag(AIModelManager.Mode.normal)
                    Text("Precision").tag(AIModelManager.Mode.precision)
                }
                .pickerStyle(.segmented)
            }
            
            if let prediction = vm.lastPrediction {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI Signal: \(prediction.signal.rawValue.uppercased())")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(signalColor(for: prediction.signal))
                            
                            Text("\(prediction.modelUsed) • \(prediction.timeframe.rawValue)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(prediction.confidence * 100))%")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                            
                            Text(DateFormatter.localizedString(from: prediction.timestamp, dateStyle: .none, timeStyle: .short))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let reasoning = prediction.reasoning {
                        Text(reasoning)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(vm.signalFlashColor?.opacity(0.1) ?? Color.secondary.opacity(0.05))
                        .animation(.easeInOut(duration: 0.3), value: vm.signalFlashColor)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .id(prediction.timestamp)
            } else if let decision = vm.lastAIDecision {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("AI Signal: \(decision.signal.rawValue.uppercased())")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(signalColor(for: decision.signal))
                        
                        Spacer()
                        
                        Text("\(Int(decision.confidence * 100))%")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if let reasoning = decision.reasoning {
                        Text(reasoning)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(vm.signalFlashColor?.opacity(0.1) ?? Color.secondary.opacity(0.05))
                        .animation(.easeInOut(duration: 0.3), value: vm.signalFlashColor)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .id(decision.timestamp)
            } else if let s = vm.lastSignal {
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
        .onAppear { 
            vm.configure(with: appSettings)
            vm.onAppear() 
        }
        .navigationTitle("Dashboard")
        .navigationBarItems(trailing: NavigationLink(destination: PnLDetailView()) { Text("PnL") })
    }
    
    private func signalColor(for signal: MyTradeMate.SignalType) -> Color {
        switch signal {
        case .buy: return .green
        case .sell: return .red
        case .hold: return .gray
        }
    }
}