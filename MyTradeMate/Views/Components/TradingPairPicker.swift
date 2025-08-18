import SwiftUI

struct TradingPairPicker: View {
    @Binding var selectedPair: TradingPair
    @State private var showingPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trading Pair")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Button(action: {
                showingPicker = true
            }) {
                HStack {
                    Text(selectedPair.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingPicker) {
            TradingPairPickerSheet(selectedPair: $selectedPair)
        }
    }
}

struct TradingPairPickerSheet: View {
    @Binding var selectedPair: TradingPair
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Popular Pairs") {
                    ForEach(TradingPair.popular, id: \.symbol) { pair in
                        Button(action: {
                            selectedPair = pair
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pair.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(pair.symbol)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if pair.symbol == selectedPair.symbol {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Select Trading Pair")
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

#Preview {
    let btcAsset = Asset(symbol: "BTC", name: "Bitcoin", basePrecision: 8, pricePrecision: 2, minNotional: 10.0, icon: "bitcoinsign.circle")
    let tradingPair = TradingPair(base: btcAsset, quote: .USD)
    
    return TradingPairPicker(selectedPair: .constant(tradingPair))
}