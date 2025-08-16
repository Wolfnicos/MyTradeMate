import SwiftUI

// MARK: - Trade Confirmation Dialog
struct TradeConfirmationDialog: View {
    let trade: TradeRequest
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let onExecutionComplete: (Bool) -> Void // New callback for execution result
    
    @StateObject private var viewModel: TradeConfirmationViewModel
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
        self._viewModel = StateObject(wrappedValue: TradeConfirmationViewModel())
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
            isExecuting: viewModel.isExecuting,
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
                        if let trackedOrder = viewModel.getCurrentOrderStatus() {
                            orderStatusTrackingView(trackedOrder)
                        }
                        
                        // Error message if any
                        if !viewModel.errorMessage.isEmpty && !viewModel.showErrorAlert {
                            errorMessageView
                        }
                    }
                )
            }
        )
        .alert("Order Failed", isPresented: $viewModel.showErrorAlert) {
            Button("OK") {
                viewModel.clearError()
            }
            Button("Retry") {
                Task {
                    await handleTradeExecution()
                }
            }
        } message: {
            Text(viewModel.getErrorAlertMessage())
        }
        .onAppear {
            // Pass toast manager to view model
            viewModel.setToastManager(toastManager)
        }
    }
    
    private var confirmButtonText: String {
        if trade.isDemo {
            return "Confirm \(trade.side.rawValue.capitalized) (DEMO)"
        } else {
            return "Confirm \(trade.side.rawValue.capitalized)"
        }
    }
    
    private var tradingModeDisplayText: String {
        if trade.isDemo {
            return "DEMO"
        } else {
            switch trade.mode {
            case .manual:
                return "LIVE - MANUAL"
            case .auto:
                return "LIVE - AUTO"
            case .demo:
                return "DEMO"
            }
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
                    value: formatAmount(trade.amount),
                    valueColor: .primary
                )
                
                OrderSummaryRow(
                    label: "Est. Price",
                    value: "$\(trade.price, specifier: "%.2f")",
                    valueColor: .primary
                )
                
                OrderSummaryRow(
                    label: "Order Type",
                    value: "Market Order",
                    valueColor: .primary
                )
                
                OrderSummaryRow(
                    label: "Est. Value",
                    value: "$\(trade.amount * trade.price, specifier: "%.2f")",
                    valueColor: .primary,
                    valueWeight: .medium
                )
                
                Divider()
                
                OrderSummaryRow(
                    label: "Trading Mode",
                    value: tradingModeDisplayText,
                    valueColor: trade.modeColor,
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
        let success = await viewModel.executeTradeOrder(trade)
        
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Order Failed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                Text(viewModel.errorMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
    
    // MARK: - Order Status Tracking View
    
    private func orderStatusTrackingView(_ trackedOrder: TrackedOrder) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Order Status")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
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
        
        VStack(spacing: 20) {
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
                onExecutionComplete: { _ in }
            )
            
            TradeConfirmationDialog(
                trade: TradeRequest(
                    symbol: "ETH/USDT",
                    side: .sell,
                    amount: 0.5,
                    price: 3200.0,
                    mode: .auto,
                    isDemo: false
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