import SwiftUI

/// Trade amount control with three modes: Fixed, % Equity, Risk %
struct TradeAmountControl: View {
    @Binding var amountMode: AmountMode
    @Binding var amountValue: Double
    let quoteCurrency: QuoteCurrency
    let currentEquity: Double
    let currentPrice: Double
    
    @State private var showingAdvanced = false
    @State private var tempFixedValue: String = ""
    @State private var tempPercentValue: Double = 5.0
    @State private var tempRiskValue: Double = 1.0
    
    init(
        amountMode: Binding<AmountMode>,
        amountValue: Binding<Double>,
        quoteCurrency: QuoteCurrency,
        currentEquity: Double = 10000,
        currentPrice: Double = 50000
    ) {
        self._amountMode = amountMode
        self._amountValue = amountValue
        self.quoteCurrency = quoteCurrency
        self.currentEquity = currentEquity
        self.currentPrice = currentPrice
        
        // Initialize temp values
        self._tempFixedValue = State(initialValue: String(format: "%.0f", amountValue.wrappedValue))
        self._tempPercentValue = State(initialValue: amountMode.wrappedValue == .percentOfEquity ? amountValue.wrappedValue : 5.0)
        self._tempRiskValue = State(initialValue: amountMode.wrappedValue == .riskPercent ? amountValue.wrappedValue : 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Trade Amount")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Choose position sizing method")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            // Mode selector
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    ForEach(AmountMode.allCases, id: \.rawValue) { mode in
                        ModeButton(
                            mode: mode,
                            isSelected: amountMode == mode,
                            action: {
                                switchToMode(mode)
                            }
                        )
                    }
                }
                .background(Color(.quaternarySystemFill))
                .cornerRadius(10)
                
                // Mode-specific control
                Group {
                    switch amountMode {
                    case .fixedNotional:
                        fixedAmountControl
                    case .percentOfEquity:
                        percentEquityControl
                    case .riskPercent:
                        riskPercentControl
                    }
                }
                .padding(.top, 4)
            }
            
            // Preview calculation
            tradePreview
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            syncTempValues()
        }
    }
    
    // MARK: - Mode Controls
    
    private var fixedAmountControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fixed Amount (\(quoteCurrency.displayName))")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack {
                Text(quoteCurrency.symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Amount", text: $tempFixedValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: tempFixedValue) { newValue in
                        if let value = Double(newValue), value > 0 {
                            amountValue = value
                        }
                    }
                
                Text("min \(quoteCurrency.symbol)10")
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondary)
            }
        }
    }
    
    private var percentEquityControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Equity Percentage")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(String(format: "%.1f", tempPercentValue))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            Slider(value: $tempPercentValue, in: 0.1...50.0, step: 0.1)
                .accentColor(.blue)
                .onChange(of: tempPercentValue) { newValue in
                    amountValue = newValue
                }
            
            HStack {
                Text("0.1%")
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondary)
                
                Spacer()
                
                Text("50%")
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondary)
            }
            
            Text("Current equity: \(quoteCurrency.symbol)\(String(format: "%.0f", currentEquity))")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private var riskPercentControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Risk Percentage")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(String(format: "%.1f", tempRiskValue))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
            }
            
            Slider(value: $tempRiskValue, in: 0.1...5.0, step: 0.1)
                .accentColor(.orange)
                .onChange(of: tempRiskValue) { newValue in
                    amountValue = newValue
                }
            
            HStack {
                Text("0.1%")
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondary)
                
                Spacer()
                
                Text("5%")
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondary)
            }
            
            Text("Risk-based sizing with ATR stop distance")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Trade Preview
    
    private var tradePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Trade Preview")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    showingAdvanced.toggle()
                }) {
                    Text(showingAdvanced ? "Less" : "More")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            
            // Basic preview
            let preview = calculatePreview()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quantity")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(preview.quantityDisplay)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Notional")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(preview.notionalDisplay)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            
            if showingAdvanced {
                Divider()
                
                VStack(spacing: 4) {
                    previewRow("Fee (10 bps)", preview.feeDisplay)
                    previewRow("Slippage (5 bps)", preview.slippageDisplay)
                    previewRow("Total Cost", preview.totalCostDisplay)
                    
                    if amountMode == .riskPercent {
                        previewRow("Max Risk", preview.maxRiskDisplay)
                        previewRow("Stop Distance", preview.stopDistanceDisplay)
                    }
                }
                .font(.system(size: 12))
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
    
    private func previewRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Helper Methods
    
    private func switchToMode(_ mode: AmountMode) {
        amountMode = mode
        
        // Update amount value based on mode
        switch mode {
        case .fixedNotional:
            if let value = Double(tempFixedValue), value > 0 {
                amountValue = value
            } else {
                amountValue = 250.0
                tempFixedValue = "250"
            }
        case .percentOfEquity:
            amountValue = tempPercentValue
        case .riskPercent:
            amountValue = tempRiskValue
        }
        
        Log.settings.info("[SETTINGS] Amount mode changed to \(mode.displayName)")
    }
    
    private func syncTempValues() {
        switch amountMode {
        case .fixedNotional:
            tempFixedValue = String(format: "%.0f", amountValue)
        case .percentOfEquity:
            tempPercentValue = amountValue
        case .riskPercent:
            tempRiskValue = amountValue
        }
    }
    
    private func calculatePreview() -> TradePreview {
        let mockRequest = OrderRequest(
            symbol: Symbol("BTC/\(quoteCurrency.rawValue)", exchange: .binance),
            side: .buy,
            quantity: 0.001
        )
        
        // Calculate quantity based on amount mode
        let quantity: Double
        let stopDistance = currentPrice * 0.02 // 2% ATR approximation
        
        switch amountMode {
        case .fixedNotional:
            quantity = amountValue / currentPrice
        case .percentOfEquity:
            quantity = (currentEquity * amountValue / 100.0) / currentPrice
        case .riskPercent:
            let riskAmount = currentEquity * (amountValue / 100.0)
            quantity = riskAmount / stopDistance
        }
        
        let notional = quantity * currentPrice
        let fee = notional * 0.001 // 10 bps
        let slippage = notional * 0.0005 // 5 bps
        let totalCost = notional + fee + slippage
        
        return TradePreview(
            quantity: quantity,
            notional: notional,
            fee: fee,
            slippage: slippage,
            totalCost: totalCost,
            maxRisk: currentEquity * (amountValue / 100.0),
            stopDistance: stopDistance,
            quoteCurrency: quoteCurrency
        )
    }
}

// MARK: - Mode Button

private struct ModeButton: View {
    let mode: AmountMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(mode.shortName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Trade Preview Model

private struct TradePreview {
    let quantity: Double
    let notional: Double
    let fee: Double
    let slippage: Double
    let totalCost: Double
    let maxRisk: Double
    let stopDistance: Double
    let quoteCurrency: QuoteCurrency
    
    var quantityDisplay: String {
        return String(format: "%.6f BTC", quantity)
    }
    
    var notionalDisplay: String {
        return "\(quoteCurrency.symbol)\(String(format: "%.2f", notional))"
    }
    
    var feeDisplay: String {
        return "\(quoteCurrency.symbol)\(String(format: "%.2f", fee))"
    }
    
    var slippageDisplay: String {
        return "\(quoteCurrency.symbol)\(String(format: "%.2f", slippage))"
    }
    
    var totalCostDisplay: String {
        return "\(quoteCurrency.symbol)\(String(format: "%.2f", totalCost))"
    }
    
    var maxRiskDisplay: String {
        return "\(quoteCurrency.symbol)\(String(format: "%.2f", maxRisk))"
    }
    
    var stopDistanceDisplay: String {
        return "\(quoteCurrency.symbol)\(String(format: "%.2f", stopDistance))"
    }
}

// MARK: - Preview

struct TradeAmountControl_Previews: PreviewProvider {
    @State static var amountMode: AmountMode = .percentOfEquity
    @State static var amountValue: Double = 5.0
    
    static var previews: some View {
        VStack(spacing: 20) {
            TradeAmountControl(
                amountMode: $amountMode,
                amountValue: $amountValue,
                quoteCurrency: .USD,
                currentEquity: 10000,
                currentPrice: 50000
            )
            
            Text("Mode: \(amountMode.displayName), Value: \(String(format: "%.1f", amountValue))")
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}