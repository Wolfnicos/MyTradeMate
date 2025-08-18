import SwiftUI

// Using DesignSystem for spacing and corner radius

// MARK: - Trade Confirmation Dialog
struct TradeConfirmationDialog: View {
    let trade: TradeRequest
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let onExecutionComplete: (Bool) -> Void // New callback for execution result
    
    @State private var isExecuting = false
    @State private var executionError: String?
    @EnvironmentObject private var toastManager: ToastManager
    
    init(
        trade: TradeRequest,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onExecutionComplete: @escaping (Bool) -> Void
    ) {
        self.trade = trade
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self.onExecutionComplete = onExecutionComplete
        // Initialize state
    }
    
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
            onConfirm: handleConfirm,
            onCancel: onCancel,
            content: {
                AnyView(
                    VStack(spacing: 16) {
                        // Order Summary
                        orderSummaryView
                        
                        // Trading mode warning
                        tradingModeWarning
                        
                        // Order status tracking if available
                        // Order status tracking would go here
                        
                        // Error message if any
                        if let error = executionError {
                            errorMessageView
                        }
                    }
                )
            }
        )
        .onAppear {
            // Initialize if needed
        }
    }
    
    private var confirmButtonText: String {
        if AppSettings.shared.demoMode {
            return "Confirm \(trade.side.rawValue.capitalized) (DEMO)"
        } else {
            return "Confirm \(trade.side.rawValue.capitalized)"
        }
    }
    
    private var tradingModeDisplayText: String {
        if AppSettings.shared.demoMode {
            return "DEMO"
        } else {
            return "LIVE TRADING"
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount >= 1.0 {
            return String(format: "%.4f", amount)
        } else if amount >= 0.001 {
            return String(format: "%.6f", amount)
        } else {
            return String(format: "%.8f", amount)
        }
    }
    
    private var orderSummaryView: some View {
        VStack(spacing: 16) {
            Text("Order Summary")
                .headlineStyle()
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
                    value: formatAmount(trade.amount),
                    valueColor: .primary
                )
                
                OrderSummaryRow(
                    label: "Est. Price",
                    value: String(format: "$%.2f", trade.price),
                    valueColor: .primary
                )
                
                OrderSummaryRow(
                    label: "Order Type",
                    value: "Market Order",
                    valueColor: .primary
                )
                
                OrderSummaryRow(
                    label: "Est. Value",
                    value: "$\(trade.amount * trade.price)",
                    valueColor: .primary,
                    valueWeight: .medium
                )
                
                Divider()
                
                OrderSummaryRow(
                    label: "Trading Mode",
                    value: tradingModeDisplayText,
                    valueColor: AppSettings.shared.demoMode ? .orange : .green,
                    valueWeight: .semibold,
                    showBadge: true
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Action Handlers
    
    private func handleConfirm() {
        Task {
            await handleTradeExecution()
        }
    }
    
    private func handleTradeExecution() async {
        isExecuting = true
        // Simulate trade execution
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        let success = true
        isExecuting = false
        
        // Notify parent of execution result
        onExecutionComplete(success)
        
        // If successful, also call the original onConfirm callback
        if success {
            onConfirm()
        }
    }
    
    // MARK: - UI Components
    
    private var errorMessageView: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Order Failed")
                    .subheadlineMediumStyle()
                    .foregroundColor(.red)
                
                Text(executionError ?? "")
                    .caption1Style()
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(12)
        .background(.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var tradingModeWarning: some View {
        Group {
            if AppSettings.shared.demoMode {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Demo Mode")
                            .subheadlineMediumStyle()
                            .foregroundColor(.orange)
                        
                        Text("This is a simulated trade - no real funds will be used")
                            .caption1Style()
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
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Live Trading")
                            .subheadlineMediumStyle()
                            .foregroundColor(.red)
                        
                        Text("This will place a real order with actual funds")
                            .caption1Style()
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Order Status Tracking View
    
    private func orderStatusTrackingView(_ trackedOrder: TrackedOrder) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Order Status")
                    .subheadlineMediumStyle()
                
                Spacer()
                
                Text("ID: \(String(trackedOrder.id.prefix(8)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            CompactOrderStatusView(trackedOrder: trackedOrder)
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
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
                .subheadlineStyle()
            
            Spacer()
            
            if showBadge {
                Text(value)
                    .caption1Style()
                    .fontWeight(valueWeight)
                    .foregroundColor(valueColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(valueColor.opacity(0.15))
                    .cornerRadius(6)
            } else {
                Text(value)
                    .subheadlineStyle()
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
        
        VStack(spacing: 20) {
            TradeConfirmationDialog(
                trade: TradeRequest(
                    symbol: "BTC/USDT",
                    side: .buy,
                    amount: 0.001,
                    price: 45000.0,
                    type: .market,
                    timeInForce: .goodTillCanceled
                ),
                onConfirm: {},
                onCancel: {},
                onExecutionComplete: { _ in }
            )
            
            TradeConfirmationDialog(
                trade: TradeRequest(
                    symbol: "ETH/USDT",
                    side: .sell,
                    amount: 0.5,
                    price: 3200.0,
                    type: .market,
                    timeInForce: .goodTillCanceled
                ),
                onConfirm: {},
                onCancel: {},
                onExecutionComplete: { _ in }
            )
        }
        .environmentObject(ToastManager())
        .padding()
    }
}