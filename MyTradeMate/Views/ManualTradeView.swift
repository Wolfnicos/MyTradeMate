import SwiftUI

struct ManualTradeView: View {
    @StateObject private var vm = ManualTradeViewModel()
    var body: some View {
        Form {
            Section("Order") {
                TextField("Symbol (e.g. BTCUSDT)", text: $vm.symbol)
                TextField("Quantity", value: $vm.quantity, format: .number)
                Picker("Side", selection: $vm.side) {
                    Text("Buy").tag(ManualTradeViewModel.Side.buy)
                    Text("Sell").tag(ManualTradeViewModel.Side.sell)
                }
                Button("Place Order") { Task { await vm.placeOrder() } }
                    .disabled(!vm.canSubmit)
            }
            if let status = vm.status {
                Section("Status") { Text(status) }
            }
        }
        .navigationTitle("Manual Trade")
    }
}
