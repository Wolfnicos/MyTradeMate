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
                        TradingPairRow(
                            pair: pair,
                            isSelected: pair.symbol == selectedPair.symbol,
                            onSelect: {
                                selectedPair = pair
                                dismiss()
                            }
                        )
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
    TradingPairPicker(selectedPair: .constant(.btcUsd))
}

struct TradingPairRow: View {
    let pair: TradingPair
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
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
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}