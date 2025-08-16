import SwiftUI

// MARK: - Trade Confirmation Dialog
struct TradeConfirmationDialog: View {
    let trade: TradeRequest
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let isExecuting: Bool
    
    var body: some View {
        ConfirmationDialog(
            title: "Confirm Trade",
            message: "Please review your order details",
            icon: trade.side == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
            iconColor: trade.side == .buy ? .green : .red,
            confirmButtonText: confirmButtonText,
            confirmButtonColor: trade.side == .buy ? .green : .red,
            cancelButtonText: "Cancel",
            isDestructive: false,
            isExecuting: isExecuting,
            onConfirm: onConfirm,
            onCancel: onCancel,
            content: {
                AnyView(
                    VStack(spacing: 16) {
                        // Order Summary
                        orderSummaryView
                        
                        // Trading mode warning
                        tradingModeWarning
                    }
                )
            }
        )
    }
    
    private var confirmButtonText: String {
        if trade.isDemo {
            return "Confirm \(trade.side.rawValue.capitalized) (DEMO)"
        } else {
            return "Confirm \(trade.side.rawValue.capitalized)"
        }
    }
    
    private var orderSummaryView: some View {
        VStack(spacing: 16) {
            Text("Order Summary")
                .font(.headline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                OrderSummaryRow(
                    label: "Symbol",
                    value: trade.symbol,
                    valueColor: .primary
                )
                
                OrderSummaryRow(
                    label: "Side",
                    value: trade.side.rawValue.uppercased(),
                    valueColor: trade.side == .buy ? .green : .red,
                    valueWeight: .semibold
                )
                
                OrderSummaryRow(
                    label: "Amount",
                    value: String(format: "%.6f", trade.amount),
                    valueColor: .primary
                )
                
                OrderSummaryRow(
                    label: "Est. Price",
                    value: "$\(trade.price, specifier: "%.2f")",
                    valueColor: .primary
                )
                
                OrderSummaryRow(
                    label: "Est. Value",
                    value: "$\(trade.amount * trade.price, specifier: "%.2f")",
                    valueColor: .primary,
                    valueWeight: .medium
                )
                
                Divider()
                
                HStack {
                    Text("Mode")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(trade.isDemo ? .orange : .green)
                            .frame(width: 8, height: 8)
                        
                        Text(trade.isDemo ? "DEMO" : "LIVE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(trade.isDemo ? .orange : .green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((trade.isDemo ? Color.orange : Color.green).opacity(0.15))
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var tradingModeWarning: some View {
        Group {
            if trade.isDemo {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Demo Mode")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                        
                        Text("This is a simulated trade - no real funds will be used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(.orange.opacity(0.1))
                .cornerRadius(8)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Live Trading")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        Text("This will place a real order with actual funds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Order Summary Row
struct OrderSummaryRow: View {
    let label: String
    let value: String
    let valueColor: Color
    let valueWeight: Font.Weight
    let showBadge: Bool
    
    init(
        label: String,
        value: String,
        valueColor: Color = .primary,
        valueWeight: Font.Weight = .regular,
        showBadge: Bool = false
    ) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.valueWeight = valueWeight
        self.showBadge = showBadge
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if showBadge {
                Text(value)
                    .font(.caption)
                    .fontWeight(valueWeight)
                    .foregroundColor(valueColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(valueColor.opacity(0.15))
                    .cornerRadius(6)
            } else {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(valueWeight)
                    .foregroundColor(valueColor)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        TradeConfirmationDialog(
            trade: TradeRequest(
                symbol: "BTC/USDT",
                side: .buy,
                amount: 0.001,
                price: 45000.0,
                mode: .manual,
                isDemo: true
            ),
            onConfirm: {},
            onCancel: {},
            isExecuting: false
        )
        .padding()
    }
}