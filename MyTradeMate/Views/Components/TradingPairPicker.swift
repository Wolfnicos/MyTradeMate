import SwiftUI

/// Trading pair picker with asset and quote currency selection
struct TradingPairPicker: View {
    @Binding var selectedPair: TradingPair
    @State private var selectedAsset: Asset
    @State private var selectedQuote: QuoteCurrency
    
    // Visual styling
    private let cornerRadius: CGFloat = 12
    private let padding: CGFloat = 16
    
    init(selectedPair: Binding<TradingPair>) {
        self._selectedPair = selectedPair
        self._selectedAsset = State(initialValue: selectedPair.wrappedValue.base)
        self._selectedQuote = State(initialValue: selectedPair.wrappedValue.quote)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Trading Pair")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Select asset and account currency")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            // Asset picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Asset")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Asset.allAssets, id: \.symbol) { asset in
                            AssetButton(
                                asset: asset,
                                isSelected: selectedAsset.symbol == asset.symbol,
                                action: {
                                    selectedAsset = asset
                                    updatePair()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Quote currency picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Account Currency")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ForEach(QuoteCurrency.allCases, id: \.rawValue) { quote in
                        QuoteButton(
                            quote: quote,
                            isSelected: selectedQuote == quote,
                            action: {
                                selectedQuote = quote
                                updatePair()
                            }
                        )
                    }
                    
                    Spacer()
                }
            }
            
            // Current pair display
            HStack {
                Image(systemName: selectedAsset.icon)
                    .foregroundColor(.blue)
                    .font(.system(size: 18, weight: .medium))
                
                Text(selectedPair.symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Exchange rate display
                if selectedQuote != .USD {
                    Text(FXService.shared.getRateDisplayString(from: .USD, to: selectedQuote))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(6)
                }
            }
            .padding(.top, 8)
        }
        .padding(padding)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(cornerRadius)
        .onChange(of: selectedPair) { newPair in
            selectedAsset = newPair.base
            selectedQuote = newPair.quote
        }
    }
    
    private func updatePair() {
        let newPair = TradingPair(base: selectedAsset, quote: selectedQuote)
        if newPair != selectedPair {
            selectedPair = newPair
            
            // Log pair change
            Log.settings.info("[SETTINGS] Trading pair changed to \(newPair.symbol)")
        }
    }
}

// MARK: - Asset Button

private struct AssetButton: View {
    let asset: Asset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: asset.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(asset.symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(asset.name)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Quote Button

private struct QuoteButton: View {
    let quote: QuoteCurrency
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(quote.symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(quote.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color(.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color(.quaternarySystemFill), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview

struct TradingPairPicker_Previews: PreviewProvider {
    @State static var selectedPair = TradingPair.btcUsd
    
    static var previews: some View {
        VStack(spacing: 20) {
            TradingPairPicker(selectedPair: $selectedPair)
            
            Text("Selected: \(selectedPair.symbol)")
                .font(.headline)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}