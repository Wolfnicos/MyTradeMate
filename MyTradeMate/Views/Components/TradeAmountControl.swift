import SwiftUI

struct TradeAmountControl: View {
    @Binding var amountMode: AmountMode
    @Binding var amountValue: Double
    let quoteCurrency: String
    let currentEquity: Double
    let currentPrice: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trade Amount")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            // Mode selector
            Picker("Amount Mode", selection: $amountMode) {
                ForEach(AmountMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            // Amount input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(amountInputLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(calculatedAmountText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    TextField("Amount", value: $amountValue, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                    
                    Text(amountUnit)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(minWidth: 40, alignment: .leading)
                }
                
                // Quick amount buttons
                HStack(spacing: 8) {
                    ForEach(quickAmounts, id: \.self) { amount in
                        Button(action: {
                            amountValue = amount
                        }) {
                            Text(quickAmountText(amount))
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var amountInputLabel: String {
        switch amountMode {
        case .percentOfEquity:
            return "Percentage of equity"
        case .fixedNotional:
            return "Fixed amount in \(quoteCurrency)"
        case .riskPercent:
            return "Risk percentage"
        }
    }
    
    private var amountUnit: String {
        switch amountMode {
        case .percentOfEquity, .riskPercent:
            return "%"
        case .fixedNotional:
            return quoteCurrency
        }
    }
    
    private var calculatedAmountText: String {
        let calculatedAmount = calculateTradeAmount()
        return String(format: "≈ %.2f %@", calculatedAmount, quoteCurrency)
    }
    
    private var quickAmounts: [Double] {
        switch amountMode {
        case .percentOfEquity, .riskPercent:
            return [1, 2, 5, 10, 25]
        case .fixedNotional:
            return [100, 250, 500, 1000, 2500]
        }
    }
    
    private func quickAmountText(_ amount: Double) -> String {
        switch amountMode {
        case .percentOfEquity, .riskPercent:
            return "\(Int(amount))%"
        case .fixedNotional:
            return "$\(Int(amount))"
        }
    }
    
    private func calculateTradeAmount() -> Double {
        switch amountMode {
        case .percentOfEquity:
            return currentEquity * (amountValue / 100)
        case .fixedNotional:
            return amountValue
        case .riskPercent:
            // Risk-based calculation would be more complex
            // For now, use a simple percentage of equity
            return currentEquity * (amountValue / 100)
        }
    }
}

#Preview {
    TradeAmountControl(
        amountMode: .constant(.percentOfEquity),
        amountValue: .constant(5.0),
        quoteCurrency: "USDT",
        currentEquity: 10000.0,
        currentPrice: 45000.0
    )
    .padding()
}