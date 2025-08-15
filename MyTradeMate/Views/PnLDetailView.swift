import SwiftUI
import Charts

struct PnLDetailView: View {
    @StateObject private var vm = PnLVM()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Equity").font(.caption)
                    Text(vm.equity, format: .currency(code: "USD")).font(.title2).bold()
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Today (realized)").font(.caption)
                    Text(formatPnL(vm.today)).font(.title3).bold().foregroundStyle(vm.today >= 0 ? .green : .red)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Unrealized").font(.caption)
                    Text(formatPnL(vm.unrealized))
                        .font(.headline)
                        .foregroundStyle(vm.unrealized >= 0 ? .green : .red)
                }
                
                Spacer()
                
                Picker("Timeframe", selection: $vm.timeframe) {
                    ForEach(PnLVM.Timeframe.allCases, id: \.rawValue) { tf in
                        Text(tf.rawValue).tag(tf)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
                .onChange(of: vm.timeframe) { newValue in
                    vm.setTimeframe(newValue)
                }
            }
            
            Chart {
                ForEach(Array(vm.history.enumerated()), id: \.offset) { index, item in
                    LineMark(
                        x: .value("Time", item.0),
                        y: .value("Equity", item.1)
                    )
                    .foregroundStyle(vm.equity >= 10000 ? .green : .red)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: vm.timeframeHours)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)).minute())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .currency(code: "USD"))
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("PnL")
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
    
    private func formatPnL(_ v: Double) -> String {
        let sign = v >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", v))"
    }
}
